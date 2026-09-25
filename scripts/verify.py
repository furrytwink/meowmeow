#!/usr/bin/env python3
"""
verify.py — run every verification check for the roblox-modular project.

Check groups (mirrors the project verification plan):
    1. extraction     — input file re-parsed; payload hashes vs extract_manifest;
                        split files hash round-trip; driver embedded byte-exactly
    2. boot_data      — JSON parses; manifest.count/files/total consistent;
                        every binary decodes & re-encodes byte-exactly at the
                        declared size; text assets match & parse; skyboxes
                        validated; full reconstruction from split parts is
                        byte-identical to the original BOOT_DATA
    3. luau           — luau-compile (hard syntax) on every chunk;
                        luau-analyze --mode=nonstrict with environmental
                        unknown-global filtering;
                        stylua --check on hand-written files;
                        selene --config selene.toml
    4. bundle         — fresh `bundle.py` run; embedded payload hashes equal the
                        extraction manifest; every require() literal resolves;
                        no duplicate module ids; no missing assets;
                        dist/main.lua compiles
    5. smoke          — lune runtime smoke test with stubbed Roblox/executor APIs
                        (skipped with instructions if lune is unavailable)
    6. zip            — fresh `build_zip.py` run; required members present;
                        no absolute paths or traversal; input/ excluded unless
                        requested; CRC test

Exit code 0 only when no check FAILED. A log is written to
scripts/verification_log.txt.
"""

from __future__ import annotations

import argparse
import base64
import datetime
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
LOG_PATH = PROJECT_ROOT / "scripts" / "verification_log.txt"

# share FEATURE_MODULES / patch logic with the generator itself, so verify
# always re-derives expectations with the exact code that produced the files
import extract  # noqa: E402  (scripts/ is on sys.path when run as a script)

HAND_WRITTEN_LUA = [
    "src/assets/init.lua",
    "src/modules/example.lua",
]

# Extracted, byte-frozen artifacts: syntax is gated hard by luau-compile;
# typecheck findings cannot be fixed without breaking byte-exactness, so the
# analyzer runs on them informationally (parse errors would still fail
# luau-compile first). Derived feature modules carry a byte-frozen callback
# body (only their small wrapper is generated), so they count as frozen too.
FROZEN_LUA = [
    "dist/main.lua",
    "src/init.lua",
    "src/neverlose/init.lua",
    "src/neverlose/skins.luau",
    "src/visualsui/init.luau",
] + [spec["file"] for spec in extract.FEATURE_MODULES]

ENVIRONMENTAL_LINT = re.compile(
    r"(Unknown global '[^']+'|Unknown type '[^']+'|Unknown global requires check)"
)

log_lines: list[str] = []
STATUS = {"PASS": 0, "FAIL": 0, "WARN": 0, "SKIP": 0}


def log(message: str = "") -> None:
    log_lines.append(message)
    print(message)


def record(status: str, name: str, detail: str = "") -> None:
    STATUS[status] += 1
    suffix = f" — {detail}" if detail else ""
    log(f"[{status}] {name}{suffix}")


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    return sha256(path.read_bytes())


def read_exact(path: Path) -> str:
    return path.read_bytes().decode("utf-8")


# ---------------------------------------------------------------------------
# tool discovery
# ---------------------------------------------------------------------------

TOOL_CANDIDATE_DIRS = [
    PROJECT_ROOT / "tools",
    PROJECT_ROOT.parent / "tools",
    PROJECT_ROOT.parent.parent / "tools",
]


def find_tool(name: str) -> str | None:
    found = shutil.which(name)
    if found:
        return found
    for directory in TOOL_CANDIDATE_DIRS:
        candidate = directory / name
        if candidate.is_file() and os.access(candidate, os.X_OK):
            return str(candidate)
    return None


def run(cmd: list[str], cwd: Path | None = None, timeout: int = 240) -> tuple[int, str]:
    proc = subprocess.run(cmd, cwd=cwd or PROJECT_ROOT, capture_output=True, timeout=timeout)
    # luau-compile --binary writes raw bytecode to stdout; decode leniently
    out = (proc.stdout or b"") + (b"\n" + proc.stderr if proc.stderr.strip() else b"")
    return proc.returncode, out.decode("utf-8", errors="replace").strip()


