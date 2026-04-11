import Testing
@testable import apfelpad

@Suite("DocumentViewModel")
@MainActor
struct DocumentViewModelTests {
    @Test("evaluating a doc with one math span fills the span value")
    func evalOneMath() async throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: "Answer: =math(40+2)")
        await vm.evaluateAll()
        #expect(vm.document.spans.count == 1)
        #expect(vm.document.spans[0].value == .ready(text: "42"))
    }

    @Test("two math spans evaluated independently")
    func evalTwoMath() async throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: "=math(2*3) and =math(10-4)")
        await vm.evaluateAll()
        #expect(vm.document.spans.count == 2)
        #expect(vm.document.spans[0].value == .ready(text: "6"))
        #expect(vm.document.spans[1].value == .ready(text: "6"))
    }

    @Test("invalid math reports .error state")
    func invalidMath() async throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: "=math(abc)")
        await vm.evaluateAll()
        if case .error = vm.document.spans[0].value {
            // pass
        } else {
            Issue.record("expected .error, got \(vm.document.spans[0].value)")
        }
    }

    @Test("=ref(@anchor) resolves to the referenced section text")
    func refResolves() async throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: """
        # Intro

        Hello world.

        # Body

        See: =ref(@intro)
        """)
        await vm.evaluateAll()
        #expect(vm.document.spans.count == 1)
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "Hello world.")
        } else {
            Issue.record("expected .ready, got \(vm.document.spans[0].value)")
        }
    }

    @Test("=ref to unknown anchor is an error")
    func refMissing() async throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: "=ref(@nope)")
        await vm.evaluateAll()
        if case .error = vm.document.spans[0].value {
            // pass
        } else {
            Issue.record("expected .error, got \(vm.document.spans[0].value)")
        }
    }

    // ── Turing-complete nested composition ──────────────────────────────────

    @Test("composition: =upper(=ref(@intro)) yields shouted intro")
    func composeUpperRef() async throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: """
        # Intro

        hello world

        # Body

        Shout: =upper(=ref(@intro))
        """)
        await vm.evaluateAll()
        let value = vm.document.spans[0].value
        if case .ready(let text) = value {
            #expect(text == "HELLO WORLD")
        } else {
            Issue.record("expected .ready(HELLO WORLD), got \(value)")
        }
    }

    @Test("composition: =concat with three sibling sub-calls")
    func composeConcat() async throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: #"=concat(=upper("a"), "-", =lower("B"))"#)
        await vm.evaluateAll()
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "A-b")
        } else {
            Issue.record("expected .ready(A-b), got \(vm.document.spans[0].value)")
        }
    }

    @Test("composition: =if(=math(5*5), \"big\", \"small\") — truthy non-zero")
    func composeIfMath() async throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: #"=if(=math(5*5), "big", "small")"#)
        await vm.evaluateAll()
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "big")
        } else {
            Issue.record("expected big, got \(vm.document.spans[0].value)")
        }
    }

    @Test("composition: =sum(=len(\"abc\"), =len(\"de\"), =math(10))")
    func composeSumLen() async throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: #"=sum(=len("abc"), =len("de"), =math(10))"#)
        await vm.evaluateAll()
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "15")
        } else {
            Issue.record("expected 15, got \(vm.document.spans[0].value)")
        }
    }
}
