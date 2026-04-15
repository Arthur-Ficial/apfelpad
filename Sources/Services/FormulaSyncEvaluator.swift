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
        }
    }
}
