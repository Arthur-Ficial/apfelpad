import Foundation

/// =SEARCH(needle, haystack, [start=1]) — case-insensitive 1-indexed
/// position of needle in haystack. Throws if not found.
enum SearchFormulaEvaluator {
    enum Error: Swift.Error, LocalizedError {
        case notFound(String)
        case startMustBeAtLeastOne
        var errorDescription: String? {
            switch self {
            case .notFound(let n): return "SEARCH: '\(n)' not found"
            case .startMustBeAtLeastOne: return "SEARCH: start must be 1 or greater"
            }
        }
    }
    static func evaluate(needle: String, haystack: String, start: Int) throws -> String {
        guard start >= 1 else { throw Error.startMustBeAtLeastOne }
        let chars = Array(haystack)
        let offset = min(start - 1, chars.count)
        let slice = String(chars[offset...])
        guard let range = slice.range(of: needle, options: .caseInsensitive) else {
            throw Error.notFound(needle)
        }
        let pos = slice.distance(from: slice.startIndex, to: range.lowerBound) + offset + 1
        return String(pos)
    }
}
