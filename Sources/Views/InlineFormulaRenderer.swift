import SwiftUI

/// Converts a `Document` into an `AttributedString` where every formula span's
/// source text is replaced by its rendered value (or a placeholder during
/// evaluation/streaming), with a pale-green background and dark-green accent
/// run for visual identity.
enum InlineFormulaRenderer {
    private static let backgroundColour = Color(red: 0.94, green: 0.98, blue: 0.93)
    private static let accentColour    = Color(red: 0.16, green: 0.49, blue: 0.22)
    private static let errorBackground = Color(red: 0.99, green: 0.93, blue: 0.93)

    static func render(_ document: Document) -> AttributedString {
        // Walk the raw markdown, emit a plain segment for everything outside
        // a span range and a styled segment for everything inside one.
        let sortedSpans = document.spans.sorted { $0.range.lowerBound < $1.range.lowerBound }
        var cursor = 0
        let text = document.rawMarkdown
        var out = AttributedString("")

        for span in sortedSpans {
            if span.range.lowerBound > cursor {
                let slice = substring(text, from: cursor, to: span.range.lowerBound)
                out.append(AttributedString(slice))
            }
            out.append(styled(for: span))
            cursor = span.range.upperBound
        }
        if cursor < (text as NSString).length {
            let slice = substring(text, from: cursor, to: (text as NSString).length)
            out.append(AttributedString(slice))
        }
        return out
    }

    private static func styled(for span: FormulaSpan) -> AttributedString {
        let displayText = FormulaSpanView.displayText(for: span)
        var piece = AttributedString(" \(displayText) ")

        switch span.value {
        case .error:
            piece.backgroundColor = errorBackground
            piece.foregroundColor = .red
        default:
            piece.backgroundColor = backgroundColour
            piece.foregroundColor = accentColour
        }
        return piece
    }

    private static func substring(_ source: String, from: Int, to: Int) -> String {
        let ns = source as NSString
        let loc = max(0, from)
        let len = max(0, min(ns.length, to) - loc)
        return ns.substring(with: NSRange(location: loc, length: len))
    }
}
