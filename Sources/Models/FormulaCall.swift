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
    // v0.6 — text (Phase 2)
    case left(text: String, n: Int)
    case right(text: String, n: Int)
    case mid(text: String, start: Int, length: Int)
    case find(needle: String, haystack: String, start: Int)
    case search(needle: String, haystack: String, start: Int)
    case rept(text: String, n: Int)
    case proper(text: String)
    case clean(text: String)
    case exact(a: String, b: String)
    case char(code: Int)
    case code(text: String)
    case textjoin(delim: String, ignoreEmpty: Bool, parts: [String])
    case value(text: String)
    case textFmt(value: String, format: String)
    // v0.6 — math (Phase 3)
    case max(args: [String])
    case min(args: [String])
    case product(args: [String])
    case abs(value: String)
    case sqrt(value: String)
    case intFn(value: String)
    case sign(value: String)
    case even(value: String)
    case odd(value: String)
    case fact(value: String)
    case ln(value: String)
    case log10Fn(value: String)
    case exp(value: String)
    case mod(dividend: String, divisor: String)
    case power(base: String, exponent: String)
    case gcd(a: Int, b: Int)
    case lcm(a: Int, b: Int)
    case combin(n: Int, k: Int)
    case randbetween(low: Int, high: Int)
    case round(value: String, places: Int)
    case roundup(value: String, places: Int)
    case rounddown(value: String, places: Int)
    case ceiling(value: String, factor: Double)
    case floor(value: String, factor: Double)
    case log(value: String, base: Double)
    case pi
    case rand
}
