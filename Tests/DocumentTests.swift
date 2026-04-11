import Testing
@testable import apfelpad

@Suite("Document")
struct DocumentTests {
    @Test("discovers a single formula span")
    func singleSpan() throws {
        let doc = try Document(rawMarkdown: "Hello =math(1+1) world")
        #expect(doc.spans.count == 1)
        #expect(doc.spans[0].source == "=math(1+1)")
        #expect(doc.spans[0].call == .math(expression: "1+1"))
    }

    @Test("discovers multiple formula spans")
    func multipleSpans() throws {
        let doc = try Document(rawMarkdown: "A =math(1+1) B =math(2*3) C")
        #expect(doc.spans.count == 2)
        #expect(doc.spans[0].call == .math(expression: "1+1"))
        #expect(doc.spans[1].call == .math(expression: "2*3"))
    }

    @Test("no spans in plain text")
    func noSpans() throws {
        let doc = try Document(rawMarkdown: "Just words.")
        #expect(doc.spans.isEmpty)
    }

    @Test("empty document")
    func empty() {
        let doc = Document.empty
        #expect(doc.rawMarkdown == "")
        #expect(doc.spans.isEmpty)
    }
}
