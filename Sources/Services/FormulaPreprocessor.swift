import Foundation

/// Normalises raw user input before the parser sees it.
/// Responsibilities:
///   1. Straighten smart/curly quotes that macOS auto-substitutes.
///   2. Expand the anonymous `=(...)` shortcut to `=apfel(...)`.
///
/// Kept tiny and pure so it can be unit-tested in isolation.
enum FormulaPreprocessor {
    static func normalize(_ source: String) -> String {
        straightenQuotes(expandAnonymous(source))
    }

    /// Replace curly/smart quotes with their ASCII equivalents so the parser's
    /// string-literal recogniser (which checks for plain `"`) works.
    static func straightenQuotes(_ source: String) -> String {
        var out = source
        out = out.replacingOccurrences(of: "\u{201C}", with: "\"")  // LEFT DOUBLE
        out = out.replacingOccurrences(of: "\u{201D}", with: "\"")  // RIGHT DOUBLE
        out = out.replacingOccurrences(of: "\u{201E}", with: "\"")  // DOUBLE LOW-9 (German)
        out = out.replacingOccurrences(of: "\u{2018}", with: "'")   // LEFT SINGLE
        out = out.replacingOccurrences(of: "\u{2019}", with: "'")   // RIGHT SINGLE
        return out
    }

    /// Expand the anonymous `=(...)` shortcut to `=apfel(...)`. Only rewrites
    /// the top-level form — does not touch nested calls (which already have
    /// their own function name).
    static func expandAnonymous(_ source: String) -> String {
        let trimmed = source.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("=(") {
            // Keep any surrounding whitespace the caller had
            let leadingWhitespace = source.prefix { $0.isWhitespace }
            let trailingWhitespace = source.reversed().prefix { $0.isWhitespace }
            let rewritten = "=apfel(" + String(trimmed.dropFirst(2))
            return String(leadingWhitespace) + rewritten + String(trailingWhitespace.reversed())
        }
        return source
    }
}
