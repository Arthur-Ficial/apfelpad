import Foundation
import Observation

/// State for the left-hand Examples library sidebar. Mirrors the shape of
/// `FormulaCatalogueSidebarViewModel` so the views feel symmetric.
@Observable
@MainActor
final class ExamplesSidebarViewModel {
    var isOpen: Bool {
        didSet {
            UserDefaults.standard.set(isOpen, forKey: persistKey)
        }
    }
    var searchQuery: String = ""

    /// Callback invoked when the user picks an example. The document VM
    /// plugs this in to receive the markdown body and load it.
    var onLoad: ((ExampleDocument) -> Void)? = nil

    private let persistKey: String

    init(persistKey: String = ExamplesSidebarViewModel.defaultPersistKey) {
        self.persistKey = persistKey
        if UserDefaults.standard.object(forKey: persistKey) == nil {
            self.isOpen = false
        } else {
            self.isOpen = UserDefaults.standard.bool(forKey: persistKey)
        }
    }

    static let defaultPersistKey = "apfelpad_examples_sidebar_open"

    var visibleSections: [ExamplesLibrarySection] {
        ExamplesLibrary.groupedSearch(searchQuery)
    }

    var totalVisibleCount: Int {
        visibleSections.reduce(0) { $0 + $1.entries.count }
    }

    func toggle() { isOpen.toggle() }
    func open()   { isOpen = true }
    func close()  { isOpen = false }

    /// Closes any peer sidebars (passed in) before opening this one, so only
    /// one right-side panel is visible at a time.
    func toggle(closing peers: [() -> Void]) {
        if isOpen {
            isOpen = false
        } else {
            peers.forEach { $0() }
            isOpen = true
        }
    }

    func load(_ entry: ExampleDocument) {
        onLoad?(entry)
    }
}
