import Testing
@testable import apfelpad

@Suite("FormulaParser")
struct FormulaParserTests {
    @Test("plain quoted string literal parses to apfel call")
    func plainQuotedString() throws {
        let result = try FormulaParser.parse(#"=apfel("hello")"#)
        #expect(result == .apfel(prompt: "hello", seed: nil))
    }

    @Test("auto-quotes a bare word")
    func bareWord() throws {
        let result = try FormulaParser.parse("=apfel(hello)")
        #expect(result == .apfel(prompt: "hello", seed: nil))
    }

    @Test("auto-quotes a bare phrase with spaces")
    func barePhrase() throws {
        let result = try FormulaParser.parse("=apfel(hello world)")
        #expect(result == .apfel(prompt: "hello world", seed: nil))
    }

    @Test("seed as second argument")
    func seedArg() throws {
        let result = try FormulaParser.parse(#"=apfel("hello", 42)"#)
        #expect(result == .apfel(prompt: "hello", seed: 42))
    }

    @Test("canonicalises on commit")
    func canonicalise() throws {
        let canonical = try FormulaParser.canonicalise("=apfel(hi)")
        #expect(canonical == #"=apfel("hi")"#)
    }

    @Test("canonicalises with seed")
    func canonicaliseWithSeed() throws {
        let canonical = try FormulaParser.canonicalise("=apfel(hi, 42)")
        #expect(canonical == #"=apfel("hi", 42)"#)
    }

    @Test("parses =math(42+2*3)")
    func mathCall() throws {
        let result = try FormulaParser.parse("=math(42+2*3)")
        #expect(result == .math(expression: "42+2*3"))
    }

    @Test("handles curly double quotes (U+201C U+201D)")
    func curlyDoubleQuotes() throws {
        // Opening: U+201C  Closing: U+201D
        let result = try FormulaParser.parse("=apfel(\u{201C}hello world\u{201D})")
        #expect(result == .apfel(prompt: "hello world", seed: nil))
    }

    @Test("handles mixed curly and straight quotes")
    func mixedQuotes() throws {
        let result = try FormulaParser.parse("=apfel(\u{201C}greet the user\u{201D}, 42)")
        #expect(result == .apfel(prompt: "greet the user", seed: 42))
    }

    @Test("handles curly quotes with em-dash and commas inside")
    func curlyWithDashAndInnerCommas() throws {
        let input = "=apfel(\u{201C}one sentence — why formulas beat chat, plus a haiku\u{201D}, 7)"
        let result = try FormulaParser.parse(input)
        #expect(result == .apfel(prompt: "one sentence — why formulas beat chat, plus a haiku", seed: 7))
    }

    @Test("handles curly single quotes (U+2018 U+2019)")
    func curlySingleQuotes() throws {
        let result = try FormulaParser.parse("=apfel(\u{2018}hi\u{2019})")
        #expect(result == .apfel(prompt: "hi", seed: nil))
    }

    @Test("canonicalises curly quotes back to straight")
    func canonicaliseCurly() throws {
        let canonical = try FormulaParser.canonicalise("=apfel(\u{201C}hi\u{201D})")
        #expect(canonical == #"=apfel("hi")"#)
    }

    @Test("=() is shortcut for =apfel(\"\")")
    func anonEmpty() throws {
        let result = try FormulaParser.parse("=()")
        #expect(result == .apfel(prompt: "", seed: nil))
    }

    @Test("=(hello world) is shortcut for =apfel(\"hello world\")")
    func anonPhrase() throws {
        let result = try FormulaParser.parse("=(hello world)")
        #expect(result == .apfel(prompt: "hello world", seed: nil))
    }

    @Test("=(\"love letter\", 42) is shortcut for =apfel with seed")
    func anonWithSeed() throws {
        let result = try FormulaParser.parse(#"=("love letter", 42)"#)
        #expect(result == .apfel(prompt: "love letter", seed: 42))
    }

    @Test("canonicalises =(hi) to =apfel(\"hi\")")
    func anonCanonicalise() throws {
        let canonical = try FormulaParser.canonicalise("=(hi)")
        #expect(canonical == #"=apfel("hi")"#)
    }

    @Test("canonicalises =() to =apfel(\"\")")
    func anonEmptyCanonicalise() throws {
        let canonical = try FormulaParser.canonicalise("=()")
        #expect(canonical == #"=apfel("")"#)
    }

    // ── Regression tests for the exact formulas the user typed ──────────────
    // These all use macOS's auto-substituted curly quotes (U+201C LEFT DOUBLE
    // QUOTE on BOTH sides, as macOS actually produces for German layouts).

    @Test("user regression: curly-quoted haiku with seed")
    func userHaikuWithSeed() throws {
        let left = "\u{201C}"
        let input = "=apfel(\(left)one sentence — why formulas beat chat for writing and a haiku\(left), 7)"
        let result = try FormulaParser.parse(input)
        #expect(result == .apfel(
            prompt: "one sentence — why formulas beat chat for writing and a haiku",
            seed: 7
        ))
    }

    @Test("user regression: curly-quoted say hello")
    func userSayHello() throws {
        let left = "\u{201C}"
        let right = "\u{201D}"
        let input = "=apfel(\(left)say hello\(right))"
        let result = try FormulaParser.parse(input)
        #expect(result == .apfel(prompt: "say hello", seed: nil))
    }

    @Test("user regression: curly-quoted haiku without seed")
    func userHaikuNoSeed() throws {
        let left = "\u{201C}"
        let input = "=apfel(\(left)one sentence — why formulas beat chat for writing and a haiku\(left))"
        let result = try FormulaParser.parse(input)
        #expect(result == .apfel(
            prompt: "one sentence — why formulas beat chat for writing and a haiku",
            seed: nil
        ))
    }

    // ── Spreadsheet-style text and numeric formulas ─────────────────────────

    @Test("parses =upper(\"hello\")")
    func parseUpper() throws {
        #expect(try FormulaParser.parse(#"=upper("hello")"#) == .upper(text: "hello"))
    }

    @Test("parses =lower(\"HELLO\")")
    func parseLower() throws {
        #expect(try FormulaParser.parse(#"=lower("HELLO")"#) == .lower(text: "HELLO"))
    }

    @Test("parses =trim(\"  hi  \")")
    func parseTrim() throws {
        #expect(try FormulaParser.parse(#"=trim("  hi  ")"#) == .trim(text: "  hi  "))
    }

    @Test("parses =len(\"abc\")")
    func parseLen() throws {
        #expect(try FormulaParser.parse(#"=len("abc")"#) == .len(text: "abc"))
    }

    @Test("parses =concat(\"a\", \"b\", \"c\")")
    func parseConcat() throws {
        #expect(
            try FormulaParser.parse(#"=concat("a", "b", "c")"#)
            == .concat(parts: ["a", "b", "c"])
        )
    }

    @Test("parses =replace(\"hi world\", \"world\", \"apfelpad\")")
    func parseReplace() throws {
        #expect(
            try FormulaParser.parse(#"=replace("hi world", "world", "apfelpad")"#)
            == .replace(text: "hi world", find: "world", replacement: "apfelpad")
        )
    }

    @Test("parses =split(\"a,b,c\", \",\", 1)")
    func parseSplit() throws {
        #expect(
            try FormulaParser.parse(#"=split("a,b,c", ",", 1)"#)
            == .splitCall(text: "a,b,c", delim: ",", index: 1)
        )
    }

    @Test("parses =if(\"yes\", \"then\", \"else\")")
    func parseIf() throws {
        #expect(
            try FormulaParser.parse(#"=if("yes", "then", "else")"#)
            == .ifCall(cond: "yes", thenValue: "then", elseValue: "else")
        )
    }

    @Test("parses =sum(1, 2, 3)")
    func parseSum() throws {
        #expect(try FormulaParser.parse("=sum(1, 2, 3)") == .sum(args: ["1", "2", "3"]))
    }

    @Test("parses =avg(10, 20, 30)")
    func parseAvg() throws {
        #expect(try FormulaParser.parse("=avg(10, 20, 30)") == .avg(args: ["10", "20", "30"]))
    }
}
