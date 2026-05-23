import Foundation

/// =OR(expr1, expr2, …) — TRUE if any argument is truthy.
enum OrFormulaEvaluator {
    static func evaluate(_ args: [String]) -> String {
        args.contains { IfFormulaEvaluator.isTruthy($0) } ? "TRUE" : "FALSE"
    }
}