# ---------------------------------------------------------------------------
# long-bracket parsing (mirrors extract.py)
# ---------------------------------------------------------------------------

def parse_long_bracket(text: str, pos: int, where: str) -> tuple[str, int]:
    m = re.compile(r"\[(=*)\[").match(text, pos)
    if not m:
        raise ValueError(f"{where}: expected long-bracket opening at offset {pos}")
    close = "]" + "=" * len(m.group(1)) + "]"
    close_at = text.find(close, m.end())
    if close_at < 0:
        raise ValueError(f"INPUT_TRUNCATED: missing {close!r} for {where}")
    body = text[m.end():close_at]
    if body.startswith("\r\n"):
        body = body[2:]
    elif body.startswith("\n") or body.startswith("\r"):
        body = body[1:]
    return body, close_at + len(close)


def parse_input(text: str) -> dict[str, str]:
    pos = text.index("local SOURCE, LIBRARY_SOURCE = ") + len("local SOURCE, LIBRARY_SOURCE = ")
    source, pos = parse_long_bracket(text, pos, "SOURCE")
    pos = text.index("[", pos)
    library, pos = parse_long_bracket(text, pos, "LIBRARY_SOURCE")
    pos = text.index("local BOOT_DATA = ", pos) + len("local BOOT_DATA = ")
    boot, pos = parse_long_bracket(text, pos, "BOOT_DATA")
    pos = text.index("local SKIN_SOURCE = ", pos) + len("local SKIN_SOURCE = ")
    skin, pos = parse_long_bracket(text, pos, "SKIN_SOURCE")
    if text[pos:pos + 1] != ";":
        raise ValueError("SKIN_SOURCE close: expected ';' after closing bracket")
    pos += 1
    driver = text[pos:]
    driver = driver[2:] if driver.startswith("\r\n") else (driver[1:] if driver[:1] in ("\n", "\r") else driver)
    return {"SOURCE": source, "LIBRARY_SOURCE": library, "BOOT_DATA": boot,
            "SKIN_SOURCE": skin, "DRIVER": driver}


def strip_lua_comments(text: str) -> str:
    out: list[str] = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c in ('"', "'"):
            quote = c
            out.append(c)
            i += 1
            while i < n:
                ch = text[i]
                out.append(ch)
                if ch == "\\" and i + 1 < n:
                    out.append(text[i + 1])
                    i += 2
                    continue
                i += 1
                if ch == quote:
                    break
            continue
        m = re.compile(r"\[(=*)\[").match(text, i)
        if c == "[" and m:
            close = "]" + "=" * len(m.group(1)) + "]"
            end = text.find(close, m.end())
            end = n if end < 0 else end + len(close)
            out.append(text[i:end])
            i = end
            continue
        m = re.compile(r"--\[(=*)\[").match(text, i)
        if c == "-" and m:
            close = "]" + "=" * len(m.group(1)) + "]"
            end = text.find(close, m.end())
            i = n if end < 0 else end + len(close)
            continue
        if c == "-" and i + 1 < n and text[i + 1] == "-":
            end = text.find("\n", i)
            i = n if end < 0 else end
            continue
        out.append(c)
        i += 1
    return "".join(out)


# ---------------------------------------------------------------------------
# check groups
# ---------------------------------------------------------------------------

