import Foundation

enum ConcatenateFormulaEvaluator {
    static func evaluate(_ parts: [String]) throws -> String {
        parts.joined()
    }
}
