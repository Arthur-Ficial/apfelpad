# Welcome to apfelpad

Hey there! This is a live workbook — every formula below is running right now. Click any green value to edit it, type new numbers into the inputs, and watch everything recalculate instantly. Switch between Render and Source (Cmd+1 / Cmd+2) to see the markdown underneath. Go ahead, break things — you can always reopen this from the File menu.

## Live Quote Calculator

Client: =input("client", text, "Acme Corp")
Hours: =input("hours", number, "48")
Hourly rate: =input("rate", number, "125")
Discount percent: =input("discount", percent, "10")
Tax percent: =input("tax", percent, "20")

Quote status: =if(=math(@hours * @rate), "ready to send", "missing numbers")
Client echo: =show(@client)
Hours echo: =show(@hours)
Rate echo: =show(@rate)

Subtotal: $=math(@hours * @rate)
Discount value: $=math(@hours * @rate * @discount / 100)
After discount: $=math(@hours * @rate * (100 - @discount) / 100)
Tax value: $=math(@hours * @rate * (100 - @discount) / 100 * @tax / 100)
Grand total: $=math(@hours * @rate * (100 - @discount) / 100 * (100 + @tax) / 100)
Weekly burn at 40 hours: $=math(@rate * 40)
Working days: =math(@hours / 8)
Working weeks: =math(@hours / 40)
Average of hours, rate, and tax: =avg(@hours, @rate, @tax)
Combined headline number: =sum(@hours, @rate, @tax)
Summary line: =concat("Quote for ", @client, " totals $", =math(@hours * @rate * (100 - @discount) / 100 * (100 + @tax) / 100), ".")

## Text Workshop

Trimmed project name: =trim("   Acme Launch Sprint   ")
Uppercase title: =upper(=trim("   launch sprint   "))
Lowercase shout: =lower("LOUD WORDS")
Length of the client name: =len(=show(@client))
Replaced tagline: =replace("ship the draft today", "draft", "calculator")
Second CSV part: =split("design,build,ship", ",", 1)
Nested text combo: =upper(=replace(=trim("  calm docs win  "), "docs", "systems"))

## Calendar And Planning

Today: =date()
Tomorrow: =date(+1)
Weekday: =day()
Calendar week: =cw()
Next week: =cw(+1)
Month: =month()
Current time: =time()

## Project Brief

apfelpad is a spreadsheet for thinking. The quote above should stay editable, testable, and readable in one text document.

## Document Intelligence

Word count of this workbook: =count()
Word count of the project brief: =count(@#project-brief)
Project brief pulled live: =ref(@#project-brief)
Shouted brief: =upper(=ref(@#project-brief))

## External Context

Bundled sample file: =file("__WELCOME_SAMPLE_FILE__")
Clipboard snapshot: =clip()

## AI Drafting

Seeded local response: =apfel("Write one calm sentence explaining why formulas make this note dependable.", 7)
Anonymous shortcut: =(write a five-word tagline for this workbook, 3)
Prompt built from the document: =apfel(=concat("Summarize this quote for ", =show(@client), ". Total is $", =math(@hours * @rate * (100 - @discount) / 100 * (100 + @tax) / 100), ". Brief: ", =ref(@#project-brief)), 11)
