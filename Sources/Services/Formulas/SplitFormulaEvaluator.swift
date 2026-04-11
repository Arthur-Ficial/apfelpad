import Foundation

enum SplitFormulaEvaluator {
    /// Return the `index`-th piece of `text` split by `delim`. Out-of-range → "".
    static func evaluate(text: String, delim: String, index: Int) throws -> String {
        let pieces = text.components(separatedBy: delim)
        guard index >= 0, index < pieces.count else { return "" }
        return pieces[index]
    }
}
