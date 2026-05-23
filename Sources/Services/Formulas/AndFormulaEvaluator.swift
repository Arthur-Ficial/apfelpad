import Foundation

/// =AND(expr1, expr2, …) — TRUE if every argument is truthy.
enum AndFormulaEvaluator {
    static func evaluate(_ args: [String]) -> String {
        guard !args.isEmpty else { return "FALSE" }
        return args.allSatisfy { IfFormulaEvaluator.isTruthy($0) } ? "TRUE" : "FALSE"
    }
}
