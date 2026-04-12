import Foundation

/// Declared type of an =input variable. Determines how the value is
/// rendered (text field, number field, toggle, date picker) and how it
/// gets coerced when substituted into another formula.
enum InputType: String, Equatable, Hashable, CaseIterable {
    case text
    case number
    case boolean
    case date

    var displayLabel: String {
        switch self {
        case .text:    return "Text"
        case .number:  return "Number"
        case .boolean: return "Boolean"
        case .date:    return "Date"
        }
    }
}
