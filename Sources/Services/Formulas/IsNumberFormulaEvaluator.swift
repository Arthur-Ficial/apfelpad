import Foundation

enum IsNumberFormulaEvaluator {
    static func evaluate(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "FALSE" }
        return Double(trimmed) != nil ? "TRUE" : "FALSE"
    }
}
