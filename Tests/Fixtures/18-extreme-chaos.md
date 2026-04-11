# EXTREME chaos — every edge case simultaneously

!!! this doc throws every adversarial input at apfelpad at once !!!

## 1. Smart quotes (German, English, mixed)
Schreib =apfel(„einen warmen Willkommensgruß“, 42).
Please =apfel(“a snappy headline”, 7).
Mixed =apfel("straight", 1) vs =apfel(“curly”, 2).

## 2. Anonymous shortcuts
Empty: =()
Phrase: =(one word)
Seeded: =("love letter", 99)

## 3. Nested and deep math
Simple: =math(1+1)
Deep: =math(((1+2)*(3+4))-((5-6)/2))
Division: =math(100/4)

## 4. All ten spreadsheet formulas
=upper("hello")
=lower("HELLO")
=trim("   padded   ")
=len("apfelpad")
=concat("Hello, ", "world", "!")
=replace("hello world", "world", "apfelpad")
=split("a,b,c,d", ",", 2)
=if("yes", "go", "stop")
=sum(1, 2, 3, 4, 5)
=avg(10, 20, 30)

## 5. Backtick-escaped code spans — MUST NOT EVALUATE
Use `=apfel(ghost)` and `=math(ghost)` in prose without them running.
Also `=upper(ghost)`.

## 6. Placeholder literal — MUST NOT EVALUATE
Every `=apfel(...)` formula runs on your Mac.

## 7. Curly parens inside string
Evil: =apfel(“laugh (out loud) about =math(2+2)”, 5)

## 8. Broken / unclosed — silently skipped
Broken: =math(1+
Broken: =apfel("missing close
But this still works: =math(99)

## 9. Formulas in headings
# =math(2025) retrospective
## Budget: =sum(40, 20, 35)

## 10. =ref back to earlier sections
Short summary: =ref(@1-smart-quotes)
Timeline: =ref(@3-nested-and-deep-math)

## 11. Emoji and unicode
🎉 Result: =math(21*2) 🧮 with =upper("résumé")
漢字 before =math(8*8) after 日本語

## 12. Chaos monkey — random invalid junk mixed with valid
=MATH(1+1) — uppercase name, skipped
= math(1+1) — space after =, skipped
=unknown(foo) — unknown function, skipped
=math(abc) — garbage expression, evaluates to .error
Final: =math(42)
