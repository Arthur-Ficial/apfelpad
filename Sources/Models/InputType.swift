import Foundation

/// Declared type of an =input variable. Determines which widget renders
/// the field in Markdown mode and how the value is coerced when
/// substituted into another formula.
///
/// The names mirror HTML `<input type="…">` for familiarity, plus a few
/// SwiftUI-native extras (textarea, select). Unknown types fall back to
/// `.text` in the parser.
enum InputType: String, Equatable, Hashable, CaseIterable {
    // Plain text family
    case text
    case textarea
    case email
    case url
    case tel
    case password
    case search

    // Numeric family
    case number
    case range     // slider, 0–100 by default
    case percent   // 0–100 integer

    // Boolean / choice
    case boolean
    case toggle    // synonym for boolean — HTML has no textarea-like; we add

    // Date / time family
    case date
    case time
    case datetime

    // Rich pickers
    case color

    var displayLabel: String {
        switch self {
        case .text:      return "Text"
        case .textarea:  return "Textarea"
        case .email:     return "Email"
        case .url:       return "URL"
        case .tel:       return "Phone"
        case .password:  return "Password"
        case .search:    return "Search"
        case .number:    return "Number"
        case .range:     return "Slider"
        case .percent:   return "Percent"
        case .boolean:   return "Boolean"
        case .toggle:    return "Toggle"
        case .date:      return "Date"
        case .time:      return "Time"
        case .datetime:  return "Date & time"
        case .color:     return "Color"
        }
    }
}
