import Foundation

enum FormulaCall: Equatable {
    case apfel(prompt: String, seed: Int?)
    case math(expression: String)
}
