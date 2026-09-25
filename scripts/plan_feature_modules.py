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

GUARD_SYNTAX = re.compile(r'guard\("([^"]+)", function\(\)')

UNSAFE_NOTE = {
    "writes": "block assigns to a driver-local upvalue — a ctx factory cannot reproduce the write-back",
    "ellipsis": "callback body uses `...` in its own scope — the factory would see the ctx table instead",
    "reassigned": "a ctx name is reassigned elsewhere in the driver — value snapshot may diverge from upvalue semantics",
    "lexical": "lexer/parser could not fully analyze the body — manual review required",
    "ctx_mismatch": "python scope analysis and luau-analyze disagree on the free-variable set",
}


# ---------------------------------------------------------------------------
# scope-aware analyzer
# ---------------------------------------------------------------------------

class Scope:
    __slots__ = ("names", "vararg")

    def __init__(self, vararg: bool = False):
        self.names: set[str] = set()
        self.vararg = vararg


class FreeVarAnalyzer:
    """Parses a callback body (token stream) and collects free reads/writes.

    The body's own function scope is the bottom scope; every name that
    resolves to no local scope and is not a known runtime global is FREE
    (i.e. closes over a driver local or is a runtime global).
    """

    def __init__(self, toks: list[lualex.Tok]):
        self.toks = toks
        self.i = 0
        self.scopes: list[Scope] = [Scope(vararg=True)]  # callback scope
        self.free_reads: set[str] = set()
        self.free_writes: set[str] = set()
        self.ellipsis_top = False
        self.parse_error: str | None = None

    # -- token helpers -------------------------------------------------------
    def peek(self, k: int = 0) -> lualex.Tok | None:
        j = self.i + k
        return self.toks[j] if j < len(self.toks) else None

    def at(self, kind: str, text: str | None = None, k: int = 0) -> bool:
        t = self.peek(k)
        return t is not None and t.kind == kind and (text is None or t.text == text)

    def eat(self, kind: str, text: str | None = None) -> lualex.Tok | None:
        if self.at(kind, text):
            t = self.toks[self.i]
            self.i += 1
            return t
        return None

    def expect(self, kind: str, text: str | None = None) -> lualex.Tok:
        t = self.eat(kind, text)
        if t is None:
            got = self.peek()
            raise lualex.LexError(
                f"parse error at token {self.i}: expected {text or kind}, "
                f"got {got.text if got else 'EOF'}"
            )
        return t

    # -- scopes ---------------------------------------------------------------
    def resolve(self, name: str) -> bool:
        for sc in reversed(self.scopes):
            if name in sc.names:
                return True
        return False

    def ref_name(self, name: str, write: bool = False) -> None:
        if self.resolve(name):
            return
        if name in KNOWN_GLOBALS:
            return
        (self.free_writes if write else self.free_reads).add(name)

    # -- type annotation skipping ---------------------------------------------
    def skip_type(self) -> None:
        depth = 0
        while True:
            t = self.peek()
            if t is None:
                return
            if t.kind == "sym":
                if t.text in "([{<":
                    depth += 1
                elif t.text in ")]}>":
                    if depth == 0:
                        return  # closing paren of a param list etc.
                    depth -= 1
                elif depth == 0 and t.text in ("=", ",", ";"):
                    return
                elif depth == 0 and t.text in ("->", "|", "&", "?", "..", ":", "."):
                    pass
            elif t.kind == "kw" and depth == 0 and t.text in (
                "local", "end", "do", "then", "else", "elseif", "until",
                "repeat", "return", "function", "if", "while", "for", "and", "or",
            ):
                if t.text in ("and", "or"):
                    pass  # `A | B` uses |; `and/or` would not appear in a type
                else:
                    return
            self.i += 1

    # -- grammar ---------------------------------------------------------------
    def parse_block(self, top: bool = False) -> None:
        while True:
            t = self.peek()
            if t is None:
                if top:
                    return  # sliced body: the callback's own `end` is not included
                raise lualex.LexError("unexpected EOF inside block")
            if t.kind == "kw" and t.text in ("end", "until", "else", "elseif"):
                return
            if t.kind == "sym" and t.text == ";":
                self.i += 1  # empty statement
                continue
            self.parse_statement()

    def parse_statement(self) -> None:
        t = self.peek()
        assert t is not None
        if t.kind == "kw":
            w = t.text
            if w == "local":
                self.parse_local()
                return
            if w == "function":
                self.parse_function_statement()
                return
            if w == "if":
                self.parse_if()
                return
            if w == "while":
                self.i += 1
                self.parse_expr()
                self.expect("kw", "do")
                self.scopes.append(Scope())
                self.parse_block()
                self.expect("kw", "end")
                self.scopes.pop()
                return
            if w == "for":
                self.parse_for()
                return
            if w == "repeat":
                self.i += 1
                self.scopes.append(Scope())
                self.parse_block()
                self.expect("kw", "until")
                self.parse_expr()  # until-condition sees the body scope (Lua rule)
                self.scopes.pop()
                return
            if w == "do":
                self.i += 1
                self.scopes.append(Scope())
                self.parse_block()
                self.expect("kw", "end")
                self.scopes.pop()
                return
            if w == "return":
                self.i += 1
                nxt = self.peek()
                if nxt and not (nxt.kind == "sym" and nxt.text in (";", ")")):
                    if not (nxt.kind == "sym" and nxt.text == ";"):
                        self.parse_exprlist_opt()
                if self.at("sym", ";"):
                    self.i += 1
                return
            if w == "break":
                self.i += 1
                return
            # fall through (keywords cannot start expressions)
            raise lualex.LexError(f"unexpected keyword '{w}' at token {self.i}")
        # statement-start `continue` (Luau contextual keyword)
        if t.kind == "name" and t.text == "continue" and not self.at("sym", "(", 1):
            self.i += 1
            return
        # Luau type declaration statement: [export] type Name = <type>
        if t.kind == "name" and t.text in ("type", "export"):
            if t.text == "export" and self.at("name", "type", 1):
                self.i += 2
                self.expect("name")
                if self.eat("sym", "<"):
                    self.skip_type()
                self.expect("sym", "=")
                self.skip_type()
                return
            if t.text == "type" and self.peek(1) and self.peek(1).kind == "name":
                self.i += 2
                if self.eat("sym", "<"):
                    self.skip_type()
                self.expect("sym", "=")
                self.skip_type()
                return
        self.parse_expr_statement()

    def parse_local(self) -> None:
        self.expect("kw", "local")
        if self.at("kw", "function"):
            self.i += 1
            name = self.expect("name").text
            self.ref_declare(name)
            self.parse_funcbody()
            return
        names: list[str] = []
        while True:
            names.append(self.expect("name").text)
            if self.at("sym", ":"):
                self.i += 1
                self.skip_type()
            if not self.eat("sym", ","):
                break
        if self.eat("sym", "="):
            self.parse_exprlist()
        for n in names:
            self.ref_declare(n)

    def ref_declare(self, name: str) -> None:
        self.scopes[-1].names.add(name)

    def parse_function_statement(self) -> None:
        self.expect("kw", "function")
        t = self.expect("name")
        method = False
        dotted = False
        while self.at("sym", ".") or self.at("sym", ":"):
            if self.toks[self.i].text == ":":
                method = True
            dotted = True
            self.i += 1
            self.expect("name")
        if dotted:
            self.ref_name(t.text, write=False)  # field assignment: root is READ
        else:
            self.ref_name(t.text, write=True)   # `function f()` == `f = function`
        self.parse_funcbody(implicit_self=method)

    def parse_funcbody(self, implicit_self: bool = False) -> None:
        self.expect("sym", "(")
        sc = Scope(vararg=True)
        if implicit_self:
            sc.names.add("self")
        if not self.at("sym", ")"):
            while True:
                if self.eat("sym", "..."):
                    pass
                else:
                    sc.names.add(self.expect("name").text)
                    if self.at("sym", ":"):
                        self.i += 1
                        self.skip_type()
                if not self.eat("sym", ","):
                    break
        self.expect("sym", ")")
        if self.at("sym", ":"):
            self.i += 1
            self.skip_type()
        self.scopes.append(sc)
        self.parse_block()
        self.expect("kw", "end")
        self.scopes.pop()

    def parse_if(self) -> None:
        self.expect("kw", "if")
        self.parse_expr()
        self.expect("kw", "then")
        self.scopes.append(Scope())
        self.parse_block()
        self.scopes.pop()
        while self.at("kw", "elseif"):
            self.i += 1
            self.parse_expr()
            self.expect("kw", "then")
            self.scopes.append(Scope())
            self.parse_block()
            self.scopes.pop()
        if self.eat("kw", "else"):
            self.scopes.append(Scope())
            self.parse_block()
            self.scopes.pop()
        self.expect("kw", "end")

    def parse_for(self) -> None:
        self.expect("kw", "for")
        names = [self.expect("name").text]
        while self.eat("sym", ","):
            names.append(self.expect("name").text)
        if self.eat("sym", "="):
            self.parse_expr()
            self.expect("sym", ",")
            self.parse_expr()
            if self.eat("sym", ","):
                self.parse_expr()
        else:
            self.expect("kw", "in")
            self.parse_exprlist()
        self.expect("kw", "do")
        sc = Scope()
        sc.names.update(names)
        self.scopes.append(sc)
        self.parse_block()
        self.expect("kw", "end")
        self.scopes.pop()

    # -- expressions ------------------------------------------------------------
    def parse_exprlist(self) -> None:
        self.parse_expr()
        while self.eat("sym", ","):
            self.parse_expr()

    def parse_exprlist_opt(self) -> None:
        nxt = self.peek()
        if nxt is None:
            return
        if nxt.kind in ("name", "num", "str") or \
           (nxt.kind == "kw" and nxt.text in ("nil", "true", "false", "function", "not")) or \
           (nxt.kind == "sym" and nxt.text in ("(", "{", "...", "#", "-")):
            self.parse_exprlist()

    BIN_LEVELS = [
        ("or",),
        ("and",),
        ("<", ">", "<=", ">=", "~=", "=="),
        ("..",),
        ("+", "-"),
        ("*", "/", "//", "%"),
    ]

    def parse_expr(self) -> None:
        self.parse_bin(0)

    def parse_bin(self, level: int) -> None:
        if level >= len(self.BIN_LEVELS):
            self.parse_unary()
            return
        ops = self.BIN_LEVELS[level]
        self.parse_bin(level + 1)
        while True:
            t = self.peek()
            if t is None or t.kind not in ("sym", "kw") or t.text not in ops:
                return
            self.i += 1
            if t.text == "..":  # right associative
                self.parse_bin(level)
            else:
                self.parse_bin(level + 1)

    def parse_unary(self) -> None:
        if self.at("kw", "not") or self.at("sym", "#") or self.at("sym", "-"):
            self.i += 1
            self.parse_unary()
            return
        self.parse_pow()

    def parse_pow(self) -> None:
        self.parse_simple()
        if self.eat("sym", "^"):
            self.parse_unary()  # right associative

    def parse_simple(self) -> None:
        t = self.peek()
        if t is None:
            raise lualex.LexError("unexpected EOF in expression")
        if t.kind in ("num", "str"):
            self.i += 1
        elif t.kind == "kw" and t.text in ("nil", "true", "false"):
            self.i += 1
        elif t.kind == "kw" and t.text == "function":
            self.i += 1
            self.parse_funcbody()
        elif t.kind == "sym" and t.text == "...":
            self.i += 1
            if len(self.scopes) == 1:
                self.ellipsis_top = True
        elif t.kind == "sym" and t.text == "{":
            self.parse_table()
        elif t.kind == "sym" and t.text == "(":
            self.i += 1
            self.parse_expr()
            self.expect("sym", ")")
        elif t.kind == "sym" and t.text == "-":
            # reached only via malformed unary chain; treat as unary
            self.i += 1
            self.parse_unary()
        elif t.kind == "name":
            self.i += 1
            self.ref_name(t.text, write=False)
        else:
            raise lualex.LexError(
                f"unexpected token '{t.text}' at index {self.i} (offset {t.s})"
            )
        self.parse_suffixes()

    def parse_suffixes(self) -> None:
        while True:
            if self.at("sym", "."):
                self.i += 1
                self.expect("name")  # field: not a variable reference
            elif self.at("sym", "["):
                self.i += 1
                self.parse_expr()
                self.expect("sym", "]")
            elif self.at("sym", ":"):
                self.i += 1
                self.expect("name")
                self.parse_args()
            elif self.at("sym", "(") or self.at("sym", "{") or self.at("str"):
                self.parse_args()
            elif self.at("name", "as"):
                self.i += 1
                self.skip_type()
            elif self.at("sym", "::"):
                self.i += 1
                self.skip_type()
            else:
                return

    def parse_args(self) -> None:
        if self.at("str"):
            self.i += 1
            return
        if self.at("sym", "{"):
            self.parse_table()
            return
        self.expect("sym", "(")
        if not self.at("sym", ")"):
            self.parse_exprlist()
        self.expect("sym", ")")

    def parse_table(self) -> None:
        self.expect("sym", "{")
        while not self.at("sym", "}"):
            if self.at("sym", "["):
                self.i += 1
                self.parse_expr()
                self.expect("sym", "]")
                self.expect("sym", "=")
                self.parse_expr()
            elif self.at("name") and self.at("sym", "=", 1):
                self.i += 2  # field name + '=' — the name is NOT a variable read
                self.parse_expr()
            else:
                self.parse_expr()
            if not (self.eat("sym", ",") or self.eat("sym", ";")):
                break
        self.expect("sym", "}")

    def parse_expr_statement(self) -> None:
        # parse a suffixed expression, then decide call vs assignment
        root = None
        bare = False
        t = self.peek()
        assert t is not None
        if t.kind == "name":
            root = t.text
            bare = True
            self.i += 1
            self.ref_name(t.text, write=False)
            before = self.i
            self.parse_suffixes()
            bare = bare and self.i == before  # suffixes (`.x`, calls) make it a field
        elif t.kind == "sym" and t.text == "(":
            self.i += 1
            self.parse_expr()
            self.expect("sym", ")")
            self.parse_suffixes()
        else:
            # expression statement must start with a suffixedexp; anything
            # else is a grammar error — surface it
            raise lualex.LexError(
                f"unexpected token '{t.text}' at statement start (index {self.i})"
            )
        # assignment?
        compound_now = self.at("sym", "=") or (
            self.peek() is not None and self.peek().kind == "sym"
            and self.peek().text in lualex.COMPOUND_OPS)
        if self.at("sym", ",") or compound_now:
            targets = [(root, bare)]
            while self.eat("sym", ","):
                t2 = self.peek()
                if t2 is not None and t2.kind == "name":
                    self.i += 1
                    self.ref_name(t2.text, write=False)
                    before2 = self.i
                    self.parse_suffixes()
                    targets.append((t2.text, self.i == before2))
                elif t2 is not None and t2.kind == "sym" and t2.text == "(":
                    self.i += 1
                    self.parse_expr()
                    self.expect("sym", ")")
                    self.parse_suffixes()
                    targets.append((None, False))
                else:
                    raise lualex.LexError("bad assignment target list")
            t3 = self.peek()
            compound = t3 is not None and t3.kind == "sym" and t3.text in lualex.COMPOUND_OPS
            if compound:
                self.i += 1
                self.parse_expr()
                r, b = targets[0]
                if r is not None and b:
                    self.ref_name(r, write=True)
                elif r is not None:
                    self.ref_name(r, write=False)
            else:
                self.expect("sym", "=")
                self.parse_exprlist()
                for r, b in targets:
                    if r is not None:
                        self.ref_name(r, write=bool(b))
        elif root is not None and not bare:
            pass  # plain call statement — root already recorded as a read


def analyze_body(body: str) -> dict:
    toks = lualex.lex(body)
    fa = FreeVarAnalyzer(toks)
    fa.parse_block(top=True)
    if fa.i != len(toks):
        raise lualex.LexError(
            f"trailing tokens after block parse: {len(toks) - fa.i} left "
            f"(first: {toks[fa.i].text!r})"
        )
    free = fa.free_reads | fa.free_writes
    return {
        "ctx": sorted(free),
        "reads": sorted(fa.free_reads),
        "writes": sorted(fa.free_writes),
        "ellipsis_top": fa.ellipsis_top,
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
