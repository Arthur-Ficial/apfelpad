import Foundation

enum FormulaCall: Equatable {
    case apfel(prompt: String, seed: Int?)
    case math(expression: String)
    // Text formulas — pure Swift, no LLM
    case upper(text: String)
    case lower(text: String)
    case trim(text: String)
    case len(text: String)
    case concat(parts: [String])
    case replace(text: String, find: String, replacement: String)
    case splitCall(text: String, delim: String, index: Int)
    case ifCall(cond: String, thenValue: String, elseValue: String)
    case sum(args: [String])
    case avg(args: [String])
    // Document reference
    case ref(anchor: String)
}
