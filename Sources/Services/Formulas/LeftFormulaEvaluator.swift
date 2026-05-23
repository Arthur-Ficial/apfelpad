import Foundation

/// =LEFT(text, n) — first n characters (clamped to length). n=0 returns "".
enum LeftFormulaEvaluator {
    enum Error: Swift.Error, LocalizedError {
        case negativeCount(Int)
        var errorDescription: String? { "LEFT: count must be >= 0 (got \(self))" }
    }
    static func evaluate(text: String, n: Int) throws -> String {
        guard n >= 0 else { throw Error.negativeCount(n) }
        return String(text.prefix(n))
    }
}
