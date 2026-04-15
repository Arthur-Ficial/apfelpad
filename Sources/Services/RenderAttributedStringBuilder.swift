import AppKit
import Markdown

/// Builds the attributed text shown in render mode.
/// Typography is applied once over the full visible document via swift-markdown,
/// then formula and input segments layer their own styling on top.
@MainActor
enum RenderAttributedStringBuilder {
    static func build(from projection: RenderProjection) -> NSAttributedString {
        let out = NSMutableAttributedString(string: projection.visibleText, attributes: [
            .font: NSFont.systemFont(ofSize: 15),
            .foregroundColor: NSColor.labelColor,
        ])

        applyMarkdownTypography(to: out)

        let inputParagraphs = NSMutableIndexSet()

        for segment in projection.segments {
            let visibleRange = NSRange(
                location: segment.visibleRange.lowerBound,
                length: segment.visibleRange.upperBound - segment.visibleRange.lowerBound
            )

            switch segment.kind {
            case .plain:
                continue
            case .formula(let span):
                out.addAttributes(renderAttributes(for: span), range: visibleRange)
                out.addAttribute(
                    .link,
                    value: URL(string: "apfelpad://span/\(span.id.uuidString)") as Any,
                    range: visibleRange
                )
            case .input:
                out.addAttributes([
                    .foregroundColor: NSColor.clear,
                    .backgroundColor: NSColor.clear,
                ], range: visibleRange)
                let pr = (out.string as NSString).paragraphRange(for: visibleRange)
                inputParagraphs.add(in: pr)
            }
        }

        applyInputLineSpacing(to: out, paragraphs: inputParagraphs)

        return out
    }

    // MARK: - Markdown typography

    /// Parse the visible text via swift-markdown and apply font / colour
    /// attributes for headings, emphasis, strong, inline code, blockquotes,
    /// and lists. Ranges are computed by walking source locations on each
    /// Markup node.
    private static func applyMarkdownTypography(to text: NSMutableAttributedString) {
        let source = text.string
        let document = Markdown.Document(parsing: source)
        let offsets = LineOffsets(source: source)

        var walker = MarkdownStyler(text: text, offsets: offsets)
        walker.visit(document)
    }

    /// Inflate the line height for any paragraph that hosts an =input widget so
    /// the inline NSView overlay (≈22pt tall) does not collide with adjacent
    /// lines. Without this, stacked input rows visually overlap.
    private static func applyInputLineSpacing(
        to text: NSMutableAttributedString,
        paragraphs: NSIndexSet
    ) {
        let style = NSMutableParagraphStyle()
        style.minimumLineHeight = 0
        style.lineSpacing = 0
        paragraphs.enumerateRanges { range, _ in
            text.addAttribute(.paragraphStyle, value: style, range: range)
        }
    }

    private static func renderAttributes(for span: FormulaSpan) -> [NSAttributedString.Key: Any] {
        return [
            .backgroundColor: AppTheme.formulaChipBackgroundNSColor(for: span),
            .foregroundColor: AppTheme.formulaChipForegroundNSColor(for: span),
            .font: AppTheme.chipFontNSFont,
            .cursor: NSCursor.pointingHand,
        ]
    }
}

// MARK: - Source-location → NSString offset table

/// UTF-16 offsets of the start of each line in `source`. swift-markdown
/// reports source locations as 1-based (line, column); NSAttributedString
/// uses UTF-16 offsets, so we precompute one table per render.
private struct LineOffsets {
    private let lineStarts: [Int]
    private let totalLength: Int

    init(source: String) {
        let ns = source as NSString
        var offsets: [Int] = [0]
        var i = 0
        let len = ns.length
        while i < len {
            let c = ns.character(at: i)
            i += 1
            if c == 0x0A { // \n
                offsets.append(i)
            } else if c == 0x0D { // \r
                if i < len, ns.character(at: i) == 0x0A { i += 1 }
                offsets.append(i)
            }
        }
        self.lineStarts = offsets
        self.totalLength = len
    }

    /// Convert a swift-markdown SourceLocation (1-based line/column,
    /// column counted in unicode scalars) to an NSString UTF-16 offset.
    func offset(for location: SourceLocation) -> Int {
        let lineIndex = max(0, location.line - 1)
        guard lineIndex < lineStarts.count else { return totalLength }
        return min(totalLength, lineStarts[lineIndex] + max(0, location.column - 1))
    }