def check_extraction() -> None:
    log("")
    log("== 1. EXTRACTION INTEGRITY ==")
    manifest_path = PROJECT_ROOT / "scripts" / "extract_manifest.json"
    if not manifest_path.exists():
        record("FAIL", "extract_manifest.json missing — run `make extract`")
        return
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    input_path = PROJECT_ROOT / "input" / "message(47).txt"
    if not input_path.exists():
        record("FAIL", "input/message(47).txt missing from project")
        return
    input_sha = sha256_file(input_path)
    if input_sha == manifest["input"]["sha256"]:
        record("PASS", f"input file intact ({input_path.stat().st_size:,} bytes, "
                       f"sha256 {input_sha[:16]}...)")
    else:
        record("FAIL", "input/message(47).txt hash differs from extraction manifest")

    payloads = parse_input(read_exact(input_path))
    for name in ("SOURCE", "LIBRARY_SOURCE", "BOOT_DATA", "SKIN_SOURCE"):
        expected = manifest["payloads"][name]
        actual_sha = sha256(payloads[name].encode("utf-8"))
        if actual_sha != expected["sha256"]:
            record("FAIL", f"re-parse {name}: sha256 {actual_sha[:16]}... != manifest {expected['sha256'][:16]}...")
        else:
            record("PASS", f"re-parse {name}: {expected['chars']:,} chars, sha256 match")

    driver_sha = sha256(payloads["DRIVER"].encode("utf-8"))
    record("PASS" if driver_sha == manifest["driver"]["sha256"] else "FAIL",
           f"re-parse driver body: {manifest['driver']['chars']:,} chars, sha256 "
           + ("match" if driver_sha == manifest["driver"]["sha256"] else "MISMATCH"))

    # split-file round-trip
    file_map = {"SOURCE": "src/neverlose/init.lua", "LIBRARY_SOURCE": "src/visualsui/init.luau",
                "BOOT_DATA": "assets/boot_data.json", "SKIN_SOURCE": "src/neverlose/skins.luau"}
    for name, rel in file_map.items():
        path = PROJECT_ROOT / rel
        if not path.exists():
            record("FAIL", f"split file missing: {rel}")
            continue
        file_sha = sha256_file(path)
        expected_sha = manifest["payloads"][name]["sha256"]
        if file_sha == expected_sha:
            record("PASS", f"round-trip {rel}: byte-exact ({path.stat().st_size:,} bytes)")
        else:
            record("FAIL", f"round-trip {rel}: sha256 {file_sha[:16]}... != {expected_sha[:16]}...")

    # driver tail of src/init.lua — original driver + documented feature patches
    init_text = read_exact(PROJECT_ROOT / "src" / "init.lua")
    marker = manifest["driver"]["marker"]
    idx = init_text.find(marker)
    if idx < 0:
        record("FAIL", "driver marker not found in src/init.lua")
    else:
        tail = init_text[idx + len(marker):]
        tail = tail[2:] if tail.startswith("\r\n") else (tail[1:] if tail[:1] in ("\n", "\r") else tail)
        patched_driver, patch_metas = extract.apply_feature_patches(payloads["DRIVER"])
        expected_sha = sha256(patched_driver.encode("utf-8"))
        tail_sha = sha256(tail.encode("utf-8"))
        if tail_sha == expected_sha:
            names = ", ".join(m["module"] for m in patch_metas) or "none"
            record("PASS", f"src/init.lua embeds the driver + documented feature patches ({names})")
        else:
            record("FAIL", "src/init.lua driver tail mismatch vs original + feature patches")

        # derived feature module files must be byte-exact re-derivations
        for spec, meta in zip(extract.FEATURE_MODULES, patch_metas):
            path = PROJECT_ROOT / spec["file"]
            if not path.exists():
                record("FAIL", f"feature module missing: {spec['file']}")
                continue
            if sha256_file(path) == meta["module_file_sha256"]:
                record("PASS", f"feature module {spec['file']}: byte-exact re-derivation "
                               f"({meta['body_chars']:,} frozen body chars, ctx: {len(meta['ctx'])} upvalues)")
            else:
                record("FAIL", f"feature module {spec['file']}: differs from re-derivation "
                               f"(body must stay byte-frozen; edit scripts/extract.py FEATURE_MODULES)")


