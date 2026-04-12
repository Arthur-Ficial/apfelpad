import Foundation

enum SubstituteFormulaEvaluator {
    /// Substitute occurrences of `find` with `replacement` in `text`.
    /// - `occurrence: nil` — replace the first occurrence (default)
    /// - `occurrence: 0` — replace ALL occurrences
    /// - `occurrence: N` (positive) — replace only the Nth occurrence
    /// Returns `text` unchanged if no match.
    static func evaluate(text: String, find: String, replacement: String, occurrence: Int? = nil) throws -> String {
        switch occurrence {
        case nil:
            // Replace the first occurrence (default behaviour)
            guard let range = text.range(of: find) else { return text }
            return text.replacingCharacters(in: range, with: replacement)

        case 0:
            // Replace ALL occurrences
            return text.replacingOccurrences(of: find, with: replacement)

        case let n? where n > 0:
            // Replace only the Nth occurrence
            var searchStart = text.startIndex
            var matchCount = 0
            while searchStart < text.endIndex,
                  let range = text.range(of: find, range: searchStart..<text.endIndex) {
                matchCount += 1
                if matchCount == n {
                    return text.replacingCharacters(in: range, with: replacement)
                }
                searchStart = range.upperBound
            }
            // Nth occurrence not found — return unchanged
            return text

        default:
            // Negative values: return unchanged
            return text
        }
    }
}
