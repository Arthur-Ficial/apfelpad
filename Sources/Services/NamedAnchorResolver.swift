import Foundation

/// Resolves `@anchor` references to the text of a named markdown section.
/// A "section" is everything under a heading up to the next heading of
/// equal or higher level. Anchor names are slugified (lowercased,
/// non-alphanumerics → `-`) so the user can write `@intro` or `@My Heading`.
enum NamedAnchorResolver {
    static func resolve(_ rawAnchor: String, in markdown: String) -> String? {
        let wanted = slug(stripAtSign(rawAnchor))

        // Line-by-line scan for ATX headings.
        let lines = markdown.components(separatedBy: "\n")
        var i = 0
        while i < lines.count {
            if let (level, title) = atxHeading(from: lines[i]),
               slug(title) == wanted {
                // Collect body until next heading of level <= `level`
                var body: [String] = []
                var j = i + 1
                while j < lines.count {
                    if let (nextLevel, _) = atxHeading(from: lines[j]),
                       nextLevel <= level {
                        break
                    }
                    body.append(lines[j])
                    j += 1
                }
                return body.joined(separator: "\n")
            }
            i += 1
        }
        return nil
    }

    /// Parse an ATX heading line like `## Title` into (level, title).
    /// Returns nil if the line is not a heading.
    static func atxHeading(from line: String) -> (level: Int, title: String)? {
        var level = 0
        var idx = line.startIndex
        while idx < line.endIndex, line[idx] == "#", level < 6 {
            level += 1
            idx = line.index(after: idx)
        }
        guard level > 0, idx < line.endIndex, line[idx] == " " else {
            return nil
        }
        let title = String(line[line.index(after: idx)...])
            .trimmingCharacters(in: .whitespaces)
        return (level, title)
    }

    /// Strip a single leading `@` character if present.
    static func stripAtSign(_ s: String) -> String {
        s.hasPrefix("@") ? String(s.dropFirst()) : s
    }

    /// Slugify: lowercase, non-alphanumeric → `-`, collapse runs, trim.
    static func slug(_ s: String) -> String {
        var out = ""
        var lastWasDash = false
        for ch in s.lowercased() {
            if ch.isLetter || ch.isNumber {
                out.append(ch)
                lastWasDash = false
            } else if !lastWasDash {
                out.append("-")
                lastWasDash = true
            }
        }
        // Trim leading/trailing dashes
        while out.hasPrefix("-") { out.removeFirst() }
        while out.hasSuffix("-") { out.removeLast() }
        return out
    }
}
