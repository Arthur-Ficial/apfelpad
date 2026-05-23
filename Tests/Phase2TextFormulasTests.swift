import Testing
import Foundation
@testable import apfelpad

@Suite("Phase 2 text: LEFT, RIGHT, MID, FIND, SEARCH, REPT, PROPER, CLEAN, EXACT, CHAR, CODE, TEXTJOIN, VALUE, TEXT")
struct Phase2TextFormulasTests {
    // MARK: - LEFT
    @Test func leftBasic() throws {
        #expect(try LeftFormulaEvaluator.evaluate(text: "apfelpad", n: 5) == "apfel")
    }
    @Test func leftClampsToLength() throws {
        #expect(try LeftFormulaEvaluator.evaluate(text: "hi", n: 10) == "hi")
    }
    @Test func leftZero() throws {
        #expect(try LeftFormulaEvaluator.evaluate(text: "abc", n: 0) == "")
    }
    @Test func leftNegativeThrows() {
        #expect(throws: (any Error).self) {
            _ = try LeftFormulaEvaluator.evaluate(text: "abc", n: -1)
        }
    }

    // MARK: - RIGHT
    @Test func rightBasic() throws {
        #expect(try RightFormulaEvaluator.evaluate(text: "apfelpad", n: 3) == "pad")
    }
    @Test func rightClampsToLength() throws {
        #expect(try RightFormulaEvaluator.evaluate(text: "hi", n: 10) == "hi")
    }

    // MARK: - MID
    @Test func midBasic() throws {
        // 1-indexed: =MID("apfelpad", 6, 3) → "pad"
        #expect(try MidFormulaEvaluator.evaluate(text: "apfelpad", start: 6, length: 3) == "pad")
    }
    @Test func midFromBeginning() throws {
        #expect(try MidFormulaEvaluator.evaluate(text: "hello", start: 1, length: 3) == "hel")
    }
    @Test func midPastEndClamps() throws {
        #expect(try MidFormulaEvaluator.evaluate(text: "abc", start: 2, length: 10) == "bc")
    }
    @Test func midStartZeroThrows() {
        #expect(throws: (any Error).self) {
            _ = try MidFormulaEvaluator.evaluate(text: "abc", start: 0, length: 1)
        }
    }

    // MARK: - FIND
    @Test func findFound() throws {
        #expect(try FindFormulaEvaluator.evaluate(needle: "pad", haystack: "apfelpad", start: 1) == "6")
    }
    @Test func findCaseSensitive() {
        #expect(throws: (any Error).self) {
            _ = try FindFormulaEvaluator.evaluate(needle: "PAD", haystack: "apfelpad", start: 1)
        }
    }
    @Test func findFromOffset() throws {
        // "l" appears at 4 and 10; with start=5 the result is 10.
        #expect(try FindFormulaEvaluator.evaluate(needle: "l", haystack: "hello world", start: 5) == "10")
    }

    // MARK: - SEARCH
    @Test func searchCaseInsensitive() throws {
        #expect(try SearchFormulaEvaluator.evaluate(needle: "PAD", haystack: "apfelpad", start: 1) == "6")
    }

    // MARK: - REPT
    @Test func reptBasic() {
        #expect(ReptFormulaEvaluator.evaluate(text: "ab", n: 3) == "ababab")
    }
    @Test func reptZero() {
        #expect(ReptFormulaEvaluator.evaluate(text: "x", n: 0) == "")
    }
    @Test func reptNegativeIsEmpty() {
        #expect(ReptFormulaEvaluator.evaluate(text: "x", n: -1) == "")
    }

    // MARK: - PROPER
    @Test func properBasic() {
        #expect(ProperFormulaEvaluator.evaluate("hello world") == "Hello World")
    }
    @Test func properMixedCase() {
        #expect(ProperFormulaEvaluator.evaluate("jOHN DOE") == "John Doe")
    }
    @Test func properMultipleSpaces() {
        #expect(ProperFormulaEvaluator.evaluate("  hi   there  ") == "  Hi   There  ")
    }

    // MARK: - CLEAN
    @Test func cleanStripsControl() {
        let input = "hello\u{0000}world\u{0007}!"
        #expect(CleanFormulaEvaluator.evaluate(input) == "helloworld!")
    }
    @Test func cleanKeepsTabAndNewline() {
        // Google Sheets keeps tab (9) and newline (10) — both >= 32? no, both
        // are 9 and 10, *under* 32. CLEAN strips them per the issue: ASCII 0-31.
        #expect(CleanFormulaEvaluator.evaluate("a\tb\nc") == "abc")
    }

    // MARK: - EXACT
    @Test func exactSame() {
        #expect(ExactFormulaEvaluator.evaluate(a: "hello", b: "hello") == "TRUE")
    }
    @Test func exactDifferentCase() {
        #expect(ExactFormulaEvaluator.evaluate(a: "Hello", b: "hello") == "FALSE")
    }

    // MARK: - CHAR
    @Test func charLetter() throws {
        #expect(try CharFormulaEvaluator.evaluate(65) == "A")
    }
    @Test func charEmoji() throws {
        #expect(try CharFormulaEvaluator.evaluate(128522) == "😊")
    }
    @Test func charInvalidThrows() {
        #expect(throws: (any Error).self) {
            _ = try CharFormulaEvaluator.evaluate(0x110000)  // out of Unicode range
        }
    }

    // MARK: - CODE
    @Test func codeLetter() throws {
        #expect(try CodeFormulaEvaluator.evaluate("A") == "65")
    }
    @Test func codeEmoji() throws {
        #expect(try CodeFormulaEvaluator.evaluate("😊") == "128522")
    }
    @Test func codeEmptyThrows() {
        #expect(throws: (any Error).self) {
            _ = try CodeFormulaEvaluator.evaluate("")
        }
    }

    // MARK: - TEXTJOIN
    @Test func textjoinSkipEmpty() {
        let result = TextJoinFormulaEvaluator.evaluate(
            delim: ", ",
            ignoreEmpty: true,
            parts: ["a", "", "b", "c"]
        )
        #expect(result == "a, b, c")
    }
    @Test func textjoinKeepEmpty() {
        let result = TextJoinFormulaEvaluator.evaluate(
            delim: ", ",
            ignoreEmpty: false,
            parts: ["a", "", "b"]
        )
        #expect(result == "a, , b")
    }

    // MARK: - VALUE
    @Test func valueInteger() throws {
        #expect(try ValueFormulaEvaluator.evaluate("123") == "123")
    }
    @Test func valueFloat() throws {
        #expect(try ValueFormulaEvaluator.evaluate("123.45") == "123.45")
    }
    @Test func valueNonNumericThrows() {
        #expect(throws: (any Error).self) {
            _ = try ValueFormulaEvaluator.evaluate("hello")
        }
    }

    // MARK: - TEXT
    @Test func textNoFormatPassesThrough() throws {
        #expect(try TextFormulaEvaluator.evaluate(value: "hello", format: "") == "hello")
    }
    @Test func textIntegerFormat() throws {
        #expect(try TextFormulaEvaluator.evaluate(value: "3.7", format: "0") == "4")
    }
    @Test func textTwoDecimalFormat() throws {
        #expect(try TextFormulaEvaluator.evaluate(value: "3.1", format: "0.00") == "3.10")
    }
    @Test func textPercentage() throws {
        #expect(try TextFormulaEvaluator.evaluate(value: "0.25", format: "0%") == "25%")
    }

    // MARK: - Parser integration
    @Test func parserLeft() throws {
        #expect(try FormulaParser.parse(#"=LEFT("hi", 1)"#) == .left(text: "hi", n: 1))
    }
    @Test func parserRight() throws {
        #expect(try FormulaParser.parse(#"=RIGHT("hi", 1)"#) == .right(text: "hi", n: 1))
    }
    @Test func parserMidOptionalStart() throws {
        #expect(try FormulaParser.parse(#"=MID("abc", 2, 1)"#) == .mid(text: "abc", start: 2, length: 1))
    }
    @Test func parserFindWithoutStart() throws {
        #expect(try FormulaParser.parse(#"=FIND("a", "abc")"#) == .find(needle: "a", haystack: "abc", start: 1))
    }
    @Test func parserFindWithStart() throws {
        #expect(try FormulaParser.parse(#"=FIND("a", "abc", 2)"#) == .find(needle: "a", haystack: "abc", start: 2))
    }
    @Test func parserSearch() throws {
        #expect(try FormulaParser.parse(#"=SEARCH("a", "ABC")"#) == .search(needle: "a", haystack: "ABC", start: 1))
    }
    @Test func parserRept() throws {
        #expect(try FormulaParser.parse(#"=REPT("ab", 3)"#) == .rept(text: "ab", n: 3))
    }
    @Test func parserProperCleanExact() throws {
        #expect(try FormulaParser.parse(#"=PROPER("hi")"#) == .proper(text: "hi"))
        #expect(try FormulaParser.parse(#"=CLEAN("hi")"#) == .clean(text: "hi"))
        #expect(try FormulaParser.parse(#"=EXACT("a", "b")"#) == .exact(a: "a", b: "b"))
    }
    @Test func parserCharCode() throws {
        #expect(try FormulaParser.parse("=CHAR(65)") == .char(code: 65))
        #expect(try FormulaParser.parse(#"=CODE("A")"#) == .code(text: "A"))
    }
    @Test func parserTextJoin() throws {
        let parsed = try FormulaParser.parse(#"=TEXTJOIN(", ", true, "a", "", "b")"#)
        #expect(parsed == .textjoin(delim: ", ", ignoreEmpty: true, parts: ["a", "", "b"]))
    }
    @Test func parserValueText() throws {
        #expect(try FormulaParser.parse(#"=VALUE("3.14")"#) == .value(text: "3.14"))
        #expect(try FormulaParser.parse(#"=TEXT("3.14", "0")"#) == .textFmt(value: "3.14", format: "0"))
        #expect(try FormulaParser.parse(#"=TEXT("3.14")"#) == .textFmt(value: "3.14", format: ""))
    }

    // MARK: - Sync evaluator integration
    @Test func syncDispatch() throws {
        #expect(try FormulaSyncEvaluator.evaluate(.left(text: "apfelpad", n: 5)) == "apfel")
        #expect(try FormulaSyncEvaluator.evaluate(.right(text: "apfelpad", n: 3)) == "pad")
        #expect(try FormulaSyncEvaluator.evaluate(.mid(text: "apfelpad", start: 6, length: 3)) == "pad")
        #expect(try FormulaSyncEvaluator.evaluate(.find(needle: "pad", haystack: "apfelpad", start: 1)) == "6")
        #expect(try FormulaSyncEvaluator.evaluate(.search(needle: "PAD", haystack: "apfelpad", start: 1)) == "6")
        #expect(try FormulaSyncEvaluator.evaluate(.rept(text: "ab", n: 3)) == "ababab")
        #expect(try FormulaSyncEvaluator.evaluate(.proper(text: "hello world")) == "Hello World")
        #expect(try FormulaSyncEvaluator.evaluate(.clean(text: "a\u{00}b")) == "ab")
        #expect(try FormulaSyncEvaluator.evaluate(.exact(a: "hi", b: "hi")) == "TRUE")
        #expect(try FormulaSyncEvaluator.evaluate(.char(code: 65)) == "A")
        #expect(try FormulaSyncEvaluator.evaluate(.code(text: "A")) == "65")
        #expect(try FormulaSyncEvaluator.evaluate(.textjoin(delim: "-", ignoreEmpty: false, parts: ["a", "b"])) == "a-b")
        #expect(try FormulaSyncEvaluator.evaluate(.value(text: "42")) == "42")
        #expect(try FormulaSyncEvaluator.evaluate(.textFmt(value: "3.7", format: "0")) == "4")
    }

    // MARK: - Registry
    @Test func registry() {
        for n in ["left", "right", "mid", "find", "search", "rept", "proper",
                  "clean", "exact", "char", "code", "textjoin", "value", "text"] {
            #expect(FormulaRegistry.definition(forFunctionName: n) != nil)
        }
    }
}
