# apfelpad formula reference

Every pale-green span in an apfelpad document is a **formula**. This page
is the full catalogue — every formula apfelpad ships, with signature,
semantics, edge cases, and real examples you can paste into the app.

apfelpad is **Turing-complete** by composition: formulas can be nested,
`=if` branches, and `=ref` can pull any section's text into any other
formula. See the [composition](#composition) section at the bottom.

---

## On-device AI

### `=apfel(prompt, seed?)`

On-device LLM call via `apfel --serve` on `localhost:11450`. The prompt is
visible, the output streams inline, the result is cached by a composite
key (source + context + model version + seed), and nothing leaves your Mac.

```
=apfel("write a warm welcome in two sentences", 42)
=apfel("summarize: ...")
```

| Parameter | Required | Notes |
|---|---|---|
| `prompt` | yes | Bare phrases are auto-quoted. Smart quotes are normalised. |
| `seed` | no | Integer. Same seed + same context + same model version → same output. |

### `=(prompt, seed?)` — anonymous shortcut

`=(hello)` is shorthand for `=apfel("hello")`. `=()` alone is shorthand
for `=apfel("")`. Both canonicalise to the full form on save.

```
=(write a haiku about apfelpad, 7)
=()
```

---

## Arithmetic

### `=math(expression)`

Pure Swift recursive-descent expression evaluator. Supports `+ - * /` and
parentheses. **Accepts US number annotation** — the parser strips `$`
prefixes, ignores commas inside numbers, and expands `k`/`m`/`b` suffixes.

```
=math(42*2)                → 84
=math((100-25)*4)          → 300
=math($1,250 + $750)       → 2000
=math(2m + 500k)           → 2500000
=math(1.5 + 2.5)           → 4
=math(-5 + 3)              → -2
```

| Syntax | Meaning |
|---|---|
| `$1,000` | Strip `$`, ignore thousand separators |
| `1,234.5` | Thousand separators with decimal point |
| `10k` | × 1,000 |
| `2m` | × 1,000,000 |
| `3b` | × 1,000,000,000 |

Invalid input throws a human-readable error: `math: invalid expression — abc`.

---

## Text

All text formulas are **pure Swift** and never touch the LLM.

### `=upper(text)` / `=lower(text)` / `=trim(text)` / `=len(text)`

```
=upper("hello apfelpad")     → HELLO APFELPAD
=lower("WORLD")              → world
=trim("   padded   ")        → padded
=len("apfelpad")             → 8
=len("🎉")                   → 1
```

`=len` counts grapheme clusters, so emoji count as 1.

### `=LEFT(text, n)` / `=RIGHT(text, n)` / `=MID(text, start, length)`

Substring formulas matching Google Sheets. `LEFT` and `RIGHT` clamp to the
string length; `MID` is **1-indexed** for `start` (the first character is
position 1, not 0).

```
=LEFT("apfelpad", 5)        → apfel
=RIGHT("apfelpad", 3)       → pad
=MID("apfelpad", 6, 3)      → pad
```

### `=FIND(needle, haystack, [start])` / `=SEARCH(needle, haystack, [start])`

Return the 1-indexed position of `needle` in `haystack`. `FIND` is
case-sensitive; `SEARCH` is case-insensitive. Both error if not found —
combine with `=IFERROR(...)` for soft search.

```
=FIND("pad", "apfelpad")            → 6
=FIND("PAD", "apfelpad")            → error
=SEARCH("PAD", "apfelpad")          → 6
=FIND("l", "hello world", 5)        → 10
```

### `=REPT(text, n)`

Repeat `text` `n` times. Negative `n` returns the empty string.

```
=REPT("ab", 3)              → ababab
=REPT("x", 0)               → ""
```

### `=PROPER(text)` / `=CLEAN(text)` / `=EXACT(a, b)`

```
=PROPER("hello world")              → Hello World
=PROPER("jOHN DOE")                 → John Doe
=CLEAN("a\u{0000}b\nc")             → abc   # strips ASCII 0-31
=EXACT("hello", "hello")            → TRUE
=EXACT("Hello", "hello")            → FALSE
```

### `=CHAR(code)` / `=CODE(text)`

Round-trip between a Unicode scalar and its code point.

```
=CHAR(65)                   → A
=CHAR(128522)               → 😊
=CODE("A")                  → 65
=CODE("😊")                 → 128522
```

### `=TEXTJOIN(delim, ignore_empty, text1, …)`

Like `=concatenate` but with a separator. If `ignore_empty` is truthy,
empty strings are skipped.

```
=TEXTJOIN(", ", true, "a", "", "b", "c")     → a, b, c
=TEXTJOIN(", ", false, "a", "", "b")         → a, , b
```

### `=VALUE(text)` / `=TEXT(value, [format])`

Round-trip between number-as-string and string-as-number.

```
=VALUE("123.45")            → 123.45
=VALUE("hello")             → error
=TEXT("3.1", "0.00")        → 3.10
=TEXT("3.7", "0")           → 4
=TEXT("0.25", "0%")         → 25%
```

Supported `TEXT` format codes: `""` (pass through), `"0"` (integer
round), `"0.0"`/`"0.00"`/… (fixed decimals), `"0%"` (percentage). Anything
else falls back to the raw value.

### `=concatenate(a, b, c, …)`

Variadic string concatenation. Joins any number of string args with no
separator — use `=concatenate("Hello, ", "world", "!")` for a separator pattern.

```
=concatenate("Hello, ", "world", "!")   → Hello, world!
=concatenate("a", "b", "c")             → abc
```

### `=substitute(text, find, replacement)`

First-occurrence substitution. Returns `text` unchanged if no match.

```
=substitute("hello world", "world", "apfelpad")  → hello apfelpad
=substitute("abc", "xyz", "!")                   → abc
```

### `=split(text, delim, index?)`

Return the `index`-th piece (default 0). Out-of-range returns `""`.

```
=split("a,b,c,d", ",", 0)     → a
=split("a,b,c,d", ",", 2)     → c
=split("a,b,c,d", ",", 99)    →
```

---

## More math

### Variadic: `=MAX(n…)` / `=MIN(n…)` / `=PRODUCT(n…)`

```
=MAX(3, 1, 7)               → 7
=MIN(3, 1, 7)               → 1
=PRODUCT(2, 3, 4)           → 24
```

### Single argument: `=ABS` / `=SQRT` / `=INT` / `=SIGN` / `=EVEN` / `=ODD` / `=FACT` / `=LN` / `=LOG10` / `=EXP`

```
=ABS(-5)                    → 5
=SQRT(16)                   → 4
=INT(3.7)                   → 3
=SIGN(-5)                   → -1
=EVEN(3)                    → 4
=ODD(4)                     → 5
=FACT(5)                    → 120
=LN(2.718281828)            → 1
=LOG10(100)                 → 2
=EXP(1)                     → 2.718281828
```

### Two arguments: `=MOD` / `=POWER` (alias `=POW`) / `=GCD` / `=LCM` / `=COMBIN` / `=RANDBETWEEN`

```
=MOD(10, 3)                 → 1
=POWER(2, 10)               → 1024
=POW(2, 10)                 → 1024
=GCD(12, 8)                 → 4
=LCM(4, 6)                  → 12
=COMBIN(5, 2)               → 10
=RANDBETWEEN(1, 10)         → (random integer 1-10)
```

### Number + optional second arg

```
=ROUND(3.14159, 2)          → 3.14
=ROUND(3.7)                 → 4         # places defaults to 0
=ROUNDUP(3.1)               → 4         # always away from zero
=ROUNDDOWN(3.9)             → 3         # always toward zero
=CEILING(4.1, 1)            → 5         # nearest multiple of factor
=CEILING(4.3, 0.5)          → 4.5
=FLOOR(4.9, 1)              → 4
=LOG(100)                   → 2         # base defaults to 10
=LOG(8, 2)                  → 3
```

### Constants and randoms: `=PI()` / `=RAND()`

```
=PI()                       → 3.141592653589793
=RAND()                     → (0..<1)
```

Both `=RAND()` and `=RANDBETWEEN()` return a different value each time they
are evaluated. They participate in caching like any other formula — open
the document again and you'll get the same cached result until you click
to re-roll.

---

## Numeric aggregates

### `=sum(n1, n2, …)` / `=average(n1, n2, …)`

Variadic sum and arithmetic mean. Each argument is parsed as a number.
Throws on non-numeric input.

```
=sum(1, 2, 3)             → 6
=sum(10, -5)              → 5
=sum(1.5, 2.5)            → 4
=average(2, 4, 6)             → 4
=average(1, 2)                → 1.5
```

---

## Control flow

### `=if(cond, then, else)`

Truthy test on `cond`. Empty string, `"0"`, `"false"`, and `"no"` (case-
insensitive) are **falsy**; everything else is **truthy**.

```
=if("yes", "go", "stop")        → go
=if("", "go", "stop")           → stop
=if("0", "on", "off")           → off
=if("1", "on", "off")           → on
```

Combine with nested `=math` to make numeric conditionals work:

```
=if(=math(5*5), "big", "small")   → big    (25 is non-zero → truthy)
=if(=math(0), "big", "small")     → small
```

---

## Logical

Truthiness follows `=if`: empty, `"0"`, `"false"`, `"no"` (case-insensitive,
trimmed) are falsy; everything else is truthy.

### `=AND(expr1, expr2, …)` / `=OR(expr1, expr2, …)` / `=NOT(expr)`

```
=AND("yes", "1", "true")        → TRUE
=AND("yes", "0", "true")        → FALSE
=OR("no", "0", "yes")           → TRUE
=NOT("false")                   → TRUE
=NOT("hello")                   → FALSE
```

### `=TRUE()` / `=FALSE()`

Literal boolean strings — useful as cell defaults or as the right-hand
side of `=if` branches. Both accept the bare form (`=TRUE`, `=false`).

### `=IFERROR(value, fallback)`

Evaluate `value`. If it errors (parse error or runtime error), return
`fallback` instead. If `value` is a plain string, it is returned as-is.

```
=IFERROR(=sum(notanumber), "n/a")   → n/a
=IFERROR(=math(1+1), "fb")          → 2
=IFERROR("hello", "fb")             → hello
```

Note: division-by-zero in `=math` returns IEEE `inf` rather than throwing,
matching Swift's `Double` semantics — IFERROR will pass it through. Use
this for malformed expressions, unparseable values, anchor lookups that
miss, and other genuine error paths.

### `=SWITCH(expr, case1, value1, [case2, value2, ...], [default])`

```
=SWITCH("b", "a", "first", "b", "second", "default")   → second
=SWITCH("x", "a", "first", "none found")               → none found
```

If no case matches and no default is supplied, SWITCH errors.

### `=IFS(cond1, value1, [cond2, value2, ...])`

Return the value paired with the first truthy condition.

```
=IFS("false", "no", "true", "yes")     → yes
=IFS("0", "zero", "1", "one")          → one
```

If no condition is truthy, IFS errors. Combine with `=IFERROR` for a
"none-of-the-above" fallback.

---

## Dates and time

All date/time formulas read the user's locale by default. `=date` returns
ISO 8601, `=time` returns 24-hour `HH:mm`, `=weeknum` returns the ISO calendar
week (Monday start).

### `=today()`

```
=today()      → 2026-04-12
```

Returns today's date in ISO 8601 format (YYYY-MM-DD). No arguments.

### `=date(offset?)`

```
=date(+1)     → 2026-04-13
=date(-7)     → 2026-04-05
=date(+30)    → 2026-05-12
```

### `=weeknum(offset?)`

```
=weeknum()         → 15
=weeknum(-1)       → 14
=weeknum(+1)       → 16
```

### `=NOW()` / `=YEAR()` / `=WEEKDAY()` / `=HOUR()` / `=MINUTE()` / `=SECOND()`

Extended date/time accessors matching Google Sheets conventions. All
take no arguments.

```
=NOW()        → 2026-04-12 17:30
=YEAR()       → 2026
=WEEKDAY()    → 1 (Sunday) … 7 (Saturday)
=HOUR()       → 17
=MINUTE()     → 30
=SECOND()     → 45
```

All accept a bare form too — `=NOW` / `=year` / `=hour` etc. work as
shorthand. The wall-clock formulas (`=NOW`, `=HOUR`, `=MINUTE`,
`=SECOND`) re-evaluate every time you re-open the document or click
their span — they are intentionally not cached.

### `=month()` / `=day()` / `=time()`

```
=month()      → April
=day()        → Sunday
=time()       → 01:28
```

---

## Document references

### `=ref(@anchor)`

Insert the text of a named heading section. Anchors are slugified
automatically: `# My Section` becomes `@my-section`. Case-insensitive.
Subsections scope correctly — a section ends at the next heading of
equal or higher level.

```markdown
# Project brief

Build a formula notepad for thinking on macOS.

# Summary

The goal: =ref(@project-brief)
```

Result: the Summary section shows the Project brief text live. Edit the
brief, every `=ref` that points at it updates automatically.

`=ref` is **pure and live** — it reads the current rawText, not a cached
value, so changes propagate immediately without re-evaluation.

---

## Info

Predicates and type classifiers. All return the literal strings `"TRUE"`,
`"FALSE"`, or one of `"number" | "text" | "blank"`.

### `=ISNUMBER(value)`

Returns `"TRUE"` if the value parses as a finite decimal number. Empty
strings and whitespace-only strings are `"FALSE"`.

```
=ISNUMBER("42")            → TRUE
=ISNUMBER("3.14")          → TRUE
=ISNUMBER("-5")            → TRUE
=ISNUMBER("hello")         → FALSE
=ISNUMBER("")              → FALSE
=ISNUMBER("   ")           → FALSE
```

### `=ISTEXT(value)`

Returns `"TRUE"` if the value is **not** parseable as a number, otherwise
`"FALSE"`. An empty string is still text.

```
=ISTEXT("hello")           → TRUE
=ISTEXT("42")              → FALSE
=ISTEXT("")                → TRUE
```

### `=ISBLANK(value)`

Returns `"TRUE"` if the value is empty after trimming whitespace,
otherwise `"FALSE"`.

```
=ISBLANK("")               → TRUE
=ISBLANK("   ")            → TRUE
=ISBLANK("hi")             → FALSE
```

### `=TYPE(value)`

Returns one of `"number"`, `"text"`, or `"blank"` describing the value.

```
=TYPE("42")                → number
=TYPE("hello")             → text
=TYPE("")                  → blank
=TYPE("   ")               → blank
```

Use info formulas inside `=if` for type-safe branching:

```
=if(=ISNUMBER(=show(@input)), =math(@input * 2), "enter a number")
```

---

## Composition — why apfelpad is Turing-complete

Every formula can take another formula as an argument. The
`NestedFormulaResolver` walks the source bottom-up with a depth cap of 10
and substitutes each sub-call with its evaluated result as a quoted
literal **before** the outer call runs.

Combined with `=if` (branching), `=ref` (state), and `=math` (arithmetic),
this is enough to express any computable function on strings and numbers.

```
=upper(=ref(@intro))                          → shouted intro
=upper(=trim(=lower("   HELLO   ")))          → HELLO
=concatenate(=upper("hello "), =lower("WORLD"))    → HELLO world
=if(=math(5*5), "big", "small")               → big
=sum(=len("abc"), =len("de"), =math(10))      → 15
=apfel(=concatenate("summarize: ", =ref(@intro))) → streaming AI summary
```

The resolver is depth-capped so any pathological recursion terminates
in at most 10 levels. Invalid sub-calls are left in place and surfaced
as errors in the outer formula's parse.

---

## Authoring ergonomics

### Auto-quoting

You never have to remember quote syntax. If the parser can't parse an
argument as a number or nested call, it treats it as a string literal.

```
=apfel(hello world)         ≡ =apfel("hello world")
=upper(hi)                  ≡ =upper("hi")
=(love letter, 42)          ≡ =apfel("love letter", 42)
```

### Smart quotes

macOS auto-substitutes `"` to curly `"…"`, `'` to curly `'…'`, and
`"` to German `„…"`. apfelpad straightens all of these to ASCII before
parsing so you can type from any keyboard layout.

### Code-span escaping

Wrap a formula in backticks in prose and it will **not** evaluate:

```markdown
Use `=apfel(...)` to call the on-device model. Actually call one:
=apfel("hello")
```

The first is documentation. The second runs.

### Caching

Every result is cached by SHA256 of `(source || context || model_version || seed)`.
The cache lives at `~/Library/Application Support/apfelpad/cache/default.sqlite`
and survives app restarts.

## Privacy

apfelpad makes exactly **one** network call: an optional daily check
against `api.github.com` for new releases (togglable in Settings).
Every AI call goes to `localhost:11450` where `apfel --serve` runs on
your machine, reading from the on-device Foundation Models framework.
No telemetry. No accounts. No cloud inference. Ever.
