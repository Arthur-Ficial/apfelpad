import Foundation

/// Pure, View-free helper that rewrites raw markdown so every non-input
/// formula span is replaced with a clickable inline-code markdown link:
///
///     =math(365*24)  →  [`8760`](apfelpad://span/<uuid>)
///
/// MarkdownUI renders the link via SwiftUI's `environment(\.openURL)`
/// handler, which routes to `SpanClickRouter` and opens the formula in
/// the formula bar. The inline code wrapper keeps the pale-green /
/// dark-green identity of a formula span.
///
/// Separated from `DocumentBodyView` so the behaviour can be unit-tested
/// without a SwiftUI host. This is the single source of truth for "how
/// formulas look in rendered markdown" — DocumentBodyView is just the
/// display surface.
enum DocumentBodySubstitution {

    /// Replace every non-input formula source in the raw markdown with
    /// a clickable inline-code link pointing at its span UUID.
    ///
    /// - Parameters:
    ///   - rawMarkdown: the full document text.
    ///   - spans: the evaluated spans from the same document.
    /// - Returns: a markdown string safe to hand to MarkdownUI.
    static func substitute(rawMarkdown: String, spans: [FormulaSpan]) -> String {
        substitute(
            slice: rawMarkdown,
            sliceStart: 0,
            spans: spans
        )
    }

    /// Slice-scoped variant. Used by `DocumentBodyView` when it splits
    /// the document into prose paragraphs and =input widget paragraphs;
    /// each prose slice is substituted independently.
    static func substitute(
        slice: String,
        sliceStart: Int,
        spans: [FormulaSpan]
    ) -> String {
        let sliceEnd = sliceStart + (slice as NSString).length
        // Keep every non-input span that lies entirely inside this slice.
        // Walk them from rightmost to leftmost so splicing doesn't shift
        // the ranges of later spans.
        let inSlice = spans.filter { span in
            if case .input = span.call { return false }
            return span.range.lowerBound >= sliceStart
                && span.range.upperBound <= sliceEnd
        }.sorted { $0.range.lowerBound > $1.range.lowerBound }

        var working = slice as NSString
        for span in inSlice {
            let local = NSRange(
                location: span.range.lowerBound - sliceStart,
                length: span.range.upperBound - span.range.lowerBound
            )
            guard local.location >= 0,
                  local.location + local.length <= working.length else { continue }
            let token = inlineToken(for: span)
            working = working.replacingCharacters(in: local, with: token) as NSString
        }
        return working as String
    }

    /// Build the clickable inline-code markdown token for one span.
    static func inlineToken(for span: FormulaSpan) -> String {
        let text = displayText(for: span)
        // Backticks inside inline code break the wrapper — replace with
        // apostrophes so the markdown stays well-formed. Formula values
        // rarely contain backticks but we handle it for safety.
        let safeText = text.replacingOccurrences(of: "`", with: "'")
        // Parentheses and square brackets inside the link label are
        // legal, but we strip any literal `]` or `)` from the VALUE to
        // avoid closing the markdown link early.
        let linkSafe = safeText
            .replacingOccurrences(of: "]", with: " ")
            .replacingOccurrences(of: ")", with: " ")
        let url = "apfelpad://span/\(span.id.uuidString)"
        return "[`\(linkSafe)`](\(url))"
    }

    /// The user-visible text for a span — mirrors `FormulaSpan.displayText`
    /// but lives here so the substitution module is self-contained.
    static func displayText(for span: FormulaSpan) -> String {
        span.displayText
    }
}
