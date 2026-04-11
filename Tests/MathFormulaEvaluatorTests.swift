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
            #expect(!message.contains("couldn"))
            #expect(!message.contains("apfelpad.MathFormulaEvaluator"))
            #expect(message.contains("math") || message.contains("expression"))
        } catch {
            Issue.record("wrong error type: \(error)")
        }
    }

    // ── US number annotation ────────────────────────────────────────────────

    @Test("US thousand separators: 1,000 + 2,500")
    func usThousands() throws {
        #expect(try MathFormulaEvaluator.evaluate("1,000 + 2,500") == "3500")
    }

    @Test("US decimal with commas: 1,234.5 * 2")
    func usDecimalWithCommas() throws {
        #expect(try MathFormulaEvaluator.evaluate("1,234.5 * 2") == "2469")
    }

    @Test("US currency: $1,000 + $500")
    func usCurrency() throws {
        #expect(try MathFormulaEvaluator.evaluate("$1,000 + $500") == "1500")
    }

    @Test("mixed: $1,000,000 / 12")
    func million() throws {
        // Non-integer result — should format as decimal
        let result = try MathFormulaEvaluator.evaluate("$1,000,000 / 12")
        #expect(result.hasPrefix("83333."))
    }

    @Test("suffixes: 10k + 5k")
    func kSuffix() throws {
        #expect(try MathFormulaEvaluator.evaluate("10k + 5k") == "15000")
    }

    @Test("suffixes: 2m / 4")
    func mSuffix() throws {
        #expect(try MathFormulaEvaluator.evaluate("2m / 4") == "500000")
    }
}
