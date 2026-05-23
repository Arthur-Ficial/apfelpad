import Foundation

/// Phase 3 variadic math: MAX, MIN, PRODUCT. Pattern matches SUM/AVERAGE —
/// each evaluator parses args as `Double` and uses `SumFormulaEvaluator.format`.
enum MaxFormulaEvaluator {
    static func evaluate(_ args: [String]) throws -> String {
        let nums = try parseAll(args, name: "MAX")
        guard let m = nums.max() else { throw SumFormulaEvaluator.Error.notANumber("MAX: empty args") }
        return SumFormulaEvaluator.format(m)
    }
}

enum MinFormulaEvaluator {
    static func evaluate(_ args: [String]) throws -> String {
        let nums = try parseAll(args, name: "MIN")
        guard let m = nums.min() else { throw SumFormulaEvaluator.Error.notANumber("MIN: empty args") }
        return SumFormulaEvaluator.format(m)
    }
}

enum ProductFormulaEvaluator {
    static func evaluate(_ args: [String]) throws -> String {
        let nums = try parseAll(args, name: "PRODUCT")
        let p = nums.reduce(1.0, *)
        return SumFormulaEvaluator.format(p)
    }
}

private func parseAll(_ args: [String], name: String) throws -> [Double] {
    try args.map { raw in
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let n = Double(t) else { throw SumFormulaEvaluator.Error.notANumber("\(name): \(t)") }
        return n
    }
}
