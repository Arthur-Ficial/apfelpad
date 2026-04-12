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

    @Test("composition: =concatenate with three sibling sub-calls")
    func composeConcatenate() async throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: #"=concatenate(=upper("a"), "-", =lower("B"))"#)
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

    // ── insertAtCursor for the catalogue sidebar ────────────────────────────

    @Test("insertAtCursor appends formula to empty doc")
    func insertEmpty() throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        vm.insertAtCursor("=math(1+1)")
        #expect(vm.rawText.contains("=math(1+1)"))
        #expect(vm.isDirty == true)
        #expect(vm.document.spans.count == 1)
    }

    @Test("insertAtCursor appends to a non-empty doc")
    func insertAppends() throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: "Some text")
        vm.insertAtCursor("=math(2+2)")
        #expect(vm.rawText.contains("Some text"))
        #expect(vm.rawText.contains("=math(2+2)"))
        #expect(vm.document.spans.count == 1)
    }

    @Test("insertAtCursor multiple times keeps all formulas")
    func insertMultiple() throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        vm.insertAtCursor(#"=upper("hello")"#)
        vm.insertAtCursor(#"=lower("WORLD")"#)
        #expect(vm.document.spans.count == 2)
    }

    @Test("insertAtCursor uses the tracked insertion location")
    func insertAtTrackedLocation() throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: "Top\n\nBottom")
        vm.setInsertionLocation(3)
        vm.insertAtCursor("=math(2+2)")
        #expect(vm.rawText == "Top\n\n=math(2+2)\n\nBottom")
    }

    @Test("focusFirstInput selects the first render input")
    func focusFirstInputSelectsFirstInput() throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: """
        Client: =input("client", text, "Acme")
        Rate: =input("rate", number, "125")
        """)
        vm.focusFirstInput()
        #expect(vm.editingMode == .render)
        #expect(vm.focusedInputName == "client")
    }

    @Test("focusNextInput cycles through document inputs")
    func focusNextInputCycles() throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: """
        Client: =input("client", text, "Acme")
        Rate: =input("rate", number, "125")
        Tax: =input("tax", percent, "20")
        """)
        vm.focusFirstInput()
        vm.focusNextInput()
        #expect(vm.focusedInputName == "rate")
        vm.focusNextInput()
        #expect(vm.focusedInputName == "tax")
        vm.focusNextInput()
        #expect(vm.focusedInputName == "client")
    }
}
