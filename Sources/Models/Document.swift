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
    /// Uses a balanced-paren walker so `=math((1+2)*3)` is found. Skips
    /// matches inside markdown code spans (backticks) so prose references
    /// like `` `=apfel(...)` `` are not accidentally evaluated. Also skips
    /// matches whose single argument is literal "..." (a placeholder).
    static func discover(_ text: String) throws -> [FormulaSpan] {
        var out: [FormulaSpan] = []
        let chars = Array(text)
        let n = chars.count
        let codeMask = codeSpanMask(for: chars)
        let knownNames: Set<String> = ["apfel", "math", "ref", "count", "date", "clip", "file"]
        var i = 0
        while i < n {
            if chars[i] != "=" || codeMask[i] {
                i += 1
                continue
            }
            // Read function name
            var j = i + 1
            var name = ""
            while j < n, chars[j].isLetter {
                name.append(chars[j])
                j += 1
            }
            guard knownNames.contains(name), j < n, chars[j] == "(" else {
                i += 1
                continue
            }
            // Balanced-paren walk for the argument list
            var depth = 1
            var k = j + 1
            var inString = false
            while k < n && depth > 0 {
                let ch = chars[k]
                if ch == "\"" { inString.toggle() }
                if !inString && ch == "(" { depth += 1 }
                if !inString && ch == ")" { depth -= 1 }
                if depth == 0 { break }
                k += 1
            }
            if depth != 0 {
                i += 1
                continue
            }
            let sourceChars = chars[i...k]
            let source = String(sourceChars)
            // Skip the placeholder form `=name(...)`
            let argStart = j + 1
            let inner = String(chars[argStart..<k]).trimmingCharacters(in: .whitespaces)
            if inner == "..." {
                i = k + 1
                continue
            }
            do {
                let call = try FormulaParser.parse(source)
                out.append(
                    FormulaSpan(range: i..<(k + 1), source: source, call: call, value: .idle)
                )
            } catch {
                // Skip unparseable matches
            }
            i = k + 1
        }
        return out
    }

    /// Produce a per-character bitmask that is true for every position
    /// inside a markdown code span (single backticks). Multi-line code
    /// fences are handled by the same logic because the markdown editor
    /// still sees them as backtick pairs.
    private static func codeSpanMask(for chars: [Character]) -> [Bool] {
        var mask = Array(repeating: false, count: chars.count)
        var inside = false
        var start: Int = 0
        for i in 0..<chars.count {
            if chars[i] == "`" {
                if !inside {
                    inside = true
                    start = i + 1
                } else {
                    inside = false
                    if start < i {
                        for k in start..<i { mask[k] = true }
                    }
                }
            }
        }
        return mask
    }
}
