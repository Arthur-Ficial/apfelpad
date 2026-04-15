import Testing
@testable import apfelpad

@Suite("FormulaPreprocessor", .serialized)
struct FormulaPreprocessorTests {
    @Test("normalizes curly double quotes to ASCII double quotes")
    func curlyDouble() {
        let input = "\u{201C}hello\u{201D}"
        #expect(FormulaPreprocessor.normalize(input) == "\"hello\"")
    }

    @Test("normalizes curly single quotes to ASCII single quotes")
    func curlySingle() {
        let input = "\u{2018}hi\u{2019}"
        #expect(FormulaPreprocessor.normalize(input) == "'hi'")
    }

    @Test("leaves straight quotes alone")
    func straightIdempotent() {
        #expect(FormulaPreprocessor.normalize("\"abc\"") == "\"abc\"")
    }

    @Test("expands =(…) to =apfel(…)")
    func expandAnon() {
        #expect(FormulaPreprocessor.normalize("=(hi)") == "=apfel(hi)")
    }

    @Test("expands =() to =apfel()")
    func expandAnonEmpty() {
        #expect(FormulaPreprocessor.normalize("=()") == "=apfel()")
    }

    @Test("does not expand =math(…) or other named functions")
    func leavesNamedAlone() {
        #expect(FormulaPreprocessor.normalize("=math(1+1)") == "=math(1+1)")
        #expect(FormulaPreprocessor.normalize("=apfel(hi)") == "=apfel(hi)")
    }

    @Test("normalization + expansion together")
    func combined() {
        let input = "=(\u{201C}write a haiku\u{201D}, 7)"
        #expect(FormulaPreprocessor.normalize(input) == #"=apfel("write a haiku", 7)"#)
    }
}
