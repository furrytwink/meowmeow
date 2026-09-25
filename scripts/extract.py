#!/usr/bin/env python3
"""
extract.py — split the monolithic input/message(47).txt into the modular project.

The input file layout (verified before every write):

    local SOURCE, LIBRARY_SOURCE = [===[ <SOURCE> ]===], [===[ <LIBRARY_SOURCE> ]===];
    local BOOT_DATA = [===[ <BOOT_DATA JSON> ]===];

    local SKIN_SOURCE = [===[ <SKIN_SOURCE> ]===];
    <driver body — top-level bootstrap code, ends with `return Visuals;`>

Extraction map:
    SOURCE          -> src/neverlose/init.lua      (raw chunk, byte-exact)
    LIBRARY_SOURCE  -> src/visualsui/init.luau     (raw chunk, byte-exact)
    BOOT_DATA       -> assets/boot_data.json       (exact JSON string)
                      + assets/manifest.json
                      + assets/text/*               (flattened: '/' -> '_')
                      + assets/binary/*             (base64-decoded bytes)
    SKIN_SOURCE     -> src/neverlose/skins.luau    (raw chunk, byte-exact)
    driver body     -> embedded verbatim as the tail of src/init.lua

Long-bracket semantics (Lua/Luau): if the first character after the opening
bracket is a line break, exactly that one break is skipped. This script
replicates that rule so extracted payloads are the *exact string values* the
original chunk produced at runtime.

A SHA256 manifest of every extracted payload is written to
scripts/extract_manifest.json for downstream verification.
"""

from __future__ import annotations

import base64
import datetime
import hashlib
import json
import re
import shutil
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
INPUT_FILE = PROJECT_ROOT / "input" / "message(47).txt"

MARKER = "-- [ EXTRACTED DRIVER BODY — everything below is byte-exact from input/message(47).txt ]"

# ---------------------------------------------------------------------------
# Feature modules — guard() blocks extracted from the driver into src/modules/.
#
# The original block is a closure over driver locals; the derived module is
#     return function(ctx) <byte-frozen callback body> end
# and the driver re-enters it via
#     guard("<guard>", function()
#         return require("<module>")({ <ctx fields> });
#     end);
#
# The callback body is re-derived from the input on every run (idempotent), so
# the module can never drift from the monolith. Blocks are located by their
# unique `guard("<name>", function()` anchor and sliced to their OWN balanced
# `end);` via scripts/lualex.py (no reliance on the next guard's position).
#
# `ctx` per block is audited by scripts/plan_feature_modules.py, which for
# every driver guard() block computes the exact free-variable set with a
# scope-aware Lua parser, cross-checks it against luau-analyze, rejects blocks
# that ASSIGN to a driver-local upvalue or use `...` in callback scope, and
# verifies no ctx name is reassigned later in the driver. A value-bound ctx
# reproduces upvalue reads exactly only under those conditions.
#
# The 25 guard blocks NOT listed here all read the driver's `ALIVE` flag,
# which the Unload function flips to false; a ctx copy would freeze it true
# and change unload behavior, so those blocks stay inline (byte-exact).
# ---------------------------------------------------------------------------

