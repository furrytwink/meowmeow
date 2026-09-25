#!/usr/bin/env python3
"""
lualex.py — minimal Lua/Luau lexer + balanced-block scanner.

Used by extract.py to locate the exact end of each guard("name", function()...)
block in the driver (no reliance on "next guard" anchors), and by
plan_feature_modules.py for structural analysis of block bodies.

Scope: tokens only. Handles short strings with escapes, long strings/long
comments with levels, line comments, numbers, names/keywords, and every
Luau symbol including compound assignments (+=, ..=, ...). Backtick
interpolated strings are lexed as ONE opaque token (callers that need the
interpolated expressions must treat files containing them as review-only).
"""

from __future__ import annotations

KEYWORDS = {
    "and", "break", "do", "else", "elseif", "end", "false", "for", "function",
    "if", "in", "local", "nil", "not", "or", "repeat", "return", "then",
    "true", "until", "while",
}

COMPOUND_OPS = {"+=", "-=", "*=", "/=", "//=", "%=", "^=", "..="}

NAME_START = set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_")
NAME_CHARS = NAME_START | set("0123456789")


class LexError(Exception):
    pass


class Tok:
    __slots__ = ("kind", "s", "e", "text")

    def __init__(self, kind: str, s: int, e: int, text: str):
        self.kind = kind  # "name" | "kw" | "num" | "str" | "sym"
        self.s = s
        self.e = e
        self.text = text

    def __repr__(self) -> str:  # pragma: no cover - debug aid
        return f"Tok({self.kind},{self.s},{self.e},{self.text!r})"


def _long_bracket_level(src: str, i: int) -> int:
    """Return level if src[i:] starts with [=*[ (level >= 0), else -1."""
    if i >= len(src) or src[i] != "[":
        return -1
    j = i + 1
    while j < len(src) and src[j] == "=":
        j += 1
    if j < len(src) and src[j] == "[":
        return j - i - 1
    return -1


def lex(src: str) -> list[Tok]:
    """Tokenize `src`, skipping comments. Raises LexError on bad input."""
    toks: list[Tok] = []
    i, n = 0, len(src)
    while i < n:
        c = src[i]
        if c in " \t\r\n\v\f":
            i += 1
            continue
        # comments
        if c == "-" and i + 1 < n and src[i + 1] == "-":
            j = i + 2
            level = _long_bracket_level(src, j)
            if level >= 0:
                close = "]" + "=" * level + "]"
                k = src.find(close, j + 2 + level)
                if k < 0:
                    raise LexError(f"unterminated long comment at offset {i}")
                i = k + len(close)
            else:
                while j < n and src[j] != "\n":
                    j += 1
                i = j  # keep the newline itself as whitespace
            continue
        # long strings
        if c == "[":
            level = _long_bracket_level(src, i)
            if level >= 0:
                close = "]" + "=" * level + "]"
                k = src.find(close, i + 2 + level)
                if k < 0:
                    raise LexError(f"unterminated long string at offset {i}")
                toks.append(Tok("str", i, k + len(close), src[i:k + len(close)]))
                i = k + len(close)
                continue
        # short strings (incl. backtick interpolated, lexed opaque)
        if c in "\"'`":
            j = _skip_short_string(src, i)
            toks.append(Tok("str", i, j, src[i:j]))
            i = j
            continue
        # names / keywords
        if c in NAME_START:
            j = i + 1
            while j < n and src[j] in NAME_CHARS:
                j += 1
            word = src[i:j]
            toks.append(Tok("kw" if word in KEYWORDS else "name", i, j, word))
            i = j
            continue
        # numbers
        if c.isdigit() or (c == "." and i + 1 < n and src[i + 1].isdigit()):
            j = i
            while j < n and (src[j] in "0123456789abcdefABCDEF.xXpP" or
                             (src[j] in "+-" and src[j - 1] in "eEpP")):
                j += 1
            toks.append(Tok("num", i, j, src[i:j]))
            i = j
            continue
        # symbols — 3-char first (`...`, `//=`, `..=`), then 2-char
        three = src[i:i + 3]
        if three == "..." or three in COMPOUND_OPS:
            toks.append(Tok("sym", i, i + 3, three))
            i += 3
            continue
        two = src[i:i + 2]
        if two in ("==", "~=", "<=", ">=", "..", "::", "->") or two in COMPOUND_OPS:
            toks.append(Tok("sym", i, i + 2, two))
            i += 2
            continue
        toks.append(Tok("sym", i, i + 1, c))
        i += 1
    return toks


def _skip_short_string(src: str, i: int) -> int:
    quote = src[i]
    if quote == "`":
        raise LexError(
            f"interpolated string (backtick) at offset {i} — not supported by the "
            "structural analyzer; treat this block as review-only"
        )
    j = i + 1
    n = len(src)
    while j < n:
        c = src[j]
        if c == "\\":
            j += 2
            continue
        if c == quote:
            return j + 1
        if c == "\n":
            raise LexError(f"unterminated short string at offset {i}")
        j += 1
    raise LexError(f"unterminated short string at offset {i}")


# ---------------------------------------------------------------------------
# balanced-block scanning
# ---------------------------------------------------------------------------

OPENERS = {"function", "if", "for", "while", "repeat"}


def find_statement_end(src: str, toks: list[Tok], func_kw_idx: int) -> int:
    """Given the index of the `function` keyword that opens a function body,
    return the token index of the matching `end`. Raises LexError if absent.

    `for`/`while` headers may contain arbitrary balanced code (e.g. a table
    constructor with function expressions) before their `do`, so pending
    headers are tracked as a COUNT, never as a single boolean flag."""
    depth = 0
    pending_do = 0
    k = func_kw_idx
    while k < len(toks):
        t = toks[k]
        w = t.text if t.kind == "kw" else None
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
            if depth == 0:
                return k
            if depth < 0:
                raise LexError("unbalanced end at token %d" % k)
        elif w == "until":
            depth -= 1
            if depth == 0:
                return k
            if depth < 0:
                raise LexError("unbalanced until at token %d" % k)
        k += 1
    raise LexError("INPUT_TRUNCATED: matching 'end' not found for function at token "
                   f"{func_kw_idx} (offset {toks[func_kw_idx].s})")


def offset_after_end(src: str, toks: list[Tok], end_idx: int) -> tuple[int, int]:
    """After the matching `end`/`until` token of a statement, a call-statement
    like guard(...)() closes with `)` and `;`. Return (offset_past_close,
    semicolon_offset_or_-1). Allows whitespace/comments between."""
    n = len(toks)
    k = end_idx + 1
    if k < n and toks[k].kind == "sym" and toks[k].text == ")":
        k += 1
    semi = -1
    if k < n and toks[k].kind == "sym" and toks[k].text == ";":
        semi = toks[k].s
        k += 1
    return (toks[k].s if k < n else len(src)), semi


def code_mask(src: str) -> bytearray:
    """Byte mask: 1 where the character is live code, 0 inside strings/comments."""
    mask = bytearray(b"\x00" * len(src))
    try:
        for t in lex(src):
            for j in range(t.s, t.e):
                mask[j] = 1
    except LexError:
        # on lexical failure mark everything as code (conservative)
        mask = bytearray(b"\x01" * len(src))
    return mask
