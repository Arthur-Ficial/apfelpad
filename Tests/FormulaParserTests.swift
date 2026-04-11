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
}
