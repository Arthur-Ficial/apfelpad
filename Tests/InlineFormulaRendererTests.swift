import Testing
import Foundation
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

    @Test("emits a .link attribute per span with the span's UUID")
    func linkAttribute() throws {
        var doc = try Document(rawMarkdown: "=math(1+1)")
        doc.spans[0].value = .ready(text: "2")
        let attr = InlineFormulaRenderer.render(doc)
        // Find at least one run carrying a link URL pointing at the span
        var foundLink: URL?
        for run in attr.runs {
            if let link = run.link {
                foundLink = link
                break
            }
        }
        let expected = URL(string: "apfelpad://span/\(doc.spans[0].id.uuidString)")
        #expect(foundLink == expected)
    }

    @Test("every span in a multi-span document has a link")
    func multipleLinks() throws {
        var doc = try Document(rawMarkdown: "=math(1) and =math(2)")
        doc.spans[0].value = .ready(text: "1")
        doc.spans[1].value = .ready(text: "2")
        let attr = InlineFormulaRenderer.render(doc)
        var links: [URL] = []
        for run in attr.runs {
            if let link = run.link { links.append(link) }
        }
        #expect(links.count == 2)
        let ids = doc.spans.map { $0.id.uuidString }
        for link in links {
            #expect(ids.contains(link.lastPathComponent))
        }
    }

    @Test("identityHash changes when span value changes")
    func identityHashChangesOnValueUpdate() throws {
        var doc = try Document(rawMarkdown: "=math(1+1)")
        doc.spans[0].value = .idle
        let idleHash = InlineFormulaRenderer.identityHash(for: doc)
        doc.spans[0].value = .ready(text: "2")
        let readyHash = InlineFormulaRenderer.identityHash(for: doc)
        #expect(idleHash != readyHash)
    }

    @Test("identityHash stable for same state")
    func identityHashStable() throws {
        var doc = try Document(rawMarkdown: "=math(7*7)")
        doc.spans[0].value = .ready(text: "49")
        let h1 = InlineFormulaRenderer.identityHash(for: doc)
        let h2 = InlineFormulaRenderer.identityHash(for: doc)
        #expect(h1 == h2)
    }

    @Test("memoized render returns identical output for same state")
    func memoizationWorks() throws {
        var doc = try Document(rawMarkdown: "=math(42)")
        doc.spans[0].value = .ready(text: "42")
        let first = InlineFormulaRenderer.render(doc)
        let second = InlineFormulaRenderer.render(doc)
        // Both must be equal — cache hit or not, content matches
        #expect(String(first.characters) == String(second.characters))
    }
}
