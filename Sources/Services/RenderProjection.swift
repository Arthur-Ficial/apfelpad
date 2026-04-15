import Foundation

/// Maps the raw markdown document to the editable text shown in Render mode.
/// Plain text stays editable 1:1. Formula spans become atomic chips. Input
/// spans reserve visible space for live widgets that are overlaid on the same
/// editor surface.
struct RenderProjection: Equatable {
    struct InputSpec: Equatable {
        let span: FormulaSpan
        let name: String
        let type: InputType
        let defaultValue: String?
        let placeholder: String
    }

    struct Segment: Equatable {
        enum Kind: Equatable {
            case plain
            case formula(span: FormulaSpan)
            case input(InputSpec)
        }

        let rawRange: Range<Int>
        let visibleRange: Range<Int>
        let kind: Kind

        var atomicSpan: FormulaSpan? {
            switch kind {
            case .plain:
                return nil
            case .formula(let span):
                return span
            case .input(let spec):
                return spec.span
            }
        }
    }

    let rawText: String
    let visibleText: String
    let segments: [Segment]

    init(document: Document) {
        rawText = document.rawMarkdown

        let ns = document.rawMarkdown as NSString
        let orderedSpans = document.spansInSourceOrder

        var pieces: [String] = []
        var builtSegments: [Segment] = []
        var rawCursor = 0
        var visibleCursor = 0
        pieces.reserveCapacity(orderedSpans.count * 2 + 1)
        builtSegments.reserveCapacity(orderedSpans.count * 2 + 1)

        func appendPlain(until upperBound: Int) {
            guard upperBound > rawCursor else { return }
            let length = upperBound - rawCursor
            let slice = ns.substring(with: NSRange(location: rawCursor, length: length))
            let visibleLength = (slice as NSString).length
            pieces.append(slice)
            builtSegments.append(Segment(
                rawRange: rawCursor..<upperBound,
                visibleRange: visibleCursor..<(visibleCursor + visibleLength),
                kind: .plain
            ))
            rawCursor = upperBound
            visibleCursor += visibleLength
        }

        for span in orderedSpans {
            appendPlain(until: span.range.lowerBound)

            switch span.call {
            case .input(let name, let type, let defaultValue):
                let placeholder = Self.inputPlaceholder(
                    name: name,
                    type: type,
                    currentValue: Self.displayValue(for: span, fallback: defaultValue ?? "")
                )
                let visibleLength = (placeholder as NSString).length
                pieces.append(placeholder)
                builtSegments.append(Segment(
                    rawRange: span.range,
                    visibleRange: visibleCursor..<(visibleCursor + visibleLength),
                    kind: .input(InputSpec(
                        span: span,
                        name: name,
                        type: type,
                        defaultValue: defaultValue,
                        placeholder: placeholder
                    ))
                ))
                visibleCursor += visibleLength
            default:
                let display = " \(span.displayText) "
                let visibleLength = (display as NSString).length
                pieces.append(display)
                builtSegments.append(Segment(
                    rawRange: span.range,
                    visibleRange: visibleCursor..<(visibleCursor + visibleLength),
                    kind: .formula(span: span)
                ))
                visibleCursor += visibleLength
            }

            rawCursor = span.range.upperBound
        }

        appendPlain(until: ns.length)

        visibleText = pieces.joined()
        segments = builtSegments
    }

    func visibleLocation(forRawLocation location: Int) -> Int {
        let clamped = max(0, min(location, (rawText as NSString).length))
        for segment in segments {
            guard clamped >= segment.rawRange.lowerBound,
                  clamped <= segment.rawRange.upperBound else {
                continue
            }

            switch segment.kind {
            case .plain:
                return segment.visibleRange.lowerBound + (clamped - segment.rawRange.lowerBound)
            case .formula, .input:
                if clamped <= segment.rawRange.lowerBound { return segment.visibleRange.lowerBound }
                return segment.visibleRange.upperBound
            }
        }
        return clamped
    }

    func rawBoundary(forVisibleLocation location: Int) -> Int? {
        let clamped = max(0, min(location, (visibleText as NSString).length))
        if clamped == 0 { return 0 }
        if clamped == (visibleText as NSString).length {
            return (rawText as NSString).length
        }

        for segment in segments {
            guard clamped >= segment.visibleRange.lowerBound,
                  clamped <= segment.visibleRange.upperBound else {
                continue
            }

            switch segment.kind {
            case .plain:
                return segment.rawRange.lowerBound + (clamped - segment.visibleRange.lowerBound)
            case .formula, .input:
                if clamped == segment.visibleRange.lowerBound { return segment.rawRange.lowerBound }
                if clamped == segment.visibleRange.upperBound { return segment.rawRange.upperBound }
                return nil
            }
        }

        return clamped
    }

    func atomicSpan(atVisibleLocation location: Int) -> FormulaSpan? {
        for segment in segments {
            guard location >= segment.visibleRange.lowerBound,
                  location < segment.visibleRange.upperBound else {
                continue
            }
            return segment.atomicSpan
        }
        return nil
    }

    func firstAtomicSpanIntersecting(visibleRange: NSRange) -> FormulaSpan? {
        let range = visibleRange.location..<(visibleRange.location + visibleRange.length)
        for segment in segments {
            guard let span = segment.atomicSpan else { continue }
            if rangesOverlap(segment.visibleRange, range) {
                return span
            }
        }
        return nil
    }

    func inputSegments() -> [Segment] {
        segments.filter {
            if case .input = $0.kind { return true }
            return false
        }
    }

    func rawEditRange(forVisibleRange visibleRange: NSRange) -> NSRange? {
        let selection = visibleRange.location..<(visibleRange.location + visibleRange.length)

        for segment in segments {
            guard segment.atomicSpan != nil else { continue }
            guard rangesOverlap(segment.visibleRange, selection) else { continue }
            let fullyCoversSegment =
                selection.lowerBound <= segment.visibleRange.lowerBound &&
                selection.upperBound >= segment.visibleRange.upperBound
            if !fullyCoversSegment { return nil }
        }

        guard let rawStart = rawBoundary(forVisibleLocation: visibleRange.location),
              let rawEnd = rawBoundary(forVisibleLocation: visibleRange.location + visibleRange.length),
              rawEnd >= rawStart else {
            return nil
        }

        return NSRange(location: rawStart, length: rawEnd - rawStart)
    }

    private static func displayValue(for span: FormulaSpan, fallback: String) -> String {
        switch span.value {
        case .ready(let text), .stale(let text):
            return text.isEmpty ? fallback : text
        default:
            return fallback
        }
    }

    private static func inputPlaceholder(
        name: String,
        type: InputType,
        currentValue: String
    ) -> String {
        let visibleValue = currentValue.isEmpty ? "value" : currentValue
        switch type {
        case .textarea:
            return " [\(name): \(visibleValue)]\n [text area]\n [continues here] "
        case .range:
            return " [\(name): \(visibleValue) slider] "
        case .date, .time, .datetime:
            return " [\(name): \(visibleValue)] "
        case .boolean, .toggle:
            return " [\(name): \(visibleValue)] "
        case .color:
            return " [\(name): \(visibleValue)] "
        default:
            return " [\(name): \(visibleValue)] "
        }
    }

    private func rangesOverlap(_ lhs: Range<Int>, _ rhs: Range<Int>) -> Bool {
        lhs.lowerBound < rhs.upperBound && rhs.lowerBound < lhs.upperBound
    }
}
