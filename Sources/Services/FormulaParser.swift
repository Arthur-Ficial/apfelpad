import Foundation

enum FormulaParser {
    enum Error: Swift.Error, Equatable {
        case invalidFormula(String)
        case unknownFunction(String)
        case malformedArguments(String)
    }

    static func parse(_ source: String) throws -> FormulaCall {
        // 1. Preprocess raw user input: straighten smart quotes + expand =(…) shortcut
        let normalised = FormulaPreprocessor.normalize(source)
        let trimmed = normalised.trimmingCharacters(in: .whitespaces)
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
        // =math takes the WHOLE inside as a single expression — no comma
        // splitting, so =math($1,250 + $750) parses with thousand separators.
        if name == "math" {
            let expression = inside.trimmingCharacters(in: .whitespaces)
            guard !expression.isEmpty else {
                throw Error.malformedArguments("math expects 1 arg")
            }
            return .math(expression: expression)
        }
        let rawArgs = try splitTopLevelCommas(inside)
        switch name {
        case "apfel":
            return try parseApfel(rawArgs)
        case "math":
            guard rawArgs.count == 1 else {
                throw Error.malformedArguments("math expects 1 arg")
            }
            return .math(expression: rawArgs[0].trimmingCharacters(in: .whitespaces))
        case "upper":
            return .upper(text: try singleStringArg(rawArgs, name: "upper"))
        case "lower":
            return .lower(text: try singleStringArg(rawArgs, name: "lower"))
        case "trim":
            return .trim(text: try singleStringArg(rawArgs, name: "trim"))
        case "len":
            return .len(text: try singleStringArg(rawArgs, name: "len"))
        case "concat":
            return .concat(parts: rawArgs.map(Self.parseStringLiteral))
        case "replace":
            guard rawArgs.count == 3 else {
                throw Error.malformedArguments("replace expects 3 args")
            }
            return .replace(
                text: Self.parseStringLiteral(rawArgs[0]),
                find: Self.parseStringLiteral(rawArgs[1]),
                replacement: Self.parseStringLiteral(rawArgs[2])
            )
        case "split":
            guard (2...3).contains(rawArgs.count) else {
                throw Error.malformedArguments("split expects 2 or 3 args")
            }
            let index = rawArgs.count == 3 ? try Self.parseIntLiteral(rawArgs[2]) : 0
            return .splitCall(
                text: Self.parseStringLiteral(rawArgs[0]),
                delim: Self.parseStringLiteral(rawArgs[1]),
                index: index
            )
        case "if":
            guard rawArgs.count == 3 else {
                throw Error.malformedArguments("if expects 3 args")
            }
            return .ifCall(
                cond: Self.parseStringLiteral(rawArgs[0]),
                thenValue: Self.parseStringLiteral(rawArgs[1]),
                elseValue: Self.parseStringLiteral(rawArgs[2])
            )
        case "sum":
            return .sum(args: rawArgs.map(Self.parseStringLiteral))
        case "avg":
            return .avg(args: rawArgs.map(Self.parseStringLiteral))
        case "ref":
            guard rawArgs.count == 1 else {
                throw Error.malformedArguments("ref expects 1 arg: =ref(@anchor)")
            }
            let raw = rawArgs[0].trimmingCharacters(in: .whitespaces)
            let anchor = raw.hasPrefix("@") ? String(raw.dropFirst()) : raw
            return .ref(anchor: anchor)
        case "date":
            let offset = rawArgs.isEmpty ? 0 : (try? Self.parseSignedInt(rawArgs[0])) ?? 0
            return .date(offsetDays: offset)
        case "cw":
            let offset = rawArgs.isEmpty ? 0 : (try? Self.parseSignedInt(rawArgs[0])) ?? 0
            return .cw(offsetWeeks: offset)
        case "month":
            guard rawArgs.isEmpty else { throw Error.malformedArguments("month takes no args") }
            return .month
        case "day":
            guard rawArgs.isEmpty else { throw Error.malformedArguments("day takes no args") }
            return .day
        case "time":
            guard rawArgs.isEmpty else { throw Error.malformedArguments("time takes no args") }
            return .time
        case "recording":
            guard rawArgs.isEmpty else { throw Error.malformedArguments("recording takes no args") }
            return .recording
        case "input":
            guard (2...3).contains(rawArgs.count) else {
                throw Error.malformedArguments("input expects: name, type, default?")
            }
            let name = Self.parseStringLiteral(rawArgs[0])
            let typeRaw = rawArgs[1].trimmingCharacters(in: .whitespaces).lowercased()
            guard let type = InputType(rawValue: typeRaw) else {
                throw Error.malformedArguments("unknown input type: \(typeRaw) — must be text|number|boolean|date")
            }
            let defaultValue: String? = rawArgs.count == 3
                ? Self.parseStringLiteral(rawArgs[2])
                : nil
            return .input(name: name, type: type, defaultValue: defaultValue)
        case "show":
            guard rawArgs.count == 1 else {
                throw Error.malformedArguments("show expects 1 arg: =show(@name)")
            }
            let raw = rawArgs[0].trimmingCharacters(in: .whitespaces)
            let name = raw.hasPrefix("@") ? String(raw.dropFirst()) : raw
            return .show(name: name)
        default:
            throw Error.unknownFunction(name)
        }
    }

