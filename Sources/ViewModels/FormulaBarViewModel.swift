import Foundation
import Observation

/// State and behavior for the Excel-style formula bar at the top of the window.
/// Editing `sourceText` is debounced-committed back to the document via the
/// `onCommit` callback so typing gives non-blocking real-time feedback.
@Observable
@MainActor
final class FormulaBarViewModel {
    enum EditState: Equatable {
        case idle
        case valid
        case invalid(message: String)
    }

    var sourceText: String = "" {
        didSet {
            // Only fire on user typing, not on programmatic .select()
            if applyingSelection { return }
            scheduleCommit()
        }
    }
    var selectedSpanID: UUID? = nil
    var editState: EditState = .idle
    let placeholder: String = "click a formula span to edit its source"

    /// Callback that replaces the selected span in the document with the
    /// new source. Returns true if the replacement succeeded (parseable +
    /// span still exists), false otherwise.
    var onCommit: ((UUID, String) -> Bool)? = nil

    private var applyingSelection = false
    private var commitTask: Task<Void, Never>?

    func select(_ span: FormulaSpan) {
        applyingSelection = true
        selectedSpanID = span.id
        sourceText = span.source
        editState = .valid
        applyingSelection = false
    }

    func clear() {
        applyingSelection = true
        selectedSpanID = nil
        sourceText = ""
        editState = .idle
        applyingSelection = false
    }

    /// Immediate commit — call this from the TextField's onSubmit handler.
    func commitNow() {
        commitTask?.cancel()
        commitTask = nil
        applyCommit()
    }

    private func scheduleCommit() {
        commitTask?.cancel()
        commitTask = Task {
            try? await Task.sleep(for: .milliseconds(120))
            guard !Task.isCancelled else { return }
            applyCommit()
        }
    }

    private func applyCommit() {
        guard let id = selectedSpanID else {
            editState = .idle
            return
        }
        // Pre-validate by parsing. If parsing fails, we mark invalid but do
        // not touch the document — so partial typing never destroys text.
        do {
            _ = try FormulaParser.parse(sourceText)
        } catch {
            editState = .invalid(message: "\(error)")
            return
        }
        let applied = onCommit?(id, sourceText) ?? false
        editState = applied ? .valid : .invalid(message: "span not found")
    }
}
