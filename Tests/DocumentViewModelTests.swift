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
}
