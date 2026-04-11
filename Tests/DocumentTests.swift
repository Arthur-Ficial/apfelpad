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

    @Test("discovers nested-paren math formula")
    func nestedParens() throws {
        let doc = try Document(rawMarkdown: "=math((365-104-10)*8)")
        #expect(doc.spans.count == 1)
        #expect(doc.spans[0].call == .math(expression: "(365-104-10)*8"))
    }

    @Test("skips formula references inside code spans")
    func skipsCodeSpans() throws {
        let doc = try Document(rawMarkdown: "Use `=apfel(hello)` anywhere.")
        #expect(doc.spans.isEmpty)
    }

    @Test("skips literal '...' placeholder")
    func skipsPlaceholder() throws {
        let doc = try Document(rawMarkdown: "Every =apfel(...) formula runs.")
        #expect(doc.spans.isEmpty)
    }

    @Test("finds formula after a skipped code span")
    func afterCodeSpan() throws {
        let doc = try Document(rawMarkdown: "`=apfel(x)` then =math(1+1)")
        #expect(doc.spans.count == 1)
        #expect(doc.spans[0].call == .math(expression: "1+1"))
    }

    @Test("paren inside curly-quoted string does not break discovery")
    func curlyQuotedParen() throws {
        // The closing `)` inside the quoted string must not be mistaken
        // for the formula's closing paren. Walker must treat curly quotes
        // as string delimiters too.
        let input = "=apfel(\u{201C}laugh (out loud)\u{201D})"
        let doc = try Document(rawMarkdown: input)
        #expect(doc.spans.count == 1)
        #expect(doc.spans[0].call == .apfel(prompt: "laugh (out loud)", seed: nil))
    }

    @Test("discovers curly-quoted =apfel with seed")
    func curlyApfelWithSeed() throws {
        let left = "\u{201C}"
        let right = "\u{201D}"
        let input = "Prelude =apfel(\(left)write a haiku\(right), 42) end"
        let doc = try Document(rawMarkdown: input)
        #expect(doc.spans.count == 1)
        #expect(doc.spans[0].call == .apfel(prompt: "write a haiku", seed: 42))
    }

    @Test("discovers =() anonymous shortcut")
    func anonShortcut() throws {
        let doc = try Document(rawMarkdown: "Hello =(say hi) world")
        #expect(doc.spans.count == 1)
        #expect(doc.spans[0].call == .apfel(prompt: "say hi", seed: nil))
    }
}
