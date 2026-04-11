import Testing
@testable import apfelpad

@Suite("InlineFormulaRenderer")
@MainActor
struct InlineFormulaRendererTests {
    @Test("replaces formula source with display text")
    func basicReplacement() throws {
        var doc = try Document(rawMarkdown: "A =math(1+1) B")
        doc.spans[0].value = .ready(text: "2")
        let attr = InlineFormulaRenderer.render(doc)
        let rendered = String(attr.characters)
        // Expect the raw source to be gone and the result "2" in its place
        #expect(rendered.contains("2"))
        #expect(!rendered.contains("=math(1+1)"))
    }

    @Test("preserves leading and trailing text")
    func bookends() throws {
        var doc = try Document(rawMarkdown: "before =math(2*3) after")
        doc.spans[0].value = .ready(text: "6")
        let rendered = String(InlineFormulaRenderer.render(doc).characters)
        #expect(rendered.hasPrefix("before"))
        #expect(rendered.hasSuffix("after"))
        #expect(rendered.contains("6"))
    }

    @Test("multiple spans in order")
    func multiple() throws {
        var doc = try Document(rawMarkdown: "=math(1) and =math(2)")
        doc.spans[0].value = .ready(text: "1")
        doc.spans[1].value = .ready(text: "2")
        let rendered = String(InlineFormulaRenderer.render(doc).characters)
        // Check the two results appear in order with "and" between them
        let one = rendered.range(of: "1")!.lowerBound
        let andR = rendered.range(of: "and")!.lowerBound
        let two = rendered.range(of: "2")!.lowerBound
        #expect(one < andR)
        #expect(andR < two)
    }

    @Test("handles emoji and multi-byte characters correctly")
    func emojiRendering() throws {
        var doc = try Document(rawMarkdown: "\u{1F389} Result: =math(1+1) done \u{1F9EE}")
        doc.spans[0].value = .ready(text: "2")
        let rendered = String(InlineFormulaRenderer.render(doc).characters)
        #expect(rendered.contains("\u{1F389}"))
        #expect(rendered.contains("2"))
        #expect(rendered.contains("done"))
        #expect(rendered.contains("\u{1F9EE}"))
        #expect(!rendered.contains("=math(1+1)"))
    }
}
