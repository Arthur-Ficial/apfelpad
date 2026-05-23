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
    // v0.6 — info / type-checking (Phase 6)
    case isnumber(value: String)
    case istext(value: String)
    case isblank(value: String)
    case type(value: String)
    // v0.6 — extended date/time (Phase 5)
    case now
    case year
    case weekday
    case hour
    case minute
    case second
    // v0.6 — logical (Phase 4)
    case and(args: [String])
    case or(args: [String])
    case not(value: String)
    case iferror(value: String, fallback: String)
    case switchCall(args: [String])
    case ifs(args: [String])
    case trueLit
    case falseLit
}
