import Foundation
import Observation

@Observable
@MainActor
final class DocumentViewModel {
    var document: Document = .empty
    var fileURL: URL?
    var isDirty: Bool = false
    private(set) var rawText: String = ""
    private(set) var insertionLocation: Int = 0
    var editingMode: EditingMode = .render
    private(set) var editorFocusToken: Int = 0
    private(set) var focusedInputName: String?
    private(set) var inputFocusToken: Int = 0

    private var runtime: FormulaRuntime
    private let store: DocumentPersistence
    private var debounceTask: Task<Void, Never>?
    private var autosaveTask: Task<Void, Never>?
    /// Document-level input variable bindings for =input / @name / =show.
    let bindings = InputBindings()

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
        insert(source, at: insertionLocation)
    }

    /// Insert source text at a specific UTF-16 offset in the raw markdown,
    /// keeping the inserted snippet separated as its own block.
    func insert(_ source: String, at location: Int) {
        let insertedSource = (try? FormulaParser.canonicalise(source)) ?? source
        let clampedLocation = max(0, min(location, (rawText as NSString).length))
        let prefix = prefixSeparator(forInsertionAt: clampedLocation)
        let suffix = suffixSeparator(forInsertionAt: clampedLocation)
        let replacement = prefix + insertedSource + suffix
        let ns = rawText as NSString
        let newText = ns.replacingCharacters(
            in: NSRange(location: clampedLocation, length: 0),
            with: replacement
        )
        rawText = newText
        insertionLocation = clampedLocation + (replacement as NSString).length
        isDirty = true
        if let doc = try? Document(rawMarkdown: newText) {
            document = doc
            Task { await evaluateAll() }
        }
    }

    /// Set a named input binding and re-evaluate every span that references
    /// it. This is the reactive state primitive: typing into an =input widget
    /// triggers a single call here which walks the document for @name
    /// mentions and re-runs only the dependent formulas.
    func setInputBinding(_ name: String, to value: String) {
        bindings.set(name, to: value)
        // Collect indices of spans whose source references @name
        var dependents: [Int] = []
        let lowered = name.lowercased()
        for (i, span) in document.spans.enumerated() {
            let refs = InputBindings.references(in: span.source)
            if refs.contains(lowered) {
                dependents.append(i)
            }
        }
        if !dependents.isEmpty {
            Task { await evaluateIndices(dependents) }
        }
    }

    func setInsertionLocation(_ location: Int) {
        insertionLocation = max(0, min(location, (rawText as NSString).length))
    }

    func setEditingMode(_ mode: EditingMode) {
        guard editingMode != mode else {
            requestEditorFocus()
            return
        }
        editingMode = mode
        flushPendingReparse()
        requestEditorFocus()
    }

    func requestEditorFocus() {
        editorFocusToken &+= 1
    }

    func focusFirstInput() {
        guard let first = inputNames.first else { return }
        focusInput(named: first)
    }

    func focusNextInput() {
        guard !inputNames.isEmpty else { return }
        guard let focusedInputName,
              let currentIndex = inputNames.firstIndex(of: focusedInputName) else {
            focusInput(named: inputNames[0])
            return
        }
        let nextIndex = (currentIndex + 1) % inputNames.count
        focusInput(named: inputNames[nextIndex])
    }

    func focusPreviousInput() {
        guard !inputNames.isEmpty else { return }
        guard let focusedInputName,
              let currentIndex = inputNames.firstIndex(of: focusedInputName) else {
            focusInput(named: inputNames[inputNames.count - 1])
            return
        }
        let previousIndex = (currentIndex - 1 + inputNames.count) % inputNames.count
        focusInput(named: inputNames[previousIndex])
    }

    func focusInput(named name: String) {
        focusedInputName = name.lowercased()
        editingMode = .render
        inputFocusToken &+= 1
    }

    func replaceText(in range: Range<Int>, with newText: String) {
        let ns = rawText as NSString
        let replacementRange = NSRange(
            location: range.lowerBound,
            length: range.upperBound - range.lowerBound
        )
        guard replacementRange.location >= 0,
              replacementRange.location + replacementRange.length <= ns.length else {
            return
        }
        rawText = ns.replacingCharacters(in: replacementRange, with: newText)
        insertionLocation = range.lowerBound + (newText as NSString).length
        isDirty = true
        reparseAndEvaluateChanged()
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
        let canonicalSource: String
        // Reparse the new source so the call and the raw bytes are in sync
        guard (try? FormulaParser.parse(newSource)) != nil else { return false }
        canonicalSource = (try? FormulaParser.canonicalise(newSource)) ?? newSource

        // Splice the new source into rawText at the old span's range
        let ns = rawText as NSString
        let oldRange = NSRange(location: oldSpan.range.lowerBound,
                               length: oldSpan.range.upperBound - oldSpan.range.lowerBound)
        guard oldRange.location + oldRange.length <= ns.length else { return false }
        let newRawText = ns.replacingCharacters(in: oldRange, with: canonicalSource)
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
        if let newIndex = document.spans.firstIndex(where: { $0.source == canonicalSource }) {
            Task { await evaluateIndices([newIndex]) }
        }
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
        reparseAndEvaluateChanged(canonicaliseSource: true)
    }

    // MARK: - Parsing

    func load(rawMarkdown: String) throws {
        rawText = rawMarkdown
        insertionLocation = (rawMarkdown as NSString).length
        self.document = try Document(rawMarkdown: rawMarkdown)
        requestEditorFocus()
    }

    private func reparseAndEvaluateChanged(canonicaliseSource: Bool = false) {
        let nextRawText = canonicaliseSource ? canonicaliseParseableSpans(in: rawText) : rawText
        if nextRawText != rawText {
            rawText = nextRawText
        }
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

    private func canonicaliseParseableSpans(in text: String) -> String {
        guard let discovered = try? Document(rawMarkdown: text), !discovered.spans.isEmpty else {
            return text
        }
        var working = text
        for span in discovered.spans.sorted(by: { $0.range.lowerBound > $1.range.lowerBound }) {
            guard let canonical = try? FormulaParser.canonicalise(span.source),
                  canonical != span.source else {
                continue
            }
            let ns = working as NSString
            let range = NSRange(
                location: span.range.lowerBound,
                length: span.range.upperBound - span.range.lowerBound
            )
            guard range.location >= 0, range.location + range.length <= ns.length else {
                continue
            }
            working = ns.replacingCharacters(in: range, with: canonical)
        }
        return working
    }

    private func prefixSeparator(forInsertionAt location: Int) -> String {
        guard !rawText.isEmpty, location > 0 else { return "" }
        let prefix = (rawText as NSString).substring(to: location)
        if prefix.hasSuffix("\n\n") { return "" }
        if prefix.hasSuffix("\n") { return "\n" }
        return "\n\n"
    }

    private func suffixSeparator(forInsertionAt location: Int) -> String {
        guard !rawText.isEmpty, location < (rawText as NSString).length else { return "" }
        let suffix = (rawText as NSString).substring(from: location)
        if suffix.hasPrefix("\n\n") { return "" }
        if suffix.hasPrefix("\n") { return "\n" }
        return "\n\n"
    }

    private var inputNames: [String] {
        document.spans.compactMap { span in
            guard case .input(let name, _, _) = span.call else { return nil }
            return name.lowercased()
        }
    }

    // MARK: - Evaluation

    func evaluateAll() async {
        await evaluateIndices(Array(document.spans.indices))
    }

    private func evaluateIndices(_ indices: [Int]) async {
        let snapshot = document
        let markdown = rawText

        // Phase 0: seed bindings from =input defaults BEFORE any dependent
        // formulas try to substitute @names. Otherwise a formula like
        // =math(@hours * 150) would see an empty @hours on first evaluation.
        for i in indices {
            guard i < snapshot.spans.count else { continue }
            let span = snapshot.spans[i]
            if let call = try? FormulaParser.parse(span.source),
               case .input(let name, _, let defaultValue) = call {
                if bindings.value(for: name) == nil, let def = defaultValue {
                    bindings.set(name, to: def)
                }
            }
        }

        // Phase 1: for each span, substitute @name bindings, then flatten
        // nested sub-calls, then parse.
        var flattenedCalls: [(Int, String, FormulaCall, String)] = []
        for i in indices {
            guard i < snapshot.spans.count else { continue }
            let span = snapshot.spans[i]
            let rawSource = span.source
            let refs = InputBindings.references(in: rawSource)
            let withBindings = bindings.substitute(in: rawSource)
            let flattened = await NestedFormulaResolver.flatten(
                source: withBindings, in: markdown
            )
            guard let call = try? FormulaParser.parse(flattened) else {
                if i < document.spans.count, document.spans[i].source == rawSource {
                    document.spans[i].value = .error(message: "parse error: \(flattened)")
                }
                continue
            }
            // Cache key source: the substituted form so changing bindings
            // invalidates. Fall back to raw source when no @ refs exist.
            let runtimeSource = refs.isEmpty ? rawSource : withBindings
            flattenedCalls.append((i, rawSource, call, runtimeSource))
        }

        // Phase 2: run the flattened calls through the runtime (or handle
        // =ref / =input / =show directly at the document layer).
        await withTaskGroup(of: (Int, String, FormulaValue).self) { group in
            for (i, rawSource, call, runtimeSource) in flattenedCalls {
                // =input — render the current binding value (or the default)
                if case .input(let name, _, let defaultValue) = call {
                    let current = bindings.value(for: name) ?? defaultValue ?? ""
                    if bindings.value(for: name) == nil, let def = defaultValue {
                        bindings.set(name, to: def)
                    }
                    if i < document.spans.count, document.spans[i].source == rawSource {
                        document.spans[i].value = .ready(text: current)
                    }
                    continue
                }
                if case .show = call {
                    // Extract variable name from the RAW source (before @name
                    // substitution), not from the parsed call — otherwise
                    // =show(@hours) becomes =show(120) after substitution and
                    // we'd look up "120" instead of "hours".
                    let showName: String
                    if let rawCall = try? FormulaParser.parse(rawSource),
                       case .show(let n) = rawCall {
                        showName = n
                    } else if case .show(let n) = call {
                        showName = n
                    } else {
                        continue
                    }
                    let current = bindings.value(for: showName) ?? "(no value)"
                    if i < document.spans.count, document.spans[i].source == rawSource {
                        document.spans[i].value = .ready(text: current)
                    }
                    continue
                }
                if case .ref(let anchor) = call {
                    let resolved: FormulaValue
                    if let text = NamedAnchorResolver.resolve(anchor, in: markdown) {
                        resolved = .ready(text: text.trimmingCharacters(in: .whitespacesAndNewlines))
                    } else {
                        resolved = .error(message: "ref: no heading named @#\(anchor)")
                    }
                    if i < document.spans.count, document.spans[i].source == rawSource {
                        document.spans[i].value = resolved
                    }
                    continue
                }
                if case .count(let anchor) = call {
                    let text = CountFormulaEvaluator.evaluate(anchor: anchor, in: markdown)
                    if i < document.spans.count, document.spans[i].source == rawSource {
                        document.spans[i].value = .ready(text: text)
                    }
                    continue
                }

                // Use the substituted source as the cache key so rebinding
                // an @name invalidates the previous cached result.
                let cacheKeySource = runtimeSource
                group.addTask { [runtime] in
                    var last: FormulaValue = .idle
                    do {
                        for try await value in runtime.evaluateStreaming(
                            call: call,
                            source: cacheKeySource,
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

    func newDocument() {
        fileURL = nil
        isDirty = false
        bindings.clear()
        try? load(rawMarkdown: "")
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
