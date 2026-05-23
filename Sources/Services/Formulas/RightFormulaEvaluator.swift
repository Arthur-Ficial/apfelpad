import Foundation

/// =RIGHT(text, n) — last n characters (clamped to length). n=0 returns "".
enum RightFormulaEvaluator {
    enum Error: Swift.Error, LocalizedError {
        case negativeCount(Int)
        var errorDescription: String? { "RIGHT: count must be >= 0" }
    }
    static func evaluate(text: String, n: Int) throws -> String {
        guard n >= 0 else { throw Error.negativeCount(n) }
        return String(text.suffix(n))
    }
}
