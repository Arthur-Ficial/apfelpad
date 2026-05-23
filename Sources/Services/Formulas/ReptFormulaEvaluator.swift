import Foundation

/// =REPT(text, n) — text repeated n times. Negative n returns "".
enum ReptFormulaEvaluator {
    static func evaluate(text: String, n: Int) -> String {
        guard n > 0 else { return "" }
        return String(repeating: text, count: n)
    }
}
