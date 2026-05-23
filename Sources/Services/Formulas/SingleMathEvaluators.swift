import Foundation

/// Phase 3 single-argument math: ABS, SQRT, INT, SIGN, EVEN, ODD, FACT,
/// LN, LOG10, EXP. Each takes one numeric string and returns one formatted
/// number string.
enum AbsFormulaEvaluator {
    static func evaluate(_ value: String) throws -> String {
        let n = try parseDouble(value, name: "ABS")
        return SumFormulaEvaluator.format(abs(n))
    }
}

enum SqrtFormulaEvaluator {
    enum Error: Swift.Error, LocalizedError {
        case negative(Double)
        var errorDescription: String? { "SQRT: cannot take square root of a negative number" }
    }
    static func evaluate(_ value: String) throws -> String {
        let n = try parseDouble(value, name: "SQRT")
        if n < 0 { throw Error.negative(n) }
        return SumFormulaEvaluator.format(n.squareRoot())
    }
}

enum IntFormulaEvaluator {
    static func evaluate(_ value: String) throws -> String {
        let n = try parseDouble(value, name: "INT")
        return SumFormulaEvaluator.format(n.rounded(.towardZero))
    }
}

enum SignFormulaEvaluator {
    static func evaluate(_ value: String) throws -> String {
        let n = try parseDouble(value, name: "SIGN")
        if n > 0 { return "1" }
        if n < 0 { return "-1" }
        return "0"
    }
}

enum EvenFormulaEvaluator {
    static func evaluate(_ value: String) throws -> String {
        let n = try parseDouble(value, name: "EVEN")
        // Round magnitude up to the nearest even integer, keep the sign.
        let mag = abs(n)
        let ceilMag = mag.rounded(.up)
        var even = ceilMag.truncatingRemainder(dividingBy: 2) == 0 ? ceilMag : ceilMag + 1
        if n < 0 { even = -even }
        return SumFormulaEvaluator.format(even)
    }
}

enum OddFormulaEvaluator {
    static func evaluate(_ value: String) throws -> String {
        let n = try parseDouble(value, name: "ODD")
        let mag = abs(n)
        let ceilMag = mag.rounded(.up)
        var odd = ceilMag.truncatingRemainder(dividingBy: 2) == 1 ? ceilMag : ceilMag + 1
        if n < 0 { odd = -odd }
        return SumFormulaEvaluator.format(odd)
    }
}

enum FactFormulaEvaluator {
    enum Error: Swift.Error, LocalizedError {
        case negative
        case notInteger
        var errorDescription: String? {
            switch self {
            case .negative: return "FACT: argument must be >= 0"
            case .notInteger: return "FACT: argument must be a whole number"
            }
        }
    }
    static func evaluate(_ value: String) throws -> String {
        let n = try parseDouble(value, name: "FACT")
        if n < 0 { throw Error.negative }
        if n.truncatingRemainder(dividingBy: 1) != 0 { throw Error.notInteger }
        var result: Double = 1
        var i: Double = 2
        while i <= n {
            result *= i
            i += 1
        }
        return SumFormulaEvaluator.format(result)
    }
}

enum LnFormulaEvaluator {
    static func evaluate(_ value: String) throws -> String {
        let n = try parseDouble(value, name: "LN")
        return SumFormulaEvaluator.format(log(n))
    }
}

enum Log10FormulaEvaluator {
    static func evaluate(_ value: String) throws -> String {
        let n = try parseDouble(value, name: "LOG10")
        return SumFormulaEvaluator.format(log10(n))
    }
}

enum ExpFormulaEvaluator {
    static func evaluate(_ value: String) throws -> String {
        let n = try parseDouble(value, name: "EXP")
        return SumFormulaEvaluator.format(exp(n))
    }
}

private func parseDouble(_ s: String, name: String) throws -> Double {
    let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let n = Double(t) else {
        throw SumFormulaEvaluator.Error.notANumber("\(name): \(t)")
    }
    return n
}
