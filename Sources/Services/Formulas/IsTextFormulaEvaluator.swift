import Foundation

enum IsTextFormulaEvaluator {
    static func evaluate(_ value: String) -> String {
        IsNumberFormulaEvaluator.evaluate(value) == "TRUE" ? "FALSE" : "TRUE"
    }
}
