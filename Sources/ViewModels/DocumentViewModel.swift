import Foundation
import Observation

@Observable
@MainActor
final class DocumentViewModel {
    var document: Document = .empty
    var fileURL: URL?
    var isDirty: Bool = false
    private(set) var rawText: String = ""

    private var runtime: FormulaRuntime
    private let store: DocumentPersistence
    private var debounceTask: Task<Void, Never>?
    private var autosaveTask: Task<Void, Never>?

    var windowTitle: String {
        let name = fileURL?.lastPathComponent ?? "Untitled"
        return isDirty ? "\(name) — Edited" : name
    }

    init(runtime: FormulaRuntime, store: DocumentPersistence = MarkdownDocumentStore()) {
        self.runtime = runtime
        self.store = store
    }

    func replaceRuntime(_ runtime: FormulaRuntime) {
        self.runtime = runtime
    }

    // MARK: - Text editing (debounced)

    func textDidChange(_ newText: String) {
        rawText = newText
        isDirty = true
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            reparseAndEvaluateChanged()
        }
    }

    func flushPendingReparse() {
        debounceTask?.cancel()
        debounceTask = nil
        reparseAndEvaluateChanged()
    }

    // MARK: - Parsing

    func load(rawMarkdown: String) throws {
        rawText = rawMarkdown
        self.document = try Document(rawMarkdown: rawMarkdown)
    }

    private func reparseAndEvaluateChanged() {
        var oldValues: [String: FormulaValue] = [:]
        for span in document.spans {
            if case .idle = span.value { continue }
            oldValues[span.source] = span.value
        }

        guard let newDoc = try? Document(rawMarkdown: rawText) else { return }
        document = newDoc

        var indicesToEvaluate: [Int] = []
        for (i, span) in document.spans.enumerated() {
            if let oldValue = oldValues[span.source] {
                document.spans[i].value = oldValue
            } else {
                indicesToEvaluate.append(i)
            }
        }

        if !indicesToEvaluate.isEmpty {
            Task { await evaluateIndices(indicesToEvaluate) }
        }
    }

    // MARK: - Evaluation

    func evaluateAll() async {
        await evaluateIndices(Array(document.spans.indices))
    }

    private func evaluateIndices(_ indices: [Int]) async {
        let snapshot = document
        await withTaskGroup(of: (Int, FormulaValue).self) { group in
            for i in indices {
                guard i < snapshot.spans.count else { continue }
                let span = snapshot.spans[i]
                let call = span.call
                let source = span.source
                group.addTask { [runtime] in
                    var last: FormulaValue = .idle
                    do {
                        for try await value in runtime.evaluateStreaming(
                            call: call,
                            source: source,
                            context: ""
                        ) {
                            last = value
                        }
                    } catch {
                        last = .error(message: error.localizedDescription)
                    }
                    return (i, last)
                }
            }
            for await (i, value) in group {
                guard i < document.spans.count else { continue }
                document.spans[i].value = value
            }
        }
    }

    // MARK: - File operations

    func save() async throws {
        guard let url = fileURL else { return }
        flushPendingReparse()
        try await store.save(rawMarkdown: rawText, to: url)
        isDirty = false
    }

    func save(to url: URL) async throws {
        fileURL = url
        flushPendingReparse()
        try await store.save(rawMarkdown: rawText, to: url)
        isDirty = false
    }

    func open(from url: URL) async throws {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        let markdown = try await store.load(from: url)
        try load(rawMarkdown: markdown)
        fileURL = url
        isDirty = false
        await evaluateAll()
    }

    // MARK: - Autosave

    func startAutosave() {
        stopAutosave()
        autosaveTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled, isDirty, fileURL != nil else { continue }
                try? await save()
            }
        }
    }

    func stopAutosave() {
        autosaveTask?.cancel()
        autosaveTask = nil
    }
}