FEATURE_MODULES = [
    {
        "module": "modules.loading",
        "file": "src/modules/loading.lua",
        "guard": "loading",
        "ctx": ["NeverLose", "Remote", "RunService", "onUnload"],
        "summary": "loading screen / initial overlay",
    },
    {
        "module": "modules.links",
        "file": "src/modules/links.lua",
        "guard": "links",
        "ctx": ["NeverLose", "Notification", "Remote"],
        "summary": "social links panel",
    },
    {
        "module": "modules.cosmetics",
        "file": "src/modules/cosmetics.lua",
        "guard": "cosmetics",
        "ctx": ["ESP", "Sections", "Visuals", "onUnload"],
        "summary": "cosmetics feature",
    },
    {
        "module": "modules.backtrack",
        "file": "src/modules/backtrack.lua",
        "guard": "backtrack",
        "ctx": ["ESP", "Sections"],
        "summary": "backtrack feature",
    },
    {
        "module": "modules.world_fx_math",
        "file": "src/modules/world_fx_math.lua",
        "guard": "world_fx_math",
        "ctx": ["ESP"],
        "summary": "world FX math helpers",
    },
    {
        "module": "modules.weather",
        "file": "src/modules/weather.lua",
        "guard": "weather",
        "ctx": ["ESP", "INIT_GENERATION", "NeverLose", "Render", "RunService", "Sections", "TAG"],
        "summary": "weather effects feature",
    },
    {
        "module": "modules.misc",
        "file": "src/modules/misc.lua",
        "guard": "misc",
        "ctx": ["ESP", "GLOBAL", "LocalPlayer", "NeverLose", "Players", "RunService",
                "Sections", "onUnload"],
        "summary": "misc tweaks feature",
    },
    {
        "module": "modules.fun_hud",
        "file": "src/modules/fun_hud.lua",
        "guard": "fun hud",
        "ctx": ["LocalPlayer", "NeverLose", "RunService", "Sections", "onUnload"],
        "summary": "fun HUD feature",
    },
    {
        "module": "modules.aimbot",
        "file": "src/modules/aimbot.lua",
        "guard": "aimbot",
        "ctx": ["ESP", "LocalPlayer", "NeverLose", "Notification",
                "Players", "RunService", "Sections", "onUnload"],
        "summary": "aimbot / triggerbot / bot-targeting feature",
    },
    {
        "module": "modules.bot_esp",
        "file": "src/modules/bot_esp.lua",
        "guard": "bot esp",
        "ctx": ["NeverLose", "RunService", "Sections", "onUnload"],
        "summary": "bot ESP feature",
    },
    {
        "module": "modules.server",
        "file": "src/modules/server.lua",
        "guard": "server",
        "ctx": ["LocalPlayer", "NeverLose", "Notification", "Players", "RunService",
                "Sections", "onUnload"],
        "summary": "server info feature",
    },
    {
        "module": "modules.trade",
        "file": "src/modules/trade.lua",
        "guard": "trade",
        "ctx": ["ESP", "GLOBAL", "Remote", "Sections", "fluxus", "http"],
        "summary": "trade logger feature",
    },
    {
        "module": "modules.menu",
        "file": "src/modules/menu.lua",
        "guard": "menu",
        "ctx": ["ESP", "NeverLose", "Notification", "Preview", "Remote", "RunService",
                "Sections", "Window", "ownedSound"],
        "summary": "menu / UI wiring feature",
    },
    {
        "module": "modules.config",
        "file": "src/modules/config.lua",
        "guard": "config",
        "ctx": ["ESP", "NeverLose", "Window", "userFile"],
        "summary": "config save/load feature",
    },
]


class ExtractionError(Exception):
    pass


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def parse_long_bracket(text: str, pos: int, where: str) -> tuple[str, int]:
    """Parse a Lua long-bracket string starting at `pos`; return (value, end_pos).

    `end_pos` points just past the closing bracket. Applies Lua's
    skip-one-leading-newline rule so the returned value matches runtime semantics.
    """
    m = re.compile(r"\[(=*)\[").match(text, pos)
    if not m:
        raise ExtractionError(f"{where}: expected long-bracket opening at offset {pos}, found {text[pos:pos+12]!r}")
    level = len(m.group(1))
    close = "]" + "=" * level + "]"
    close_at = text.find(close, m.end())
    if close_at < 0:
        raise ExtractionError(
            f"INPUT_TRUNCATED: missing closing delimiter for {where} "
            f"(expected {close!r} after offset {m.end()})"
        )
    body = text[m.end():close_at]
    # Lua: skip exactly one leading line break (\r\n, \n or \r)
    if body.startswith("\r\n"):
        body = body[2:]
    elif body.startswith("\n") or body.startswith("\r"):
        body = body[1:]
    return body, close_at + len(close)


def expect(text: str, pos: int, literal: str, where: str) -> int:
    if not text.startswith(literal, pos):
        found = text[pos:pos + len(literal) + 24]
        raise ExtractionError(f"{where}: expected {literal!r} at offset {pos}, found {found!r}")
    return pos + len(literal)


