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
}
