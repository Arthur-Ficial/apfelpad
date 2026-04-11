import Foundation

enum ConcatFormulaEvaluator {
    static func evaluate(_ parts: [String]) throws -> String {
        parts.joined()
    }
}