def parse_input(text: str) -> dict:
    """Parse the four long-bracket payloads + trailing driver body."""
    pos = expect(text, 0, "local SOURCE, LIBRARY_SOURCE = ", "header")
    source, pos = parse_long_bracket(text, pos, "SOURCE")
    pos = expect(text, pos, ", ", "LIBRARY_SOURCE separator")
    library, pos = parse_long_bracket(text, pos, "LIBRARY_SOURCE")
    pos = expect(text, pos, ";", "LIBRARY_SOURCE close")
    pos = expect(text, pos, "\r\nlocal BOOT_DATA = ", "BOOT_DATA open")
    boot_data, pos = parse_long_bracket(text, pos, "BOOT_DATA")
    pos = expect(text, pos, ";", "BOOT_DATA close")
    pos = expect(text, pos, "\r\n\r\nlocal SKIN_SOURCE = ", "SKIN_SOURCE open")
    skin, pos = parse_long_bracket(text, pos, "SKIN_SOURCE")
    pos = expect(text, pos, ";", "SKIN_SOURCE close")
    driver = text[pos:]
    if driver.startswith("\r\n"):
        driver = driver[2:]
    elif driver.startswith("\n"):
        driver = driver[1:]
    elif driver.startswith("\r"):
        driver = driver[1:]
    if not driver:
        raise ExtractionError("driver body is empty — input truncated?")
    if not driver.rstrip().endswith("return Visuals;"):
        raise ExtractionError(
            "INPUT_TRUNCATED: driver body does not end with 'return Visuals;' "
            f"(ends with {driver.rstrip()[-60:]!r})"
        )
    return {"SOURCE": source, "LIBRARY_SOURCE": library, "BOOT_DATA": boot_data,
            "SKIN_SOURCE": skin, "DRIVER": driver}


def find_unique(text: str, needle: str, where: str) -> int:
    """Index of the single occurrence of `needle`, or ExtractionError."""
    hits = [m.start() for m in re.finditer(re.escape(needle), text)]
    if len(hits) != 1:
        raise ExtractionError(f"{where}: expected exactly one occurrence of {needle!r}, found {len(hits)}")
    return hits[0]


def build_feature_module_text(spec: dict, body: str) -> str:
    """Derive src/modules/<name>.lua: ctx factory + byte-frozen callback body."""
    nl = "\r\n"  # the driver is CRLF; keep the derived module consistent
    ctx_locals = "".join(f"\tlocal {name} = ctx.{name};{nl}" for name in spec["ctx"])
    ctx_inline = ", ".join(f"{name} = {name}" for name in spec["ctx"])
    header = (
        f"--!nonstrict{nl}"
        f"--[[{nl}"
        f"\t{Path(spec['file']).name} — extracted feature module (require id \"{spec['module']}\").{nl}"
        f"{nl}"
        f"\tAuto-derived by scripts/extract.py from input/message(47).txt: this is the{nl}"
        f"\tcallback body of guard(\"{spec['guard']}\") in the driver — byte-frozen original{nl}"
        f"\tcode below the marker (re-derived on every `make extract`; do not hand-edit).{nl}"
        f"{nl}"
        f"\tThe block originally closed over driver locals; the driver now passes them{nl}"
        f"\tin via the ctx table:{nl}"
        f"{nl}"
        f"\t\tguard(\"{spec['guard']}\", function(){nl}"
        f"\t\t\treturn require(\"{spec['module']}\")({{ {ctx_inline} }});{nl}"
        f"\t\tend);{nl}"
        f"]]{nl}"
        f"return function(ctx){nl}"
        f"{ctx_locals}"
        f"{nl}"
    )
    marker = f"-- [ guard(\"{spec['guard']}\") callback body — byte-exact from input/message(47).txt ]"
    return header + marker + nl + body + "end;" + nl


def build_feature_shim(spec: dict) -> str:
    """The driver-side replacement: guard() re-entered through the ctx factory."""
    nl = "\r\n"
    ctx_entries = "".join(f"\t\t{name} = {name},{nl}" for name in spec["ctx"])
    return (
        f"-- [ {spec['summary']} — extracted to {spec['file']}; driver locals it uses are bound via ctx ]{nl}"
        f"guard(\"{spec['guard']}\", function(){nl}"
        f"\treturn require(\"{spec['module']}\")({{{nl}"
        f"{ctx_entries}"
        f"\t}});{nl}"
        f"end);"
    )


