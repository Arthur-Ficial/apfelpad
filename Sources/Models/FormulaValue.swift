import Foundation

enum FormulaValue: Equatable {
    case idle
    case evaluating
    case streaming(partial: String)
    case ready(text: String)
    case stale(text: String)
    case error(message: String)
}
