import Foundation

/// =PROPER(text) — Capitalises the first letter of each space-separated
/// token and lowercases the rest. Preserves the original whitespace runs.
enum ProperFormulaEvaluator {
    static func evaluate(_ text: String) -> String {
        // Split on whitespace boundaries while preserving the whitespace runs.
        // Build the result character-by-character.
        var out = ""
        var atWordStart = true
        for ch in text {
            if ch.isWhitespace {
                out.append(ch)
                atWordStart = true
            } else if atWordStart {
                out.append(Character(String(ch).uppercased()))
                atWordStart = false
            } else {
                out.append(Character(String(ch).lowercased()))
            }
        }
        return out
    }
}
