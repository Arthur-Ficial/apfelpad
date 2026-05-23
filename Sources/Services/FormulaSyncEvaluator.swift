import Foundation

/// Single synchronous evaluation surface for every non-streaming formula.
/// Runtime, nested composition, and document-level helpers should all route
/// through this instead of maintaining parallel switch statements.
enum FormulaSyncEvaluator {
    static func evaluate(
        _ call: FormulaCall,
        documentMarkdown: String? = nil,
        clipboard: any ClipboardReading = SystemClipboard()
    ) throws -> String {
        switch call {
        case .math(let expression):
            return try MathFormulaEvaluator.evaluate(expression)
        case .upper(let text):
            return try UpperFormulaEvaluator.evaluate(text)
        case .lower(let text):
            return try LowerFormulaEvaluator.evaluate(text)
        case .trim(let text):
            return try TrimFormulaEvaluator.evaluate(text)
        case .len(let text):
            return try LenFormulaEvaluator.evaluate(text)
        case .concatenate(let parts):
            return try ConcatenateFormulaEvaluator.evaluate(parts)
        case .substitute(let text, let oldText, let newText, let occurrence):
            return try SubstituteFormulaEvaluator.evaluate(
                text: text,
                find: oldText,
                replacement: newText,
                occurrence: occurrence
            )
        case .split(let text, let delim, let index):
            return try SplitFormulaEvaluator.evaluate(text: text, delim: delim, index: index)
        case .if(let cond, let thenValue, let elseValue):
            return try IfFormulaEvaluator.evaluate(
                cond: cond,
                thenValue: thenValue,
                elseValue: elseValue
            )
        case .sum(let args):
            return try SumFormulaEvaluator.evaluate(args)
        case .average(let args):
            return try AverageFormulaEvaluator.evaluate(args)
        case .ref(let anchor):
            guard let documentMarkdown else {
                throw RuntimeError.refRequiresDocumentContext
            }
            guard let text = NamedAnchorResolver.resolve(anchor, in: documentMarkdown) else {
                throw RuntimeError.anchorNotFound(anchor)
            }
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        case .date(let offsetDays):
            return DateFormulaEvaluator.evaluate(offsetDays: offsetDays)
        case .weeknum(let offsetWeeks):
            return WeeknumFormulaEvaluator.evaluate(offsetWeeks: offsetWeeks)
        case .today:
            return DateFormulaEvaluator.evaluate(offsetDays: 0)
        case .month:
            return MonthFormulaEvaluator.evaluate()
        case .day:
            return DayFormulaEvaluator.evaluate()
        case .time:
            return TimeFormulaEvaluator.evaluate()
        case .recording:
            return "🎙 recording UI — v0.4 (tap to record via apfel)"
        case .count(let anchor):
            guard let documentMarkdown else {
                throw RuntimeError.refRequiresDocumentContext
            }
            return CountFormulaEvaluator.evaluate(anchor: anchor, in: documentMarkdown)
        case .clip:
            return ClipFormulaEvaluator.evaluate(clipboard: clipboard)
        case .file(let path):
            return try FileFormulaEvaluator.evaluate(path: path)
        case .apfel:
            throw RuntimeError.apfelRequiresStreamingPath
        case .input, .show:
            throw RuntimeError.inputRequiresDocumentContext
        case .isnumber(let v):
            return IsNumberFormulaEvaluator.evaluate(v)
        case .istext(let v):
            return IsTextFormulaEvaluator.evaluate(v)
        case .isblank(let v):
            return IsBlankFormulaEvaluator.evaluate(v)
        case .type(let v):
            return TypeFormulaEvaluator.evaluate(v)
        case .now:
            return NowFormulaEvaluator.evaluate()
        case .year:
            return YearFormulaEvaluator.evaluate()
        case .weekday:
            return WeekdayFormulaEvaluator.evaluate()
        case .hour:
            return HourFormulaEvaluator.evaluate()
        case .minute:
            return MinuteFormulaEvaluator.evaluate()
        case .second:
            return SecondFormulaEvaluator.evaluate()
        case .and(let args):
            return AndFormulaEvaluator.evaluate(args)
        case .or(let args):
            return OrFormulaEvaluator.evaluate(args)
        case .not(let v):
            return NotFormulaEvaluator.evaluate(v)
        case .iferror(let v, let fb):
            return try IfErrorFormulaEvaluator.evaluate(value: v, fallback: fb)
        case .switchCall(let args):
            return try SwitchFormulaEvaluator.evaluate(args: args)
        case .ifs(let args):
            return try IfsFormulaEvaluator.evaluate(args: args)
        case .trueLit:
            return TrueFormulaEvaluator.evaluate()
        case .falseLit:
            return FalseFormulaEvaluator.evaluate()
        case .left(let t, let n):
            return try LeftFormulaEvaluator.evaluate(text: t, n: n)
        case .right(let t, let n):
            return try RightFormulaEvaluator.evaluate(text: t, n: n)
        case .mid(let t, let s, let l):
            return try MidFormulaEvaluator.evaluate(text: t, start: s, length: l)
        case .find(let n, let h, let s):
            return try FindFormulaEvaluator.evaluate(needle: n, haystack: h, start: s)
        case .search(let n, let h, let s):
            return try SearchFormulaEvaluator.evaluate(needle: n, haystack: h, start: s)
        case .rept(let t, let n):
            return ReptFormulaEvaluator.evaluate(text: t, n: n)
        case .proper(let t):
            return ProperFormulaEvaluator.evaluate(t)
        case .clean(let t):
            return CleanFormulaEvaluator.evaluate(t)
        case .exact(let a, let b):
            return ExactFormulaEvaluator.evaluate(a: a, b: b)
        case .char(let c):
            return try CharFormulaEvaluator.evaluate(c)
        case .code(let t):
            return try CodeFormulaEvaluator.evaluate(t)
        case .textjoin(let d, let ie, let parts):
            return TextJoinFormulaEvaluator.evaluate(delim: d, ignoreEmpty: ie, parts: parts)
        case .value(let t):
            return try ValueFormulaEvaluator.evaluate(t)
        case .textFmt(let v, let f):
            return try TextFormulaEvaluator.evaluate(value: v, format: f)
        }
    }
}
