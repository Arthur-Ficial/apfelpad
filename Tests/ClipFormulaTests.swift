import Testing
@testable import apfelpad

@Suite("ClipFormula")
struct ClipFormulaTests {
    @Test("parser recognises =clip()")
    func parseClip() throws {
        let call = try FormulaParser.parse("=clip()")
        #expect(call == .clip)
    }

    @Test("parser rejects =clip with args")
    func parseClipWithArgs() throws {
        #expect(throws: FormulaParser.Error.self) {
            try FormulaParser.parse(#"=clip("arg")"#)
        }
    }

    @Test("render =clip()")
    func renderClip() {
        let rendered = FormulaParser.render(.clip)
        #expect(rendered == "=clip()")
    }

    @Test("canonicalise round-trips =clip()")
    func canonicaliseClip() throws {
        let canonical = try FormulaParser.canonicalise("=clip()")
        #expect(canonical == "=clip()")
    }

    @Test("evaluator returns clipboard content")
    func evaluateWithContent() {
        let clip = MockClipboard(value: "hello from clipboard")
        #expect(ClipFormulaEvaluator.evaluate(clipboard: clip) == "hello from clipboard")
    }

    @Test("evaluator returns empty string when clipboard is nil")
    func evaluateEmpty() {
        let clip = MockClipboard(value: nil)
        #expect(ClipFormulaEvaluator.evaluate(clipboard: clip) == "")
    }
}
