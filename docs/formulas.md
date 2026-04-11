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

### `=concat(a, b, c, …)`

Variadic string concatenation. Joins any number of string args with no
separator — use `=concat("Hello, ", "world", "!")` for a separator pattern.

```
=concat("Hello, ", "world", "!")   → Hello, world!
=concat("a", "b", "c")             → abc
```

### `=replace(text, find, replacement)`

First-occurrence substitution. Returns `text` unchanged if no match.

```
=replace("hello world", "world", "apfelpad")  → hello apfelpad
=replace("abc", "xyz", "!")                   → abc
```

### `=split(text, delim, index?)`

Return the `index`-th piece (default 0). Out-of-range returns `""`.

```
=split("a,b,c,d", ",", 0)     → a
=split("a,b,c,d", ",", 2)     → c
=split("a,b,c,d", ",", 99)    →
```

---

## Numeric aggregates

### `=sum(n1, n2, …)` / `=avg(n1, n2, …)`

Variadic sum and arithmetic mean. Each argument is parsed as a number.
Throws on non-numeric input.

```
=sum(1, 2, 3)             → 6
=sum(10, -5)              → 5
=sum(1.5, 2.5)            → 4
=avg(2, 4, 6)             → 4
=avg(1, 2)                → 1.5
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

## Dates and time

All date/time formulas read the user's locale by default. `=date` returns
ISO 8601, `=time` returns 24-hour `HH:mm`, `=cw` returns the ISO calendar
week (Monday start).

### `=date(offset?)`

```
=date()       → 2026-04-12
=date(+1)     → 2026-04-13
=date(-7)     → 2026-04-05
```

### `=cw(offset?)`

```
=cw()         → 15
=cw(-1)       → 14
=cw(+1)       → 16
```

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
=concat(=upper("hello "), =lower("WORLD"))    → HELLO world
=if(=math(5*5), "big", "small")               → big
=sum(=len("abc"), =len("de"), =math(10))      → 15
=apfel(=concat("summarize: ", =ref(@intro))) → streaming AI summary
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

---

## v0.4 preview

### `=recording()` — stub

Parses, round-trips, renders a placeholder. The real implementation (v0.4)
will show an inline record button that captures audio via apfel and
transcribes on stop. Composes with `=apfel(=recording())` already.

### `=count(@anchor?)` / `=date(format?)` / `=clip()` / `=file(path)`

Reserved names. Coming in v0.4+.

---

## Privacy

apfelpad makes exactly **one** network call: an optional daily check
against `api.github.com` for new releases (togglable in Settings).
Every AI call goes to `localhost:11450` where `apfel --serve` runs on
your machine, reading from the on-device Foundation Models framework.
No telemetry. No accounts. No cloud inference. Ever.
