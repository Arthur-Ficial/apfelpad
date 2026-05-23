import Foundation

/// =NOT(expr) — TRUE if the argument is falsy, FALSE if truthy.
enum NotFormulaEvaluator {
    static func evaluate(_ value: String) -> String {
        IfFormulaEvaluator.isTruthy(value) ? "FALSE" : "TRUE"
    }
}
