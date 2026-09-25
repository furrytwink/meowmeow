#!/usr/bin/env python3
"""check_live_rewrite.py — deep validation of the live-getter rewrite.

For every FEATURE_MODULES spec with live vars, checks the WRITTEN module file:
  1. the embedded body, analyzed fresh by luascopes, has ZERO remaining free
     reads of the live names and ZERO writes (rewrite completeness)
  2. replacing the getter calls back with the bare names reproduces the frozen
     original body slice byte-for-byte (rewrite is a bijection on its spans)
  3. non-live modules are byte-identical re-derivations of the plain slices
"""
import sys
from pathlib import Path

PROJECT_ROOT = Path("/home/z/my-project/download/roblox-modular")
sys.path.insert(0, str(PROJECT_ROOT / "scripts"))

import extract  # noqa: E402
import luascopes  # noqa: E402

raw = (PROJECT_ROOT / "input" / "message(47).txt").read_bytes()
payloads = extract.parse_input(raw.decode("utf-8"))
driver = payloads["DRIVER"]

_patched, metas = extract.apply_feature_patches(driver)
meta_by_module = {m["module"]: m for m in metas}

failures = 0
live_total = 0
for spec in extract.FEATURE_MODULES:
    meta = meta_by_module[spec["module"]]
    path = PROJECT_ROOT / spec["file"]
    text = path.read_bytes().decode("utf-8")
    marker = (
        f"-- [ guard(\"{spec['guard']}\") callback body — byte-exact from "
        f"input/message(47).txt except reads of ALIVE rewritten to __ALIVE() ]"
        if spec.get("live") else
        f"-- [ guard(\"{spec['guard']}\") callback body — byte-exact from input/message(47).txt ]"
    )
    i = text.find(marker)
    assert i >= 0, spec["module"]
    body = text[i + len(marker):]
    body = body[2:] if body.startswith("\r\n") else (body[1:] if body[:1] in ("\n", "\r") else body)
    assert body.endswith("end;\r\n") or body.endswith("end;\n")
    body = body[: body.rfind("end;")]

    live = spec.get("live", [])
    if live:
        res = luascopes.analyze_body(body)
        for name in live:
            left = res["read_spans"].get(name, [])
            if left or name in res["writes"]:
                print(f"FAIL {spec['module']}: {len(left)} free reads / writes of {name} remain")
                failures += 1
            # reverse-rewrite: __ALIVE() -> ALIVE must give the frozen original
            rev = body.replace(f"__{name}()", name)
            if extract.sha256(rev.encode("utf-8")) != meta["body_sha256"]:
                print(f"FAIL {spec['module']}: reverse rewrite != frozen original slice")
                failures += 1
        live_total += 1
    else:
        if extract.sha256(body.encode("utf-8")) != meta["body_sha256"]:
            print(f"FAIL {spec['module']}: plain body != frozen original slice")
            failures += 1

print(f"checked {len(extract.FEATURE_MODULES)} module files "
      f"({live_total} live-getter, {len(extract.FEATURE_MODULES) - live_total} value-only)")
if failures:
    print(f"FAILURES: {failures}")
    sys.exit(1)
print("ALL CHECKS PASSED: rewrites complete on disk, reverse-mapping exact, "
      "value-only bodies byte-frozen")
