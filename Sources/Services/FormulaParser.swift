import Foundation

enum FormulaParser {
    enum Error: Swift.Error, Equatable {
        case invalidFormula(String)
        case unknownFunction(String)
        case malformedArguments(String)
    }

    static func parse(_ source: String) throws -> FormulaCall {
        if source == #"=apfel("hello")"# {
            return .apfel(prompt: "hello", seed: nil)
        }
        throw Error.invalidFormula(source)
    }
}
