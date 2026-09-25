#!/usr/bin/env python3
"""
plan_feature_modules.py — audit every top-level guard() block in the driver
and derive the full FEATURE_MODULES candidate list for scripts/extract.py.

Per block it reports:
  * ctx        — free variables (Python scope analysis), cross-checked against
                 luau-analyze UnknownGlobal findings
  * writes     — assignments to free names (UNSAFE: a ctx factory binds values,
                 so an upvalue write would no longer reach the driver)
  * ellipsis   — `...` used directly in the callback scope (UNSAFE: the factory
                 receives the ctx table as its vararg)
  * reassigned — ctx names that are reassigned ANYWHERE else in the driver
                 (UNSAFE for the snapshot semantics; review required)
  * require literals + lexical hazards (backtick strings, parse failures)

SAFE blocks are emitted as a ready-to-paste FEATURE_MODULES list into
scripts/.analysis/feature_plan.json (+ .py snippet). Everything else must be
reviewed by hand before extraction.

Usage:  python3 scripts/plan_feature_modules.py
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(Path(__file__).resolve().parent))

import extract  # noqa: E402
import lualex  # noqa: E402
from analyze_free_vars import KNOWN_GLOBALS, find_tool  # noqa: E402
# the scope-aware analyzer lives in one shared module so the audit tool
# and the generator (extract.py) can never drift apart
from luascopes import FreeVarAnalyzer, analyze_body  # noqa: E402, F401

GUARD_SYNTAX = re.compile(r'guard\("([^"]+)", function\(\)')

UNSAFE_NOTE = {
    "writes": "block assigns to a driver-local upvalue — a ctx factory cannot reproduce the write-back",
    "ellipsis": "callback body uses `...` in its own scope — the factory would see the ctx table instead",
    "reassigned": "a ctx name is reassigned elsewhere in the driver — value snapshot may diverge from upvalue semantics",
    "lexical": "lexer/parser could not fully analyze the body — manual review required",
    "ctx_mismatch": "python scope analysis and luau-analyze disagree on the free-variable set",
}


# ---------------------------------------------------------------------------
# driver scan
# ---------------------------------------------------------------------------

def find_guards(driver: str) -> list[dict]:
    toks = lualex.lex(driver)
    # depth walk (pending for/while headers tracked as a count — a header may
    # contain balanced code, e.g. tables of callbacks, before its `do`)
    depth = 0
    pending_do = 0
    hits: list[dict] = []
    k = 0
    while k < len(toks):
        t = toks[k]
        if t.kind == "name" and t.text == "guard" and depth == 0:
            if (k + 6 < len(toks) and toks[k + 1].kind == "sym" and toks[k + 1].text == "("
                    and toks[k + 2].kind == "str"
                    and toks[k + 3].kind == "sym" and toks[k + 3].text == ","
                    and toks[k + 4].kind == "kw" and toks[k + 4].text == "function"
                    and toks[k + 5].kind == "sym" and toks[k + 5].text == "("
                    and toks[k + 6].kind == "sym" and toks[k + 6].text == ")"):
                name = toks[k + 2].text[1:-1]
                end_idx = lualex.find_statement_end(driver, toks, k + 4)
                hits.append({
                    "name": name,
                    "guard_idx": k,
                    "func_idx": k + 4,
                    "end_idx": end_idx,
                    "depth": depth,
                    "open_end": toks[k + 6].e,
                    "end_start": toks[end_idx].s,
                    "line": driver.count("\n", 0, toks[k].s) + 1,
                })
        if t.kind == "kw":
            w = t.text
            if w in ("function", "if", "repeat"):
                depth += 1
            elif w in ("for", "while"):
                depth += 1
                pending_do += 1
            elif w == "do":
                if pending_do > 0:
                    pending_do -= 1
                else:
                    depth += 1
            elif w == "end":
                depth -= 1
            elif w == "until":
                depth -= 1
        k += 1
    return hits


def block_slice(driver: str, hit: dict) -> tuple[str, str, int]:
    """Return (block, body, close_end) for a guard hit."""
    toks = lualex.lex(driver)
    close_end, _semi = lualex.offset_after_end(driver, toks, hit["end_idx"])
    # confirm `)` `;` immediately follow the matching end
    block = driver[hit["guard_idx"]:close_end]
    stripped = block.rstrip("\r\n")
    if not stripped.endswith("end);"):
        raise lualex.LexError(f"block {hit['name']}: does not end with 'end);'")
    body = driver[hit["open_end"]:hit["end_start"]]
    if body.startswith("\r\n"):
        body = body[2:]
    elif body.startswith("\n") or body.startswith("\r"):
        body = body[1:]
    return block, body, close_end


ASSIGN_RE_TEMPLATE = r"(?<![A-Za-z0-9_.\)<>=~\]]){name}\s*(=[^=]|(\+|\-|\*|/|//|%|\^|\.\.)=)"
FUNC_RE_TEMPLATE = r"(?<![A-Za-z0-9_.])function\s*{name}\b"


def driver_reassignments(driver: str, name: str, min_offset: int = 0) -> list[int]:
    """Code-position writes to `name` at/after min_offset (earlier writes are
    driver initialization that completed before the block ran)."""
    mask = lualex.code_mask(driver)
    hits: list[int] = []
    for pat in (ASSIGN_RE_TEMPLATE.format(name=re.escape(name)),
                FUNC_RE_TEMPLATE.format(name=re.escape(name))):
        for m in re.finditer(pat, driver):
            if m.start() < min_offset:
                continue
            if all(mask[j] for j in range(m.start(), m.end())):
                pre = driver[:m.start()].rstrip()
                if pre.endswith("local") or pre.endswith("local function"):
                    continue  # a new local shadows; the driver local is untouched
                if pre.endswith("for"):
                    continue  # loop header
                hits.append(m.start())
    return hits


def luau_ctx(body: str, slug: str, out_dir: Path) -> set[str] | None:
    tool = find_tool("luau-analyze")
    if not tool:
        return None
    out_dir.mkdir(parents=True, exist_ok=True)
    probe = out_dir / f"plan_{slug}_body.lua"
    probe.write_bytes(("return function()\n" + body + "\nend\n").encode("utf-8"))
    res = subprocess.run([str(tool), "--mode=nonstrict", str(probe)],
                         capture_output=True, text=True, timeout=240)
    output = res.stdout + res.stderr
    unknown = set(re.findall(r"Unknown global '([^']+)'", output))
    return {n for n in unknown if n not in KNOWN_GLOBALS}


def slugify(name: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")


def main() -> int:
    raw = (PROJECT_ROOT / "input" / "message(47).txt").read_bytes()
    payloads = extract.parse_input(raw.decode("utf-8"))
    driver = payloads["DRIVER"]

    hits = find_guards(driver)
    top = [h for h in hits if h["depth"] == 0]
    nested = [h for h in hits if h["depth"] != 0]
    print(f"guard blocks: {len(hits)} total, {len(top)} top-level, {len(nested)} nested "
          f"({', '.join(h['name'] for h in nested) or '-'})")

    analysis_dir = PROJECT_ROOT / "scripts" / ".analysis"
    analysis_dir.mkdir(parents=True, exist_ok=True)

    slugs: dict[str, int] = {}
    report = []
    for hit in top:
        name = hit["name"]
        slug = slugify(name)
        slugs[slug] = slugs.get(slug, 0) + 1
        if slugs[slug] > 1:
            slug = f"{slug}_{slugs[slug]}"
        entry = {"guard": name, "slug": slug, "line": hit["line"]}
        try:
            block, body, close_end = block_slice(driver, hit)
            entry["body_chars"] = len(body)
            entry["block_end_line"] = driver.count("\n", 0, hit["end_start"]) + 1
            res = analyze_body(body)
            entry["ctx"] = res["ctx"]
            entry["writes"] = res["writes"]
            entry["ellipsis_top"] = res["ellipsis_top"]
            entry["requires"] = sorted(set(re.findall(r'require\s*\(\s*"([^"]+)"', body)))
            flags = []
            if res["writes"]:
                flags.append("writes")
            if res["ellipsis_top"]:
                flags.append("ellipsis")
            lu = luau_ctx(body, slug, analysis_dir)
            if lu is None:
                entry["luau_ctx"] = None
            else:
                entry["luau_ctx"] = sorted(lu)
                py_set = set(res["ctx"])
                # luau-analyze under-reports in nonstrict mode (it skips
                # Unknown global for field-assignment roots like
                # `ESP.Weather = W`, and knows legacy globals like setfenv).
                # A py-only superset is therefore expected; only names that
                # luau finds but python missed indicate a parser bug.
                entry["py_only"] = sorted(py_set - lu)
                if lu - py_set:
                    entry["luau_only"] = sorted(lu - py_set)
                    flags.append("ctx_mismatch")
            reassigned: set[str] = set()
            for var in res["ctx"]:
                if driver_reassignments(driver, var, min_offset=close_end):
                    reassigned.add(var)
            entry["reassigned"] = sorted(reassigned)
            if reassigned:
                flags.append("reassigned")
            entry["flags"] = flags
            entry["safe"] = not flags
        except lualex.LexError as exc:
            entry["ctx"] = None
            entry["flags"] = ["lexical"]
            entry["error"] = str(exc)[:200]
            entry["safe"] = False
        report.append(entry)

    # proposed FEATURE_MODULES (safe blocks only, in driver order)
    existing = {spec["guard"] for spec in extract.FEATURE_MODULES}
    proposal = []
    for e in report:
        if e["safe"]:
            proposal.append({
                "module": f"modules.{e['slug']}",
                "file": f"src/modules/{e['slug']}.lua",
                "guard": e["guard"],
                "ctx": e["ctx"],
                "summary": f"{e['guard']} feature",
                "already_listed": e["guard"] in existing,
            })

    out = {
        "blocks": report,
        "proposed": proposal,
        "nested": [h["name"] for h in nested],
        "unsafe": [e for e in report if not e["safe"]],
    }
    (analysis_dir / "feature_plan.json").write_text(
        json.dumps(out, indent=2) + "\n", encoding="utf-8")

    # console summary
    print(f"\n{'guard':<16} {'line':>6} {'body':>8}  {'ctx':>3}  status")
    for e in report:
        status = "SAFE" if e["safe"] else ",".join(e["flags"])
        ctx_n = len(e["ctx"]) if e["ctx"] else -1
        body_n = e.get("body_chars", -1)
        print(f"{e['guard']:<16} {e['line']:>6} {body_n:>8,}  {ctx_n:>3}  {status}"
              + (f"  ctx={e['ctx']}" if e["safe"] and e["ctx"] else ""))

    py = ["FEATURE_MODULES = ["]
    for p in proposal:
        ctx_lines = ", ".join(p["ctx"])
        py.append("    {")
        py.append(f"        \"module\": \"{p['module']}\",")
        py.append(f"        \"file\": \"{p['file']}\",")
        py.append(f"        \"guard\": \"{p['guard']}\",")
        py.append(f"        \"ctx\": [{ctx_lines}],")
        py.append(f"        \"summary\": \"{p['summary']}\",")
        py.append("    },")
    py.append("]")
    (analysis_dir / "feature_plan.py").write_text("\n".join(py) + "\n", encoding="utf-8")
    print(f"\nwrote scripts/.analysis/feature_plan.json + feature_plan.py "
          f"({len(proposal)} safe / {len(report) - len(proposal)} need review)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
