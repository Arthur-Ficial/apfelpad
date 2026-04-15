import AppKit

/// Builds the attributed text shown in render mode.
/// Typography is applied once over the full visible document, then formula and
/// input segments layer their own styling on top.
@MainActor
enum RenderAttributedStringBuilder {
    static func build(from projection: RenderProjection) -> NSAttributedString {
        let out = NSMutableAttributedString(string: projection.visibleText, attributes: [
            .font: NSFont.systemFont(ofSize: 15),
            .foregroundColor: NSColor.labelColor,
        ])

        applyTypography(to: out)

        for segment in projection.segments {
            let visibleRange = NSRange(
                location: segment.visibleRange.lowerBound,
                length: segment.visibleRange.upperBound - segment.visibleRange.lowerBound
            )

            switch segment.kind {
            case .plain:
                continue
            case .formula(let span):
                out.addAttributes(renderAttributes(for: span), range: visibleRange)
                out.addAttribute(
                    .link,
                    value: URL(string: "apfelpad://span/\(span.id.uuidString)") as Any,
                    range: visibleRange
                )
            case .input:
                out.addAttributes([
                    .foregroundColor: NSColor.clear,
                    .backgroundColor: NSColor.clear,
                ], range: visibleRange)
            }
        }

        return out
    }

    private static func applyTypography(to text: NSMutableAttributedString) {
        let ns = text.string as NSString
        var paragraphStart = 0

        while paragraphStart < ns.length {
            let paragraphRange = ns.paragraphRange(for: NSRange(location: paragraphStart, length: 0))
            let paragraph = ns.substring(with: paragraphRange)

            if paragraph.hasPrefix("# ") {
                hideMarkdownPrefix(in: text, paragraphRange: paragraphRange, prefixLength: 2)
                text.addAttributes([
                    .font: NSFont.systemFont(ofSize: 28, weight: .bold),
                ], range: NSRange(location: paragraphRange.location + 2, length: max(0, paragraphRange.length - 2)))
            } else if paragraph.hasPrefix("## ") {
                hideMarkdownPrefix(in: text, paragraphRange: paragraphRange, prefixLength: 3)
                text.addAttributes([
                    .font: NSFont.systemFont(ofSize: 22, weight: .semibold),
                ], range: NSRange(location: paragraphRange.location + 3, length: max(0, paragraphRange.length - 3)))
            } else if paragraph.hasPrefix("### ") {
                hideMarkdownPrefix(in: text, paragraphRange: paragraphRange, prefixLength: 4)
                text.addAttributes([
                    .font: NSFont.systemFont(ofSize: 18, weight: .semibold),
                ], range: NSRange(location: paragraphRange.location + 4, length: max(0, paragraphRange.length - 4)))
            }

            let nextParagraphStart = paragraphRange.location + paragraphRange.length
            if nextParagraphStart <= paragraphStart { break }
            paragraphStart = nextParagraphStart
        }
    }

    private static func hideMarkdownPrefix(
        in text: NSMutableAttributedString,
        paragraphRange: NSRange,
        prefixLength: Int
    ) {
        guard paragraphRange.length >= prefixLength else { return }
        text.addAttributes([
            .foregroundColor: NSColor.clear,
            .font: NSFont.systemFont(ofSize: 1),
        ], range: NSRange(location: paragraphRange.location, length: prefixLength))
    }

    private static func renderAttributes(for span: FormulaSpan) -> [NSAttributedString.Key: Any] {
        return [
            .backgroundColor: AppTheme.formulaChipBackgroundNSColor(for: span),
            .foregroundColor: AppTheme.formulaChipForegroundNSColor(for: span),
            .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .semibold),
            .cursor: NSCursor.pointingHand,
        ]
    }
}
