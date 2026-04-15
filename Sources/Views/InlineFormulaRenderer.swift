import SwiftUI
import CryptoKit

/// Converts a `Document` into an `AttributedString` with inline styled runs
/// for every formula span. A memoization layer avoids rebuilding the attributed
/// string when the document's rendering-relevant state is unchanged.
enum InlineFormulaRenderer {
    // MARK: - Cache

    /// Single-entry memo — we only need the most-recent render because the
    /// UI only ever renders one document at a time. Lock-protected so
    /// tests off the main actor can use it.
    private final class Memo: @unchecked Sendable {
        var key: String?
        var value: AttributedString?
        let lock = NSLock()
    }
    private static let memo = Memo()

    static func render(_ document: Document) -> AttributedString {
        let key = identityHash(for: document)
        memo.lock.lock()
        if memo.key == key, let cached = memo.value {
            memo.lock.unlock()
            return cached
        }
        memo.lock.unlock()
        let built = buildAttributedString(for: document)
        memo.lock.lock()
        memo.key = key
        memo.value = built
        memo.lock.unlock()
        return built
    }

    /// Identity key that only changes when something rendering-relevant
    /// actually changes: the raw text or any span's value. Span IDs are
    /// included so re-parsing triggers a cache miss.
    static func identityHash(for document: Document) -> String {
        var hasher = SHA256()
        hasher.update(data: Data(document.rawMarkdown.utf8))
        for span in document.spans {
            hasher.update(data: Data(span.id.uuidString.utf8))
            hasher.update(data: Data("\u{1e}".utf8))
            hasher.update(data: Data(span.displayText.utf8))
            // Include value type so stale/error states flip correctly
            hasher.update(data: Data(stateTag(span.value).utf8))
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private static func stateTag(_ v: FormulaValue) -> String {
        switch v {
        case .idle: return "i"
        case .evaluating: return "e"
        case .streaming: return "s"
        case .ready: return "r"
        case .stale: return "t"
        case .error: return "x"
        }
    }

    // MARK: - Build

    static func buildAttributedString(for document: Document) -> AttributedString {
        let sortedSpans = document.spansInSourceOrder
        let chars = Array(document.rawMarkdown)
        var cursor = 0
        var out = AttributedString("")

        for span in sortedSpans {
            if span.range.lowerBound > cursor {
                out.append(AttributedString(String(chars[cursor..<span.range.lowerBound])))
            }
            out.append(styled(for: span))
            cursor = span.range.upperBound
        }
        if cursor < chars.count {
            out.append(AttributedString(String(chars[cursor...])))
        }
        return out
    }

    private static func styled(for span: FormulaSpan) -> AttributedString {
        let displayText = span.displayText
        var piece = AttributedString(" \(displayText) ")
        piece.backgroundColor = AppTheme.formulaChipBackground(for: span)
        piece.foregroundColor = AppTheme.formulaChipForeground(for: span)
        // Every span gets a link pointing at its UUID so clicks route through
        // SwiftUI's environment(\.openURL) handler in DocumentView. The link
        // attribute also makes SwiftUI automatically show the pointing-hand
        // cursor on hover, which is the identity we want.
        piece.link = URL(string: "apfelpad://span/\(span.id.uuidString)")
        return piece
    }
}
