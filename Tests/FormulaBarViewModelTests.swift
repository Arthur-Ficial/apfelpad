import Testing
import Foundation
@testable import apfelpad

@Suite("FormulaBarViewModel", .serialized)
@MainActor
struct FormulaBarViewModelTests {
    @Test("selecting a span shows its source")
    func select() {
        let vm = FormulaBarViewModel()
        let span = FormulaSpan(
            range: 0..<10,
            source: "=math(1+1)",
            call: .math(expression: "1+1"),
            value: .ready(text: "2")
        )
        vm.select(span)
        #expect(vm.sourceText == "=math(1+1)")
        #expect(vm.selectedSpanID == span.id)
    }

    @Test("clearing leaves placeholder")
    func clear() {
        let vm = FormulaBarViewModel()
        vm.clear()
        #expect(vm.sourceText == "")
        #expect(vm.placeholder == "click a formula span to edit its source")
        #expect(vm.selectedSpanID == nil)
    }

    @Test("commitNow invokes onCommit with the current source")
    func commitInvokesCallback() {
        let vm = FormulaBarViewModel()
        var committed: (UUID, String)?
        vm.onCommit = { id, src in
            committed = (id, src)
            return true
        }
        let span = FormulaSpan(
            range: 0..<10,
            source: "=math(1+1)",
            call: .math(expression: "1+1"),
            value: .ready(text: "2")
        )
        vm.select(span)
        vm.sourceText = "=math(2+2)"
        vm.commitNow()
        #expect(committed?.0 == span.id)
        #expect(committed?.1 == "=math(2+2)")
    }

    @Test("commitNow canonicalises the source before commit")
    func commitCanonicalises() {
        let vm = FormulaBarViewModel()
        var committed: String?
        vm.onCommit = { _, src in
            committed = src
            return true
        }
        let span = FormulaSpan(
            range: 0..<12,
            source: "=upper(\"hi\")",
            call: .upper(text: "hi"),
            value: .ready(text: "HI")
        )
        vm.select(span)
        vm.sourceText = "=upper(hi)"
        vm.commitNow()
        #expect(committed == #"=upper("hi")"#)
        #expect(vm.sourceText == #"=upper("hi")"#)
    }

    @Test("invalid source sets editState to invalid and does not commit")
    func invalidCommit() {
        let vm = FormulaBarViewModel()
        var called = false
        vm.onCommit = { _, _ in
            called = true
            return true
        }
        let span = FormulaSpan(
            range: 0..<10,
            source: "=math(1+1)",
            call: .math(expression: "1+1"),
            value: .ready(text: "2")
        )
        vm.select(span)
        vm.sourceText = "=math("  // unclosed
        vm.commitNow()
        #expect(called == false)
        if case .invalid = vm.editState {} else {
            Issue.record("expected .invalid, got \(vm.editState)")
        }
    }

    @Test("commitNow with no selected span does nothing")
    func noSelection() {
        let vm = FormulaBarViewModel()
        var called = false
        vm.onCommit = { _, _ in called = true; return true }
        vm.sourceText = "=math(5)"
        vm.commitNow()
        #expect(called == false)
    }
}

@Suite("DocumentViewModel.replaceSpanSource", .serialized)
@MainActor
struct DocumentReplaceSpanTests {
    @Test("replaces a math span and re-evaluates")
    func replaceMath() async throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: "Answer: =math(1+1)")
        await vm.evaluateAll()
        let id = vm.document.spans[0].id
        let ok = vm.replaceSpanSource(id: id, with: "=math(40+2)")
        #expect(ok == true)
        // rawText should now contain the new source
        #expect(vm.rawText.contains("=math(40+2)"))
        #expect(!vm.rawText.contains("=math(1+1)"))
        // Wait for async evaluation
        try await Task.sleep(for: .milliseconds(50))
        #expect(vm.document.spans[0].call == .math(expression: "40+2"))
    }

    @Test("replaceSpanSource canonicalises bare strings before splicing")
    func replaceCanonicalises() async throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: "=upper(\"hello\")")
        let id = vm.document.spans[0].id
        let ok = vm.replaceSpanSource(id: id, with: "=upper(hi there)")
        #expect(ok == true)
        #expect(vm.rawText == #"=upper("hi there")"#)
    }

    @Test("fails gracefully on unknown span id")
    func unknownID() throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: "=math(1+1)")
        let ok = vm.replaceSpanSource(id: UUID(), with: "=math(2+2)")
        #expect(ok == false)
    }

    @Test("fails on unparseable new source, leaves doc untouched")
    func unparseable() throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: "=math(1+1)")
        let id = vm.document.spans[0].id
        let ok = vm.replaceSpanSource(id: id, with: "=math(")
        #expect(ok == false)
        #expect(vm.rawText == "=math(1+1)")
    }
}
