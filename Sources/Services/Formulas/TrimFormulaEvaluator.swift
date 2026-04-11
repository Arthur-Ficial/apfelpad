import Foundation

enum TrimFormulaEvaluator {
    static func evaluate(_ text: String) throws -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
