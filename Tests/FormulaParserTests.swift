import Testing
@testable import apfelpad

@Suite("FormulaParser")
struct FormulaParserTests {
    @Test("plain quoted string literal parses to apfel call")
    func plainQuotedString() throws {
        let result = try FormulaParser.parse(#"=apfel("hello")"#)
        #expect(result == .apfel(prompt: "hello", seed: nil))
    }
}
