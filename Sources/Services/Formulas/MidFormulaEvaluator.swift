import Foundation

/// =MID(text, start, length) — substring starting at 1-indexed `start`
/// (Google Sheets convention) of `length` graphemes. Clamps length to the
/// remaining string. Throws if `start < 1` or `length < 0`.
enum MidFormulaEvaluator {
    enum Error: Swift.Error, LocalizedError {
        case startMustBeAtLeastOne
        case negativeLength
        var errorDescription: String? {
            switch self {
            case .startMustBeAtLeastOne: return "MID: start must be 1 or greater (1-indexed)"
            case .negativeLength: return "MID: length must be >= 0"
            }
        }
    }
    static func evaluate(text: String, start: Int, length: Int) throws -> String {
        guard start >= 1 else { throw Error.startMustBeAtLeastOne }
        guard length >= 0 else { throw Error.negativeLength }
        let count = text.count
        let from = min(start - 1, count)
        let upTo = min(from + length, count)
        let s = text.index(text.startIndex, offsetBy: from)
        let e = text.index(text.startIndex, offsetBy: upTo)
        return String(text[s..<e])
    }
}
