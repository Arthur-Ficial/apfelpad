import Foundation

/// 25+ ready-to-load workbooks shown in the left Examples sidebar.
/// Each example exercises real apfelpad formulas (=input, =math, =apfel,
/// =if, =today(), =show, …) so the user gets a working sheet, not docs.
enum ExamplesLibrary {
    static let all: [ExampleDocument] = [

        // MARK: - GET STARTED

        ExampleDocument(
            title: "Hello, apfelpad",
            blurb: "Your first formula. Arithmetic that updates as you type.",
            icon: "hand.wave",
            category: .starter,
            body: """
            # Hello, apfelpad

            apfelpad is a markdown document where every span can be a
            live formula. Try editing the inputs below — the answer
            updates instantly.

            =input(a, number, 12)  +  =input(b, number, 30)  =  =math(@a + @b)

            Or ask the on-device AI a question:

            =apfel("Write a one-sentence welcome to a new user.")
            """
        ),

        ExampleDocument(
            title: "All formulas at a glance",
            blurb: "One example of each built-in formula type.",
            icon: "list.bullet.rectangle",
            category: .starter,
            body: """
            # Formula sampler

            **Math.**            =math(2 + 2 * 5)
            **Today.**           =today()
            **Date in 7 days.**  =date(7)
            **Word count.**      =count
            **Upper.**           =upper("good morning")
            **Lower.**           =lower("HELLO WORLD")
            **Concat.**          =concatenate("apfel", "pad")
            **If.**              =if(@n > 10, "many", "few")  with =input(n, number, 7)
            **Echo input.**      =show(@n)

            Open the right sidebar (⌘⇧F) for the full reference.
            """
        ),

        // MARK: - CALCULATORS

        ExampleDocument(
            title: "Quote calculator",
            blurb: "Hours × rate, with discount and tax. Live totals.",
            icon: "doc.text.magnifyingglass",
            category: .calculator,
            body: """
            # Live Quote Calculator

            Client: =input(client, text, "Acme Corp")
            Hours:  =input(hours, number, 48)
            Hourly rate: =input(rate, number, 125)
            Discount percent: =input(disc, percent, 10)
            Tax percent: =input(tax, percent, 20)

            Subtotal: =math(@hours * @rate)
            After discount: =math(@hours * @rate * (1 - @disc / 100))
            **Total (incl. tax):** =math(@hours * @rate * (1 - @disc / 100) * (1 + @tax / 100))
            """
        ),

        ExampleDocument(
            title: "Tip calculator",
            blurb: "Bill split with tip, rounded per person.",
            icon: "fork.knife",
            category: .calculator,
            body: """
            # Tip splitter

            Bill: =input(bill, number, 84.50)
            Tip percent: =input(tip, percent, 18)
            People: =input(people, number, 4)

            Tip: =math(@bill * @tip / 100)
            **Each pays:** =math((@bill * (1 + @tip / 100)) / @people)
            """
        ),

        ExampleDocument(
            title: "Tax-inclusive price",
            blurb: "Type a net price; see gross with VAT.",
            icon: "percent",
            category: .calculator,
            body: """
            # VAT calculator

            Net price:    =input(net, number, 100)
            VAT percent:  =input(vat, percent, 20)

            VAT amount:   =math(@net * @vat / 100)
            **Gross:**    =math(@net * (1 + @vat / 100))
            """
        ),

        ExampleDocument(
            title: "BMI calculator",
            blurb: "Height + weight → body mass index.",
            icon: "figure.stand",
            category: .calculator,
            body: """
            # BMI

            Height (cm): =input(h, number, 178)
            Weight (kg): =input(w, number, 72)

            BMI: =math(@w / ((@h / 100) * (@h / 100)))

            Category: =if(@w / ((@h / 100) * (@h / 100)) < 18.5, "underweight",
                       =if(@w / ((@h / 100) * (@h / 100)) < 25, "healthy",
                       =if(@w / ((@h / 100) * (@h / 100)) < 30, "overweight", "obese")))
            """
        ),

        ExampleDocument(
            title: "Mortgage estimator",
            blurb: "Loan amount, rate, years → monthly payment.",
            icon: "house",
            category: .calculator,
            body: """
            # Monthly mortgage payment

            Loan (€):    =input(p, number, 320000)
            Annual rate (%): =input(r, percent, 3.5)
            Years:       =input(y, number, 25)

            Monthly rate: =math(@r / 100 / 12)
            Total payments: =math(@y * 12)

            **Monthly payment (€):** =math((@p * (@r / 100 / 12)) / (1 - (1 + @r / 100 / 12) ** (-@y * 12)))
            """
        ),

        ExampleDocument(
            title: "Compound interest",
            blurb: "Watch your savings grow at a chosen rate.",
            icon: "chart.line.uptrend.xyaxis",
            category: .calculator,
            body: """
            # Compound interest

            Principal (€): =input(p, number, 10000)
            Annual rate (%): =input(r, percent, 5)
            Years:        =input(y, number, 10)

            Final value: =math(@p * (1 + @r / 100) ** @y)
            Interest earned: =math(@p * (1 + @r / 100) ** @y - @p)
            """
        ),

        ExampleDocument(
            title: "Unit converter (km ↔ mi)",
            blurb: "Type kilometres, get miles back instantly.",
            icon: "arrow.left.arrow.right",
            category: .calculator,
            body: """
            # Distance

            Kilometres: =input(km, number, 100)
            → Miles:    =math(@km * 0.621371)

            Miles:      =input(mi, number, 60)
            → Kilometres: =math(@mi * 1.609344)
            """
        ),

        ExampleDocument(
            title: "Currency conversion",
            blurb: "Plug your own rate; see converted value.",
            icon: "eurosign.circle",
            category: .calculator,
            body: """
            # Currency

            Amount (EUR): =input(eur, number, 1000)
            EUR → USD rate: =input(rate, number, 1.08)

            **USD:** =math(@eur * @rate)

            (Pull the latest rate from your bank, then enter it
            above. apfelpad never makes a network call for inference.)
            """
        ),

        // MARK: - PRODUCTIVITY

        ExampleDocument(
            title: "Daily standup",
            blurb: "Yesterday / today / blockers, dated.",
            icon: "person.3",
            category: .productivity,
            body: """
            # Standup — =today()

            **Name:** =input(who, text, "Arthur")

            ## Yesterday
            =input(yesterday, textarea, "Shipped v0.5.8 release pipeline.")

            ## Today
            =input(today, textarea, "Examples library, input field redesign.")

            ## Blockers
            =input(blockers, textarea, "None")
            """
        ),

        ExampleDocument(
            title: "Meeting notes",
            blurb: "Inputs for attendees + decisions, AI summary.",
            icon: "person.2.wave.2",
            category: .productivity,
            body: """
            # Meeting — =input(topic, text, "Q2 planning")

            **Date:** =today()
            **Attendees:** =input(attendees, text, "Arthur, Franz")

            ## Discussion
            =input(notes, textarea, "We agreed to ship the examples library this week.")

            ## Action items
            =input(actions, textarea, "1. Arthur: prototype examples library
            2. Franz: review designs")

            ## One-line summary
            =apfel(=concatenate("Summarise this meeting in one sentence: ", @notes))
            """
        ),

        ExampleDocument(
            title: "Project status update",
            blurb: "Weekly snapshot you can paste into Slack.",
            icon: "rectangle.on.rectangle",
            category: .productivity,
            body: """
            # =input(project, text, "apfelpad") — week of =today()

            **Status:** =input(status, text, "On track")
            **Owner:**  =input(owner, text, "Arthur")

            ## Done this week
            =input(done, textarea, "- Notarised release pipeline\\n- Examples library")

            ## Up next
            =input(next, textarea, "- Reader-model spike\\n- v0.6 milestone")

            ## Risks
            =input(risks, textarea, "None")
            """
        ),

        ExampleDocument(
            title: "Reading list",
            blurb: "Books with one-line AI summaries.",
            icon: "books.vertical",
            category: .productivity,
            body: """
            # Reading list

            **Book 1:** =input(b1, text, "Designing Data-Intensive Applications")
            One-liner: =apfel(=concatenate("In one sentence, what is the book '", @b1, "' about?"))

            **Book 2:** =input(b2, text, "The Pragmatic Programmer")
            One-liner: =apfel(=concatenate("In one sentence, what is the book '", @b2, "' about?"))

            **Book 3:** =input(b3, text, "Working in Public")
            One-liner: =apfel(=concatenate("In one sentence, what is the book '", @b3, "' about?"))
            """
        ),

        ExampleDocument(
            title: "Habit tracker",
            blurb: "Toggles + a weekly score.",
            icon: "checkmark.circle",
            category: .productivity,
            body: """
            # Habits — week of =today()

            Walked 10k steps: =input(walk, toggle, false)
            Read 30 min:      =input(read, toggle, false)
            Wrote in journal: =input(journal, toggle, false)
            No screens after 22:00: =input(noscreen, toggle, false)

            **Score:** =math(=if(@walk, 1, 0) + =if(@read, 1, 0) + =if(@journal, 1, 0) + =if(@noscreen, 1, 0)) / 4
            """
        ),

        // MARK: - WRITING & EMAIL

        ExampleDocument(
            title: "Cold outreach email",
            blurb: "Fill the inputs; AI drafts the email.",
            icon: "envelope",
            category: .writing,
            body: """
            # Cold outreach draft

            Recipient name: =input(name, text, "Sam")
            Recipient role: =input(role, text, "Head of Engineering")
            Their company:  =input(company, text, "Acme Corp")
            Why I'm reaching out: =input(why, textarea, "We help eng teams cut CI cost by 30%.")
            One specific thing I admire: =input(admire, text, "Your post on staff-eng career growth")

            ---

            =apfel(=concatenate(
                "Write a short, warm cold-outreach email under 90 words. ",
                "Recipient: ", @name, ", ", @role, " at ", @company, ". ",
                "Reason: ", @why, ". ",
                "Specific compliment to lead with: ", @admire, ". ",
                "Sign off as Arthur."
            ))
            """
        ),

        ExampleDocument(
            title: "Customer support reply",
            blurb: "Empathetic reply drafted from a complaint.",
            icon: "bubble.left.and.bubble.right",
            category: .writing,
            body: """
            # Support reply draft

            Customer name: =input(name, text, "Jane")
            Their issue: =input(issue, textarea, "I was charged twice for the same order.")
            Resolution we are offering: =input(fix, textarea, "Refund of the duplicate charge within 3 business days.")

            ---

            =apfel(=concatenate(
                "Draft a calm, empathetic customer support reply under 120 words. ",
                "Customer: ", @name, ". Issue: ", @issue, ". ",
                "Resolution: ", @fix, ". ",
                "Sign off as the apfelpad support team."
            ))
            """
        ),

        ExampleDocument(
            title: "Bug report template",
            blurb: "Structured fields with an AI severity rating.",
            icon: "ant",
            category: .writing,
            body: """
            # Bug — =input(title, text, "Input field overlap in render mode")

            **Reporter:** =input(reporter, text, "Arthur")
            **Date:** =today()

            ## Steps to reproduce
            =input(steps, textarea, "1. Open the quote calculator example.\\n2. Look at adjacent input lines.")

            ## Expected
            =input(expected, text, "Lines do not overlap.")

            ## Actual
            =input(actual, text, "Lines visibly overlap.")

            ## AI-suggested severity
            =apfel(=concatenate(
                "Given this bug report, return one word — Severity: low, medium, high, or critical. ",
                "Title: ", @title, ". Steps: ", @steps, ". Expected: ", @expected, ". Actual: ", @actual
            ))
            """
        ),

        ExampleDocument(
            title: "Cover letter",
            blurb: "Job application draft from your inputs.",
            icon: "person.text.rectangle",
            category: .writing,
            body: """
            # Cover letter

            Company: =input(company, text, "Anthropic")
            Role: =input(role, text, "Software Engineer, AI")
            Why you: =input(why, textarea, "10 years shipping production Swift, deep interest in safe, interpretable AI.")
            Top accomplishment: =input(accomp, textarea, "Built and shipped apfelpad — a local, formula-first markdown editor with on-device AI.")

            ---

            =apfel(=concatenate(
                "Write a cover letter under 250 words for the ", @role, " role at ",
                @company, ". Reasons to hire me: ", @why, ". ",
                "Top accomplishment to feature: ", @accomp, ". ",
                "Tone: confident, specific, no clichés. Sign off as Arthur."
            ))
            """
        ),

        ExampleDocument(
            title: "Birthday card",
            blurb: "Warm message generated for someone you love.",
            icon: "gift",
            category: .writing,
            body: """
            # Birthday card

            For: =input(name, text, "Mom")
            Their age: =input(age, number, 60)
            One specific memory: =input(memory, textarea, "Teaching me to make spaghetti carbonara.")
            One quality I love: =input(quality, text, "Always making everyone feel at home")

            ---

            =apfel(=concatenate(
                "Write a warm, sincere birthday card message under 80 words for ",
                @name, " turning ", @age, ". ",
                "Reference this specific memory: ", @memory, ". ",
                "And this quality: ", @quality, ". Sign off as Arthur."
            ))
            """
        ),

        // MARK: - ON-DEVICE AI

        ExampleDocument(
            title: "Translate to any language",
            blurb: "Type English, get the translation.",
            icon: "character.book.closed",
            category: .ai,
            body: """
            # Translator

            Source text:
            =input(text, textarea, "The quick brown fox jumps over the lazy dog.")

            Target language: =input(lang, text, "German")

            ---

            =apfel(=concatenate("Translate the following text to ", @lang, ", returning only the translation. Text: ", @text))
            """
        ),

        ExampleDocument(
            title: "Idea brainstormer",
            blurb: "Topic in, five sharp ideas out.",
            icon: "lightbulb",
            category: .ai,
            body: """
            # Brainstorm

            Topic: =input(topic, text, "Marketing ideas for a local bookshop")

            =apfel(=concatenate(
                "Give exactly 5 short, concrete ideas for: ", @topic,
                ". Format as a numbered list. No preamble."
            ))
            """
        ),

        ExampleDocument(
            title: "Explain like I'm five",
            blurb: "Paste any concept; get a kid-friendly version.",
            icon: "person.crop.circle.badge.questionmark",
            category: .ai,
            body: """
            # ELI5

            Concept: =input(concept, textarea, "Quantum entanglement")

            =apfel(=concatenate(
                "Explain '", @concept,
                "' to a curious 5-year-old in 3 short paragraphs. Use a concrete everyday metaphor."
            ))
            """
        ),

        ExampleDocument(
            title: "TL;DR summariser",
            blurb: "Drop in a long passage; get the short version.",
            icon: "text.alignleft",
            category: .ai,
            body: """
            # Summarise

            Length: =input(length, text, "two sentences")

            Text:
            =input(text, textarea, "Paste a long article or note here.")

            ---

            =apfel(=concatenate("Summarise the following text in ", @length, ". Text: ", @text))
            """
        ),

        // MARK: - EVERYDAY LIFE

        ExampleDocument(
            title: "Recipe scaler",
            blurb: "Original servings → your servings, all amounts.",
            icon: "frying.pan",
            category: .life,
            body: """
            # Recipe scaler — Spaghetti carbonara

            Original servings: =input(orig, number, 4)
            Wanted servings:   =input(want, number, 6)

            **Scale factor:** =math(@want / @orig)

            | Ingredient | Original | Scaled |
            |---|---|---|
            | Spaghetti (g) | 400 | =math(400 * @want / @orig) |
            | Guanciale (g) | 200 | =math(200 * @want / @orig) |
            | Egg yolks | 6 | =math(6 * @want / @orig) |
            | Pecorino (g) | 100 | =math(100 * @want / @orig) |
            """
        ),

        ExampleDocument(
            title: "Workout plan",
            blurb: "Effort percent → today's working weights.",
            icon: "dumbbell",
            category: .life,
            body: """
            # Today's lifts

            Effort: =input(effort, percent, 80)

            One-rep max — squat (kg): =input(squatMax, number, 140)
            One-rep max — bench (kg): =input(benchMax, number, 100)
            One-rep max — deadlift (kg): =input(dlMax, number, 180)

            **Working weights**
            Squat: =math(@squatMax * @effort / 100)
            Bench: =math(@benchMax * @effort / 100)
            Deadlift: =math(@dlMax * @effort / 100)
            """
        ),

        ExampleDocument(
            title: "Travel itinerary",
            blurb: "Trip details in, day-by-day plan out.",
            icon: "airplane",
            category: .life,
            body: """
            # Trip plan

            Destination: =input(dest, text, "Lisbon")
            Days: =input(days, number, 4)
            Style: =input(style, text, "food + walking, low-key")

            =apfel(=concatenate(
                "Plan a ", @days, "-day trip to ", @dest,
                ". Style preference: ", @style,
                ". Output a day-by-day itinerary with morning, lunch, afternoon, dinner. Be specific (real place names)."
            ))
            """
        ),

        ExampleDocument(
            title: "Restaurant order",
            blurb: "Pick dishes; bill totals on the fly.",
            icon: "fork.knife.circle",
            category: .life,
            body: """
            # Order

            Mains: =input(mains, number, 2) × €18.50
            Sides: =input(sides, number, 1) × €6
            Drinks: =input(drinks, number, 3) × €4.50
            Service tip: =input(tip, percent, 12)

            Subtotal: =math(@mains * 18.5 + @sides * 6 + @drinks * 4.5)
            **Total:** =math((@mains * 18.5 + @sides * 6 + @drinks * 4.5) * (1 + @tip / 100))
            """
        ),

        ExampleDocument(
            title: "Dates & time",
            blurb: "today, in 30 days, week number, month, day.",
            icon: "calendar",
            category: .life,
            body: """
            # Dates

            **Today is:** =today()
            **In 7 days:** =date(7)
            **In 30 days:** =date(30)
            **A week ago:** =date(-7)

            **This week number:** =weeknum(0)
            **Month:** =month()
            **Day of month:** =day()
            **Time:** =time()
            """
        ),
    ]

    static func search(_ query: String) -> [ExampleDocument] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return all }
        return all.filter { doc in
            if doc.title.lowercased().contains(q) { return true }
            if doc.blurb.lowercased().contains(q) { return true }
            if doc.body.lowercased().contains(q) { return true }
            if doc.category.title.lowercased().contains(q) { return true }
            return false
        }
    }

    static func grouped() -> [ExamplesLibrarySection] {
        let byCategory = Dictionary(grouping: all, by: \.category)
        let order = ExampleDocument.Category.allCases
            .filter { byCategory[$0] != nil }
            .sorted { $0.order < $1.order }
        return order.map { cat in
            ExamplesLibrarySection(category: cat, entries: byCategory[cat] ?? [])
        }
    }

    static func groupedSearch(_ query: String) -> [ExamplesLibrarySection] {
        let matching = Set(search(query).map(\.id))
        return grouped().compactMap { section in
            let kept = section.entries.filter { matching.contains($0.id) }
            return kept.isEmpty ? nil : ExamplesLibrarySection(category: section.category, entries: kept)
        }
    }
}
