# Quote calculator

Type values into the inputs below. Every formula that references them
updates in real time.

## Project details

Client name: =input("client", text, "Acme Corp")
Project hours: =input("hours", number, "40")
Hourly rate: =input("rate", number, "150")

## Calculations

Subtotal: $=math(@hours * @rate)
Tax (20%): $=math(@hours * @rate * 0.2)
Total: $=math(@hours * @rate * 1.2)

## Summary

You're quoting =show(@client) for =show(@hours) hours at $=show(@rate) per hour.

Current subtotal is $=math(@hours * @rate), tax adds $=math(@hours * @rate * 0.2),
bringing the grand total to $=math(@hours * @rate * 1.2).