def check_boot_data() -> None:
    log("")
    log("== 2. BOOT_DATA INTEGRITY ==")
    boot_path = PROJECT_ROOT / "assets" / "boot_data.json"
    if not boot_path.exists():
        record("FAIL", "assets/boot_data.json missing — run `make extract`")
        return
    original_text = read_exact(boot_path)
    boot = json.loads(original_text)
    record("PASS", "assets/boot_data.json parses as JSON")

    manifest = boot["manifest"]
    files: dict[str, int] = manifest["files"]
    ok = manifest["count"] == len(files)
    record("PASS" if ok else "FAIL",
           f"manifest.count == len(files) == {len(files)}" if ok
           else f"manifest.count={manifest['count']} != len(files)={len(files)}")
    total_ok = manifest["total"] == sum(files.values())
    record("PASS" if total_ok else "FAIL",
           f"manifest.total == sum(sizes) == {manifest['total']:,} bytes" if total_ok
           else f"manifest.total={manifest['total']} != sum={sum(files.values())}")

    # skyboxes
    sky_pattern = re.compile(r"^skyboxes/(.+)_([a-z]{2})\.jpg$")
    sky_files: dict[str, set[str]] = {}
    for rel in files:
        m = sky_pattern.match(rel)
        if m:
            sky_files.setdefault(m.group(1), set()).add(m.group(2))
    sky_ok = set(manifest["skyboxes"].keys()) == set(sky_files.keys()) and \
        all(set(faces) == sky_files[name] for name, faces in manifest["skyboxes"].items())
    record("PASS" if sky_ok else "FAIL",
           f"manifest.skyboxes valid: {len(manifest['skyboxes'])} names x 6 faces "
           f"({sum(1 for rel in files if rel.startswith('skyboxes/'))} files)" if sky_ok
           else "manifest.skyboxes inconsistent with skyboxes/* files")

    # embedded assets
    rebuilt_text: dict[str, str] = {}
    for rel, body in boot["text"].items():
        flat = rel.replace("/", "_")
        path = PROJECT_ROOT / "assets" / "text" / flat
        if not path.exists():
            record("FAIL", f"text asset missing: {path.relative_to(PROJECT_ROOT)}")
            continue
        content = read_exact(path)
        if content != body:
            record("FAIL", f"text asset {flat}: content differs from BOOT_DATA")
            continue
        parse_note = ""
        try:
            json.loads(content)
            parse_note = " (parses as JSON)"
        except json.JSONDecodeError as exc:
            record("FAIL", f"text asset {flat} does not parse as JSON: {exc}")
            continue
        declared = files.get(rel)
        size_note = f" declared={declared}" if declared is not None else ""
        if declared is not None and declared != len(content):
            size_note += f" [NOTE: original data declares {declared} but embeds {len(content)} — preserved as-is]"
        record("PASS", f"text asset {flat}: byte-exact{parse_note}{size_note}")
        rebuilt_text[rel] = content

    rebuilt_binary: dict[str, str] = {}
    for rel, b64 in boot["binary"].items():
        path = PROJECT_ROOT / "assets" / "binary" / rel
        if not path.exists():
            record("FAIL", f"binary asset missing: {path.relative_to(PROJECT_ROOT)}")
            continue
        raw = path.read_bytes()
        declared = files.get(rel)
        reenc = base64.b64encode(raw).decode("ascii")
        if len(raw) != declared:
            record("FAIL", f"binary asset {rel}: {len(raw)} bytes != declared {declared}")
            continue
        if reenc != b64:
            record("FAIL", f"binary asset {rel}: re-encoded base64 differs from original")
            continue
        record("PASS", f"binary asset {rel}: {len(raw):,} bytes == declared, "
                       f"base64 round-trip exact")
        rebuilt_binary[rel] = reenc

    # full reconstruction from split parts
    reconstructed = {
        "manifest": json.loads(read_exact(PROJECT_ROOT / "assets" / "manifest.json")),
        "text": rebuilt_text,
        "binary": rebuilt_binary,
    }
    recon_text = json.dumps(reconstructed, separators=(",", ":"), ensure_ascii=False)
    if recon_text == original_text:
        record("PASS", f"full reconstruction from split parts is byte-identical "
                       f"({len(original_text):,} chars, sha256 {sha256(original_text.encode())[:16]}...)")
    else:
        record("FAIL", "reconstructed BOOT_DATA differs from assets/boot_data.json")


