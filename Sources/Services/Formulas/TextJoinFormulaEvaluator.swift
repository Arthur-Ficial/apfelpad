import Foundation

/// =TEXTJOIN(delim, ignore_empty, text1, text2, …) — join text args with
/// `delim`, optionally skipping empty strings.
enum TextJoinFormulaEvaluator {
    static func evaluate(delim: String, ignoreEmpty: Bool, parts: [String]) -> String {
        let kept = ignoreEmpty ? parts.filter { !$0.isEmpty } : parts
        return kept.joined(separator: delim)
    }
}
