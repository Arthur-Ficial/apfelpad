import Foundation

struct FormulaSpan: Identifiable, Equatable {
    let id: UUID
    var range: Range<Int>
    var source: String
    var call: FormulaCall
    var value: FormulaValue

    init(
        id: UUID = UUID(),
        range: Range<Int>,
        source: String,
        call: FormulaCall,
        value: FormulaValue
    ) {
        self.id = id
        self.range = range
        self.source = source
        self.call = call
        self.value = value
    }

    var displayText: String {
        switch value {
        case .idle: return source
        case .evaluating: return "…"
        case .streaming(let partial): return partial.isEmpty ? "…" : partial
        case .ready(let text): return text
        case .stale(let text): return text
        case .error(let message): return message
        }
    }

    var isError: Bool {
        if case .error = value {
            return true
        }
        return false
    }

    var isStale: Bool {
        if case .stale = value {
            return true
        }
        return false
    }
}
