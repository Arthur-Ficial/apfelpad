import Foundation

/// One formula definition — the single source of truth for parser names,
/// discoverability, sidebar metadata, and public documentation coverage.
struct FormulaDefinition: Identifiable, Equatable, Hashable {
    enum ParserKind: Hashable {
        case apfel
        case math
        case upper
        case lower
        case trim
        case len
        case concatenate
        case substitute
        case split
        case ifExpr
        case sum
        case average
        case ref
        case today
        case date
        case weeknum
        case month
        case day
        case time
        case input
        case show
        case count
        case clip
        case file
        case recording
        case isnumber
        case istext
        case isblank
        case type
        case now
        case year
        case weekday
        case hour
        case minute
        case second
    }

    let functionName: String
    let displayName: String
    let category: FormulaCatalogueEntry.Category
    let signature: String
    let description: String
    let example: String
    let exampleResult: String
    let keywords: [String]
    let parserKind: ParserKind
    let isPublic: Bool
    let isDiscoverable: Bool

    var id: String { displayName }

    init(
        functionName: String,
        displayName: String,
        category: FormulaCatalogueEntry.Category,
        signature: String,
        description: String,
        example: String,
        exampleResult: String,
        keywords: [String] = [],
        parserKind: ParserKind,
        isPublic: Bool = true,
        isDiscoverable: Bool = true
    ) {
        self.functionName = functionName
        self.displayName = displayName
        self.category = category
        self.signature = signature
        self.description = description
        self.example = example
        self.exampleResult = exampleResult
        self.keywords = keywords.map { $0.lowercased() }
        self.parserKind = parserKind
        self.isPublic = isPublic
        self.isDiscoverable = isDiscoverable
    }

    var catalogueEntry: FormulaCatalogueEntry {
        FormulaCatalogueEntry(
            name: displayName,
            category: category,
            signature: signature,
            description: description,
            example: example,
            exampleResult: exampleResult,
            keywords: keywords
        )
    }
}

