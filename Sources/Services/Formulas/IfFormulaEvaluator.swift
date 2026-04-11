import Foundation

enum IfFormulaEvaluator {
    /// Truthy-test a condition string. Empty, "0", "false" (case-insensitive),
    /// and "no" (case-insensitive) are falsy; everything else is truthy.
    static func evaluate(cond: String, thenValue: String, elseValue: String) throws -> String {
        isTruthy(cond) ? thenValue : elseValue
    }

    static func isTruthy(_ s: String) -> Bool {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return false }
        let lower = trimmed.lowercased()
        if lower == "false" || lower == "no" || lower == "0" { return false }
        return true
    }
}
