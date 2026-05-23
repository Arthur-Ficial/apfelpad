import Foundation

/// Phase 3 binary math: MOD, POWER (with =POW alias), GCD, LCM, COMBIN,
/// RANDBETWEEN.
enum ModFormulaEvaluator {
    enum Error: Swift.Error, LocalizedError {
        case divideByZero
        var errorDescription: String? { "MOD: divisor must not be zero" }
    }
    static func evaluate(dividend: String, divisor: String) throws -> String {
        let a = try parseD(dividend, name: "MOD")
        let b = try parseD(divisor, name: "MOD")
        if b == 0 { throw Error.divideByZero }
        return SumFormulaEvaluator.format(a.truncatingRemainder(dividingBy: b))
    }
}

enum PowerFormulaEvaluator {
    static func evaluate(base: String, exponent: String) throws -> String {
        let b = try parseD(base, name: "POWER")
        let e = try parseD(exponent, name: "POWER")
        return SumFormulaEvaluator.format(pow(b, e))
    }
}

enum GcdFormulaEvaluator {
    static func evaluate(a: Int, b: Int) throws -> String {
        var x = abs(a), y = abs(b)
        while y != 0 { (x, y) = (y, x % y) }
        return String(x)
    }
}

enum LcmFormulaEvaluator {
    static func evaluate(a: Int, b: Int) throws -> String {
        if a == 0 || b == 0 { return "0" }
        let gcdString = try GcdFormulaEvaluator.evaluate(a: a, b: b)
        let g = Int(gcdString) ?? 1
        return String(abs(a * b) / g)
    }
}

enum CombinFormulaEvaluator {
    enum Error: Swift.Error, LocalizedError {
        case kOutOfRange
        case negative
        var errorDescription: String? {
            switch self {
            case .kOutOfRange: return "COMBIN: k must be between 0 and n"
            case .negative: return "COMBIN: n and k must be >= 0"
            }
        }
    }
    static func evaluate(n: Int, k: Int) throws -> String {
        if n < 0 || k < 0 { throw Error.negative }
        if k > n { throw Error.kOutOfRange }
        if k == 0 || k == n { return "1" }
        let r = min(k, n - k)
        var result: Double = 1
        for i in 0..<r {
            result *= Double(n - i)
            result /= Double(i + 1)
        }
        return SumFormulaEvaluator.format(result)
    }
}

enum RandBetweenFormulaEvaluator {
    static func evaluate(low: Int, high: Int) throws -> String {
        let lo = min(low, high), hi = max(low, high)
        return String(Int.random(in: lo...hi))
    }
}

private func parseD(_ s: String, name: String) throws -> Double {
    let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let n = Double(t) else {
        throw SumFormulaEvaluator.Error.notANumber("\(name): \(t)")
    }
    return n
}
