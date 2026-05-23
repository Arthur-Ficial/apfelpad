import Foundation

/// Phase 3 zero-arg math: PI, RAND.
enum PiFormulaEvaluator {
    static func evaluate() -> String {
        SumFormulaEvaluator.format(.pi)
    }
}

enum RandFormulaEvaluator {
    static func evaluate() -> String {
        // [0, 1) - matches Google Sheets behavior.
        String(Double.random(in: 0..<1))
    }
}