def apply_feature_patches(driver: str) -> tuple[str, list[dict]]:
    """Extract each FEATURE_MODULES guard block; return (patched driver, per-feature metas).

    Deterministic: the same input driver always yields byte-identical output.
    Each block is located by its unique `guard("<name>", function()` anchor and
    sliced to its own balanced `end);` with scripts/lualex.py, then moved
    byte-for-byte into the derived module file — no payload content is
    interpreted or reformatted. Blocks are disjoint; patches are applied from
    the last block backwards so earlier offsets stay valid.
    """
    import lualex  # scripts/ is on sys.path when extract.py runs

    # ---- locate + validate every block on the ORIGINAL driver text ----------
    toks = lualex.lex(driver)
    token_at = {t.s: i for i, t in enumerate(toks)}
    plans: list[dict] = []
    for spec in FEATURE_MODULES:
        start_anchor = f"guard(\"{spec['guard']}\", function()"
        prefix = f"guard(\"{spec['guard']}\", "
        where = f"feature module {spec['module']}"
        start = find_unique(driver, start_anchor, where)
        func_kw_at = start + len(prefix)
        fi = token_at.get(func_kw_at)
        if fi is None or toks[fi].kind != "kw" or toks[fi].text != "function":
            raise ExtractionError(f"{where}: function keyword not found at offset {func_kw_at}")
        end_idx = lualex.find_statement_end(driver, toks, fi)
        close_end, _semi = lualex.offset_after_end(driver, toks, end_idx)
        block = driver[start:close_end]
        stripped = block.rstrip("\r\n")
        if not stripped.endswith("end);"):
            raise ExtractionError(f"{where}: block does not end with 'end);' (ends {stripped[-24:]!r})")
        if not stripped.startswith(start_anchor):
            raise ExtractionError(f"{where}: internal anchor alignment error")
        body = driver[start + len(start_anchor):toks[end_idx].s]
        if body.startswith("\r\n"):
            body = body[2:]
        elif body.startswith("\n") or body.startswith("\r"):
            body = body[1:]
        # body is everything between `function()` and the block's own `end`,
        # byte-exact (trailing indentation/newlines before `end` included)
        plans.append({
            "spec": spec,
            "start": start,
            "close_end": close_end,
            "body": body,
        })

    # disjointness guard
    ordered = sorted(plans, key=lambda p: p["start"])
    for a, b in zip(ordered, ordered[1:]):
        if b["start"] < a["close_end"]:
            raise ExtractionError(
                f"feature blocks overlap: {a['spec']['guard']} and {b['spec']['guard']}")

    # ---- patch from the last block backwards ---------------------------------
    metas: list[dict] = [None] * len(plans)  # type: ignore[list-item]
    patched = driver
    for idx in range(len(plans) - 1, -1, -1):
        plan = plans[idx]
        spec = plan["spec"]
        body = plan["body"]
        shim = build_feature_shim(spec)
        module_text = build_feature_module_text(spec, body)
        patched = patched[:plan["start"]] + shim + patched[plan["close_end"]:]
        stripped_block = driver[plan["start"]:plan["close_end"]].rstrip("\r\n")
        metas[idx] = {
            "module": spec["module"],
            "file": spec["file"],
            "guard": spec["guard"],
            "ctx": list(spec["ctx"]),
            "block_chars": len(stripped_block),
            "body_chars": len(body),
            "block_sha256": sha256(stripped_block.encode("utf-8")),
            "body_sha256": sha256(body.encode("utf-8")),
            "module_file_sha256": sha256(module_text.encode("utf-8")),
            "shim_sha256": sha256(shim.encode("utf-8")),
            "_module_text": module_text,
        }

    # ---- invariants ----------------------------------------------------------
    if patched.count('guard("') != driver.count('guard("'):
        raise ExtractionError("patched driver lost or gained guard() statements")
    for spec in FEATURE_MODULES:
        n = len(re.findall(re.escape(f'guard("{spec["guard"]}", function()'), patched))
        if n != 1:
            raise ExtractionError(
                f"patched driver: guard(\"{spec['guard']}\"...) appears {n} times (expected 1)")
    return patched, metas


