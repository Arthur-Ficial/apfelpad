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
        var trimmed = normalised.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("=") else { throw Error.invalidFormula(source) }
        // Bare zero-arg form: `=name` (no parens) is shorthand for `=name()`
        // when the formula allows bare invocation. See issue #18.
        if !trimmed.hasSuffix(")"),
           !trimmed.contains("(") {
            let bareName = String(trimmed.dropFirst()).lowercased()
            if FormulaRegistry.bareNameAllowedNames.contains(bareName) {
                trimmed = "=\(bareName)()"
            }
        }
        guard trimmed.hasSuffix(")") else { throw Error.invalidFormula(source) }
        let afterEquals = String(trimmed.dropFirst())
        guard let lparen = afterEquals.firstIndex(of: "(") else {
            throw Error.invalidFormula(source)
        }
        let name = String(afterEquals[..<lparen])
        let inside = String(
            afterEquals[afterEquals.index(after: lparen)..<afterEquals.index(before: afterEquals.endIndex)]
        )
        guard let definition = FormulaRegistry.definition(forFunctionName: name) else {
            throw Error.unknownFunction(name)
        }
        // =math takes the WHOLE inside as a single expression — no comma
        // splitting, so =math($1,250 + $750) parses with thousand separators.
        if definition.parserKind == .math {
            let expression = inside.trimmingCharacters(in: .whitespaces)
            guard !expression.isEmpty else {
                throw Error.malformedArguments("math expects 1 arg")
            }
            return .math(expression: expression)
        }
        let rawArgs = try splitTopLevelCommas(inside)
        switch definition.parserKind {
        case .apfel:
            return try parseApfel(rawArgs)
        case .math:
            guard rawArgs.count == 1 else {
                throw Error.malformedArguments("math expects 1 arg")
            }
            return .math(expression: rawArgs[0].trimmingCharacters(in: .whitespaces))
        case .upper:
            return .upper(text: try singleStringArg(rawArgs, name: "upper"))
        case .lower:
            return .lower(text: try singleStringArg(rawArgs, name: "lower"))
        case .trim:
            return .trim(text: try singleStringArg(rawArgs, name: "trim"))
        case .len:
            return .len(text: try singleStringArg(rawArgs, name: "len"))
        case .concatenate:
            return .concatenate(parts: rawArgs.map(Self.parseStringLiteral))
        case .substitute:
            guard (3...4).contains(rawArgs.count) else {
                throw Error.malformedArguments("substitute expects 3 or 4 args")
            }
            let occurrence: Int? = rawArgs.count == 4 ? try Self.parseIntLiteral(rawArgs[3]) : nil
            return .substitute(
                text: Self.parseStringLiteral(rawArgs[0]),
                oldText: Self.parseStringLiteral(rawArgs[1]),
                newText: Self.parseStringLiteral(rawArgs[2]),
                occurrence: occurrence
            )
        case .split:
            guard (2...3).contains(rawArgs.count) else {
                throw Error.malformedArguments("split expects 2 or 3 args")
            }
            let index = rawArgs.count == 3 ? try Self.parseIntLiteral(rawArgs[2]) : 0
            return .`split`(
                text: Self.parseStringLiteral(rawArgs[0]),
                delim: Self.parseStringLiteral(rawArgs[1]),
                index: index
            )
        case .ifExpr:
            guard rawArgs.count == 3 else {
                throw Error.malformedArguments("if expects 3 args")
            }
            return .`if`(
                cond: Self.parseStringLiteral(rawArgs[0]),
                thenValue: Self.parseStringLiteral(rawArgs[1]),
                elseValue: Self.parseStringLiteral(rawArgs[2])
            )
        case .sum:
            return .sum(args: rawArgs.map(Self.parseStringLiteral))
        case .average:
            return .average(args: rawArgs.map(Self.parseStringLiteral))
        case .ref:
            guard rawArgs.count == 1 else {
                throw Error.malformedArguments("ref expects 1 arg: =ref(@#anchor)")
            }
            return .ref(anchor: parseRefAnchor(rawArgs[0]))
        case .date:
            let offset = rawArgs.isEmpty ? 0 : (try? Self.parseSignedInt(rawArgs[0])) ?? 0
            return .date(offsetDays: offset)
        case .weeknum:
            let offset = rawArgs.isEmpty ? 0 : (try? Self.parseSignedInt(rawArgs[0])) ?? 0
            return .weeknum(offsetWeeks: offset)
        case .today:
            guard rawArgs.isEmpty else { throw Error.malformedArguments("today takes no args") }
            return .today
        case .month:
            guard rawArgs.isEmpty else { throw Error.malformedArguments("month takes no args") }
            return .month
        case .day:
            guard rawArgs.isEmpty else { throw Error.malformedArguments("day takes no args") }
            return .day
        case .time:
            guard rawArgs.isEmpty else { throw Error.malformedArguments("time takes no args") }
            return .time
        case .recording:
            guard rawArgs.isEmpty else { throw Error.malformedArguments("recording takes no args") }
            return .recording
        case .input:
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
        case .show:
            guard rawArgs.count == 1 else {
                throw Error.malformedArguments("show expects 1 arg: =show(@name)")
            }
            let raw = rawArgs[0].trimmingCharacters(in: .whitespaces)
            let name = raw.hasPrefix("@") ? String(raw.dropFirst()) : raw
            return .show(name: name)
        case .count:
            if rawArgs.isEmpty {
                return .count(anchor: nil)
            }
            guard rawArgs.count == 1 else {
                throw Error.malformedArguments("count expects 0 or 1 arg: =count(@#anchor?)")
            }
            return .count(anchor: parseRefAnchor(rawArgs[0]))
        case .clip:
            guard rawArgs.isEmpty else { throw Error.malformedArguments("clip takes no args") }
            return .clip
        case .file:
            guard rawArgs.count == 1 else {
                throw Error.malformedArguments("file expects 1 arg: =file(path)")
            }
            return .file(path: Self.parseStringLiteral(rawArgs[0]))
        case .now:
            guard rawArgs.isEmpty else { throw Error.malformedArguments("now takes no args") }
            return .now
        case .year:
            guard rawArgs.isEmpty else { throw Error.malformedArguments("year takes no args") }
            return .year
        case .weekday:
            guard rawArgs.isEmpty else { throw Error.malformedArguments("weekday takes no args") }
            return .weekday
        case .hour:
            guard rawArgs.isEmpty else { throw Error.malformedArguments("hour takes no args") }
            return .hour
        case .minute:
            guard rawArgs.isEmpty else { throw Error.malformedArguments("minute takes no args") }
            return .minute
        case .second:
            guard rawArgs.isEmpty else { throw Error.malformedArguments("second takes no args") }
            return .second
        case .isnumber:
            return .isnumber(value: try singleStringArg(rawArgs, name: "isnumber"))
        case .istext:
            return .istext(value: try singleStringArg(rawArgs, name: "istext"))
        case .isblank:
            // ISBLANK is allowed to receive an empty string literal, so don't
            // reject when the only arg trimmed to empty (which singleStringArg
            // would do via splitTopLevelCommas filtering).
            if rawArgs.isEmpty {
                return .isblank(value: "")
            }
            return .isblank(value: try singleStringArg(rawArgs, name: "isblank"))
        case .type:
            if rawArgs.isEmpty {
                return .type(value: "")
            }
            return .type(value: try singleStringArg(rawArgs, name: "type"))
        case .and:
            return .and(args: rawArgs.map(Self.parseStringLiteral))
        case .or:
            return .or(args: rawArgs.map(Self.parseStringLiteral))
        case .not:
            return .not(value: try singleStringArg(rawArgs, name: "not"))
        case .iferror:
            guard rawArgs.count == 2 else {
                throw Error.malformedArguments("iferror expects 2 args: =IFERROR(value, fallback)")
            }
            // First arg: keep raw (may contain nested formula source). Strip
            // only matched outer quote pair so a literal string still works.
            let rawFirst = rawArgs[0].trimmingCharacters(in: .whitespaces)
            let value: String
            if rawFirst.count >= 2,
               (rawFirst.hasPrefix("\"") && rawFirst.hasSuffix("\"")) ||
                (rawFirst.hasPrefix("'") && rawFirst.hasSuffix("'")) {
                value = String(rawFirst.dropFirst().dropLast())
            } else {
                value = rawFirst
            }
            return .iferror(value: value, fallback: Self.parseStringLiteral(rawArgs[1]))
        case .switchCall:
            guard rawArgs.count >= 3 else {
                throw Error.malformedArguments("switch expects expr + at least one case/value")
            }
            return .switchCall(args: rawArgs.map(Self.parseStringLiteral))
        case .ifs:
            return .ifs(args: rawArgs.map(Self.parseStringLiteral))
        case .trueLit:
            guard rawArgs.isEmpty else { throw Error.malformedArguments("TRUE takes no args") }
            return .trueLit
        case .falseLit:
            guard rawArgs.isEmpty else { throw Error.malformedArguments("FALSE takes no args") }
            return .falseLit
        case .left:
            guard rawArgs.count == 2 else { throw Error.malformedArguments("LEFT expects (text, n)") }
            return .left(text: Self.parseStringLiteral(rawArgs[0]), n: try parseIntLiteral(rawArgs[1]))
        case .right:
            guard rawArgs.count == 2 else { throw Error.malformedArguments("RIGHT expects (text, n)") }
            return .right(text: Self.parseStringLiteral(rawArgs[0]), n: try parseIntLiteral(rawArgs[1]))
        case .mid:
            guard rawArgs.count == 3 else { throw Error.malformedArguments("MID expects (text, start, length)") }
            return .mid(
                text: Self.parseStringLiteral(rawArgs[0]),
                start: try parseIntLiteral(rawArgs[1]),
                length: try parseIntLiteral(rawArgs[2])
            )
        case .find:
            guard (2...3).contains(rawArgs.count) else { throw Error.malformedArguments("FIND expects (needle, haystack, [start])") }
            let start = rawArgs.count == 3 ? try parseIntLiteral(rawArgs[2]) : 1
            return .find(
                needle: Self.parseStringLiteral(rawArgs[0]),
                haystack: Self.parseStringLiteral(rawArgs[1]),
                start: start
            )
        case .search:
            guard (2...3).contains(rawArgs.count) else { throw Error.malformedArguments("SEARCH expects (needle, haystack, [start])") }
            let start = rawArgs.count == 3 ? try parseIntLiteral(rawArgs[2]) : 1
            return .search(
                needle: Self.parseStringLiteral(rawArgs[0]),
                haystack: Self.parseStringLiteral(rawArgs[1]),
                start: start
            )
        case .rept:
            guard rawArgs.count == 2 else { throw Error.malformedArguments("REPT expects (text, n)") }
            return .rept(text: Self.parseStringLiteral(rawArgs[0]), n: try parseIntLiteral(rawArgs[1]))
        case .proper:
            return .proper(text: try singleStringArg(rawArgs, name: "PROPER"))
        case .clean:
            return .clean(text: try singleStringArg(rawArgs, name: "CLEAN"))
        case .exact:
            guard rawArgs.count == 2 else { throw Error.malformedArguments("EXACT expects 2 args") }
            return .exact(a: Self.parseStringLiteral(rawArgs[0]), b: Self.parseStringLiteral(rawArgs[1]))
        case .char:
            guard rawArgs.count == 1 else { throw Error.malformedArguments("CHAR expects 1 arg") }
            return .char(code: try parseIntLiteral(rawArgs[0]))
        case .code:
            return .code(text: try singleStringArg(rawArgs, name: "CODE"))
        case .textjoin:
            guard rawArgs.count >= 3 else { throw Error.malformedArguments("TEXTJOIN expects (delim, ignore_empty, text1, …)") }
            let delim = Self.parseStringLiteral(rawArgs[0])
            let ignore = IfFormulaEvaluator.isTruthy(Self.parseStringLiteral(rawArgs[1]))
            let parts = rawArgs.dropFirst(2).map(Self.parseStringLiteral)
            return .textjoin(delim: delim, ignoreEmpty: ignore, parts: Array(parts))
        case .value:
            return .value(text: try singleStringArg(rawArgs, name: "VALUE"))
        case .textFmt:
            guard (1...2).contains(rawArgs.count) else { throw Error.malformedArguments("TEXT expects (value, [format])") }
            let fmt = rawArgs.count == 2 ? Self.parseStringLiteral(rawArgs[1]) : ""
            return .textFmt(value: Self.parseStringLiteral(rawArgs[0]), format: fmt)
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

    private static func parseRefAnchor(_ token: String) -> String {
        let raw = token.trimmingCharacters(in: .whitespaces)
        if raw.hasPrefix("@#") {
            return String(raw.dropFirst(2))
        }
        if raw.hasPrefix("@") {
            return String(raw.dropFirst())
        }
        return raw
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
        case .concatenate(let parts):
            let rendered = parts.map { "\"\($0)\"" }.joined(separator: ", ")
            return "=concatenate(\(rendered))"
        case .substitute(let t, let o, let n, let occ):
            if let occ {
                return "=substitute(\"\(t)\", \"\(o)\", \"\(n)\", \(occ))"
            }
            return "=substitute(\"\(t)\", \"\(o)\", \"\(n)\")"
        case .`split`(let t, let d, let i):
            return "=split(\"\(t)\", \"\(d)\", \(i))"
        case .`if`(let c, let tv, let ev):
            return "=if(\"\(c)\", \"\(tv)\", \"\(ev)\")"
        case .sum(let args):
            return "=sum(\(args.joined(separator: ", ")))"
        case .average(let args):
            return "=average(\(args.joined(separator: ", ")))"
        case .ref(let anchor):
            return "=ref(@#\(anchor))"
        case .date(let offset):
            return offset == 0 ? "=date()" : "=date(\(offset >= 0 ? "+" : "")\(offset))"
        case .weeknum(let offset):
            return offset == 0 ? "=weeknum()" : "=weeknum(\(offset >= 0 ? "+" : "")\(offset))"
        case .today:
            return "=today()"
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
        case .count(nil):
            return "=count()"
        case .count(let anchor?):
            return "=count(@#\(anchor))"
        case .clip:
            return "=clip()"
        case .file(let path):
            return "=file(\"\(path)\")"
        case .now: return "=NOW()"
        case .year: return "=YEAR()"
        case .weekday: return "=WEEKDAY()"
        case .hour: return "=HOUR()"
        case .minute: return "=MINUTE()"
        case .second: return "=SECOND()"
        case .isnumber(let v):
            return "=ISNUMBER(\"\(v)\")"
        case .istext(let v):
            return "=ISTEXT(\"\(v)\")"
        case .isblank(let v):
            return "=ISBLANK(\"\(v)\")"
        case .type(let v):
            return "=TYPE(\"\(v)\")"
        case .and(let args):
            return "=AND(\(args.map { "\"\($0)\"" }.joined(separator: ", ")))"
        case .or(let args):
            return "=OR(\(args.map { "\"\($0)\"" }.joined(separator: ", ")))"
        case .not(let v):
            return "=NOT(\"\(v)\")"
        case .iferror(let v, let fb):
            // Preserve formula sources unquoted; quote literal strings.
            let firstRendered = v.hasPrefix("=") ? v : "\"\(v)\""
            return "=IFERROR(\(firstRendered), \"\(fb)\")"
        case .switchCall(let args):
            return "=SWITCH(\(args.map { "\"\($0)\"" }.joined(separator: ", ")))"
        case .ifs(let args):
            return "=IFS(\(args.map { "\"\($0)\"" }.joined(separator: ", ")))"
        case .trueLit: return "=TRUE()"
        case .falseLit: return "=FALSE()"
        case .left(let t, let n): return "=LEFT(\"\(t)\", \(n))"
        case .right(let t, let n): return "=RIGHT(\"\(t)\", \(n))"
        case .mid(let t, let s, let l): return "=MID(\"\(t)\", \(s), \(l))"
        case .find(let n, let h, let s): return "=FIND(\"\(n)\", \"\(h)\", \(s))"
        case .search(let n, let h, let s): return "=SEARCH(\"\(n)\", \"\(h)\", \(s))"
        case .rept(let t, let n): return "=REPT(\"\(t)\", \(n))"
        case .proper(let t): return "=PROPER(\"\(t)\")"
        case .clean(let t): return "=CLEAN(\"\(t)\")"
        case .exact(let a, let b): return "=EXACT(\"\(a)\", \"\(b)\")"
        case .char(let c): return "=CHAR(\(c))"
        case .code(let t): return "=CODE(\"\(t)\")"
        case .textjoin(let d, let ig, let parts):
            let p = parts.map { "\"\($0)\"" }.joined(separator: ", ")
            return "=TEXTJOIN(\"\(d)\", \(ig ? "true" : "false"), \(p))"
        case .value(let t): return "=VALUE(\"\(t)\")"
        case .textFmt(let v, let f):
            return f.isEmpty ? "=TEXT(\"\(v)\")" : "=TEXT(\"\(v)\", \"\(f)\")"
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
