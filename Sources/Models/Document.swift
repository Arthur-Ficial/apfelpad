import Foundation

/// A document is raw markdown plus discovered formula spans.
/// The markdown is the source of truth; spans are derived.
struct Document: Equatable {
    var rawMarkdown: String
    var spans: [FormulaSpan]

    init(rawMarkdown: String) throws {
        self.rawMarkdown = rawMarkdown
        self.spans = try Self.discover(rawMarkdown)
    }

    private init(rawMarkdown: String, spans: [FormulaSpan]) {
        self.rawMarkdown = rawMarkdown
        self.spans = spans
    }

    static var empty: Document {
        Document(rawMarkdown: "", spans: [])
    }

    /// Scan the raw markdown for formula calls of the form `=name(...)`.
    /// v0.1 supports simple (non-nested) parens. Nested formulas arrive in v0.2.
    static func discover(_ text: String) throws -> [FormulaSpan] {
        var out: [FormulaSpan] = []
        let ns = text as NSString
        let pattern = #"=(apfel|math|ref|count|date|clip|file)\(([^()]*)\)"#
        let regex = try NSRegularExpression(pattern: pattern)
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        for m in matches {
            let src = ns.substring(with: m.range)
            do {
                let call = try FormulaParser.parse(src)
                let r = m.range.location..<(m.range.location + m.range.length)
                out.append(
                    FormulaSpan(range: r, source: src, call: call, value: .idle)
                )
            } catch {
                // Skip unparseable matches in v0.1; v0.2 will render them as errors.
                continue
            }
        }
        return out
    }
}
