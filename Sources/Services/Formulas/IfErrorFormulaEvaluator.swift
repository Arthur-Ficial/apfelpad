import Foundation

/// =IFERROR(value, fallback) — return `value`'s evaluated result if it
/// succeeds, otherwise return `fallback`. If `value` does not begin with
/// `=`, it is returned unchanged (no formula to evaluate).
///
/// This evaluator deliberately re-parses + re-evaluates its first argument
/// so it can catch errors that NestedFormulaResolver couldn't suppress
/// (those errors leave the sub-call source literal in place, which is what
/// gets passed in here).
enum IfErrorFormulaEvaluator {
    static func evaluate(value: String, fallback: String) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("=") else { return value }
        do {
            let call = try FormulaParser.parse(trimmed)
            return try FormulaSyncEvaluator.evaluate(call)
        } catch {
            return fallback
        }
    }
}
