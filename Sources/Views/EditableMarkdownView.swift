import SwiftUI
import AppKit

/// An editable NSTextView wrapped for SwiftUI. Renders the document's raw
/// markdown with pale-green highlighting on every formula span's source
/// range. Fully editable — typing, backspace, paste, cut, drag-and-drop
/// text, all flow back through `text` binding.
///
/// This is the v0.5.1 answer to "Markdown mode must be editable" — it's
/// a single view that is BOTH a preview (you see the formulas highlighted
/// in pale green) AND a real text editor (you can put the cursor anywhere
/// and type).
struct EditableMarkdownView: NSViewRepresentable {
    @Binding var text: String
    let document: Document

    // Visual palette — matches FormulaSpanView / InlineFormulaRenderer.
    private static let paleGreen = NSColor(red: 0.94, green: 0.98, blue: 0.93, alpha: 1)
    private static let darkGreen = NSColor(red: 0.16, green: 0.49, blue: 0.22, alpha: 1)
    private static let errorBg   = NSColor(red: 0.99, green: 0.93, blue: 0.93, alpha: 1)

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSTextView.scrollableTextView()
        scroll.hasVerticalScroller = true
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.drawsBackground = false

        guard let tv = scroll.documentView as? NSTextView else { return scroll }
        tv.isEditable = true
        tv.isRichText = true
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.isAutomaticTextReplacementEnabled = false
        tv.allowsUndo = true
        tv.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        tv.textContainerInset = NSSize(width: 20, height: 20)
        tv.delegate = context.coordinator
        tv.usesFindBar = true
        tv.registerForDraggedTypes([.string, .URL])
        // Drag-and-drop: NSTextView accepts text drops natively
        context.coordinator.textView = tv
        applyText(tv, text: text)
        applyHighlighting(tv)
        return scroll
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let tv = scrollView.documentView as? NSTextView else { return }
        if tv.string != text {
            applyText(tv, text: text)
        }
        applyHighlighting(tv)
    }

    private func applyText(_ tv: NSTextView, text: String) {
        let ranges = tv.selectedRanges
        tv.string = text
        // Restore selection (clamped)
        let maxLen = tv.string.count
        let clamped = ranges.compactMap { rv -> NSValue? in
            var r = rv.rangeValue
            if r.location > maxLen { r.location = maxLen }
            if r.location + r.length > maxLen { r.length = max(0, maxLen - r.location) }
            return NSValue(range: r)
        }
        tv.selectedRanges = clamped
    }

    private func applyHighlighting(_ tv: NSTextView) {
        guard let storage = tv.textStorage else { return }
        let fullRange = NSRange(location: 0, length: storage.length)
        storage.beginEditing()

        // Base typography
        storage.setAttributes([
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor.labelColor,
        ], range: fullRange)

        // Per-span highlighting — pale green background + dark green foreground
        for span in document.spans {
            let r = NSRange(
                location: span.range.lowerBound,
                length: max(0, span.range.upperBound - span.range.lowerBound)
            )
            guard r.location >= 0, r.location + r.length <= storage.length else { continue }

            let isError: Bool
            if case .error = span.value { isError = true } else { isError = false }

            storage.addAttributes([
                .backgroundColor: isError ? Self.errorBg : Self.paleGreen,
                .foregroundColor: isError ? NSColor.systemRed : Self.darkGreen,
                .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold),
            ], range: r)
        }

        storage.endEditing()
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: EditableMarkdownView
        weak var textView: NSTextView?

        init(_ parent: EditableMarkdownView) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string
        }
    }
}
