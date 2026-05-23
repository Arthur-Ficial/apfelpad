import Testing
import Foundation
@testable import apfelpad

@Suite("Phase 4 logical: AND, OR, NOT, IFERROR, SWITCH, IFS, TRUE, FALSE")
struct Phase4LogicalFormulasTests {
    // MARK: - AND
    @Test("AND with all truthy returns TRUE")
    func andAllTruthy() {
        #expect(AndFormulaEvaluator.evaluate(["yes", "1", "true"]) == "TRUE")
    }

    @Test("AND with one falsy returns FALSE")
    func andOneFalsy() {
        #expect(AndFormulaEvaluator.evaluate(["yes", "0", "true"]) == "FALSE")
    }

    @Test("AND with single truthy arg returns TRUE")
    func andSingleTruthy() {
        #expect(AndFormulaEvaluator.evaluate(["yes"]) == "TRUE")
    }

    @Test("AND with empty arg returns FALSE")
    func andEmptyArg() {
        #expect(AndFormulaEvaluator.evaluate([""]) == "FALSE")
    }

    // MARK: - OR
    @Test("OR with one truthy returns TRUE")
    func orOneTruthy() {
        #expect(OrFormulaEvaluator.evaluate(["no", "0", "yes"]) == "TRUE")
    }

    @Test("OR with all falsy returns FALSE")
    func orAllFalsy() {
        #expect(OrFormulaEvaluator.evaluate(["0", "false", ""]) == "FALSE")
    }

    // MARK: - NOT
    @Test("NOT of truthy returns FALSE")
    func notOfTruthy() {
        #expect(NotFormulaEvaluator.evaluate("hello") == "FALSE")
    }

    @Test("NOT of falsy returns TRUE")
    func notOfFalsy() {
        #expect(NotFormulaEvaluator.evaluate("0") == "TRUE")
        #expect(NotFormulaEvaluator.evaluate("false") == "TRUE")
        #expect(NotFormulaEvaluator.evaluate("FALSE") == "TRUE")
        #expect(NotFormulaEvaluator.evaluate("") == "TRUE")
    }

    // MARK: - TRUE / FALSE
    @Test("TRUE returns the literal string TRUE")
    func trueLiteral() {
        #expect(TrueFormulaEvaluator.evaluate() == "TRUE")
    }

    @Test("FALSE returns the literal string FALSE")
    func falseLiteral() {
        #expect(FalseFormulaEvaluator.evaluate() == "FALSE")
    }

    // MARK: - IFERROR
    @Test("IFERROR returns first arg when it is not a formula and not an error")
    func iferrorPlainPassThrough() throws {
        #expect(try IfErrorFormulaEvaluator.evaluate(value: "hello", fallback: "fb") == "hello")
    }

    @Test("IFERROR returns first arg's evaluated value when first arg is a successful formula")
    func iferrorSuccessfulFormula() throws {
        let result = try IfErrorFormulaEvaluator.evaluate(value: "=math(1+1)", fallback: "fb")
        #expect(result == "2")
    }

    @Test("IFERROR returns fallback when first arg is a failing formula")
    func iferrorFailingFormula() throws {
        // =sum throws on non-numeric input.
        let result = try IfErrorFormulaEvaluator.evaluate(value: "=sum(notanumber)", fallback: "n/a")
        #expect(result == "n/a")
    }

    @Test("IFERROR returns fallback when first arg is an unparseable formula")
    func iferrorUnparseable() throws {
        let result = try IfErrorFormulaEvaluator.evaluate(value: "=nosuch(1)", fallback: "fb")
        #expect(result == "fb")
    }

    // MARK: - SWITCH
    @Test("SWITCH returns the matching value")
    func switchMatches() throws {
        let result = try SwitchFormulaEvaluator.evaluate(args: ["b", "a", "first", "b", "second", "default"])
        #expect(result == "second")
    }

    @Test("SWITCH falls through to default when nothing matches")
    func switchDefault() throws {
        let result = try SwitchFormulaEvaluator.evaluate(args: ["x", "a", "first", "none found"])
        #expect(result == "none found")
    }

