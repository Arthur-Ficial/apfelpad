import Foundation

enum SumFormulaEvaluator {
    enum Error: Swift.Error, Equatable, LocalizedError {
        case notANumber(String)

        var errorDescription: String? {
            switch self {
            case .notANumber(let raw):
                return "sum / avg: not a number — \(raw)"
            }
        }
    }

    static func evaluate(_ args: [String]) throws -> String {
        var total: Double = 0
        for raw in args {
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let n = Double(t) else { throw Error.notANumber(t) }
            total += n
        }
        return format(total)
    }

    static func format(_ value: Double) -> String {
        if value.isNaN || value.isInfinite { return String(value) }
        if value == value.rounded() && abs(value) < 1e15 {
            return String(Int(value))
        }
        return String(value)
    }
}
