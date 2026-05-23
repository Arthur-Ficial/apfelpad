import Testing
@testable import apfelpad

@Suite("Info formulas: ISNUMBER, ISTEXT, ISBLANK, TYPE")
struct InfoFormulasTests {
    // MARK: - ISNUMBER

    @Test("ISNUMBER returns TRUE for an integer literal")
    func isnumberInteger() {
        #expect(IsNumberFormulaEvaluator.evaluate("42") == "TRUE")
    }

    @Test("ISNUMBER returns TRUE for a float literal")
    func isnumberFloat() {
        #expect(IsNumberFormulaEvaluator.evaluate("3.14") == "TRUE")
    }

    @Test("ISNUMBER returns TRUE for a negative number")
    func isnumberNegative() {
        #expect(IsNumberFormulaEvaluator.evaluate("-5") == "TRUE")
    }

    @Test("ISNUMBER returns FALSE for a word")
    func isnumberWord() {
        #expect(IsNumberFormulaEvaluator.evaluate("hello") == "FALSE")
    }

    @Test("ISNUMBER returns FALSE for an empty string")
    func isnumberEmpty() {
        #expect(IsNumberFormulaEvaluator.evaluate("") == "FALSE")
    }

    @Test("ISNUMBER returns FALSE for whitespace only")
    func isnumberWhitespace() {
        #expect(IsNumberFormulaEvaluator.evaluate("   ") == "FALSE")
    }

    // MARK: - ISTEXT

    @Test("ISTEXT returns TRUE for a word")
    func istextWord() {
        #expect(IsTextFormulaEvaluator.evaluate("hello") == "TRUE")
    }

    @Test("ISTEXT returns FALSE for an integer literal")
    func istextNumber() {
        #expect(IsTextFormulaEvaluator.evaluate("42") == "FALSE")
    }

    @Test("ISTEXT returns TRUE for an empty string")
    func istextEmpty() {
        #expect(IsTextFormulaEvaluator.evaluate("") == "TRUE")
    }

    // MARK: - ISBLANK

    @Test("ISBLANK returns TRUE for an empty string")
    func isblankEmpty() {
        #expect(IsBlankFormulaEvaluator.evaluate("") == "TRUE")
    }

    @Test("ISBLANK returns TRUE for whitespace only")
    func isblankWhitespace() {
        #expect(IsBlankFormulaEvaluator.evaluate("   ") == "TRUE")
    }

    @Test("ISBLANK returns FALSE for any content")
    func isblankContent() {
        #expect(IsBlankFormulaEvaluator.evaluate("hi") == "FALSE")
    }

    // MARK: - TYPE

    @Test("TYPE returns 'number' for a numeric string")
    func typeNumber() {
        #expect(TypeFormulaEvaluator.evaluate("42") == "number")
    }

    @Test("TYPE returns 'text' for a word")
    func typeText() {
        #expect(TypeFormulaEvaluator.evaluate("hello") == "text")
    }

    @Test("TYPE returns 'blank' for an empty string")
    func typeBlank() {
        #expect(TypeFormulaEvaluator.evaluate("") == "blank")
    }

    @Test("TYPE returns 'blank' for whitespace only")
    func typeWhitespace() {
        #expect(TypeFormulaEvaluator.evaluate("   ") == "blank")
    }

    // MARK: - Parser integration

    @Test("Parser parses =isnumber(42)")
    func parserIsnumber() throws {
        let result = try FormulaParser.parse("=isnumber(42)")
        #expect(result == .isnumber(value: "42"))
    }

    @Test("Parser parses =ISNUMBER(42) (case-insensitive)")
    func parserIsnumberCaseInsensitive() throws {
        let result = try FormulaParser.parse("=ISNUMBER(42)")
        #expect(result == .isnumber(value: "42"))
    }

    @Test("Parser parses =istext(hello)")
    func parserIstext() throws {
        let result = try FormulaParser.parse("=istext(hello)")
        #expect(result == .istext(value: "hello"))
    }

    @Test("Parser parses =isblank(\"\")")
    func parserIsblank() throws {
        let result = try FormulaParser.parse(#"=isblank("")"#)
        #expect(result == .isblank(value: ""))
    }

    @Test("Parser parses =type(42)")
    func parserType() throws {
        let result = try FormulaParser.parse("=type(42)")
        #expect(result == .type(value: "42"))
    }

    // MARK: - Sync evaluator integration

    @Test("Sync evaluator routes =isnumber to evaluator")
    func syncEvalIsnumber() throws {
        let result = try FormulaSyncEvaluator.evaluate(.isnumber(value: "42"))
        #expect(result == "TRUE")
    }

    @Test("Sync evaluator routes =istext to evaluator")
    func syncEvalIstext() throws {
        let result = try FormulaSyncEvaluator.evaluate(.istext(value: "hello"))
        #expect(result == "TRUE")
    }

    @Test("Sync evaluator routes =isblank to evaluator")
    func syncEvalIsblank() throws {
        let result = try FormulaSyncEvaluator.evaluate(.isblank(value: ""))
        #expect(result == "TRUE")
    }

    @Test("Sync evaluator routes =type to evaluator")
    func syncEvalType() throws {
        let result = try FormulaSyncEvaluator.evaluate(.type(value: "hello"))
        #expect(result == "text")
    }

    // MARK: - Registry

    @Test("Registry contains =isnumber")
    func registryIsnumber() {
        #expect(FormulaRegistry.definition(forFunctionName: "isnumber") != nil)
    }

    @Test("Registry contains =istext")
    func registryIstext() {
        #expect(FormulaRegistry.definition(forFunctionName: "istext") != nil)
    }

    @Test("Registry contains =isblank")
    func registryIsblank() {
        #expect(FormulaRegistry.definition(forFunctionName: "isblank") != nil)
    }

    @Test("Registry contains =type")
    func registryType() {
        #expect(FormulaRegistry.definition(forFunctionName: "type") != nil)
    }
}