    @Test("SWITCH throws when no match and no default")
    func switchNoMatchNoDefault() {
        #expect(throws: (any Error).self) {
            _ = try SwitchFormulaEvaluator.evaluate(args: ["x", "a", "first"])
        }
    }

    // MARK: - IFS
    @Test("IFS returns first matching value")
    func ifsFirstMatch() throws {
        let result = try IfsFormulaEvaluator.evaluate(args: ["false", "no", "true", "yes"])
        #expect(result == "yes")
    }

    @Test("IFS finds the first truthy value when many are truthy")
    func ifsFirstOfMany() throws {
        let result = try IfsFormulaEvaluator.evaluate(args: ["0", "zero", "1", "one", "yes", "another"])
        #expect(result == "one")
    }

    @Test("IFS throws when no condition is truthy")
    func ifsNoMatch() {
        #expect(throws: (any Error).self) {
            _ = try IfsFormulaEvaluator.evaluate(args: ["false", "no", "0", "zero"])
        }
    }

    @Test("IFS throws on odd number of args")
    func ifsOddArgs() {
        #expect(throws: (any Error).self) {
            _ = try IfsFormulaEvaluator.evaluate(args: ["true", "yes", "true"])
        }
    }

    // MARK: - Parser integration
    @Test("Parser parses =AND(...)")
    func parserAnd() throws {
        let result = try FormulaParser.parse("=AND(yes, 1, true)")
        #expect(result == .and(args: ["yes", "1", "true"]))
    }

    @Test("Parser parses =OR(...)")
    func parserOr() throws {
        let result = try FormulaParser.parse("=or(no, yes)")
        #expect(result == .or(args: ["no", "yes"]))
    }

    @Test("Parser parses =NOT(value)")
    func parserNot() throws {
        let result = try FormulaParser.parse("=NOT(hello)")
        #expect(result == .not(value: "hello"))
    }

    @Test("Parser parses =TRUE() and =FALSE()")
    func parserTrueFalse() throws {
        #expect(try FormulaParser.parse("=TRUE()") == .trueLit)
        #expect(try FormulaParser.parse("=FALSE()") == .falseLit)
    }

    @Test("Parser parses =IFERROR(=sum(notanumber), \"fb\")")
    func parserIferror() throws {
        let result = try FormulaParser.parse(#"=IFERROR(=sum(notanumber), "fb")"#)
        #expect(result == .iferror(value: "=sum(notanumber)", fallback: "fb"))
    }

    @Test("Parser parses =SWITCH(a, b, c, d)")
    func parserSwitch() throws {
        let result = try FormulaParser.parse("=SWITCH(x, a, b, c)")
        #expect(result == .switchCall(args: ["x", "a", "b", "c"]))
    }

    @Test("Parser parses =IFS(c1, v1, c2, v2)")
    func parserIfs() throws {
        let result = try FormulaParser.parse("=IFS(true, yes, false, no)")
        #expect(result == .ifs(args: ["true", "yes", "false", "no"]))
    }

    // MARK: - Sync evaluator integration
    @Test("Sync evaluator routes =AND")
    func syncAnd() throws {
        let r = try FormulaSyncEvaluator.evaluate(.and(args: ["yes", "1"]))
        #expect(r == "TRUE")
    }

    @Test("Sync evaluator routes =OR")
    func syncOr() throws {
        let r = try FormulaSyncEvaluator.evaluate(.or(args: ["no", "yes"]))
        #expect(r == "TRUE")
    }

    @Test("Sync evaluator routes =NOT")
    func syncNot() throws {
        let r = try FormulaSyncEvaluator.evaluate(.not(value: "hello"))
        #expect(r == "FALSE")
    }

    @Test("Sync evaluator routes =TRUE")
    func syncTrue() throws {
        let r = try FormulaSyncEvaluator.evaluate(.trueLit)
        #expect(r == "TRUE")
    }

    @Test("Sync evaluator routes =FALSE")
    func syncFalse() throws {
        let r = try FormulaSyncEvaluator.evaluate(.falseLit)
        #expect(r == "FALSE")
    }

    @Test("Sync evaluator routes =IFERROR")
    func syncIferror() throws {
        let r = try FormulaSyncEvaluator.evaluate(.iferror(value: "=sum(notanumber)", fallback: "fb"))
        #expect(r == "fb")
    }

    @Test("Sync evaluator routes =SWITCH")
    func syncSwitch() throws {
        let r = try FormulaSyncEvaluator.evaluate(.switchCall(args: ["b", "a", "1", "b", "2"]))
        #expect(r == "2")
    }

    @Test("Sync evaluator routes =IFS")
    func syncIfs() throws {
        let r = try FormulaSyncEvaluator.evaluate(.ifs(args: ["false", "no", "true", "yes"]))
        #expect(r == "yes")
    }

    // MARK: - Registry
    @Test("Registry exposes all 8 new logical formulas")
    func registry() {
        for n in ["and", "or", "not", "iferror", "switch", "ifs", "true", "false"] {
            #expect(FormulaRegistry.definition(forFunctionName: n) != nil)
        }
    }
}