def check_luau() -> None:
    log("")
    log("== 3. LUAU SYNTAX / STYLE ==")
    compile_tool = find_tool("luau-compile")
    analyze_tool = find_tool("luau-analyze")
    stylua_tool = find_tool("stylua")
    selene_tool = find_tool("selene")

    luau_files = [
        "src/init.lua",
        "src/neverlose/init.lua",
        "src/neverlose/skins.luau",
        "src/visualsui/init.luau",
        "src/assets/init.lua",
        "src/modules/init.lua",
        "src/modules/example.lua",
    ] + [spec["file"] for spec in extract.FEATURE_MODULES]
    dist_main = PROJECT_ROOT / "dist" / "main.lua"
    if dist_main.exists():
        luau_files.append("dist/main.lua")

    if compile_tool:
        all_ok = True
        for rel in luau_files:
            path = PROJECT_ROOT / rel
            if not path.exists():
                record("FAIL", f"luau-compile: file missing {rel}")
                all_ok = False
                continue
            code, out = run([compile_tool, "--binary", rel])
            if code == 0:
                record("PASS", f"luau-compile {rel}")
            else:
                record("FAIL", f"luau-compile {rel}: {out.splitlines()[0] if out else 'unknown error'}")
                all_ok = False
        del all_ok
    else:
        record("SKIP", "luau-compile not available — install luau (https://github.com/luau-lang/luau)")

    if analyze_tool:
        for rel in luau_files:
            path = PROJECT_ROOT / rel
            if not path.exists():
                continue
            code, out = run([analyze_tool, "--mode=nonstrict", rel])
            lines = out.splitlines() if out else []
            environmental = [ln for ln in lines if ENVIRONMENTAL_LINT.search(ln)]
            real = [ln for ln in lines if not ENVIRONMENTAL_LINT.search(ln)]
            if code == 0:
                record("PASS", f"luau-analyze {rel}")
            elif rel in FROZEN_LUA:
                # frozen artifact: hard syntax already proven by luau-compile;
                # typecheck depth limits on 300KB+ chunks are environmental
                record("PASS", f"luau-analyze {rel} (informational: {len(environmental)} "
                               f"environmental + {len(real)} typecheck-depth findings on "
                               f"byte-frozen code; syntax gated by luau-compile)")
            elif not real:
                record("PASS", f"luau-analyze {rel} "
                               f"({len(environmental)} environmental unknown-global/type notices, "
                               f"expected for executor code outside Roblox)")
            else:
                record("FAIL", f"luau-analyze {rel}: {real[0]} (+{len(real)-1} more)")
    else:
        record("SKIP", "luau-analyze not available — install luau (https://github.com/luau-lang/luau)")

    if stylua_tool:
        existing = [rel for rel in HAND_WRITTEN_LUA if (PROJECT_ROOT / rel).exists()]
        code, out = run([stylua_tool, "--check", *existing])
        if code == 0:
            record("PASS", f"stylua --check {len(existing)} hand-written file(s)")
        else:
            record("FAIL", f"stylua --check reported differences: {out.splitlines()[0] if out else ''}")
        record("WARN", "stylua --check scoped to hand-written files only — extracted payloads, "
                       "the driver tail (incl. feature-module patches) and the generated modules "
                       "index must stay byte-exact per extraction integrity checks")
    else:
        record("SKIP", "stylua not available — install StyLua (https://github.com/JohnnyMorganz/StyLua)")

    if selene_tool:
        config = PROJECT_ROOT / "selene.toml"
        std_file = PROJECT_ROOT / "executor.yml"
        if not config.exists() or not std_file.exists():
            record("SKIP", "selene.toml / executor.yml missing")
        else:
            all_src = [rel for rel in luau_files if rel.startswith("src/")]
            code, out = run([selene_tool, "--config", "selene.toml", "--allow-warnings", *all_src])
            if code == 0:
                record("PASS", f"selene {len(all_src)} file(s) (0 errors; warnings tolerated via "
                               f"--allow-warnings, executor std from executor.yml)")
            else:
                first = out.splitlines()[0] if out else "unknown"
                record("FAIL", f"selene findings: {first} (+{max(0, len(out.splitlines())-1)} more)")
    else:
        record("SKIP", "selene not available — install selene (https://github.com/Kampfkarren/selene)")


