import Foundation

enum CountFormulaEvaluator {
    static func evaluate(anchor: String?, in markdown: String) -> String {
        let text: String
        if let anchor {
            text = NamedAnchorResolver.resolve(anchor, in: markdown)
                ?? ""
        } else {
            text = markdown
        }
        let count = text.split { $0.isWhitespace }.count
        return String(count)
    }
}
