import SwiftUI

enum InlineFormulaRenderer {
    private static let backgroundColour = Color(red: 0.94, green: 0.98, blue: 0.93)
    private static let accentColour    = Color(red: 0.16, green: 0.49, blue: 0.22)
    private static let errorBackground = Color(red: 0.99, green: 0.93, blue: 0.93)

    static func render(_ document: Document) -> AttributedString {
        let sortedSpans = document.spans.sorted { $0.range.lowerBound < $1.range.lowerBound }
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
}
