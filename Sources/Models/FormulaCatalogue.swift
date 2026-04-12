import Foundation

/// Static catalogue of every formula apfelpad ships. The source of truth
/// for the right-sidebar formula browser, the README, and docs/formulas.md.
enum FormulaCatalogue {
    // MARK: - All entries

    static let all: [FormulaCatalogueEntry] = [
        // AI
        FormulaCatalogueEntry(
            name: "=apfel",
            category: .ai,
            signature: "=apfel(prompt, seed?)",
            description: "On-device LLM call via apfel --serve",
            example: #"=apfel("write a haiku about spring", 42)"#,
            exampleResult: "(streams from Foundation Models)",
            keywords: ["llm", "ai", "foundation models", "prompt", "chat", "gpt", "generate"]
        ),
        FormulaCatalogueEntry(
            name: "=()",
            category: .ai,
            signature: "=(prompt, seed?)",
            description: "Anonymous shortcut — canonicalises to =apfel(...)",
            example: "=(write a haiku, 3)",
            exampleResult: "(streams from Foundation Models)",
            keywords: ["apfel", "anonymous", "shortcut", "llm"]
        ),

        // Arithmetic
        FormulaCatalogueEntry(
            name: "=math",
            category: .math,
            signature: "=math(expression)",
            description: "Arithmetic with US annotation ($, commas, k/m/b)",
            example: "=math($1,250 + $750)",
            exampleResult: "2000",
            keywords: ["arithmetic", "calculator", "number", "sum", "add", "multiply", "divide", "currency"]
        ),

        // Text
        FormulaCatalogueEntry(
            name: "=upper",
            category: .text,
            signature: "=upper(text)",
            description: "Uppercase a string",
            example: #"=upper("hello apfelpad")"#,
            exampleResult: "HELLO APFELPAD",
            keywords: ["case", "uppercase", "caps", "shout"]
        ),
        FormulaCatalogueEntry(
            name: "=lower",
            category: .text,
            signature: "=lower(text)",
            description: "Lowercase a string",
            example: #"=lower("WORLD")"#,
            exampleResult: "world",
            keywords: ["case", "lowercase"]
        ),
        FormulaCatalogueEntry(
            name: "=trim",
            category: .text,
            signature: "=trim(text)",
            description: "Strip leading and trailing whitespace",
            example: #"=trim("   padded   ")"#,
            exampleResult: "padded",
            keywords: ["whitespace", "strip", "clean"]
        ),
        FormulaCatalogueEntry(
            name: "=len",
            category: .text,
            signature: "=len(text)",
            description: "Count grapheme clusters (emoji-safe)",
            example: #"=len("apfelpad")"#,
            exampleResult: "8",
            keywords: ["length", "count", "size", "characters"]
        ),
        FormulaCatalogueEntry(
            name: "=concat",
            category: .text,
            signature: "=concat(a, b, c, …)",
            description: "Join any number of strings",
            example: #"=concat("Hello, ", "world", "!")"#,
            exampleResult: "Hello, world!",
            keywords: ["join", "string", "combine", "append"]
        ),
        FormulaCatalogueEntry(
            name: "=replace",
            category: .text,
            signature: "=replace(text, find, replacement)",
            description: "Substitute the first occurrence",
            example: #"=replace("hello world", "world", "apfelpad")"#,
            exampleResult: "hello apfelpad",
            keywords: ["substitute", "swap", "find", "rewrite"]
        ),
        FormulaCatalogueEntry(
            name: "=split",
            category: .text,
            signature: "=split(text, delim, index?)",
            description: "Return the nth piece (default 0)",
            example: #"=split("a,b,c", ",", 1)"#,
            exampleResult: "b",
            keywords: ["split", "part", "piece", "delimiter"]
        ),

        // Aggregates
        FormulaCatalogueEntry(
            name: "=sum",
            category: .aggregate,
            signature: "=sum(n1, n2, …)",
            description: "Variadic numeric sum",
            example: "=sum(1, 2, 3, 4, 5)",
            exampleResult: "15",
            keywords: ["add", "total", "numbers"]
        ),
        FormulaCatalogueEntry(
            name: "=avg",
            category: .aggregate,
            signature: "=avg(n1, n2, …)",
            description: "Arithmetic mean",
            example: "=avg(2, 4, 6)",
            exampleResult: "4",
            keywords: ["average", "mean", "numbers"]
        ),

        // Control flow
        FormulaCatalogueEntry(
            name: "=if",
            category: .control,
            signature: "=if(cond, then, else)",
            description: "Branch on a truthy condition",
            example: #"=if("yes", "go", "stop")"#,
            exampleResult: "go",
            keywords: ["branch", "conditional", "if", "then", "else"]
        ),

        // Dates & time
        FormulaCatalogueEntry(
            name: "=date",
            category: .date,
            signature: "=date(offset?)",
            description: "Today's date in ISO 8601 with optional day offset",
            example: "=date(+4)",
            exampleResult: "(four days from today)",
            keywords: ["today", "iso", "day", "calendar", "now"]
        ),
        FormulaCatalogueEntry(
            name: "=cw",
            category: .date,
            signature: "=cw(offset?)",
            description: "ISO calendar week with optional offset",
            example: "=cw(-1)",
            exampleResult: "(last week's number)",
            keywords: ["week", "calendar", "iso", "kw"]
        ),
        FormulaCatalogueEntry(
            name: "=month",
            category: .date,
            signature: "=month()",
            description: "Current month name in the user's locale",
            example: "=month()",
            exampleResult: "(current month)",
            keywords: ["month", "calendar", "date"]
        ),
        FormulaCatalogueEntry(
            name: "=day",
            category: .date,
            signature: "=day()",
            description: "Current weekday name in the user's locale",
            example: "=day()",
            exampleResult: "(today's weekday)",
            keywords: ["day", "weekday", "calendar"]
        ),
        FormulaCatalogueEntry(
            name: "=time",
            category: .date,
            signature: "=time()",
            description: "Current time as HH:mm",
            example: "=time()",
            exampleResult: "(now, 24-hour)",
            keywords: ["time", "hour", "clock", "now"]
        ),

        // Document references
        FormulaCatalogueEntry(
            name: "=ref",
            category: .reference,
            signature: "=ref(@anchor)",
            description: "Insert the text of a named heading section (live)",
            example: "=ref(@intro)",
            exampleResult: "(contents of the 'Intro' section)",
            keywords: ["reference", "section", "anchor", "heading", "link"]
        ),

        // v0.4 preview
        FormulaCatalogueEntry(
            name: "=recording",
            category: .preview,
            signature: "=recording()",
            description: "Placeholder for the upcoming audio recording formula",
            example: "=recording()",
            exampleResult: "🎙 recording UI — v0.4",
            keywords: ["record", "audio", "transcribe", "voice", "microphone", "v0.4"]
        ),

        // v0.5 — reactive input variables
        FormulaCatalogueEntry(
            name: "=input",
            category: .reference,
            signature: "=input(name, type, default?)",
            description: "Declare a reactive variable. Reference with @name in other formulas.",
            example: #"=input("hours", number, "40")"#,
            exampleResult: "40",
            keywords: ["variable", "input", "form", "reactive", "bind", "value"]
        ),
        FormulaCatalogueEntry(
            name: "=show",
            category: .reference,
            signature: "=show(@name)",
            description: "Echo the current value of a bound variable",
            example: "=show(@hours)",
            exampleResult: "(current value)",
            keywords: ["echo", "show", "print", "variable", "display"]
        ),
    ]

