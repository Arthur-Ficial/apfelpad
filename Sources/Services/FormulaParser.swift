import Foundation

enum FormulaParser {
    enum Error: Swift.Error, Equatable {
        case invalidFormula(String)
        case unknownFunction(String)
        case malformedArguments(String)
    }

    static func parse(_ source: String) throws -> FormulaCall {
        let trimmed = source.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("=") else { throw Error.invalidFormula(source) }
        guard trimmed.hasSuffix(")") else { throw Error.invalidFormula(source) }
        let afterEquals = String(trimmed.dropFirst())
        guard let lparen = afterEquals.firstIndex(of: "(") else {
            throw Error.invalidFormula(source)
        }
        let name = String(afterEquals[..<lparen])
        let inside = String(
            afterEquals[afterEquals.index(after: lparen)..<afterEquals.index(before: afterEquals.endIndex)]
        )
        let rawArgs = try splitTopLevelCommas(inside)
        switch name {
        case "apfel":
            return try parseApfel(rawArgs)
        case "math":
            guard rawArgs.count == 1 else {
                throw Error.malformedArguments("math expects 1 arg")
            }
            return .math(expression: rawArgs[0].trimmingCharacters(in: .whitespaces))
        default:
            throw Error.unknownFunction(name)
        }
    }

    static func canonicalise(_ source: String) throws -> String {
        render(try parse(source))
    }

    static func render(_ call: FormulaCall) -> String {
        switch call {
        case .apfel(let prompt, nil):
            return "=apfel(\"\(prompt)\")"
        case .apfel(let prompt, let seed?):
            return "=apfel(\"\(prompt)\", \(seed))"
        case .math(let expr):
            return "=math(\(expr))"
        }
    }

    private static func parseApfel(_ args: [String]) throws -> FormulaCall {
        guard (1...2).contains(args.count) else {
            throw Error.malformedArguments("apfel expects 1 or 2 args")
        }
        let prompt = parseStringLiteral(args[0])
        let seed: Int? = args.count == 2 ? try parseIntLiteral(args[1]) : nil
        return .apfel(prompt: prompt, seed: seed)
    }

    private static func parseStringLiteral(_ token: String) -> String {
        let t = token.trimmingCharacters(in: .whitespaces)
        if t.hasPrefix("\"") && t.hasSuffix("\"") && t.count >= 2 {
            return String(t.dropFirst().dropLast())
        }
        // Auto-quote bare phrase
        return t
    }

    private static func parseIntLiteral(_ token: String) throws -> Int {
        let t = token.trimmingCharacters(in: .whitespaces)
        guard let n = Int(t) else {
            throw Error.malformedArguments("not a number: \(t)")
        }
        return n
    }

    private static func splitTopLevelCommas(_ inside: String) throws -> [String] {
        var out: [String] = []
        var current = ""
        var depth = 0
        var inString = false
        for ch in inside {
            if ch == "\"" { inString.toggle() }
            if !inString && ch == "(" { depth += 1 }
            if !inString && ch == ")" { depth -= 1 }
            if !inString && depth == 0 && ch == "," {
                out.append(current)
                current = ""
                continue
            }
            current.append(ch)
        }
        out.append(current)
        return out.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }
}
