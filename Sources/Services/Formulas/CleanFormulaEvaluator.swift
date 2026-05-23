import Foundation

/// =CLEAN(text) — strip ASCII control characters 0-31 (includes tab and
/// newline). Higher Unicode codepoints are preserved unchanged.
enum CleanFormulaEvaluator {
    static func evaluate(_ text: String) -> String {
        text.unicodeScalars.filter { $0.value >= 32 }.map { String($0) }.joined()
    }
}
