import Foundation

/// =CHAR(code) — Unicode character for a code point. Errors for out-of-range
/// scalars (including surrogate halves).
enum CharFormulaEvaluator {
    enum Error: Swift.Error, LocalizedError {
        case invalidCodePoint(Int)
        var errorDescription: String? {
            if case .invalidCodePoint(let v) = self {
                return "CHAR: \(v) is not a valid Unicode scalar"
            }
            return nil
        }
    }
    static func evaluate(_ code: Int) throws -> String {
        guard let scalar = UnicodeScalar(code) else { throw Error.invalidCodePoint(code) }
        return String(scalar)
    }
}
