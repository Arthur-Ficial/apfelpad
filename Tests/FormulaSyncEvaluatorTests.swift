import Testing
@testable import apfelpad

@Suite("FormulaSyncEvaluator", .serialized)
struct FormulaSyncEvaluatorTests {
    @Test("resolves =ref when document markdown is available")
    func resolvesRefWithMarkdown() throws {
        let markdown = """
        # Intro

        hello world

        # Body

        other
        """

        let result = try FormulaSyncEvaluator.evaluate(
            .ref(anchor: "intro"),
            documentMarkdown: markdown
        )

        #expect(result == "hello world")
    }

    @Test("counts words in the whole document when markdown is available")
    func countsDocumentWords() throws {
        let result = try FormulaSyncEvaluator.evaluate(
            .count(anchor: nil),
            documentMarkdown: "hello brave new world"
        )

        #expect(result == "4")
    }

    @Test("uses the injected clipboard for =clip()")
    func clipUsesInjectedClipboard() throws {
        let result = try FormulaSyncEvaluator.evaluate(
            .clip,
            clipboard: MockClipboard(value: "from test clipboard")
        )

        #expect(result == "from test clipboard")
    }

    @Test("throws when a document-only formula has no markdown context")
    func documentFormulaNeedsMarkdown() {
        #expect(throws: RuntimeError.self) {
            _ = try FormulaSyncEvaluator.evaluate(.ref(anchor: "intro"))
        }
    }
}
