import Foundation
import Observation

@Observable
@MainActor
final class FormulaBarViewModel {
    var sourceText: String = ""
    var selectedSpanID: UUID? = nil
    let placeholder: String = "click a formula span to edit its source"

    func select(_ span: FormulaSpan) {
        selectedSpanID = span.id
        sourceText = span.source
    }

    func clear() {
        selectedSpanID = nil
        sourceText = ""
    }
}
