import Foundation

/// Static catalogue derived from `FormulaRegistry`, so the sidebar, docs
/// validation, parser discovery, and examples all describe the same product.
enum FormulaCatalogue {
    static let all: [FormulaCatalogueEntry] = FormulaRegistry.publicDefinitions.map(\.catalogueEntry)

    /// Case-insensitive search across name, signature, description, example,
    /// and keyword list. Empty query returns every entry.
    static func search(_ query: String) -> [FormulaCatalogueEntry] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return all }
        return all.filter { entry in
            if entry.name.lowercased().contains(q) { return true }
            if entry.signature.lowercased().contains(q) { return true }
            if entry.description.lowercased().contains(q) { return true }
            if entry.example.lowercased().contains(q) { return true }
            if entry.category.title.lowercased().contains(q) { return true }
            for keyword in entry.keywords where keyword.contains(q) { return true }
            return false
        }
    }

    /// Returns entries grouped by category, in a deterministic display order.
    /// Entries within each section are sorted alphabetically by name.
    static func grouped() -> [FormulaCatalogueSection] {
        let byCategory = Dictionary(grouping: all, by: \.category)
        let sortedCategories = FormulaCatalogueEntry.Category.allCases
            .filter { byCategory[$0] != nil }
            .sorted { $0.order < $1.order }
        return sortedCategories.map { category in
            let entries = byCategory[category, default: []].sorted { $0.name < $1.name }
            return FormulaCatalogueSection(category: category, entries: entries)
        }
    }

    /// Same as grouped(), but filters by the search query first.
    /// Sections with no matching entries are omitted.
    static func groupedSearch(_ query: String) -> [FormulaCatalogueSection] {
        let matching = Set(search(query).map(\.id))
        return grouped().compactMap { section in
            let kept = section.entries.filter { matching.contains($0.id) }
            return kept.isEmpty ? nil : FormulaCatalogueSection(category: section.category, entries: kept)
        }
    }
}