PROLOGUE = """\
--!nonstrict
--[[
\tVisualsUI bootstrap — modular build.
\tGenerated by scripts/extract.py from input/message(47).txt.

\tThis file is the only entrypoint. The four payload strings of the original
\tmonolithic script are provided by the module system:

\t\trequire("neverlose")         -> SOURCE          (Luau chunk as a string)
\t\trequire("visualsui")         -> LIBRARY_SOURCE  (Luau chunk as a string)
\t\trequire("assets")            -> BOOT_DATA       (JSON string)
\t\trequire("neverlose.skins")   -> SKIN_SOURCE     (Luau chunk as a string)
\t\trequire("modules")           -> table of discovered code modules

\tThe chunk body below the marker is the original top-level driver, embedded
\tbyte-exactly except for documented feature-module patches: the guard()
\tblocks listed in FEATURE_MODULES (scripts/extract.py) are extracted into
\tsrc/modules/ and re-entered through require("modules.<name>") with their
\tdriver-local upvalues bound via a ctx table. Blocks that read the driver's
\tmutable ALIVE flag stay inline on purpose (a ctx copy would freeze it).
\tExecution order and behavior are identical to the original.
]]
local SOURCE = require("neverlose");
local LIBRARY_SOURCE = require("visualsui");
local BOOT_DATA = require("assets");
local SKIN_SOURCE = require("neverlose.skins");
local MODULES = require("modules");

{MARKER}
"""

MODULES_INIT_HEADER = """\
--!nonstrict
--[[
\tmodules/init.lua — module index.
\tAUTO-GENERATED by scripts/bundle.py from the files discovered under src/modules/.
\tAdding src/modules/<name>.lua makes it available as require("modules.<name>").
]]
local modules = {{}};

{ENTRIES}\
return modules;
"""

ASSETS_INIT = """\
--!nonstrict
--[[
	assets/init.lua — BOOT_DATA provider (dev mode).

	The original monolithic script inlined BOOT_DATA as a JSON string inside a
	long-bracket literal. The bootstrap driver expects require("assets") to
	return that exact JSON string (the driver runs
	HttpService:JSONDecode(BOOT_DATA) and then drops the reference).

	In the bundled dist/main.lua, scripts/bundle.py embeds the JSON from
	assets/boot_data.json verbatim as a source-string module, so this loader is
	bypassed and runtime behavior is byte-identical to the original.

	For un-bundled (dev) execution this loader reads assets/boot_data.json
	relative to getgenv().VISUALS_ROOT (the folder containing assets/).
	If VISUALS_ROOT is unset, the executor workspace root is assumed.
]]
local REL = "assets/boot_data.json"
local ROOT = (getgenv and getgenv().VISUALS_ROOT) or ""

local function fail(message)
	error("[assets] " .. message, 0)
end

if type(readfile) ~= "function" then
	fail("readfile is unavailable; run the bundled dist/main.lua or provide an executor environment.")
end

local path = ROOT .. REL

if type(isfile) == "function" and not isfile(path) then
	fail(
		"missing "
			.. path
			.. " — set getgenv().VISUALS_ROOT to the folder containing assets/, or use the bundled dist/main.lua."
	)
end

local ok, body = pcall(readfile, path)
if not ok or type(body) ~= "string" or body:sub(1, 1) ~= "{" then
	fail("could not read BOOT_DATA JSON from " .. path)
end

return body
"""

EXAMPLE_MODULE = """\
--!nonstrict
--[[
	modules/example.lua — template for new modules.

	Pattern:
	  1. drop a .lua/.luau file into src/modules/
	  2. run `make bundle` — the bundler auto-discovers it and regenerates
	     the modules index (src/modules/init.lua)
	  3. require it as require("modules.<name>") from anywhere in the project

	Module factories run once and are cached; return your public table.
]]
local Example = {}

Example.name = "example"

function Example.hello()
	return "hello from " .. Example.name
end

return Example
"""


def write_bytes(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)


def write_text(path: Path, text: str) -> None:
    write_bytes(path, text.encode("utf-8"))


