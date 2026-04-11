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
        // The server just came up — re-evaluate every =apfel span that was
        // waiting (.idle, .evaluating, or .error) so users never see the
        // "LLM not configured" error message in normal launch.
        var indicesToRerun: [Int] = []
        for (i, span) in document.spans.enumerated() {
            if case .apfel = span.call {
                switch span.value {
                case .idle, .evaluating, .error:
                    indicesToRerun.append(i)
                default:
                    break
                }
            }
        }
        if !indicesToRerun.isEmpty {
            Task { await evaluateIndices(indicesToRerun) }
        }
    }
}

extension DocumentViewModel {

    /// Insert formula source text at the end of the current document.
    /// v0.3.2: we don't track the text cursor position inside SwiftUI's
    /// TextEditor, so "at cursor" means "at end, on its own line". The
    /// real cursor-aware insertion arrives with the custom attributed
    /// text editor in v0.4.
    func insertAtCursor(_ source: String) {
        let separator: String
        if rawText.isEmpty {
            separator = ""
        } else if rawText.hasSuffix("\n\n") {
            separator = ""
        } else if rawText.hasSuffix("\n") {
            separator = ""
        } else {
            separator = "\n\n"
        }
        let newText = rawText + separator + source
        rawText = newText
        isDirty = true
        if let doc = try? Document(rawMarkdown: newText) {
            document = doc
            Task { await evaluateAll() }
        }
    }

    /// Replace the source text of a single formula span and re-evaluate it.
    /// Called from the formula bar's commit loop. Updates rawText so the
    /// underlying markdown is in sync. Returns true on success.
    @discardableResult
    func replaceSpanSource(id: UUID, with newSource: String) -> Bool {
        guard let index = document.spans.firstIndex(where: { $0.id == id }) else {
            return false
        }
        let oldSpan = document.spans[index]
        // Reparse the new source so the call and the raw bytes are in sync
        guard let newCall = try? FormulaParser.parse(newSource) else { return false }

        // Splice the new source into rawText at the old span's range
        let ns = rawText as NSString
        let oldRange = NSRange(location: oldSpan.range.lowerBound,
                               length: oldSpan.range.upperBound - oldSpan.range.lowerBound)
        guard oldRange.location + oldRange.length <= ns.length else { return false }
        let newRawText = ns.replacingCharacters(in: oldRange, with: newSource)
        rawText = newRawText
        isDirty = true

        // Rebuild Document from the new raw text. We have to do this because
        // all subsequent span ranges shifted by the length delta.
        guard let newDoc = try? Document(rawMarkdown: newRawText) else { return false }
        // Preserve cached values on same-source spans; evaluate the changed one.
        var oldValues: [String: FormulaValue] = [:]
        for span in document.spans {
            if case .idle = span.value { continue }
            oldValues[span.source] = span.value
        }
        document = newDoc
        for (i, span) in document.spans.enumerated() {
            if let v = oldValues[span.source] {
                document.spans[i].value = v
            }
        }

        // Find the span that now matches newSource and kick off evaluation
        // without blocking the caller.
        if let newIndex = document.spans.firstIndex(where: { $0.source == newSource }) {
            Task { await evaluateIndices([newIndex]) }
        }
        _ = newCall
        return true
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
        let markdown = rawText

        // Phase 1: flatten every span's source (sync, on main) so nested
        // sub-calls are resolved into quoted literals BEFORE the runtime
        // runs. =upper(=ref(@intro)) becomes =upper("hello world") etc.
        var flattenedCalls: [(Int, String, FormulaCall)] = []
        for i in indices {
            guard i < snapshot.spans.count else { continue }
            let span = snapshot.spans[i]
            let rawSource = span.source
            let flattened = await NestedFormulaResolver.flatten(
                source: rawSource, in: markdown
            )
            guard let call = try? FormulaParser.parse(flattened) else {
                if i < document.spans.count, document.spans[i].source == rawSource {
                    document.spans[i].value = .error(message: "parse error: \(flattened)")
                }
                continue
            }
            flattenedCalls.append((i, rawSource, call))
        }

        // Phase 2: run the flattened calls through the runtime (or handle
        // =ref standalone).
        await withTaskGroup(of: (Int, String, FormulaValue).self) { group in
            for (i, rawSource, call) in flattenedCalls {
                // Standalone =ref at the top level (not inside another call)
                if case .ref(let anchor) = call {
                    let resolved: FormulaValue
                    if let text = NamedAnchorResolver.resolve(anchor, in: markdown) {
                        resolved = .ready(text: text.trimmingCharacters(in: .whitespacesAndNewlines))
                    } else {
                        resolved = .error(message: "ref: no heading named @\(anchor)")
                    }
                    if i < document.spans.count, document.spans[i].source == rawSource {
                        document.spans[i].value = resolved
                    }
                    continue
                }

                group.addTask { [runtime] in
                    var last: FormulaValue = .idle
                    do {
                        for try await value in runtime.evaluateStreaming(
                            call: call,
                            source: rawSource,
                            context: ""
                        ) {
                            last = value
                        }
                    } catch {
                        last = .error(message: error.localizedDescription)
                    }
                    return (i, rawSource, last)
                }
            }
            for await (i, originalSource, value) in group {
                guard i < document.spans.count else { continue }
                guard document.spans[i].source == originalSource else { continue }
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
