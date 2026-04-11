import Testing
@testable import apfelpad

@Suite("MathFormulaEvaluator")
struct MathFormulaEvaluatorTests {
    @Test("evaluates 42+2*3")
    func evalAddMul() throws {
        #expect(try MathFormulaEvaluator.evaluate("42+2*3") == "48")
    }

    @Test("respects parens")
    func parens() throws {
        #expect(try MathFormulaEvaluator.evaluate("(1+2)*3") == "9")
    }

    @Test("returns integer when result is whole")
    func wholeAsInt() throws {
        #expect(try MathFormulaEvaluator.evaluate("10/2") == "5")
    }

    @Test("returns decimal when not whole")
    func decimal() throws {
        #expect(try MathFormulaEvaluator.evaluate("1/4") == "0.25")
    }

    @Test("unary minus")
    func unary() throws {
        #expect(try MathFormulaEvaluator.evaluate("-5+3") == "-2")
    }

    @Test("invalid expression throws")
    func invalid() {
        #expect(throws: MathFormulaEvaluator.Error.self) {
            try MathFormulaEvaluator.evaluate("abc")
        }
    }
}
