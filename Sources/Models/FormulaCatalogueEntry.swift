import Foundation

/// One entry in the formula catalogue shown in the right sidebar.
/// Pure data — carries everything the UI needs to render a row and
/// respond to search / drag / click.
struct FormulaCatalogueEntry: Identifiable, Equatable, Hashable {
    enum Category: String, CaseIterable, Equatable, Hashable {
        case ai
        case math
        case text
        case aggregate
        case control
        case date
        case reference
        case preview

        var title: String {
            switch self {
            case .ai:        return "On-device AI"
            case .math:      return "Arithmetic"
            case .text:      return "Text"
            case .aggregate: return "Aggregates"
            case .control:   return "Control flow"
            case .date:      return "Dates & time"
            case .reference: return "Document references"
            case .preview:   return "v0.4 preview"
            }
        }

        /// Deterministic display order for `FormulaCatalogue.grouped()`.
        var order: Int {
            switch self {
            case .ai:        return 0
            case .math:      return 1
            case .text:      return 2
            case .aggregate: return 3
            case .control:   return 4
            case .date:      return 5
            case .reference: return 6
            case .preview:   return 7
            }
        }
    }

    let id: UUID
    let name: String          // e.g. "=upper"
    let category: Category
    let signature: String     // e.g. "=upper(text)"
    let description: String   // one-line
    let example: String       // a complete formula ready to paste
    let exampleResult: String // what the example evaluates to (for the row preview)
    let keywords: [String]    // search hints (lowercased)

    init(
        name: String,
        category: Category,
        signature: String,
        description: String,
        example: String,
        exampleResult: String,
        keywords: [String] = []
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.signature = signature
        self.description = description
        self.example = example
        self.exampleResult = exampleResult
        self.keywords = keywords.map { $0.lowercased() }
    }
}

/// One section of the grouped catalogue.
struct FormulaCatalogueSection: Identifiable, Equatable {
    var id: String { category.rawValue }
    let category: FormulaCatalogueEntry.Category
    let entries: [FormulaCatalogueEntry]
}