    // MARK: - Search

    /// Case-insensitive search across name, signature, description, example,
    /// and keyword list. Empty query returns every entry.
    static func search(_ query: String) -> [FormulaCatalogueEntry] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return all }
        return all.filter { entry in
            if entry.name.lowercased().contains(q) { return true }
            if entry.signature.lowercased().contains(q) { return true }
            if entry.description.lowercased().contains(q) { return true }
            if entry.example.lowercased().contains(q) { return true }
            if entry.category.title.lowercased().contains(q) { return true }
            for kw in entry.keywords where kw.contains(q) { return true }
            return false
        }
    }

    // MARK: - Grouping

    /// Returns entries grouped by category, in a deterministic display order.
    /// Entries within each section are sorted alphabetically by name.
    static func grouped() -> [FormulaCatalogueSection] {
        let byCategory = Dictionary(grouping: all, by: \.category)
        let sortedCategories = FormulaCatalogueEntry.Category.allCases
            .filter { byCategory[$0] != nil }
            .sorted { $0.order < $1.order }
        return sortedCategories.map { category in
            let entries = byCategory[category, default: []].sorted { $0.name < $1.name }
            return FormulaCatalogueSection(category: category, entries: entries)
        }
    }

    /// Same as grouped(), but filters by the search query first.
    /// Sections with no matching entries are omitted.
    static func groupedSearch(_ query: String) -> [FormulaCatalogueSection] {
        let matching = Set(search(query).map(\.id))
        return grouped().compactMap { section in
            let kept = section.entries.filter { matching.contains($0.id) }
            return kept.isEmpty ? nil : FormulaCatalogueSection(category: section.category, entries: kept)
        }
    }
}
