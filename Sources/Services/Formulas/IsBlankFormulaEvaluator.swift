import Foundation

enum IsBlankFormulaEvaluator {
    static func evaluate(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "TRUE" : "FALSE"
    }
}