enum FormulaRegistry {
    static let all: [FormulaDefinition] = [
        FormulaDefinition(
            functionName: "apfel",
            displayName: "=apfel",
            category: .ai,
            signature: "=apfel(prompt, seed?)",
            description: "On-device LLM call via apfel --serve",
            example: #"=apfel("write a haiku about spring", 42)"#,
            exampleResult: "(streams from Foundation Models)",
            keywords: ["llm", "ai", "foundation models", "prompt", "chat", "gpt", "generate"],
            parserKind: .apfel
        ),
        FormulaDefinition(
            functionName: "",
            displayName: "=()",
            category: .ai,
            signature: "=(prompt, seed?)",
            description: "Anonymous shortcut — canonicalises to =apfel(...)",
            example: "=(write a haiku, 3)",
            exampleResult: "(streams from Foundation Models)",
            keywords: ["apfel", "anonymous", "shortcut", "llm"],
            parserKind: .apfel,
            isDiscoverable: false
        ),
        FormulaDefinition(
            functionName: "math",
            displayName: "=math",
            category: .math,
            signature: "=math(expression)",
            description: "Arithmetic with US annotation ($, commas, k/m/b)",
            example: "=math($1,250 + $750)",
            exampleResult: "2000",
            keywords: ["arithmetic", "calculator", "number", "sum", "add", "multiply", "divide", "currency"],
            parserKind: .math
        ),
        FormulaDefinition(
            functionName: "upper",
            displayName: "=upper",
            category: .text,
            signature: "=upper(text)",
            description: "Uppercase a string",
            example: #"=upper("hello apfelpad")"#,
            exampleResult: "HELLO APFELPAD",
            keywords: ["case", "uppercase", "caps", "shout"],
            parserKind: .upper
        ),
        FormulaDefinition(
            functionName: "lower",
            displayName: "=lower",
            category: .text,
            signature: "=lower(text)",
            description: "Lowercase a string",
            example: #"=lower("WORLD")"#,
            exampleResult: "world",
            keywords: ["case", "lowercase"],
            parserKind: .lower
        ),
        FormulaDefinition(
            functionName: "trim",
            displayName: "=trim",
            category: .text,
            signature: "=trim(text)",
            description: "Strip leading and trailing whitespace",
            example: #"=trim("   padded   ")"#,
            exampleResult: "padded",
            keywords: ["whitespace", "strip", "clean"],
            parserKind: .trim
        ),
        FormulaDefinition(
            functionName: "len",
            displayName: "=len",
            category: .text,
            signature: "=len(text)",
            description: "Count grapheme clusters (emoji-safe)",
            example: #"=len("apfelpad")"#,
            exampleResult: "8",
            keywords: ["length", "count", "size", "characters"],
            parserKind: .len
        ),
        FormulaDefinition(
            functionName: "concatenate",
            displayName: "=concatenate",
            category: .text,
            signature: "=concatenate(a, b, c, …)",
            description: "Join any number of strings",
            example: #"=concatenate("Hello, ", "world", "!")"#,
            exampleResult: "Hello, world!",
            keywords: ["join", "string", "combine", "append", "concat"],
            parserKind: .concatenate
        ),
        FormulaDefinition(
            functionName: "substitute",
            displayName: "=substitute",
            category: .text,
            signature: "=substitute(text, old_text, new_text, [occurrence])",
            description: "Substitute the first occurrence (or nth if occurrence given)",
            example: #"=substitute("hello world", "world", "apfelpad")"#,
            exampleResult: "hello apfelpad",
            keywords: ["replace", "swap", "find", "rewrite"],
            parserKind: .substitute
        ),
        FormulaDefinition(
            functionName: "split",
            displayName: "=split",
            category: .text,
            signature: "=split(text, delim, index?)",
            description: "Return the nth piece (default 0)",
            example: #"=split("a,b,c", ",", 1)"#,
            exampleResult: "b",
            keywords: ["split", "part", "piece", "delimiter"],
            parserKind: .split
        ),
        FormulaDefinition(
            functionName: "sum",
            displayName: "=sum",
            category: .aggregate,
            signature: "=sum(n1, n2, …)",
            description: "Variadic numeric sum",
            example: "=sum(1, 2, 3, 4, 5)",
            exampleResult: "15",
            keywords: ["add", "total", "numbers"],
            parserKind: .sum
        ),
        FormulaDefinition(
            functionName: "average",
            displayName: "=average",
            category: .aggregate,
            signature: "=average(n1, n2, …)",
            description: "Arithmetic mean",
            example: "=average(2, 4, 6)",
            exampleResult: "4",
            keywords: ["avg", "mean", "numbers"],
            parserKind: .average
        ),
        FormulaDefinition(
            functionName: "if",
            displayName: "=if",
            category: .logical,
            signature: "=if(cond, then, else)",
            description: "Branch on a truthy condition",
            example: #"=if("yes", "go", "stop")"#,
            exampleResult: "go",
            keywords: ["branch", "conditional", "if", "then", "else"],
            parserKind: .ifExpr
        ),
        FormulaDefinition(
            functionName: "today",
            displayName: "=today",
            category: .date,
            signature: "=today()",
            description: "Today's date in ISO 8601",
            example: "=today()",
            exampleResult: "(today's date)",
            keywords: ["today", "date", "iso", "now"],
            parserKind: .today
        ),
        FormulaDefinition(
            functionName: "date",
            displayName: "=date",
            category: .date,
            signature: "=date(offset?)",
            description: "Today's date in ISO 8601 with optional day offset",
            example: "=date(+4)",
            exampleResult: "(four days from today)",
            keywords: ["today", "iso", "day", "calendar", "now"],
            parserKind: .date
        ),
        FormulaDefinition(
            functionName: "weeknum",
            displayName: "=weeknum",
            category: .date,
            signature: "=weeknum(offset?)",
            description: "ISO calendar week with optional offset",
            example: "=weeknum(-1)",
            exampleResult: "(last week's number)",
            keywords: ["week", "calendar", "iso", "kw", "cw"],
            parserKind: .weeknum
        ),
        FormulaDefinition(
            functionName: "month",
            displayName: "=month",
            category: .date,
            signature: "=month()",
            description: "Current month name in the user's locale",
            example: "=month()",
            exampleResult: "(current month)",
            keywords: ["month", "calendar", "date"],
            parserKind: .month
        ),
        FormulaDefinition(
            functionName: "day",
            displayName: "=day",
            category: .date,
            signature: "=day()",
            description: "Current weekday name in the user's locale",
            example: "=day()",
            exampleResult: "(today's weekday)",
            keywords: ["day", "weekday", "calendar"],
            parserKind: .day
        ),
        FormulaDefinition(
            functionName: "time",
            displayName: "=time",
            category: .date,
            signature: "=time()",
            description: "Current time as HH:mm",
            example: "=time()",
            exampleResult: "(now, 24-hour)",
            keywords: ["time", "hour", "clock", "now"],
            parserKind: .time
        ),
        FormulaDefinition(
            functionName: "ref",
            displayName: "=ref",
            category: .reference,
            signature: "=ref(@#anchor)",
            description: "Insert the text of a named heading section (live)",
            example: "=ref(@#intro)",
            exampleResult: "(contents of the 'Intro' section)",
            keywords: ["reference", "section", "anchor", "heading", "link"],
            parserKind: .ref
        ),
        FormulaDefinition(
            functionName: "count",
            displayName: "=count",
            category: .reference,
            signature: "=count(@#anchor?)",
            description: "Word count of the whole document or a named section",
            example: "=count(@#intro)",
            exampleResult: "42",
            keywords: ["word", "count", "length", "section", "words", "statistics"],
            parserKind: .count
        ),
        FormulaDefinition(
            functionName: "clip",
            displayName: "=clip",
            category: .text,
            signature: "=clip()",
            description: "Current clipboard contents (text only)",
            example: "=clip()",
            exampleResult: "(clipboard text)",
            keywords: ["clipboard", "paste", "copy", "pasteboard"],
            parserKind: .clip
        ),
        FormulaDefinition(
            functionName: "file",
            displayName: "=file",
            category: .reference,
            signature: "=file(path)",
            description: "Read a local text file (max 1 MB)",
            example: #"=file("~/notes.txt")"#,
            exampleResult: "(file contents)",
            keywords: ["file", "read", "local", "include", "import", "text"],
            parserKind: .file
        ),
        FormulaDefinition(
            functionName: "input",
            displayName: "=input",
            category: .reference,
            signature: "=input(name, type, default?)",
            description: "Declare a reactive variable. Reference with @name in other formulas.",
            example: #"=input("hours", number, "40")"#,
            exampleResult: "40",
            keywords: ["variable", "input", "form", "reactive", "bind", "value"],
            parserKind: .input
        ),
        FormulaDefinition(
            functionName: "show",
            displayName: "=show",
            category: .reference,
            signature: "=show(@name)",
            description: "Echo the current value of a bound variable",
            example: "=show(@hours)",
            exampleResult: "(current value)",
            keywords: ["echo", "show", "print", "variable", "display"],
            parserKind: .show
        ),
        FormulaDefinition(
            functionName: "recording",
            displayName: "=recording",
            category: .preview,
            signature: "=recording()",
            description: "Reserved name for a future audio recording formula",
            example: "=recording()",
            exampleResult: "🎙 recording UI — v0.4",
            keywords: ["record", "audio", "transcribe", "voice", "microphone"],
            parserKind: .recording,
            isPublic: false
        ),
        FormulaDefinition(
            functionName: "isnumber",
            displayName: "=ISNUMBER",
            category: .info,
            signature: "=ISNUMBER(value)",
            description: "TRUE if value parses as a number, FALSE otherwise",
            example: #"=ISNUMBER("42")"#,
            exampleResult: "TRUE",
            keywords: ["is", "number", "numeric", "type", "check"],
            parserKind: .isnumber
        ),
        FormulaDefinition(
            functionName: "istext",
            displayName: "=ISTEXT",
            category: .info,
            signature: "=ISTEXT(value)",
            description: "TRUE if value is not a number, FALSE if it is",
            example: #"=ISTEXT("hello")"#,
            exampleResult: "TRUE",
            keywords: ["is", "text", "string", "type", "check"],
            parserKind: .istext
        ),
        FormulaDefinition(
            functionName: "isblank",
            displayName: "=ISBLANK",
            category: .info,
            signature: "=ISBLANK(value)",
            description: "TRUE if value is empty (after trimming), FALSE otherwise",
            example: #"=ISBLANK("")"#,
            exampleResult: "TRUE",
            keywords: ["is", "blank", "empty", "whitespace", "type", "check"],
            parserKind: .isblank
        ),
        FormulaDefinition(
            functionName: "type",
            displayName: "=TYPE",
            category: .info,
            signature: "=TYPE(value)",
            description: "Returns 'number', 'text', or 'blank' describing the value",
            example: #"=TYPE("hello")"#,
            exampleResult: "text",
            keywords: ["type", "kind", "classify", "info"],
            parserKind: .type
        ),
        FormulaDefinition(
            functionName: "now",
            displayName: "=NOW",
            category: .date,
            signature: "=NOW()",
            description: "Current date and time as YYYY-MM-DD HH:mm",
            example: "=NOW()",
            exampleResult: "(current date and time)",
            keywords: ["now", "current", "time", "timestamp"],
            parserKind: .now
        ),
        FormulaDefinition(
            functionName: "year",
            displayName: "=YEAR",
            category: .date,
            signature: "=YEAR()",
            description: "Current 4-digit year",
            example: "=YEAR()",
            exampleResult: "(current year)",
            keywords: ["year", "annual", "date"],
            parserKind: .year
        ),
        FormulaDefinition(
            functionName: "weekday",
            displayName: "=WEEKDAY",
            category: .date,
            signature: "=WEEKDAY()",
            description: "Day of the week as a number (1=Sunday, 7=Saturday)",
            example: "=WEEKDAY()",
            exampleResult: "(weekday 1-7)",
            keywords: ["weekday", "day", "dow"],
            parserKind: .weekday
        ),
        FormulaDefinition(
            functionName: "hour",
            displayName: "=HOUR",
            category: .date,
            signature: "=HOUR()",
            description: "Current hour, 0-23",
            example: "=HOUR()",
            exampleResult: "(0-23)",
            keywords: ["hour", "clock", "time"],
            parserKind: .hour
        ),
        FormulaDefinition(
            functionName: "minute",
            displayName: "=MINUTE",
            category: .date,
            signature: "=MINUTE()",
            description: "Current minute, 0-59",
            example: "=MINUTE()",
            exampleResult: "(0-59)",
            keywords: ["minute", "clock", "time"],
            parserKind: .minute
        ),
        FormulaDefinition(
            functionName: "second",
            displayName: "=SECOND",
            category: .date,
            signature: "=SECOND()",
            description: "Current second, 0-59",
            example: "=SECOND()",
            exampleResult: "(0-59)",
            keywords: ["second", "clock", "time"],
            parserKind: .second
        ),
    ]

    static var discoverableFunctionNames: Set<String> {
        Set(all.filter(\.isDiscoverable).map { $0.functionName.lowercased() }.filter { !$0.isEmpty })
    }

    /// Names of formulas that may be written as a bare `=name` (no parens) in
    /// the document. Allowed for formulas whose every argument is optional.
    /// Used by `Document.discover` so users can type `=today` instead of
    /// `=today()`. See issue #18.
    static var bareNameAllowedNames: Set<String> {
        [
            "today", "time", "month", "day", "clip", "recording", "count",
            "now", "year", "weekday", "hour", "minute", "second",
        ]
    }

    static var publicDefinitions: [FormulaDefinition] {
        all.filter(\.isPublic)
    }

    static var publicNames: Set<String> {
        Set(publicDefinitions.map(\.displayName))
    }

    static func definition(forFunctionName name: String) -> FormulaDefinition? {
        let lower = name.lowercased()
        return all.first { $0.functionName == lower }
    }
}