    func nsRange(from sourceRange: SourceRange) -> NSRange {
        let lo = offset(for: sourceRange.lowerBound)
        let hi = offset(for: sourceRange.upperBound)
        let location = max(0, min(lo, totalLength))
        let length = max(0, min(hi, totalLength) - location)
        return NSRange(location: location, length: length)
    }
}

// MARK: - Markup walker

private struct MarkdownStyler: MarkupWalker {
    let text: NSMutableAttributedString
    let offsets: LineOffsets

    var totalLength: Int { text.length }

    mutating func visitHeading(_ heading: Heading) {
        guard let range = heading.range else { return }
        let nsRange = offsets.nsRange(from: range)
        guard nsRange.length > 0 else { return }

        let prefixLength = heading.level + 1 // e.g. "# " = 2
        let safePrefix = min(prefixLength, nsRange.length)
        let prefixRange = NSRange(location: nsRange.location, length: safePrefix)
        let bodyLocation = nsRange.location + safePrefix
        let bodyLength = max(0, nsRange.length - safePrefix)
        let bodyRange = NSRange(location: bodyLocation, length: bodyLength)

        hidePrefix(prefixRange)

        let font: NSFont
        switch heading.level {
        case 1: font = NSFont.systemFont(ofSize: 28, weight: .bold)
        case 2: font = NSFont.systemFont(ofSize: 22, weight: .semibold)
        case 3: font = NSFont.systemFont(ofSize: 18, weight: .semibold)
        case 4: font = NSFont.systemFont(ofSize: 16, weight: .semibold)
        default: font = NSFont.systemFont(ofSize: 15, weight: .semibold)
        }
        if bodyRange.length > 0 {
            text.addAttribute(.font, value: font, range: bodyRange)
        }
    }

    mutating func visitStrong(_ strong: Strong) {
        applyFont(in: strong.range, transform: { boldify($0) })
        hideMarkers(around: strong, markerLength: 2)
        descendInto(strong)
    }

    mutating func visitEmphasis(_ emphasis: Emphasis) {
        applyFont(in: emphasis.range, transform: { italicize($0) })
        hideMarkers(around: emphasis, markerLength: 1)
        descendInto(emphasis)
    }

    mutating func visitInlineCode(_ code: InlineCode) {
        guard let range = code.range else { return }
        let nsRange = clamp(offsets.nsRange(from: range))
        guard nsRange.length > 0 else { return }
        text.addAttributes([
            .font: NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
            .backgroundColor: AppTheme.chromeBackgroundNSColor,
        ], range: nsRange)
        // Hide the surrounding backticks (always 1 each in spec-compliant
        // markdown — runs of N backticks are rare and we leave them visible).
        if nsRange.length >= 2 {
            hidePrefix(NSRange(location: nsRange.location, length: 1))
            hidePrefix(NSRange(location: nsRange.location + nsRange.length - 1, length: 1))
        }
    }

    /// Hide the leading + trailing markdown markers (e.g. `**` / `*`) around
    /// an inline node by collapsing their character range to invisible.
    private func hideMarkers(around node: InlineContainer, markerLength: Int) {
        guard let range = node.range else { return }
        let nsRange = clamp(offsets.nsRange(from: range))
        guard nsRange.length >= markerLength * 2 else { return }
        hidePrefix(NSRange(location: nsRange.location, length: markerLength))
        hidePrefix(NSRange(
            location: nsRange.location + nsRange.length - markerLength,
            length: markerLength
        ))
    }

    mutating func visitCodeBlock(_ block: CodeBlock) {
        guard let range = block.range else { return }
        let nsRange = clamp(offsets.nsRange(from: range))
        guard nsRange.length > 0 else { return }
        text.addAttributes([
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
            .backgroundColor: AppTheme.chromeBackgroundNSColor,
        ], range: nsRange)
    }

