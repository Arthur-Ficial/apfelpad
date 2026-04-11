import Foundation

/// Walks a formula source string and resolves any nested `=name(...)` calls
/// inside its arguments before the outer parser sees them. Returns a
/// flattened source where every sub-call has been replaced by its
/// evaluated result as a canonicalised string literal.
///
/// This is the primitive that makes apfelpad Turing-complete via
/// composition: `=if(=math(...), =upper(=ref(@a)), "fallback")` works
/// because nested calls are resolved bottom-up before the outer call runs.
///
/// Depth is capped at 10 so pathological input always terminates.
enum NestedFormulaResolver {
    static let maxDepth = 10

    static func flatten(source: String, in documentMarkdown: String) async -> String {
        await flatten(source: source, in: documentMarkdown, depth: 0)
    }

    private static func flatten(
        source: String,
        in documentMarkdown: String,
        depth: Int
    ) async -> String {
        guard depth < maxDepth else { return source }

        // Parse the outer formula. If that fails, return source unchanged.
        let outer: FormulaCall
        do {
            outer = try FormulaParser.parse(source)
        } catch {
            return source
        }

        // Walk the inside of the source looking for sub-`=name(...)` ranges.
        // Only scan INSIDE the outer parens — not the whole source.
        guard let (innerStart, innerEnd) = innerRange(of: source) else {
            return source
        }
        let chars = Array(source)
        var out = String(chars[..<innerStart])
        var i = innerStart

        while i < innerEnd {
            // Check if a sub-call starts here
            if chars[i] == "=", let (subEnd, subSource) = nextSubCall(chars: chars, start: i, boundary: innerEnd) {
                let flattenedSub = await flatten(
                    source: subSource,
                    in: documentMarkdown,
                    depth: depth + 1
                )
                // Evaluate the flattened sub-call into a plain string
                let subResult = await evaluate(
                    flattenedSource: flattenedSub,
                    in: documentMarkdown
                )
                if let subResult {
                    // Replace with a canonical quoted literal
                    out.append("\"\(escapeQuotes(subResult))\"")
                } else {
                    // Leave it alone; outer parse will surface the error
                    out.append(contentsOf: chars[i..<subEnd])
                }
                i = subEnd
            } else {
                out.append(chars[i])
                i += 1
            }
        }
        out.append(contentsOf: chars[innerEnd...])
        // Suppress warning about `outer` being unused — parse was for validation
        _ = outer
        return out
    }

    /// Given the source of a formula `=name(...)`, return the character
    /// indices of the content inside the outermost parens (half-open).
    private static func innerRange(of source: String) -> (Int, Int)? {
        let chars = Array(source)
        guard let lparenIdx = chars.firstIndex(of: "(") else { return nil }
        // Walk from lparenIdx with a smart-quote-aware paren counter to find
        // the matching close.
        var depth = 1
        var k = lparenIdx + 1
        var inString = false
        while k < chars.count && depth > 0 {
            let ch = chars[k]
            if isStringDelimiter(ch) { inString.toggle() }
            if !inString && ch == "(" { depth += 1 }
            if !inString && ch == ")" { depth -= 1 }
            if depth == 0 { return (lparenIdx + 1, k) }
            k += 1
        }
        return nil
    }

    /// Scan from `start` for a `=name(...)` sub-call whose `=` is at `start`
    /// and whose closing `)` is at or before `boundary`. Returns the end index
    /// (exclusive) and the raw source string. Returns nil if there is no
    /// complete sub-call here.
    private static func nextSubCall(chars: [Character], start: Int, boundary: Int) -> (end: Int, source: String)? {
        guard chars[start] == "=" else { return nil }
        // Allow anonymous =(…) or named =name(…)
        var nameEnd = start + 1
        while nameEnd < boundary, chars[nameEnd].isLetter {
            nameEnd += 1
        }
        guard nameEnd < boundary, chars[nameEnd] == "(" else { return nil }
        var depth = 1
        var k = nameEnd + 1
        var inString = false
        while k < boundary && depth > 0 {
            let ch = chars[k]
            if isStringDelimiter(ch) { inString.toggle() }
            if !inString && ch == "(" { depth += 1 }
            if !inString && ch == ")" { depth -= 1 }
            if depth == 0 { break }
            k += 1
        }
        guard depth == 0 else { return nil }
        let sub = String(chars[start...k])
        return (k + 1, sub)
    }

    /// Evaluate a fully-flattened formula source (no more nested calls)
    /// synchronously using the pure evaluators + the document markdown for
    /// =ref resolution. Returns nil if evaluation fails or encounters an
    /// async-only formula (=apfel).
    private static func evaluate(
        flattenedSource: String,
        in markdown: String
    ) async -> String? {
        do {
            let call = try FormulaParser.parse(flattenedSource)
            return try syncEvaluate(call: call, in: markdown)
        } catch {
            return nil
        }
    }

    private static func syncEvaluate(call: FormulaCall, in markdown: String) throws -> String {
        switch call {
        case .math(let expr):
            return try MathFormulaEvaluator.evaluate(expr)
        case .upper(let t):
            return try UpperFormulaEvaluator.evaluate(t)
        case .lower(let t):
            return try LowerFormulaEvaluator.evaluate(t)
        case .trim(let t):
            return try TrimFormulaEvaluator.evaluate(t)
        case .len(let t):
            return try LenFormulaEvaluator.evaluate(t)
        case .concat(let parts):
            return try ConcatFormulaEvaluator.evaluate(parts)
        case .replace(let text, let find, let replacement):
            return try ReplaceFormulaEvaluator.evaluate(text: text, find: find, replacement: replacement)
        case .splitCall(let text, let delim, let index):
            return try SplitFormulaEvaluator.evaluate(text: text, delim: delim, index: index)
        case .ifCall(let cond, let thenValue, let elseValue):
            return try IfFormulaEvaluator.evaluate(cond: cond, thenValue: thenValue, elseValue: elseValue)
        case .sum(let args):
            return try SumFormulaEvaluator.evaluate(args)
        case .avg(let args):
            return try AvgFormulaEvaluator.evaluate(args)
        case .ref(let anchor):
            guard let text = NamedAnchorResolver.resolve(anchor, in: markdown) else {
                throw RuntimeError.anchorNotFound(anchor)
            }
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        case .date(let offsetDays):
            return DateFormulaEvaluator.evaluate(offsetDays: offsetDays)
        case .cw(let offsetWeeks):
            return CwFormulaEvaluator.evaluate(offsetWeeks: offsetWeeks)
        case .month:
            return MonthFormulaEvaluator.evaluate()
        case .day:
            return DayFormulaEvaluator.evaluate()
        case .time:
            return TimeFormulaEvaluator.evaluate()
        case .recording:
            return "🎙 recording"
        case .apfel:
            // =apfel is async — not supported inside nested composition
            // at this depth. The outer evaluator will handle a standalone
            // =apfel span separately.
            throw RuntimeError.apfelRequiresStreamingPath
        }
    }

    private static func escapeQuotes(_ s: String) -> String {
        s.replacingOccurrences(of: "\"", with: "\\\"")
    }

    private static func isStringDelimiter(_ ch: Character) -> Bool {
        switch ch {
        case "\"", "'":
            return true
        case "\u{201C}", "\u{201D}", "\u{201E}", "\u{2018}", "\u{2019}":
            return true
        default:
            return false
        }
    }
}
