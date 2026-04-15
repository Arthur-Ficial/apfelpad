import Testing
import Foundation
@testable import apfelpad

@Suite("Speed: debounce and incremental evaluation", .serialized)
@MainActor
struct SpeedTests {
    @MainActor
    private func waitUntil(
        timeout: Duration = .seconds(2),
        step: Duration = .milliseconds(25),
        _ condition: () -> Bool
    ) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout
        while !condition() {
            if clock.now >= deadline {
                Issue.record("timed out waiting for condition")
                return
            }
            try await Task.sleep(for: step)
        }
    }

    @Test("debounced reparse — multiple rapid changes coalesce into one parse")
    func debouncedReparse() async throws {
        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let vm = DocumentViewModel(runtime: runtime)

        vm.textDidChange("=math(1")
        vm.textDidChange("=math(1+")
        vm.textDidChange("=math(1+2)")

        // Debounce has not fired yet — document should still be empty
        #expect(vm.document.spans.isEmpty)

        try await waitUntil {
            vm.document.spans.count == 1
        }

        let span = try #require(vm.document.spans.first)
        #expect(vm.document.spans.count == 1)
        #expect(span.source == "=math(1+2)")
    }

    @Test("debounce timer resets on each keystroke")
    func debounceResets() async throws {
        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let vm = DocumentViewModel(runtime: runtime)

        vm.textDidChange("=math(1+1)")
        try await Task.sleep(for: .milliseconds(100))

        // 100ms < 300ms debounce — not yet fired
        #expect(vm.document.spans.isEmpty)

        // New change resets timer
        vm.textDidChange("=math(2+2)")
        try await Task.sleep(for: .milliseconds(100))

        // Still not fired (only 100ms since last change)
        #expect(vm.document.spans.isEmpty)

        try await waitUntil {
            vm.document.spans.count == 1
        }

        // Now fired — with the LAST text
        let span = try #require(vm.document.spans.first)
        #expect(vm.document.spans.count == 1)
        #expect(span.source == "=math(2+2)")
    }

    @Test("flushPendingReparse forces immediate parse")
    func flushImmediate() async throws {
        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let vm = DocumentViewModel(runtime: runtime)

        vm.textDidChange("=math(5*5)")
        vm.flushPendingReparse()

        #expect(vm.document.spans.count == 1)
        #expect(vm.document.spans[0].source == "=math(5*5)")
    }

    @Test("unchanged spans carry forward values without re-evaluation")
    func carryForward() async throws {
        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let vm = DocumentViewModel(runtime: runtime)

        try vm.load(rawMarkdown: "X is =math(1+1) done")
        await vm.evaluateAll()
        #expect(vm.document.spans[0].value == .ready(text: "2"))

        // Edit text around the formula (formula source unchanged)
        vm.textDidChange("Y is =math(1+1) done")
        vm.flushPendingReparse()

        // Value carried forward synchronously
        #expect(vm.document.spans[0].value == .ready(text: "2"))
    }

    @Test("changed formula source triggers re-evaluation")
    func changedFormula() async throws {
        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let vm = DocumentViewModel(runtime: runtime)

        try vm.load(rawMarkdown: "A: =math(1+1) B: =math(2+2)")
        await vm.evaluateAll()
        #expect(vm.document.spans[0].value == .ready(text: "2"))
        #expect(vm.document.spans[1].value == .ready(text: "4"))

        // Change second formula
        vm.textDidChange("A: =math(1+1) B: =math(3+3)")
        vm.flushPendingReparse()

        // First formula preserved
        #expect(vm.document.spans[0].value == .ready(text: "2"))

        // Evaluate all to ensure second formula computes
        await vm.evaluateAll()
        #expect(vm.document.spans[1].value == .ready(text: "6"))
    }

    @Test("textDidChange sets isDirty")
    func dirtyOnEdit() async throws {
        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let vm = DocumentViewModel(runtime: runtime)

        #expect(!vm.isDirty)
        vm.textDidChange("hello")
        #expect(vm.isDirty)
    }

    @Test("large document discovers spans efficiently")
    func largeDocumentDiscovery() throws {
        var markdown = "# Large Document\n\n"
        for i in 0..<1000 {
            markdown += "Line \(i): value is =math(\(i)+1) here.\n"
        }
        let doc = try Document(rawMarkdown: markdown)
        #expect(doc.spans.count == 1000)
    }
}
