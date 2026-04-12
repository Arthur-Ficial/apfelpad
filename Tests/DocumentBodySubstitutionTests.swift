import Testing
import Foundation
@testable import apfelpad

/// Regression suite for the markdown prose substitution + click routing in
/// DocumentBodyView. These tests guard the user-visible contract that:
///
///   1. Every evaluated formula in a prose paragraph is substituted into
///      the markdown source as a clickable link pointing at its span UUID.
///   2. Clicking that link (via SpanClickRouter) resolves to the exact
///      FormulaSpan the user sees on screen.
///
/// Both behaviours must survive future refactors — if either breaks,
/// click-to-edit and live-value rendering break with them.
@Suite("DocumentBody prose substitution + click routing")
@MainActor
struct DocumentBodySubstitutionTests {

    /// Build a VM, load markdown, evaluate, and return the same
    /// prose-substituted markdown that DocumentBodyView feeds into
    /// MarkdownUI. The production code uses DocumentBodyView.Substitution
    /// — a pure helper we expose for testing.
    private func substituted(_ raw: String) async -> String {
        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let vm = DocumentViewModel(runtime: runtime)
        try? vm.load(rawMarkdown: raw)
        await vm.evaluateAll()
        return DocumentBodySubstitution.substitute(
            rawMarkdown: vm.rawText,
            spans: vm.document.spans
        )
    }

    @Test("math formulas become clickable markdown links")
    func mathBecomesLink() async {
        let out = await substituted("There are =math(365*24) hours.")
        // Contains the evaluated value
        #expect(out.contains("8760"))
        // Contains an apfelpad://span/ link somewhere
        #expect(out.contains("apfelpad://span/"))
        // The raw formula source is gone
        #expect(!out.contains("=math(365*24)"))
    }

    @Test("each formula gets its own unique span UUID in the link")
    func uniquePerFormula() async {
        let out = await substituted("=math(1+1) and =math(2+2) and =math(3+3).")
        // Three occurrences of apfelpad://span/
        let count = out.components(separatedBy: "apfelpad://span/").count - 1
        #expect(count == 3)
    }

    @Test("clicking the substituted link resolves to the right span")
    func clickResolves() async {
        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let vm = DocumentViewModel(runtime: runtime)
        try? vm.load(rawMarkdown: "Answer: =math(40+2)")
        await vm.evaluateAll()
        let originalSpan = vm.document.spans[0]
        let subbed = DocumentBodySubstitution.substitute(
            rawMarkdown: vm.rawText, spans: vm.document.spans
        )
        // Extract the UUID from the substituted text
        let marker = "apfelpad://span/"
        guard let range = subbed.range(of: marker) else {
            Issue.record("no apfelpad link in substituted markdown: \(subbed)")
            return
        }
        let rest = String(subbed[range.upperBound...])
        let uuidString = String(rest.prefix { $0.isHexDigit || $0 == "-" })
        guard let url = URL(string: "apfelpad://span/\(uuidString)") else {
            Issue.record("cannot parse url from uuid \(uuidString)")
            return
        }
        let resolved = SpanClickRouter.handle(url: url, in: vm.document)
        #expect(resolved?.id == originalSpan.id)
    }

    @Test("input spans are not substituted — they split paragraphs")
    func inputNotSubstituted() async {
        // The raw markdown around an =input stays intact; =input itself is
        // handled by the split-into-paragraphs pass, not the substitution.
        let out = await substituted("Pick: =input(\"name\", text, \"Alice\")")
        // The =input source survives substitution untouched
        #expect(out.contains("=input"))
    }

    @Test("formulas inside tables are substituted")
    func tableFormulas() async {
        let doc = """
        | A | B |
        |---|---|
        | =math(1+1) | =math(2+2) |
        """
        let out = await substituted(doc)
        #expect(out.contains("2"))
        #expect(out.contains("4"))
        #expect(out.contains("apfelpad://span/"))
        #expect(!out.contains("=math(1+1)"))
        #expect(!out.contains("=math(2+2)"))
    }
}