    /// Parse a signed integer offset like "+4", "-1", "3".
    private static func parseSignedInt(_ token: String) throws -> Int {
        let t = token.trimmingCharacters(in: .whitespaces)
        guard let n = Int(t) else {
            throw Error.malformedArguments("not a signed integer: \(t)")
        }
        return n
    }

    private static func singleStringArg(_ args: [String], name: String) throws -> String {
        guard args.count == 1 else {
            throw Error.malformedArguments("\(name) expects 1 arg")
        }
        return Self.parseStringLiteral(args[0])
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
        case .upper(let t):   return "=upper(\"\(t)\")"
        case .lower(let t):   return "=lower(\"\(t)\")"
        case .trim(let t):    return "=trim(\"\(t)\")"
        case .len(let t):     return "=len(\"\(t)\")"
        case .concat(let parts):
            let rendered = parts.map { "\"\($0)\"" }.joined(separator: ", ")
            return "=concat(\(rendered))"
        case .replace(let t, let f, let r):
            return "=replace(\"\(t)\", \"\(f)\", \"\(r)\")"
        case .splitCall(let t, let d, let i):
            return "=split(\"\(t)\", \"\(d)\", \(i))"
        case .ifCall(let c, let tv, let ev):
            return "=if(\"\(c)\", \"\(tv)\", \"\(ev)\")"
        case .sum(let args):
            return "=sum(\(args.joined(separator: ", ")))"
        case .avg(let args):
            return "=avg(\(args.joined(separator: ", ")))"
        case .ref(let anchor):
            return "=ref(@\(anchor))"
        case .date(let offset):
            return offset == 0 ? "=date()" : "=date(\(offset >= 0 ? "+" : "")\(offset))"
        case .cw(let offset):
            return offset == 0 ? "=cw()" : "=cw(\(offset >= 0 ? "+" : "")\(offset))"
        case .month: return "=month()"
        case .day: return "=day()"
        case .time: return "=time()"
        case .recording: return "=recording()"
        case .input(let name, let type, let def):
            if let d = def {
                return "=input(\"\(name)\", \(type.rawValue), \"\(d)\")"
            }
            return "=input(\"\(name)\", \(type.rawValue))"
        case .show(let name):
            return "=show(@\(name))"
        }
    }

    private static func parseApfel(_ args: [String]) throws -> FormulaCall {
        // Allow zero args for the =() / =apfel() anonymous empty-prompt form.
        guard args.count <= 2 else {
            throw Error.malformedArguments("apfel expects at most 2 args")
        }
        if args.isEmpty {
            return .apfel(prompt: "", seed: nil)
        }
        let prompt = parseStringLiteral(args[0])
        let seed: Int? = args.count == 2 ? try parseIntLiteral(args[1]) : nil
        return .apfel(prompt: prompt, seed: seed)
    }

    private static func parseStringLiteral(_ token: String) -> String {
        let t = token.trimmingCharacters(in: .whitespaces)
        // Strip matched quote pairs — both " and ' are supported so typed
        // apostrophes (and the preprocessor's normalised curly quotes) work.
        if t.count >= 2 {
            if t.hasPrefix("\"") && t.hasSuffix("\"") {
                return String(t.dropFirst().dropLast())
            }
            if t.hasPrefix("'") && t.hasSuffix("'") {
                return String(t.dropFirst().dropLast())
            }
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
