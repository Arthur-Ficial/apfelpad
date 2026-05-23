import Foundation

/// =VALUE(text) — parse `text` to a number, returning the number as a
/// string. Errors when not parseable.
enum ValueFormulaEvaluator {
    enum Error: Swift.Error, LocalizedError {
        case notANumber(String)
        var errorDescription: String? {
            if case .notANumber(let raw) = self {
                return "VALUE: '\(raw)' is not a number"
            }
            return nil
        }
    }
    static func evaluate(_ text: String) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let n = Double(trimmed) else { throw Error.notANumber(trimmed) }
        return SumFormulaEvaluator.format(n)
    }
}
