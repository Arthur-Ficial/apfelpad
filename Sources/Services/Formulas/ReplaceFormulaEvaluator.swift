import Foundation

enum ReplaceFormulaEvaluator {
    /// Substitute the first occurrence of `find` with `replacement` in `text`.
    /// Returns `text` unchanged if no match.
    static func evaluate(text: String, find: String, replacement: String) throws -> String {
        guard let range = text.range(of: find) else { return text }
        return text.replacingCharacters(in: range, with: replacement)
    }
}
