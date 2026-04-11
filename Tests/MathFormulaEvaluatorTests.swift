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

    @Test("invalid expression has a human-readable error description")
    func errorDescription() {
        do {
            _ = try MathFormulaEvaluator.evaluate("abc")
            Issue.record("expected throw")
        } catch let error as MathFormulaEvaluator.Error {
            let message = error.errorDescription ?? ""
            // Must NOT contain the Swift default pattern
            #expect(!message.contains("couldn"))
            #expect(!message.contains("apfelpad.MathFormulaEvaluator"))
            // Must contain something user-facing
            #expect(message.contains("math") || message.contains("expression"))
        } catch {
            Issue.record("wrong error type: \(error)")
        }
    }
}
