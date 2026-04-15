import Foundation

/// One ready-to-load example workbook shown in the left "Examples" sidebar.
/// The library gives users a one-click jumping-off point: math calculators,
/// email drafts, planning sheets, etc. Loading an example replaces the
/// current document via `DocumentViewModel.load(rawMarkdown:)`.
struct ExampleDocument: Identifiable, Equatable, Hashable {
    enum Category: String, CaseIterable, Hashable {
        case starter
        case calculator
        case productivity
        case writing
        case ai
        case life

        var title: String {
            switch self {
            case .starter:      return "GET STARTED"
            case .calculator:   return "CALCULATORS"
            case .productivity: return "PRODUCTIVITY"
            case .writing:      return "WRITING & EMAIL"
            case .ai:           return "ON-DEVICE AI"
            case .life:         return "EVERYDAY LIFE"
            }
        }

        var order: Int {
            switch self {
            case .starter:      return 0
            case .calculator:   return 1
            case .productivity: return 2
            case .writing:      return 3
            case .ai:           return 4
            case .life:         return 5
            }
        }
    }

    let id: UUID
    let title: String
    let blurb: String
    let icon: String
    let category: Category
    let body: String

    init(
        title: String,
        blurb: String,
        icon: String,
        category: Category,
        body: String
    ) {
        self.id = UUID()
        self.title = title
        self.blurb = blurb
        self.icon = icon
        self.category = category
        self.body = body
    }
}

struct ExamplesLibrarySection: Identifiable, Equatable {
    var id: String { category.rawValue }
    let category: ExampleDocument.Category
    let entries: [ExampleDocument]
}
