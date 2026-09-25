#!/usr/bin/env python3
"""
build_zip.py — package the project into dist/roblox-modular.zip.

Contents (relative paths only, deterministic order and timestamps):
    README.md, Makefile, selene.toml
    src/**            (entrypoint, payloads, modules)
    assets/**         (manifest, boot_data, text/*, binary/*)
    scripts/**        (extract.py, bundle.py, verify.py, build_zip.py,
                       smoke_preamble.lua, smoke_assert.lua, extract_manifest.json,
                       verification_log.txt if present)
    dist/main.lua     (the bundled executor script — self-contained)
    dist/bundle_report.json

Excluded by default:
    input/message(47).txt   (pass --include-input to embed the original paste)
    dist/roblox-modular.zip (itself), scripts/.smoke/, __pycache__, *.pyc

Pass --include-input (or `make zip INCLUDE_INPUT=1`) to also store input/.
"""

from __future__ import annotations

import argparse
import json
import sys
import zipfile
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
ZIP_PATH = PROJECT_ROOT / "dist" / "roblox-modular.zip"

INCLUDE_FILES = ["README.md", "Makefile", "selene.toml", "executor.yml", "roblox.yml",
                 "dist/main.lua", "dist/bundle_report.json"]
INCLUDE_DIRS = ["src", "assets", "scripts"]
ALWAYS_EXCLUDE_PARTS = {".smoke", "__pycache__"}
ALWAYS_EXCLUDE_SUFFIX = {".pyc"}
FIXED_DATE = (2026, 1, 1, 0, 0, 0)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--include-input", action="store_true",
                        help="also store input/message(47).txt inside the zip")
    parser.add_argument("--output", default=str(ZIP_PATH))
    args = parser.parse_args()

    members: list[Path] = []
    for name in INCLUDE_FILES:
        p = PROJECT_ROOT / name
        if p.exists():
            members.append(p)
    for d in INCLUDE_DIRS:
        base = PROJECT_ROOT / d
        if not base.exists():
            print(f"[zip] WARNING: expected directory missing: {base}", file=sys.stderr)
            continue
        for p in sorted(base.rglob("*")):
            if p.is_file():
                members.append(p)
    if args.include_input:
        input_dir = PROJECT_ROOT / "input"
        if input_dir.exists():
            members.extend(p for p in sorted(input_dir.rglob("*")) if p.is_file())
        else:
            print("[zip] WARNING: --include-input requested but input/ is missing", file=sys.stderr)

    members = sorted({p for p in members}, key=lambda p: p.as_posix())

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    stored = 0
    with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as zf:
        for p in members:
            rel = p.relative_to(PROJECT_ROOT).as_posix()
            parts = Path(rel).parts
            if not args.include_input and parts[0] == "input":
                continue
            if any(part in ALWAYS_EXCLUDE_PARTS for part in parts):
                continue
            if p.suffix in ALWAYS_EXCLUDE_SUFFIX:
                continue
            if p.resolve() == out_path.resolve():
                continue
            info = zipfile.ZipInfo(rel, date_time=FIXED_DATE)
            info.external_attr = 0o644 << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            zf.writestr(info, p.read_bytes())
            stored += 1

    size = out_path.stat().st_size
    print(f"[zip] wrote {out_path.relative_to(PROJECT_ROOT)} ({size:,} bytes, {stored} files)")
    print(f"[zip] input/message(47).txt included: {args.include_input}")
    print("[zip] DONE")
    return 0


if __name__ == "__main__":
    sys.exit(main())