def main() -> int:
    if not INPUT_FILE.exists():
        print(f"ERROR: input file not found: {INPUT_FILE}", file=sys.stderr)
        return 1

    raw = INPUT_FILE.read_bytes()
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise ExtractionError(f"input is not valid UTF-8: {exc}") from exc

    print(f"[extract] input: {INPUT_FILE.name} ({len(raw):,} bytes, sha256 {sha256(raw)[:16]}...)")

    payloads = parse_input(text)
    print("[extract] parsed payloads: SOURCE, LIBRARY_SOURCE, BOOT_DATA, SKIN_SOURCE + driver body")

    # ---- BOOT_DATA validation & split -------------------------------------
    try:
        boot = json.loads(payloads["BOOT_DATA"])
    except json.JSONDecodeError as exc:
        raise ExtractionError(f"BOOT_DATA is not valid JSON: {exc}") from exc

    if set(boot.keys()) != {"manifest", "text", "binary"}:
        raise ExtractionError(f"BOOT_DATA top-level keys unexpected: {sorted(boot.keys())}")

    manifest = boot["manifest"]
    files = manifest["files"]
    if manifest["count"] != len(files):
        raise ExtractionError(f"manifest.count={manifest['count']} != files={len(files)}")
    if manifest["total"] != sum(files.values()):
        raise ExtractionError("manifest.total != sum of file sizes")

    binary_assets: dict[str, str] = {}
    for rel, b64 in boot["binary"].items():
        try:
            decoded = base64.b64decode(b64, validate=True)
        except Exception as exc:  # noqa: BLE001
            raise ExtractionError(f"binary asset {rel}: invalid base64: {exc}") from exc
        declared = files.get(rel)
        if declared is None:
            raise ExtractionError(f"binary asset {rel} not present in manifest.files")
        if len(decoded) != declared:
            raise ExtractionError(f"binary asset {rel}: decoded {len(decoded)} != declared {declared}")
        if base64.b64encode(decoded).decode("ascii") != b64:
            raise ExtractionError(f"binary asset {rel}: base64 re-encode mismatch (non-standard encoding)")
        binary_assets[rel] = b64

    text_assets: dict[str, str] = {}
    for rel, body in boot["text"].items():
        declared = files.get(rel)
        if declared is None:
            raise ExtractionError(f"text asset {rel} not present in manifest.files")
        if not isinstance(body, str):
            raise ExtractionError(f"text asset {rel} is not a string")
        text_assets[rel] = body

    # skybox cross-check: skyboxes/<name>_<face>.jpg <-> manifest.skyboxes
    sky_pattern = re.compile(r"^skyboxes/(.+)_([a-z]{2})\.jpg$")
    sky_files: dict[str, set[str]] = {}
    for rel in files:
        m = sky_pattern.match(rel)
        if m:
            sky_files.setdefault(m.group(1), set()).add(m.group(2))
    skyboxes = manifest["skyboxes"]
    if set(skyboxes.keys()) != set(sky_files.keys()):
        raise ExtractionError("manifest.skyboxes names do not match skyboxes/* manifest.files entries")
    for name, faces in skyboxes.items():
        if set(faces) != sky_files[name]:
            raise ExtractionError(f"skybox {name}: faces {sorted(faces)} != files {sorted(sky_files[name])}")

    print(f"[extract] BOOT_DATA OK: {len(files)} manifest files, {len(text_assets)} text, {len(binary_assets)} binary, "
          f"{len(skyboxes)} skyboxes")

    # ---- write payload files ----------------------------------------------
    write_text(PROJECT_ROOT / "src" / "neverlose" / "init.lua", payloads["SOURCE"])
    write_text(PROJECT_ROOT / "src" / "visualsui" / "init.luau", payloads["LIBRARY_SOURCE"])
    write_text(PROJECT_ROOT / "src" / "neverlose" / "skins.luau", payloads["SKIN_SOURCE"])
    write_text(PROJECT_ROOT / "assets" / "boot_data.json", payloads["BOOT_DATA"])

    patched_driver, patch_metas = apply_feature_patches(payloads["DRIVER"])
    for meta in patch_metas:
        write_text(PROJECT_ROOT / meta["file"], meta["_module_text"])

    prologue = PROLOGUE.replace("{MARKER}", MARKER)
    write_text(PROJECT_ROOT / "src" / "init.lua", prologue + patched_driver)

    # ---- write asset files --------------------------------------------------
    manifest_json = json.dumps(manifest, separators=(",", ":"), ensure_ascii=False)
    write_text(PROJECT_ROOT / "assets" / "manifest.json", manifest_json)

    text_meta = []
    for rel in sorted(text_assets):
        flat = rel.replace("/", "_")
        write_text(PROJECT_ROOT / "assets" / "text" / flat, text_assets[rel])
        text_meta.append({
            "path": rel,
            "file": f"assets/text/{flat}",
            "sha256": sha256(text_assets[rel].encode("utf-8")),
            "declared_size": files[rel],
            "embedded_len": len(text_assets[rel]),
        })

    binary_meta = []
    for rel in sorted(binary_assets):
        rel_path = rel.replace("\\", "/")
        if rel_path.startswith("/") or ".." in rel_path.split("/"):
            raise ExtractionError(f"unsafe asset path: {rel}")
        decoded = base64.b64decode(binary_assets[rel], validate=True)
        write_bytes(PROJECT_ROOT / "assets" / "binary" / rel_path, decoded)
        binary_meta.append({
            "path": rel,
            "file": f"assets/binary/{rel_path}",
            "sha256_decoded": sha256(decoded),
            "declared_size": files[rel],
            "decoded_size": len(decoded),
            "b64_sha256": sha256(binary_assets[rel].encode("ascii")),
        })

    # ---- generated support files --------------------------------------------
    write_text(PROJECT_ROOT / "src" / "assets" / "init.lua", ASSETS_INIT)
    write_text(PROJECT_ROOT / "src" / "modules" / "example.lua", EXAMPLE_MODULE)
    write_text(
        PROJECT_ROOT / "src" / "modules" / "init.lua",
        MODULES_INIT_HEADER.format(ENTRIES='modules["example"] = require("modules.example");\n\n'),
    )

    # keep a pristine copy of the input inside the project
    project_input = PROJECT_ROOT / "input" / "message(47).txt"
    if not project_input.exists() or project_input.read_bytes() != raw:
        project_input.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(INPUT_FILE, project_input)

    # ---- extraction manifest -------------------------------------------------
    extract_manifest = {
        "generated_utc": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
        "input": {"path": "input/message(47).txt", "sha256": sha256(raw), "bytes": len(raw)},
        "payloads": {
            name: {
                "sha256": sha256(payloads[name].encode("utf-8")),
                "chars": len(payloads[name]),
                "file": dest,
            }
            for name, dest in (
                ("SOURCE", "src/neverlose/init.lua"),
                ("LIBRARY_SOURCE", "src/visualsui/init.luau"),
                ("BOOT_DATA", "assets/boot_data.json"),
                ("SKIN_SOURCE", "src/neverlose/skins.luau"),
            )
        },
        "driver": {
            "sha256": sha256(payloads["DRIVER"].encode("utf-8")),
            "chars": len(payloads["DRIVER"]),
            "file": "src/init.lua (tail after the marker line; feature-module patches applied)",
            "marker": MARKER,
            "patched_sha256": sha256(patched_driver.encode("utf-8")),
            "patched_chars": len(patched_driver),
            "patches": [{k: v for k, v in meta.items() if not k.startswith("_")}
                       for meta in patch_metas],
        },
        "boot_data": {
            "manifest_count": manifest["count"],
            "manifest_files": len(files),
            "manifest_total": manifest["total"],
            "skyboxes": len(skyboxes),
            "text_assets": text_meta,
            "binary_assets": binary_meta,
        },
    }
    write_text(PROJECT_ROOT / "scripts" / "extract_manifest.json",
               json.dumps(extract_manifest, indent=2, ensure_ascii=False) + "\n")

    print(f"[extract] wrote src/init.lua + 3 payload chunks + assets "
          f"({len(text_assets)} text, {len(binary_assets)} binary)")
    for meta in patch_metas:
        print(f"[extract] feature module: {meta['file']} "
              f"({meta['body_chars']:,} frozen body chars; ctx: {', '.join(meta['ctx'])})")
    print("[extract] wrote scripts/extract_manifest.json")
    print("[extract] DONE")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except ExtractionError as exc:
        print(f"EXTRACTION FAILED: {exc}", file=sys.stderr)
        sys.exit(2)
