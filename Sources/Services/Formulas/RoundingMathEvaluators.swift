import Foundation

/// Phase 3 rounding math: ROUND, ROUNDUP, ROUNDDOWN, CEILING, FLOOR, LOG.
enum RoundFormulaEvaluator {
    static func evaluate(value: String, places: Int) throws -> String {
        let n = try parseR(value, name: "ROUND")
        let m = pow(10.0, Double(places))
        return SumFormulaEvaluator.format((n * m).rounded() / m)
    }
}

enum RoundUpFormulaEvaluator {
    /// Away from zero, per Google Sheets ROUNDUP semantics.
    static func evaluate(value: String, places: Int) throws -> String {
        let n = try parseR(value, name: "ROUNDUP")
        let m = pow(10.0, Double(places))
        let rule: FloatingPointRoundingRule = n >= 0 ? .up : .down
        return SumFormulaEvaluator.format((n * m).rounded(rule) / m)
    }
}

enum RoundDownFormulaEvaluator {
    /// Toward zero.
    static func evaluate(value: String, places: Int) throws -> String {
        let n = try parseR(value, name: "ROUNDDOWN")
        let m = pow(10.0, Double(places))
        return SumFormulaEvaluator.format((n * m).rounded(.towardZero) / m)
    }
}

enum CeilingFormulaEvaluator {
    enum Error: Swift.Error, LocalizedError {
        case factorZero
        var errorDescription: String? { "CEILING: factor must not be zero" }
    }
    static func evaluate(value: String, factor: Double) throws -> String {
        let n = try parseR(value, name: "CEILING")
        if factor == 0 { throw Error.factorZero }
        return SumFormulaEvaluator.format((n / factor).rounded(.up) * factor)
    }
}

enum FloorFormulaEvaluator {
    enum Error: Swift.Error, LocalizedError {
        case factorZero
        var errorDescription: String? { "FLOOR: factor must not be zero" }
    }
    static func evaluate(value: String, factor: Double) throws -> String {
        let n = try parseR(value, name: "FLOOR")
        if factor == 0 { throw Error.factorZero }
        return SumFormulaEvaluator.format((n / factor).rounded(.down) * factor)
    }
}

enum LogFormulaEvaluator {
    /// =LOG(value, [base=10]) — logarithm of `value` to `base`.
    static func evaluate(value: String, base: Double) throws -> String {
        let n = try parseR(value, name: "LOG")
        return SumFormulaEvaluator.format(log(n) / log(base))
    }
}

private func parseR(_ s: String, name: String) throws -> Double {
    let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let n = Double(t) else {
        throw SumFormulaEvaluator.Error.notANumber("\(name): \(t)")
    }
    return n
}
