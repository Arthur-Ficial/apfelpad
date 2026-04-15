import Testing
import Foundation
@testable import apfelpad

/// Drag-and-drop from the formula catalogue sidebar must insert the
/// dropped formula into the document and trigger evaluation. The drop
/// target in DocumentBodyView routes through DocumentViewModel.insertAtCursor
/// which is the single insertion primitive for both rendered Markdown mode
/// and Source mode.
///
/// The rendered-markdown drop path previously broke because MarkdownUI
/// captured all gestures inside its Text views. These tests pin the
/// contract: insertAtCursor always appends the dropped source on its own
/// line, re-parses the document, and re-evaluates the new span.
@Suite("Drag & drop into rendered markdown", .serialized)
@MainActor
struct DragDropTests {

    private func makeVM() -> DocumentViewModel {
        DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
    }

    @Test("dropping =math(1+2) into empty doc inserts and evaluates")
    func dropIntoEmptyDoc() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: "")
        vm.insertAtCursor("=math(1+2)")
        // Deterministic wait: fire evaluation synchronously via the VM so
        // parallel test runs don't race with the fire-and-forget Task{}.
        await vm.evaluateAll()
        #expect(vm.rawText.contains("=math(1+2)"))
        #expect(vm.document.spans.count == 1)
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "3")
        } else {
            Issue.record("expected ready(3), got \(vm.document.spans[0].value)")
        }
    }

    @Test("dropping onto existing doc appends on its own line")
    func dropAppendsOnOwnLine() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: "Hello world.")
        vm.insertAtCursor("=math(10*10)")
        await vm.evaluateAll()
        #expect(vm.rawText.contains("Hello world."))
        #expect(vm.rawText.contains("=math(10*10)"))
        #expect(vm.rawText.contains("\n\n"))
    }

    @Test("dropping multiple formulas stacks them")
    func dropMultiple() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: "")
        vm.insertAtCursor("=math(1)")
        vm.insertAtCursor("=math(2)")
        vm.insertAtCursor("=math(3)")
        await vm.evaluateAll()
        #expect(vm.document.spans.count == 3)
    }

    @Test("dropping substitutes cleanly through DocumentBodySubstitution")
    func dropRendersAfter() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: "Pre text.")
        vm.insertAtCursor("=math(21*2)")
        await vm.evaluateAll()
        let out = DocumentBodySubstitution.substitute(
            rawMarkdown: vm.rawText,
            spans: vm.document.spans
        )
        #expect(out.contains("42"))
        #expect(out.contains("apfelpad://span/"))
        #expect(!out.contains("=math(21*2)"))
    }

    @Test("dropping =input inserts a widget, not a link")
    func dropInput() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: "")
        vm.insertAtCursor(#"=input("hours", number, "40")"#)
        await vm.evaluateAll()
        #expect(vm.document.spans.count == 1)
        if case .input(let name, let type, let def) = vm.document.spans[0].call {
            #expect(name == "hours")
            #expect(type == .number)
            #expect(def == "40")
        } else {
            Issue.record("expected .input call")
        }
        // Substitution leaves =input alone (handled by paragraph splitter)
        let out = DocumentBodySubstitution.substitute(
            rawMarkdown: vm.rawText,
            spans: vm.document.spans
        )
        #expect(out.contains("=input"))
    }
}
