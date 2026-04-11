import Foundation

enum LowerFormulaEvaluator {
    static func evaluate(_ text: String) throws -> String {
        text.lowercased()
    }
}
