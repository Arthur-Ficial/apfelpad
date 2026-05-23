import Foundation

/// =CODE(text) — Unicode code point of the first character. Errors on empty.
enum CodeFormulaEvaluator {
    enum Error: Swift.Error, LocalizedError {
        case emptyString
        var errorDescription: String? { "CODE: cannot read code of empty string" }
    }
    static func evaluate(_ text: String) throws -> String {
        guard let first = text.unicodeScalars.first else { throw Error.emptyString }
        return String(first.value)
    }
}
