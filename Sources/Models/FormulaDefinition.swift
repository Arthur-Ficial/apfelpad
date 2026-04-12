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
        case concat
        case replace
        case split
        case ifCall
        case sum
        case avg
        case ref
        case date
        case cw
        case month
        case day
        case time
        case input
        case show
        case count
        case clip
        case file
        case recording
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
            functionName: "concat",
            displayName: "=concat",
            category: .text,
            signature: "=concat(a, b, c, …)",
            description: "Join any number of strings",
            example: #"=concat("Hello, ", "world", "!")"#,
            exampleResult: "Hello, world!",
            keywords: ["join", "string", "combine", "append"],
            parserKind: .concat
        ),
        FormulaDefinition(
            functionName: "replace",
            displayName: "=replace",
            category: .text,
            signature: "=replace(text, find, replacement)",
            description: "Substitute the first occurrence",
            example: #"=replace("hello world", "world", "apfelpad")"#,
            exampleResult: "hello apfelpad",
            keywords: ["substitute", "swap", "find", "rewrite"],
            parserKind: .replace
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
            functionName: "avg",
            displayName: "=avg",
            category: .aggregate,
            signature: "=avg(n1, n2, …)",
            description: "Arithmetic mean",
            example: "=avg(2, 4, 6)",
            exampleResult: "4",
            keywords: ["average", "mean", "numbers"],
            parserKind: .avg
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
            parserKind: .ifCall
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
            functionName: "cw",
            displayName: "=cw",
            category: .date,
            signature: "=cw(offset?)",
            description: "ISO calendar week with optional offset",
            example: "=cw(-1)",
            exampleResult: "(last week's number)",
            keywords: ["week", "calendar", "iso", "kw"],
            parserKind: .cw
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
    ]

    static var discoverableFunctionNames: Set<String> {
        Set(all.filter(\.isDiscoverable).map { $0.functionName.lowercased() }.filter { !$0.isEmpty })
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
