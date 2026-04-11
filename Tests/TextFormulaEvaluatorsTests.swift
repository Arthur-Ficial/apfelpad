import Testing
@testable import apfelpad

@Suite("Text / numeric formula evaluators")
struct TextFormulaEvaluatorsTests {
    // MARK: - upper / lower / trim / len

    @Test("upper uppercases ASCII and unicode")
    func upper() throws {
        #expect(try UpperFormulaEvaluator.evaluate("hello") == "HELLO")
        #expect(try UpperFormulaEvaluator.evaluate("grüße") == "GRÜSSE")
    }

    @Test("lower lowercases ASCII and unicode")
    func lower() throws {
        #expect(try LowerFormulaEvaluator.evaluate("HELLO") == "hello")
        #expect(try LowerFormulaEvaluator.evaluate("GRÜSSE") == "grüsse")
    }

    @Test("trim strips leading/trailing whitespace")
    func trim() throws {
        #expect(try TrimFormulaEvaluator.evaluate("  hello  ") == "hello")
        #expect(try TrimFormulaEvaluator.evaluate("\n\tabc\n") == "abc")
    }

    @Test("len counts grapheme clusters")
    func len() throws {
        #expect(try LenFormulaEvaluator.evaluate("hello") == "5")
        #expect(try LenFormulaEvaluator.evaluate("🎉") == "1")
        #expect(try LenFormulaEvaluator.evaluate("") == "0")
    }

    // MARK: - concat / replace / split

    @Test("concat joins any number of string args")
    func concat() throws {
        #expect(try ConcatFormulaEvaluator.evaluate(["a", "b", "c"]) == "abc")
        #expect(try ConcatFormulaEvaluator.evaluate(["Hello, ", "world"]) == "Hello, world")
        #expect(try ConcatFormulaEvaluator.evaluate([]) == "")
    }

    @Test("replace substitutes the first occurrence")
    func replace() throws {
        #expect(
            try ReplaceFormulaEvaluator.evaluate(
                text: "hello world", find: "world", replacement: "apfelpad"
            ) == "hello apfelpad"
        )
        // No match: returns original
        #expect(
            try ReplaceFormulaEvaluator.evaluate(
                text: "abc", find: "xyz", replacement: "!"
            ) == "abc"
        )
    }

    @Test("split returns the nth piece")
    func split() throws {
        #expect(try SplitFormulaEvaluator.evaluate(text: "a,b,c", delim: ",", index: 0) == "a")
        #expect(try SplitFormulaEvaluator.evaluate(text: "a,b,c", delim: ",", index: 1) == "b")
        #expect(try SplitFormulaEvaluator.evaluate(text: "a,b,c", delim: ",", index: 2) == "c")
    }

    @Test("split with out-of-range index returns empty")
    func splitOOB() throws {
        #expect(try SplitFormulaEvaluator.evaluate(text: "a,b,c", delim: ",", index: 9) == "")
    }

    // MARK: - if

    @Test("if returns then-branch when condition is non-empty")
    func ifTrue() throws {
        #expect(try IfFormulaEvaluator.evaluate(cond: "yes", thenValue: "a", elseValue: "b") == "a")
        #expect(try IfFormulaEvaluator.evaluate(cond: "1", thenValue: "a", elseValue: "b") == "a")
    }

    @Test("if returns else-branch when condition is empty or 0")
    func ifFalse() throws {
        #expect(try IfFormulaEvaluator.evaluate(cond: "", thenValue: "a", elseValue: "b") == "b")
        #expect(try IfFormulaEvaluator.evaluate(cond: "0", thenValue: "a", elseValue: "b") == "b")
        #expect(try IfFormulaEvaluator.evaluate(cond: "false", thenValue: "a", elseValue: "b") == "b")
        #expect(try IfFormulaEvaluator.evaluate(cond: "no", thenValue: "a", elseValue: "b") == "b")
    }

    // MARK: - sum / avg

    @Test("sum adds variadic numeric args")
    func sum() throws {
        #expect(try SumFormulaEvaluator.evaluate(["1", "2", "3"]) == "6")
        #expect(try SumFormulaEvaluator.evaluate(["10", "-5"]) == "5")
        #expect(try SumFormulaEvaluator.evaluate([]) == "0")
    }

    @Test("sum accepts decimals and returns formatted result")
    func sumDecimals() throws {
        #expect(try SumFormulaEvaluator.evaluate(["1.5", "2.5"]) == "4")
        #expect(try SumFormulaEvaluator.evaluate(["0.1", "0.2"]) == "0.30000000000000004")
    }

    @Test("sum throws on non-numeric input")
    func sumInvalid() {
        #expect(throws: Error.self) {
            try SumFormulaEvaluator.evaluate(["1", "two"])
        }
    }

    @Test("avg computes arithmetic mean")
    func avg() throws {
        #expect(try AvgFormulaEvaluator.evaluate(["2", "4", "6"]) == "4")
        #expect(try AvgFormulaEvaluator.evaluate(["1", "2"]) == "1.5")
    }

    @Test("avg of empty list returns 0")
    func avgEmpty() throws {
        #expect(try AvgFormulaEvaluator.evaluate([]) == "0")
    }
}
