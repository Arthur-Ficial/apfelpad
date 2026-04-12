import Testing
@testable import apfelpad

@Suite("CountFormula")
struct CountFormulaTests {
    @Test("parser recognises =count() with no args")
    func parseCountNoArgs() throws {
        let call = try FormulaParser.parse("=count()")
        #expect(call == .count(anchor: nil))
    }

    @Test("parser recognises =count(@#section)")
    func parseCountWithAnchor() throws {
        let call = try FormulaParser.parse("=count(@#intro)")
        #expect(call == .count(anchor: "intro"))
    }

    @Test("parser accepts legacy =count(@section) syntax")
    func parseCountLegacyAt() throws {
        let call = try FormulaParser.parse("=count(@intro)")
        #expect(call == .count(anchor: "intro"))
    }

    @Test("render =count() with no anchor")
    func renderCountNoAnchor() {
        let rendered = FormulaParser.render(.count(anchor: nil))
        #expect(rendered == "=count()")
    }

    @Test("render =count(@#intro)")
    func renderCountWithAnchor() {
        let rendered = FormulaParser.render(.count(anchor: "intro"))
        #expect(rendered == "=count(@#intro)")
    }

    @Test("evaluator counts words in whole document")
    func evaluateWholeDoc() {
        let markdown = "hello world foo bar"
        let result = CountFormulaEvaluator.evaluate(anchor: nil, in: markdown)
        #expect(result == "4")
    }

    @Test("evaluator counts words in a named section")
    func evaluateSection() {
        let markdown = """
        # Intro

        hello world

        # Body

        one two three four five
        """
        let result = CountFormulaEvaluator.evaluate(anchor: "intro", in: markdown)
        #expect(result == "2")
    }

    @Test("evaluator returns 0 for unknown section")
    func evaluateUnknownSection() {
        let markdown = "# Intro\n\nhello"
        let result = CountFormulaEvaluator.evaluate(anchor: "nope", in: markdown)
        #expect(result == "0")
    }

    @Test("document-level integration: =count() in a document")
    @MainActor
    func integrationCount() async throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: "one two three =count()")
        await vm.evaluateAll()
        let span = vm.document.spans.first { $0.source == "=count()" }
        #expect(span != nil)
        if let s = span, case .ready(let text) = s.value {
            #expect(Int(text)! > 0)
        }
    }
}
