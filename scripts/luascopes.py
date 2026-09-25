#!/usr/bin/env python3
"""
luascopes.py — scope-aware Lua/Luau free-variable analyzer over lualex tokens.

Single source of truth for two consumers:
  * scripts/plan_feature_modules.py — audits every top-level guard() block of
    the driver (ctx sets, upvalue writes, callback `...`, reassignments)
  * scripts/extract.py — rewrites the free READS of a driver-owned mutable
    upvalue (the ALIVE flag) into calls of a live getter when a guard block is
    extracted into src/modules/

For every identifier the parser resolves it through the lexical scope chain
(locals, parameters, for-loop vars, shadowing, vararg rules), so a recorded
"free read" is exactly an upvalue/global read of the ORIGINAL callback. That
makes the recorded byte spans safe to rewrite: strings, comments, suffix field
names (X.name), method names (X:name), string keys (X["name"]), table
constructor keys ({name = ...}) and shadowed locals never appear in the span
list.

The parser is deliberately conservative: anything it cannot fully parse raises
LexError instead of silently returning partial results.
"""

from __future__ import annotations

from analyze_free_vars import KNOWN_GLOBALS  # noqa: F401  (re-exported)
import lualex


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

    Free READS additionally record their exact byte span (tok.s, tok.e) in
    document order, so callers can deterministically rewrite them.
    """

    def __init__(self, toks: list[lualex.Tok]):
        self.toks = toks
        self.i = 0
        self.scopes: list[Scope] = [Scope(vararg=True)]  # callback scope
        self.free_reads: set[str] = set()
        self.free_writes: set[str] = set()
        self.free_read_spans: list[tuple[str, int, int]] = []
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

    def ref_name(self, name: str, write: bool = False,
                 tok: lualex.Tok | None = None) -> None:
        if self.resolve(name):
            return
        if name in KNOWN_GLOBALS:
            return
        if write:
            self.free_writes.add(name)
            return
        self.free_reads.add(name)
        if tok is not None:
            self.free_read_spans.append((name, tok.s, tok.e))

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
            self.ref_name(t.text, write=False, tok=t)  # field assignment: root is READ
        else:
            self.ref_name(t.text, write=True, tok=t)   # `function f()` == `f = function`
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
            self.ref_name(t.text, write=False, tok=t)
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
            self.ref_name(t.text, write=False, tok=t)
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
                    self.ref_name(t2.text, write=False, tok=t2)
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
    """Parse a sliced guard-callback body; return its free-variable profile.

    Returns a dict with:
      ctx          — sorted free names (reads | writes)
      reads        — sorted free read names
      writes       — sorted free write names
      ellipsis_top — `...` used directly in the callback scope
      read_spans   — {name: [(start, end), ...]} byte spans of every free
                     read, in document order (for deterministic rewrites)
    """
    toks = lualex.lex(body)
    fa = FreeVarAnalyzer(toks)
    fa.parse_block(top=True)
    if fa.i != len(toks):
        raise lualex.LexError(
            f"trailing tokens after block parse: {len(toks) - fa.i} left "
            f"(first: {toks[fa.i].text!r})"
        )
    free = fa.free_reads | fa.free_writes
    read_spans: dict[str, list[tuple[int, int]]] = {}
    for name, s, e in fa.free_read_spans:
        read_spans.setdefault(name, []).append((s, e))
    return {
        "ctx": sorted(free),
        "reads": sorted(fa.free_reads),
        "writes": sorted(fa.free_writes),
        "ellipsis_top": fa.ellipsis_top,
        "read_spans": read_spans,
    }
