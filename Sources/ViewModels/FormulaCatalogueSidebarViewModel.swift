import Foundation
import Observation

/// State for the right-hand formula catalogue sidebar.
/// Pure Swift, no SwiftUI imports — the view binds to this.
@Observable
@MainActor
final class FormulaCatalogueSidebarViewModel {
    // MARK: - State

    var isOpen: Bool {
        didSet {
            UserDefaults.standard.set(isOpen, forKey: persistKey)
        }
    }
    var searchQuery: String = ""
    var selectedEntryID: FormulaCatalogueEntry.ID? = nil

    /// Callback invoked when a formula is inserted (by click or Enter).
    /// The document view model plugs this in to receive the source text.
    var onInsert: ((String) -> Void)? = nil

    private let persistKey: String

    init(persistKey: String = FormulaCatalogueSidebarViewModel.defaultPersistKey) {
        self.persistKey = persistKey
        if UserDefaults.standard.object(forKey: persistKey) == nil {
            self.isOpen = false
        } else {
            self.isOpen = UserDefaults.standard.bool(forKey: persistKey)
        }
    }

    static let defaultPersistKey = "apfelpad_formula_catalogue_sidebar_open"

    // MARK: - Derived

    /// Sections filtered by the current search query. Empty query → all.
    var visibleSections: [FormulaCatalogueSection] {
        FormulaCatalogue.groupedSearch(searchQuery)
    }

    var totalVisibleCount: Int {
        visibleSections.reduce(0) { $0 + $1.entries.count }
    }

    // MARK: - Actions

    func toggle() { isOpen.toggle() }
    func open()   { isOpen = true }
    func close()  { isOpen = false }

    /// Insert a formula into the document via the registered callback.
    func insert(_ entry: FormulaCatalogueEntry) {
        onInsert?(entry.example)
    }
}
