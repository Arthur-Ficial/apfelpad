import Testing
@testable import apfelpad

@Suite("Document", .serialized)
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

    // MARK: - Bare zero-arg formulas (issue #18)

    @Test("=today (no parens, EOL) is discovered as zero-arg call")
    func bareTodayAtEnd() throws {
        let doc = try Document(rawMarkdown: "Date: =today")
        #expect(doc.spans.count == 1)
        #expect(doc.spans[0].source == "=today")
        #expect(doc.spans[0].call == .today)
    }

    @Test("=today. (followed by punctuation) is discovered")
    func bareTodayBeforePunctuation() throws {
        let doc = try Document(rawMarkdown: "It is =today.")
        #expect(doc.spans.count == 1)
        #expect(doc.spans[0].source == "=today")
        #expect(doc.spans[0].call == .today)
    }

    @Test("=today\\n (followed by newline) is discovered")
    func bareTodayBeforeNewline() throws {
        let doc = try Document(rawMarkdown: "Stamp: =today\nNext line")
        #expect(doc.spans.count == 1)
        #expect(doc.spans[0].source == "=today")
        #expect(doc.spans[0].call == .today)
    }

    @Test("=count (followed by EOL) is discovered as zero-arg")
    func bareCount() throws {
        let doc = try Document(rawMarkdown: "Words: =count")
        #expect(doc.spans.count == 1)
        #expect(doc.spans[0].source == "=count")
        #expect(doc.spans[0].call == .count(anchor: nil))
    }

    @Test("=clip! (followed by punctuation) is discovered")
    func bareClipBeforeBang() throws {
        let doc = try Document(rawMarkdown: "Paste =clip!")
        #expect(doc.spans.count == 1)
        #expect(doc.spans[0].source == "=clip")
        #expect(doc.spans[0].call == .clip)
    }

    @Test("=time, =month, =day, =recording all parse bare")
    func bareAllZeroArg() throws {
        let doc = try Document(rawMarkdown: "T=time M=month D=day R=recording")
        #expect(doc.spans.count == 4)
        #expect(doc.spans.contains { $0.call == .time })
        #expect(doc.spans.contains { $0.call == .month })
        #expect(doc.spans.contains { $0.call == .day })
        #expect(doc.spans.contains { $0.call == .recording })
    }

    @Test("bare name with parens still parses normally")
    func bareNameDoesNotBreakParenForm() throws {
        let doc = try Document(rawMarkdown: "=today() and =today")
        #expect(doc.spans.count == 2)
        #expect(doc.spans[0].source == "=today()")
        #expect(doc.spans[1].source == "=today")
    }

    @Test("=apfel without parens is NOT discovered (apfel takes a required prompt)")
    func bareApfelIsRejected() throws {
        let doc = try Document(rawMarkdown: "Just =apfel here")
        #expect(doc.spans.isEmpty)
    }

    @Test("=math without parens is NOT discovered (math takes a required expression)")
    func bareMathIsRejected() throws {
        let doc = try Document(rawMarkdown: "Just =math here")
        #expect(doc.spans.isEmpty)
    }

    @Test("=todayish (longer name continuing the word) is NOT discovered")
    func longerWordIsNotBareToday() throws {
        let doc = try Document(rawMarkdown: "I am =todayish")
        // The name `todayish` is not in the registry, so no span is produced.
        #expect(doc.spans.isEmpty)
    }

    @Test("bare name inside code span is still skipped")
    func bareNameInCodeIsSkipped() throws {
        let doc = try Document(rawMarkdown: "Type `=today` to insert.")
        #expect(doc.spans.isEmpty)
    }
}
