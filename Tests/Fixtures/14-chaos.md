!!! Random chaos test !!!

=math(1+1) => valid
=math() => invalid (empty math) — skipped
=unknown(foo) => unknown function — skipped
=math(abc) => invalid expression — still a span, evaluates to .error
= math(1+1) => space after = => invalid — skipped
=MATH(1+1) => uppercase name — now discovered (case-insensitive)
==math(1+1) => double equals => `=math(1+1)` at offset 1 is valid, the first `=` is stray
)(=math(3*3) => noise + valid

Final: =math(7*6)
