import Foundation

enum FormulaCall: Equatable {
    case apfel(prompt: String, seed: Int?)
    case math(expression: String)
    // Text formulas — pure Swift, no LLM
    case upper(text: String)
    case lower(text: String)
    case trim(text: String)
    case len(text: String)
    case concatenate(parts: [String])
    case substitute(text: String, oldText: String, newText: String, occurrence: Int?)
    case split(text: String, delim: String, index: Int)
    case `if`(cond: String, thenValue: String, elseValue: String)
    case sum(args: [String])
    case average(args: [String])
    // Document reference
    case ref(anchor: String)
    // Date / time
    case today
    case date(offsetDays: Int)
    case weeknum(offsetWeeks: Int)
    case month
    case day
    case time
    // v0.4 preview — placeholder that renders a "coming soon" message.
    case recording
    // v0.4 — document introspection
    case count(anchor: String?)
    // v0.5 — reactive input variables + echo
    case input(name: String, type: InputType, defaultValue: String?)
    case show(name: String)
    // v0.5 — system access
    case clip
    case file(path: String)
}
