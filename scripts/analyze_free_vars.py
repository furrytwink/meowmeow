#!/usr/bin/env python3
"""
analyze_free_vars.py — find the free variables (driver upvalues) of a guard()
feature block in the driver tail of src/init.lua.

Method:
  1. slice the block between `guard("<name>", function()` and the next
     `guard("<next>", function()` anchor
  2. wrap the callback body as `return function() <body> end` in a temp file
  3. run luau-analyze --mode=nonstrict and collect `Unknown global 'x'` findings
  4. subtract known Roblox/executor globals — the remainder is exactly the set
     of driver locals the block closes over (the module ctx).

Used to derive/audit the `ctx` table passed to extracted feature modules
(see FEATURE_MODULES in extract.py).
"""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent

# globals that are LEGITIMATE runtime globals (executor / Roblox / Lua std) and
# must NOT be passed through ctx — the code probes some of them on purpose
# (e.g. `type(mousemoverel) == "function"`).
KNOWN_GLOBALS = {
    # Lua / Luau std
    "assert", "error", "pcall", "xpcall", "select", "type", "typeof", "unpack",
    "tostring", "tonumber", "ipairs", "next", "pairs", "rawget", "rawset",
    "rawequal", "rawlen", "setmetatable", "getmetatable", "require", "warn",
    "print", "os", "math", "string", "table", "coroutine", "buffer", "utf8",
    "bit32", "vector", "tick", "time", "wait", "spawn", "delay", "elapsedTime",
    # Roblox
    "game", "workspace", "script", "shared", "task", "Enum", "Instance",
    "Vector2", "Vector3", "CFrame", "Color3", "UDim", "UDim2", "TweenInfo",
    "NumberRange", "NumberSequence", "NumberSequenceKeypoint", "ColorSequence",
    "ColorSequenceKeypoint", "Ray", "Rect", "Region3", "BrickColor", "Font",
    "DateTime", "Random", "Axes", "Faces", "PhysicalProperties", "RaycastParams",
    "OverlapParams", "NumberSequence_new", "TweenService", "Path2DControlPoint",
    # executor
    "getgenv", "getrenv", "getreg", "getsenv", "getcallingscript",
    "mousemoverel", "mousemoveabs", "mousescroll", "mouse1click", "mouse2click",
    "mouse1press", "mouse1release", "mouse2press", "mouse2release",
    "Drawing", "loadstring", "readfile", "writefile", "isfile", "isfolder",
    "makefolder", "listfiles", "delfile", "delfolder", "appendfile",
    "gethui", "cloneref", "getcustomasset", "identifyexecutor", "request",
    "http_request", "syn", "setthreadidentity", "getidentity", "setclipboard",
    "queue_on_teleport", "hookfunction", "hookmetamethod", "getconnections",
    "getloadedmodules", "fireclickdetector", "firetouchinterest", "fireproximityprompt",
    "setsimulationradius", "setfpscap", "getfpscap", "getgc", "getgenv_legacy",
    "islclosure", "is_l_closure", "checkcaller", "newcclosure", "getupvalue",
    "setupvalue", "getupvalues", "debug",
    # Luau legacy env globals — luau-analyze does not flag them; reading them
    # as a global vs receiving them via ctx is semantically identical anyway
    "getfenv", "setfenv",
}

GUARD_RE = re.compile(r'guard\("([^"]+)", function\(\)')


def slice_block(driver: str, name: str, next_name: str) -> str:
    start_anchor = f'guard("{name}", function()'
    next_anchor = f'guard("{next_name}", function()'
    starts = [m.start() for m in re.finditer(re.escape(start_anchor), driver)]
    nexts = [m.start() for m in re.finditer(re.escape(next_anchor), driver)]
    if len(starts) != 1 or len(nexts) != 1:
        raise SystemExit(f"anchors not unique: {start_anchor!r} x{len(starts)}, {next_anchor!r} x{len(nexts)}")
    if nexts[0] <= starts[0]:
        raise SystemExit("next guard anchor appears before the target block")
    return driver[starts[0]:nexts[0]]


def callback_body(block: str, name: str) -> str:
    open_anchor = f'guard("{name}", function()'
    body = block[len(open_anchor):]
    stripped = body.rstrip("\r\n")
    if not stripped.endswith("end);"):
        raise SystemExit(f"block does not end with 'end);' — ends with {stripped[-40:]!r}")
    body = stripped[: -len("end);")]
    if body.startswith("\r\n"):
        body = body[2:]
    elif body.startswith("\n") or body.startswith("\r"):
        body = body[1:]
    return body


def find_tool(binary: str) -> Path | None:
    candidates = [
        PROJECT_ROOT / "tools" / binary,
        PROJECT_ROOT.parent / "tools" / binary,
        PROJECT_ROOT.parent.parent / "tools" / binary,
    ]
    for cand in candidates:
        if cand.exists():
            return cand
    which = subprocess.run(["which", binary], capture_output=True, text=True)
    return Path(which.stdout.strip()) if which.returncode == 0 and which.stdout.strip() else None


def main() -> int:
    name = sys.argv[1] if len(sys.argv) > 1 else "aimbot"
    next_name = sys.argv[2] if len(sys.argv) > 2 else "bot esp"

    init_text = (PROJECT_ROOT / "src" / "init.lua").read_bytes().decode("utf-8")
    marker = "-- [ EXTRACTED DRIVER BODY — everything below is byte-exact from input/message(47).txt ]"
    idx = init_text.find(marker)
    if idx < 0:
        raise SystemExit("driver marker not found in src/init.lua")
    driver = init_text[idx + len(marker):].lstrip("\r\n")

    block = slice_block(driver, name, next_name)
    body = callback_body(block, name)

    out_dir = PROJECT_ROOT / "scripts" / ".analysis"
    out_dir.mkdir(parents=True, exist_ok=True)
    probe = out_dir / f"{name.replace(' ', '_')}_body.lua"
    probe.write_bytes(("return function()\n" + body + "\nend\n").encode("utf-8"))

    tool = find_tool("luau-analyze")
    if not tool:
        raise SystemExit("luau-analyze not found (looked in ../tools and PATH)")
    res = subprocess.run([str(tool), "--mode=nonstrict", str(probe)], capture_output=True, text=True)
    output = res.stdout + res.stderr

    unknown = sorted(set(re.findall(r"Unknown global '([^']+)'", output)))
    ctx = [n for n in unknown if n not in KNOWN_GLOBALS]
    known = [n for n in unknown if n in KNOWN_GLOBALS]

    print(f"block: guard(\"{name}\") -> {len(block):,} chars, body {len(body):,} chars")
    print(f"probe: {probe.relative_to(PROJECT_ROOT)}")
    print(f"\nCTX (driver-local upvalues, {len(ctx)}):")
    for n in ctx:
        print(f"  {n}")
    print(f"\nKNOWN globals referenced ({len(known)}):")
    for n in known:
        print(f"  {n}")
    other = [ln for ln in output.splitlines() if "Unknown global" not in ln]
    if other:
        print(f"\nother luau-analyze output ({len(other)} lines):")
        for ln in other[:10]:
            print(f"  {ln}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