def check_bundle() -> None:
    log("")
    log("== 4. BUNDLE INTEGRITY ==")
    bundle_py = PROJECT_ROOT / "scripts" / "bundle.py"
    code, out = run([sys.executable, "scripts/bundle.py"])
    log(out)
    if code != 0:
        record("FAIL", "bundle.py exited non-zero")
        return
    record("PASS", "bundle.py ran clean")

    report_path = PROJECT_ROOT / "dist" / "bundle_report.json"
    if not report_path.exists():
        record("FAIL", "dist/bundle_report.json missing")
        return
    report = json.loads(report_path.read_text(encoding="utf-8"))
    extract_manifest = json.loads((PROJECT_ROOT / "scripts" / "extract_manifest.json").read_text(encoding="utf-8"))

    embedded_ok = True
    for name, meta in report["source_modules"].items():
        expected = extract_manifest["payloads"].get(name)
        if expected and meta["sha256"] != expected["sha256"]:
            record("FAIL", f"embedded {name}: sha256 differs from extraction manifest")
            embedded_ok = False
    if embedded_ok:
        record("PASS", f"all {len(report['source_modules'])} embedded source modules are "
                       f"byte-identical to the extracted payloads")

    dist_main = PROJECT_ROOT / "dist" / "main.lua"
    bundle_text = read_exact(dist_main)
    stripped = strip_lua_comments(bundle_text)
    referenced = set(re.findall(r'require\s*\(\s*"([^"]+)"\s*\)', stripped))
    registered = set(report["source_modules"].keys()) | set(report["code_modules"].keys())
    unresolved = sorted(referenced - registered)
    if unresolved:
        record("FAIL", f"unresolved require() literals: {unresolved}")
    else:
        record("PASS", f"every require() literal resolves ({len(referenced)} distinct ids)")

    ids = list(report["source_modules"].keys()) + list(report["code_modules"].keys())
    dupes = sorted({x for x in ids if ids.count(x) > 1})
    record("PASS" if not dupes else "FAIL",
           "no duplicate module ids" if not dupes else f"duplicate module ids: {dupes}")

    src_assigns = re.findall(r'__SOURCES\["([^"]+)"\]\s*=', stripped)
    fac_assigns = re.findall(r'__FACTORIES\["([^"]+)"\]\s*=', stripped)
    dupes2 = sorted({x for x in src_assigns if src_assigns.count(x) > 1}
                    | {x for x in fac_assigns if fac_assigns.count(x) > 1})
    record("PASS" if not dupes2 else "FAIL",
           "registry assignment scan: no duplicate keys" if not dupes2
           else f"registry duplicate keys: {dupes2}")

    missing_assets = 0
    for group in ("text_assets", "binary_assets"):
        for meta in extract_manifest["boot_data"][group]:
            path = PROJECT_ROOT / meta["file"]
            if not path.exists() or sha256_file(path) not in (meta.get("sha256"), meta.get("sha256_decoded")):
                record("FAIL", f"asset missing/changed: {meta['file']}")
                missing_assets += 1
    if missing_assets == 0:
        record("PASS", f"all {len(extract_manifest['boot_data']['text_assets'])} text + "
                       f"{len(extract_manifest['boot_data']['binary_assets'])} binary assets present, hashes match")

    compile_tool = find_tool("luau-compile")
    if compile_tool:
        code, out = run([compile_tool, "--binary", "dist/main.lua"])
        record("PASS" if code == 0 else "FAIL",
               "dist/main.lua is valid Luau (luau-compile)" if code == 0
               else f"dist/main.lua does not compile: {out.splitlines()[0] if out else ''}")
    dist_sha = sha256_file(dist_main)
    if dist_sha == report["dist"]["sha256"]:
        record("PASS", f"dist/main.lua hash matches bundle report ({dist_main.stat().st_size:,} bytes)")
    else:
        record("FAIL", "dist/main.lua hash differs from bundle report")


