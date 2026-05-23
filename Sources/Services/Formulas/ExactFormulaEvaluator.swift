import Foundation

/// =EXACT(a, b) — case-sensitive string equality as "TRUE" / "FALSE".
enum ExactFormulaEvaluator {
    static func evaluate(a: String, b: String) -> String {
        a == b ? "TRUE" : "FALSE"
    }
}
