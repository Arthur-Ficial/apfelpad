# apfelpad formula catalogue

apfelpad formulas work like spreadsheet formulas, except the "cells" are
inline spans in a markdown document. Every formula is a pure function:
given the same inputs you get the same output, results are cached
deterministically, and nothing leaves your Mac.

## Auto-quoting

You never have to remember quote syntax. If apfelpad can't parse the
arguments as expressions, it treats them as a single string literal.

| You type | Canonical form |
|---|---|
| `=apfel(hello world)` | `=apfel("hello world")` |
| `=(hello world)` | `=apfel("hello world")` |
| `=upper(hello)` | `=upper("hello")` |
| `=concat(a, b, c)` | `=concat("a", "b", "c")` |

Smart quotes (`"…"`, `„…"`, `'…'`) that macOS auto-substitutes are
straightened to ASCII before parsing, so you can type `=apfel("hi")`
from any keyboard layout.

## The anonymous shortcut

`=(...)` is shorthand for `=apfel(...)`. It canonicalises to the full
form on commit, so the stored markdown file is always self-explanatory.

```
=(write a haiku about spring, 7)
```
becomes
```
=apfel("write a haiku about spring", 7)
```

## On-device AI

| Formula | What it does |
|---|---|
| `=apfel(prompt, seed?)` | On-device LLM call via `apfel --serve`. Auto-scoped context. Seeded calls are deterministic via the formula cache. |
| `=()` | Anonymous shortcut for `=apfel("")`. |
| `=(prompt)` | Anonymous shortcut for `=apfel("prompt")`. |

Example:

```
=apfel("write a warm welcome in two sentences", 42)
```

The seed parameter is the reproducibility contract: same seed +
same context + same model version → same output, via a composite cache
key. Change the seed, regenerate. Change the prompt, regenerate.
Never destructively.

## Arithmetic

| Formula | What it does | Example |
|---|---|---|
| `=math(expression)` | Pure arithmetic. Supports `+ - * /` and parens. | `=math(365*24)` → `8760` |

## Text formulas

All text formulas are pure Swift and never touch the LLM.

| Formula | Google Sheets equivalent | What it does | Example |
|---|---|---|---|
| `=upper(text)` | `UPPER()` | Uppercase | `=upper("hello")` → `HELLO` |
| `=lower(text)` | `LOWER()` | Lowercase | `=lower("HELLO")` → `hello` |
| `=trim(text)` | `TRIM()` | Strip leading/trailing whitespace | `=trim("  hi  ")` → `hi` |
| `=len(text)` | `LEN()` | Grapheme count | `=len("🎉")` → `1` |
| `=concat(a, b, c, …)` | `CONCATENATE()` | Join any number of strings | `=concat("Hello, ", "world")` → `Hello, world` |
| `=replace(text, find, replacement)` | `SUBSTITUTE()` | First-occurrence substitution | `=replace("hi world", "world", "apfelpad")` → `hi apfelpad` |
| `=split(text, delim, index?)` | `SPLIT()` | Return the `index`-th piece (default `0`) | `=split("a,b,c", ",", 1)` → `b` |

## Numeric formulas

| Formula | Google Sheets equivalent | What it does | Example |
|---|---|---|---|
| `=sum(n1, n2, …)` | `SUM()` | Add variadic numeric args | `=sum(1, 2, 3)` → `6` |
| `=avg(n1, n2, …)` | `AVERAGE()` | Arithmetic mean | `=avg(2, 4, 6)` → `4` |

## Control flow

| Formula | What it does | Example |
|---|---|---|
| `=if(cond, then, else)` | Truthy-test `cond`. Empty string, `"0"`, `"false"`, `"no"` are falsy; everything else is truthy. | `=if("yes", "go", "stop")` → `go` |

## Click to edit

Every rendered formula span is a link. Clicking it populates the
formula bar at the top of the window with the span's source. Edit in
the bar and the change applies in real time (debounced 120 ms). Press
Enter to commit immediately. If what you type doesn't parse, the bar
shows a red exclamation mark and the document stays untouched — partial
typing never destroys text.

## Caching

Every formula evaluation is cached by a composite key:

```
sha256(formula_source || resolved_context || model_version || seed)
```

The cache lives at `~/Library/Application Support/apfelpad/cache/default.sqlite`
and survives app restarts. Change any input and the cache key changes
and the formula re-runs. Re-run the same formula and you get the same
answer instantly from cache.

## Privacy

apfelpad makes exactly one network call: an optional check against
`api.github.com` for new apfelpad releases. Every LLM call goes to
`localhost:11450` where `apfel --serve` runs on your machine, reading
from the on-device Foundation Models framework. Documents are plain
markdown on your disk. No telemetry, no accounts, no cloud inference.
