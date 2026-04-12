# The big sheet — every apfelpad formula, one document

apfelpad is a formula notepad. Every pale-green span below is a live
formula that you can click and edit. This whole document is a regression
fixture — the formulas evaluate end-to-end via the same runtime that
ships with the app.

# Arithmetic

Plain math: =math(42*2) — a classic answer.
Nested parens: =math((100-25)*4) — orders work.
US formatting: =math($1,250 + $750) — currency and commas parse.
Suffixes: =math(2m + 500k) — `m`/`k`/`b` expand to their full value.

# Dates

Today: =date() · Tomorrow: =date(+1) · A week ago: =date(-7)
Week number: =weeknum() · Last week: =weeknum(-1) · Next week: =weeknum(+1)
Today is a =day() in =month() at =time().

# Text

Uppercase: =upper("hello apfelpad")
Lowercase: =lower("WORLD")
Trim: =trim("   padded   ")
Length: =len("apfelpad")
Concatenate: =concatenate("Hello, ", "world", "!")
Substitute: =substitute("hello world", "world", "apfelpad")
Split (index 1): =split("a,b,c", ",", 1)

# Numeric aggregates

Sum: =sum(10, 20, 30, 40)
Average: =average(2, 4, 6, 8, 10)
If: =if("yes", "✓ confirmed", "✗ denied")

# Document references

## Goal

Build a formula notepad for thinking on macOS.

## Recap

The goal we set was: =ref(@goal)

The word count of the goal section is =len(=ref(@goal)) characters.
The goal shouted: =upper(=ref(@goal))

# Turing-complete composition

Routing at work — nested calls flatten bottom-up before the outer call runs:

  =upper(=trim(=lower("   HELLO WORLD   "))) → =upper(=trim("hello world")) → =upper("hello world") → HELLO WORLD

Live result: =upper(=trim(=lower("   HELLO WORLD   ")))

Conditional math: =if(=math(5*5), "big", "small")
Summed lengths: =sum(=len("abc"), =len("de"), =math(10))
Upper ref: =upper(=ref(@goal))

# On-device AI

Ask the model: =apfel("one sentence: why is apfelpad the calmest AI writing tool", 7)
Compose AI with context: =apfel(=concatenate("summarize: ", =ref(@goal)), 42)
Anonymous shortcut: =(write a haiku about formulas, 3)

# v0.4 preview

Future recording formula: =recording() — tap to record, stops and transcribes via apfel.