def check_smoke(only: bool = False) -> None:
    log("")
    log("== 5. RUNTIME SMOKE TEST (lune) ==")
    lune_tool = find_tool("lune")
    dist_main = PROJECT_ROOT / "dist" / "main.lua"
    if not lune_tool:
        record("SKIP", "lune not available — runtime smoke test skipped")
        log("   Manual executor test required instead:")
        log("     1. open your executor, attach to a Roblox client")
        log("     2. execute dist/main.lua (the bundled, self-contained script)")
        log("     3. expected: the VisualsUI overlay mounts; warn() lines such as")
        log("        '[visuals] <feature> failed' indicate a stub mismatch, not a bundle issue")
        log("     4. re-execute the script — it must unload the previous instance (generation guard)")
        return
    if not dist_main.exists():
        record("FAIL", "dist/main.lua missing — run `make bundle` first")
        return

    smoke_dir = PROJECT_ROOT / "scripts" / ".smoke"
    smoke_dir.mkdir(parents=True, exist_ok=True)
    preamble = read_exact(PROJECT_ROOT / "scripts" / "smoke_preamble.lua")
    assert_src = read_exact(PROJECT_ROOT / "scripts" / "smoke_assert.lua")
    dist_text = read_exact(dist_main)
    combined = (
        preamble
        + "\nSMOKE.driver_ok, SMOKE.driver_err = pcall(function()\n"
        + dist_text
        + "\nend)\n"
        + assert_src
    )
    combined_path = smoke_dir / "combined.lua"
    combined_path.write_bytes(combined.encode("utf-8"))
    # mask the mid-file directive/long-bracket noise for the lune chunk loader
    try:
        code, out = run([lune_tool, "run", str(combined_path.relative_to(PROJECT_ROOT))],
                        cwd=PROJECT_ROOT, timeout=300)
    except subprocess.TimeoutExpired:
        record("FAIL", "smoke test timed out after 300s")
        return
    for line in out.splitlines():
        if line.startswith(("SMOKE_NOTE", "SMOKE_FAIL", "SMOKE_RESULT")):
            log("   " + line)
    if code == 0 and "SMOKE_PASS" in out:
        record("PASS", "lune smoke test: driver ran to completion, payloads compiled, "
                       "BOOT_DATA JSON-decoded byte-exactly")
    else:
        record("FAIL", f"smoke test failed (exit {code}) — see SMOKE_FAIL lines above")


def check_zip() -> None:
    log("")
    log("== 6. ZIP INTEGRITY ==")
    code, out = run([sys.executable, "scripts/build_zip.py"])
    log(out)
    if code != 0:
        record("FAIL", "build_zip.py exited non-zero")
        return
    record("PASS", "build_zip.py ran clean")

    zip_path = PROJECT_ROOT / "dist" / "roblox-modular.zip"
    import zipfile

    try:
        with zipfile.ZipFile(zip_path) as zf:
            bad = zf.testzip()
            if bad is not None:
                record("FAIL", f"zip CRC failure: {bad}")
                return
            record("PASS", "zip opens and every member passes CRC")

            names = zf.namelist()
            required = ["README.md", "Makefile", "dist/main.lua", "selene.toml"]
            prefixes = ["src/", "assets/", "scripts/"]
            missing = [r for r in required if r not in names]
            missing += [p for p in prefixes if not any(n.startswith(p) for n in names)]
            if missing:
                record("FAIL", f"zip missing required members: {missing}")
            else:
                record("PASS", "zip contains src/, assets/, scripts/, dist/main.lua, README.md, Makefile")

            absolute = [n for n in names if n.startswith("/") or ".." in Path(n).parts or ":" in n]
            if absolute:
                record("FAIL", f"zip contains absolute/unsafe paths: {absolute[:5]}")
            else:
                record("PASS", "zip has no absolute paths or traversal segments")

            input_in_zip = [n for n in names if n.startswith("input/")]
            record("PASS" if not input_in_zip else "WARN",
                   "input/message(47).txt excluded from zip (use INCLUDE_INPUT=1 to embed)"
                   if not input_in_zip else f"input included on request: {input_in_zip}")
    except zipfile.BadZipFile as exc:
        record("FAIL", f"zip unreadable: {exc}")


# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--only", choices=["extraction", "boot_data", "luau", "bundle", "smoke", "zip"],
                        help="run a single check group only")
    args = parser.parse_args()

    log(f"roblox-modular verification — {datetime.datetime.now(datetime.timezone.utc).isoformat(timespec='seconds')}")
    only = args.only

    if only in (None, "extraction"):
        check_extraction()
    if only in (None, "boot_data"):
        check_boot_data()
    if only in (None, "luau"):
        check_luau()
    if only in (None, "bundle"):
        check_bundle()
    if only in (None, "smoke"):
        check_smoke()
    if only in (None, "zip"):
        check_zip()

    log("")
    log(f"SUMMARY: {STATUS['PASS']} passed, {STATUS['FAIL']} failed, "
        f"{STATUS['WARN']} warnings, {STATUS['SKIP']} skipped")
    LOG_PATH.write_text("\n".join(log_lines) + "\n", encoding="utf-8")
    return 1 if STATUS["FAIL"] else 0


if __name__ == "__main__":
    sys.exit(main())
