import Testing
import Foundation
@testable import apfelpad

@Suite("File persistence", .serialized)
@MainActor
struct FilePersistenceTests {

    private func tempURL(_ ext: String = "md") -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("apfelpad-test-\(UUID().uuidString).\(ext)")
    }

    @Test("save and reopen preserves content exactly")
    func saveAndReopen() async throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let vm = DocumentViewModel(runtime: runtime)

        let markdown = "# Test\n\nResult: =math(42+8)\n"
        try vm.load(rawMarkdown: markdown)
        try await vm.save(to: url)

        let vm2 = DocumentViewModel(runtime: runtime)
        try await vm2.open(from: url)

        #expect(vm2.document.rawMarkdown == markdown)
        #expect(vm2.fileURL == url)
        #expect(!vm2.isDirty)
    }

    @Test("dirty tracking — edit marks dirty, save clears")
    func dirtyTracking() async throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let vm = DocumentViewModel(runtime: runtime)

        #expect(!vm.isDirty)

        try vm.load(rawMarkdown: "hello")
        try await vm.save(to: url)
        #expect(!vm.isDirty)

        vm.textDidChange("hello world")
        #expect(vm.isDirty)

        vm.flushPendingReparse()
        try await vm.save()
        #expect(!vm.isDirty)
    }

    @Test("save during formula evaluation does not corrupt file")
    func saveDuringEval() async throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let vm = DocumentViewModel(runtime: runtime)

        let markdown = "=math(1+1) and =math(2+2)"
        try vm.load(rawMarkdown: markdown)

        // Save before evaluation completes
        try await vm.save(to: url)

        let saved = try String(contentsOf: url, encoding: .utf8)
        #expect(saved == markdown)
    }

    @Test("large file round-trip")
    func largeFile() async throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let vm = DocumentViewModel(runtime: runtime)

        var markdown = "# Large Document\n\n"
        for i in 0..<5000 {
            markdown += "Line \(i): result is =math(\(i)+1) here.\n"
        }

        try vm.load(rawMarkdown: markdown)
        try await vm.save(to: url)

        let vm2 = DocumentViewModel(runtime: runtime)
        try await vm2.open(from: url)

        #expect(vm2.document.rawMarkdown == markdown)
        #expect(vm2.document.spans.count == 5000)
    }

    @Test("rapid saves — last write wins, no corruption")
    func rapidSaves() async throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let vm = DocumentViewModel(runtime: runtime)

        try vm.load(rawMarkdown: "v1")
        try await vm.save(to: url)

        try vm.load(rawMarkdown: "v2")
        try await vm.save()

        try vm.load(rawMarkdown: "v3")
        try await vm.save()

        let final = try String(contentsOf: url, encoding: .utf8)
        #expect(final == "v3")
    }

    @Test("special characters in content round-trip correctly")
    func specialCharacters() async throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let vm = DocumentViewModel(runtime: runtime)

        let markdown = "# Ünïcödé 🎉\n\n日本語テスト\n=math(1+1)\nEmoji: 🧮📝\n"
        try vm.load(rawMarkdown: markdown)
        try await vm.save(to: url)

        let vm2 = DocumentViewModel(runtime: runtime)
        try await vm2.open(from: url)

        #expect(vm2.document.rawMarkdown == markdown)
        #expect(vm2.document.spans.count == 1)
    }

    @Test("open nonexistent file throws")
    func openNonexistent() async throws {
        let url = URL(fileURLWithPath: "/tmp/apfelpad-nonexistent-\(UUID()).md")
        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let vm = DocumentViewModel(runtime: runtime)

        await #expect(throws: (any Error).self) {
            try await vm.open(from: url)
        }
    }

    @Test("window title reflects file state")
    func windowTitle() async throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let vm = DocumentViewModel(runtime: runtime)

        #expect(vm.windowTitle == "Untitled")

        try vm.load(rawMarkdown: "test")
        try await vm.save(to: url)

        #expect(vm.windowTitle.contains(url.lastPathComponent))
        #expect(!vm.windowTitle.contains("Edited"))

        vm.textDidChange("test changed")
        #expect(vm.windowTitle.contains("Edited"))
    }

    @Test("open evaluates formulas automatically")
    func openEvaluates() async throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let store = MarkdownDocumentStore()
        try await store.save(rawMarkdown: "Result: =math(7*6)", to: url)

        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let vm = DocumentViewModel(runtime: runtime)

        try await vm.open(from: url)

        #expect(vm.document.spans.count == 1)
        #expect(vm.document.spans[0].value == .ready(text: "42"))
    }

    @Test("save preserves formula source text, not rendered values")
    func savePreservesSource() async throws {
        let url = tempURL()
        defer { try? FileManager.default.removeItem(at: url) }

        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let vm = DocumentViewModel(runtime: runtime)

        let markdown = "The answer is =math(6*7)"
        try vm.load(rawMarkdown: markdown)
        await vm.evaluateAll()

        // Span shows "42" but saved file must have the formula source
        #expect(vm.document.spans[0].value == .ready(text: "42"))
        try await vm.save(to: url)

        let saved = try String(contentsOf: url, encoding: .utf8)
        #expect(saved == markdown)
        #expect(saved.contains("=math(6*7)"))
        #expect(!saved.contains("42"))
    }
}
