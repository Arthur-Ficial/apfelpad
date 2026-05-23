import Foundation

enum TypeFormulaEvaluator {
    static func evaluate(_ value: String) -> String {
        if IsBlankFormulaEvaluator.evaluate(value) == "TRUE" { return "blank" }
        if IsNumberFormulaEvaluator.evaluate(value) == "TRUE" { return "number" }
        return "text"
    }
}
