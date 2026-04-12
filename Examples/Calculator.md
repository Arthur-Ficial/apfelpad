# Freelance Project Calculator

A practical calculator for estimating project costs, built entirely with apfelpad formulas.

## Inputs

=input("hours", number, "120")
=input("rate", number, "95")
=input("tax_rate", number, "20")
=input("discount", number, "0")

## Project Estimate

| Item | Value |
|------|-------|
| Hours | =show(@hours) |
| Hourly rate | =concatenate("$", @rate) |
| Subtotal | =concatenate("$", =math(@hours * @rate)) |
| Discount | =concatenate(@discount, "%") |
| After discount | =concatenate("$", =math(@hours * @rate * (100 - @discount) / 100)) |
| Tax (=concatenate(@tax_rate, "%")) | =concatenate("$", =math(@hours * @rate * (100 - @discount) / 100 * @tax_rate / 100)) |
| **Total** | =concatenate("$", =math(@hours * @rate * (100 - @discount) / 100 * (100 + @tax_rate) / 100)) |

## Weekly breakdown

If the project runs =math(@hours / 40) weeks at 40 hours/week:

- Per week: =concatenate("$", =math(@rate * 40))
- Per day: =concatenate("$", =math(@rate * 8))

## Unit conversions

Quick reference:

- =math(120) hours = =math(120 / 8) working days
- =math(120 / 40) weeks
- =math(120 * 60) minutes

## Date & time

- Today: =date()
- Weekday: =day()
- Calendar week: =weeknum()
- This month: =month()

## Document stats

This document has =count() words.

## Quick math reference

| Expression | Result |
|-----------|--------|
| =math(15 * 12) | 15 x 12 |
| =math(100 / 3) | 100 / 3 |
| =math(2 * 2 * 2 * 2) | 2^4 |
| =math($1,250 + $3,750) | US currency |
| =math(1.5k + 500) | k notation |
=(write a haiku, 3)