    mutating func visitBlockQuote(_ quote: BlockQuote) {
        guard let range = quote.range else { return }
        let nsRange = clamp(offsets.nsRange(from: range))
        guard nsRange.length > 0 else { return }
        text.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: nsRange)
        descendInto(quote)
    }

    mutating func visitTable(_ table: Table) {
        guard let range = table.range else { return }
        let nsRange = clamp(offsets.nsRange(from: range))
        guard nsRange.length > 0 else { return }

        // Monospaced font over the whole table makes columns line up since
        // we render in a flat NSTextView (no real table layout).
        text.addAttribute(
            .font,
            value: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
            range: nsRange
        )

        // Bold the header row.
        if let headRange = table.head.range {
            let headNS = clamp(offsets.nsRange(from: headRange))
            if headNS.length > 0 {
                text.addAttribute(
                    .font,
                    value: NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold),
                    range: headNS
                )
            }
        }

        // Hide the separator row between header and body — the `|---|---|`
        // line is layout noise to the reader.
        hideAlignmentRow(after: table.head, within: nsRange)

        descendInto(table)
    }

    mutating func visitUnorderedList(_ list: UnorderedList) {
        descendInto(list)
    }

    mutating func visitOrderedList(_ list: OrderedList) {
        descendInto(list)
    }

    mutating func visitThematicBreak(_ rule: ThematicBreak) {
        guard let range = rule.range else { return }
        let nsRange = clamp(offsets.nsRange(from: range))
        guard nsRange.length > 0 else { return }
        text.addAttributes([
            .foregroundColor: NSColor.tertiaryLabelColor,
        ], range: nsRange)
    }

    /// In the NSAttributedString, find the line immediately after the table
    /// header row and hide it. That line is the alignment row (e.g. `|---|---|`)
    /// which is part of GFM tables but not part of the visible content.
    private func hideAlignmentRow(after head: Table.Head, within tableRange: NSRange) {
        guard let headRange = head.range else { return }
        let headNS = clamp(offsets.nsRange(from: headRange))
        let ns = text.string as NSString
        let cursor = headNS.location + headNS.length
        guard cursor < tableRange.location + tableRange.length else { return }
        let lineRange = ns.lineRange(for: NSRange(location: cursor, length: 0))
        let safe = clamp(lineRange)
        guard safe.length > 0 else { return }
        text.addAttributes([
            .foregroundColor: NSColor.clear,
            .font: NSFont.systemFont(ofSize: 1),
        ], range: safe)
    }

    mutating func visitLink(_ link: Link) {
        guard let range = link.range else { return }
        let nsRange = clamp(offsets.nsRange(from: range))
        guard nsRange.length > 0 else { return }
        text.addAttributes([
            .foregroundColor: NSColor.linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ], range: nsRange)
        descendInto(link)
    }

    // MARK: - Helpers

    private func clamp(_ r: NSRange) -> NSRange {
        let location = max(0, min(r.location, totalLength))
        let length = max(0, min(r.length, totalLength - location))
        return NSRange(location: location, length: length)
    }

    private func hidePrefix(_ range: NSRange) {
        let safe = clamp(range)
        guard safe.length > 0 else { return }
        text.addAttributes([
            .foregroundColor: NSColor.clear,
            .font: NSFont.systemFont(ofSize: 1),
        ], range: safe)
    }

    /// Apply a font transform to every existing font attribute run inside the
    /// given source range. This preserves heading sizes etc. while layering
    /// bold / italic on top.
    private func applyFont(in sourceRange: SourceRange?, transform: (NSFont) -> NSFont) {
        guard let sourceRange else { return }
        let nsRange = clamp(offsets.nsRange(from: sourceRange))
        guard nsRange.length > 0 else { return }
        text.enumerateAttribute(.font, in: nsRange, options: []) { value, sub, _ in
            let base = (value as? NSFont) ?? NSFont.systemFont(ofSize: 15)
            text.addAttribute(.font, value: transform(base), range: sub)
        }
    }

    private func boldify(_ font: NSFont) -> NSFont {
        let traits = font.fontDescriptor.symbolicTraits.union(.bold)
        let descriptor = font.fontDescriptor.withSymbolicTraits(traits)
        return NSFont(descriptor: descriptor, size: font.pointSize) ?? font
    }

    private func italicize(_ font: NSFont) -> NSFont {
        let traits = font.fontDescriptor.symbolicTraits.union(.italic)
        let descriptor = font.fontDescriptor.withSymbolicTraits(traits)
        return NSFont(descriptor: descriptor, size: font.pointSize) ?? font
    }
}
