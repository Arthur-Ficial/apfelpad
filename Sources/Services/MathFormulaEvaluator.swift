import Foundation

enum MathFormulaEvaluator {
    enum Error: Swift.Error, Equatable {
        case invalidExpression(String)
    }

    static func evaluate(_ expression: String) throws -> String {
        let tokens = tokenise(expression)
        var parser = Parser(tokens: tokens)
        let value = try parser.parseExpression()
        if parser.hasRemaining {
            throw Error.invalidExpression(expression)
        }
        return format(value)
    }

    private static func format(_ value: Double) -> String {
        if value.isNaN || value.isInfinite {
            return String(value)
        }
        if value == value.rounded() && abs(value) < 1e15 {
            return String(Int(value))
        }
        return String(value)
    }

    // MARK: - Tokeniser

    private enum Token: Equatable {
        case number(Double)
        case plus, minus, star, slash, lparen, rparen
    }

    private static func tokenise(_ s: String) -> [Token] {
        var out: [Token] = []
        var i = s.startIndex
        while i < s.endIndex {
            let ch = s[i]
            if ch.isWhitespace {
                i = s.index(after: i)
                continue
            }
            if ch.isNumber || ch == "." {
                var num = ""
                while i < s.endIndex && (s[i].isNumber || s[i] == ".") {
                    num.append(s[i])
                    i = s.index(after: i)
                }
                if let v = Double(num) {
                    out.append(.number(v))
                }
                continue
            }
            switch ch {
            case "+": out.append(.plus)
            case "-": out.append(.minus)
            case "*": out.append(.star)
            case "/": out.append(.slash)
            case "(": out.append(.lparen)
            case ")": out.append(.rparen)
            default:
                // Unknown character — leave as garbage so parser fails cleanly.
                out.append(.plus)
                out.removeLast()
            }
            i = s.index(after: i)
        }
        return out
    }

    // MARK: - Parser

    private struct Parser {
        let tokens: [Token]
        var pos: Int = 0
        var hasRemaining: Bool { pos < tokens.count }

        mutating func parseExpression() throws -> Double {
            var left = try parseTerm()
            while pos < tokens.count, tokens[pos] == .plus || tokens[pos] == .minus {
                let op = tokens[pos]
                pos += 1
                let right = try parseTerm()
                left = (op == .plus) ? (left + right) : (left - right)
            }
            return left
        }

        mutating func parseTerm() throws -> Double {
            var left = try parseFactor()
            while pos < tokens.count, tokens[pos] == .star || tokens[pos] == .slash {
                let op = tokens[pos]
                pos += 1
                let right = try parseFactor()
                left = (op == .star) ? (left * right) : (left / right)
            }
            return left
        }

        mutating func parseFactor() throws -> Double {
            guard pos < tokens.count else {
                throw Error.invalidExpression("unexpected end of input")
            }
            switch tokens[pos] {
            case .number(let n):
                pos += 1
                return n
            case .lparen:
                pos += 1
                let v = try parseExpression()
                guard pos < tokens.count, tokens[pos] == .rparen else {
                    throw Error.invalidExpression("missing )")
                }
                pos += 1
                return v
            case .minus:
                pos += 1
                return -(try parseFactor())
            default:
                throw Error.invalidExpression("unexpected token")
            }
        }
    }
}
