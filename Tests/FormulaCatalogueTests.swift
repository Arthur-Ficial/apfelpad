import Testing
@testable import apfelpad

@Suite("FormulaCatalogue")
struct FormulaCatalogueTests {
    @Test("contains every v0.3.1 formula (at least 19 entries)")
    func count() {
        #expect(FormulaCatalogue.all.count >= 19)
    }

    @Test("every entry has a non-empty name, description, and example")
    func wellFormed() {
        for entry in FormulaCatalogue.all {
            #expect(!entry.name.isEmpty)
            #expect(!entry.description.isEmpty)
            #expect(!entry.example.isEmpty)
            #expect(entry.name.hasPrefix("="))
            // Example must start with = too — it's a complete formula
            #expect(entry.example.hasPrefix("="))
        }
    }

    @Test("every entry belongs to a known category")
    func categories() {
        let known: Set<FormulaCatalogueEntry.Category> = [
            .ai, .math, .text, .aggregate, .control, .date, .reference, .preview
        ]
        for entry in FormulaCatalogue.all {
            #expect(known.contains(entry.category))
        }
    }

    @Test("names are unique")
    func uniqueNames() {
        let names = FormulaCatalogue.all.map(\.name)
        #expect(Set(names).count == names.count)
    }

    // MARK: - Search

    @Test("empty search returns all entries")
    func searchEmpty() {
        #expect(FormulaCatalogue.search("").count == FormulaCatalogue.all.count)
    }

    @Test("search by exact name: upper")
    func searchExactName() {
        let results = FormulaCatalogue.search("upper")
        #expect(results.contains { $0.name == "=upper" })
    }

    @Test("search is case-insensitive: UPPER matches =upper")
    func searchCaseInsensitive() {
        let results = FormulaCatalogue.search("UPPER")
        #expect(results.contains { $0.name == "=upper" })
    }

    @Test("search by keyword: 'case' matches both upper and lower")
    func searchByKeyword() {
        let results = FormulaCatalogue.search("case")
        let names = results.map(\.name)
        #expect(names.contains("=upper"))
        #expect(names.contains("=lower"))
    }

    @Test("search by description: 'arithmetic' matches =math")
    func searchByDescription() {
        let results = FormulaCatalogue.search("arithmetic")
        #expect(results.contains { $0.name == "=math" })
    }

    @Test("search with no matches returns empty array")
    func searchNoMatch() {
        #expect(FormulaCatalogue.search("zzxqwerty").isEmpty)
    }

    // MARK: - Grouping

    @Test("grouped() returns sections in a deterministic order")
    func groupedOrder() {
        let sections = FormulaCatalogue.grouped()
        #expect(sections.count >= 6)
        // First section should be AI (the headline feature)
        #expect(sections.first?.category == .ai)
    }

    @Test("entries within a group are alphabetical by name")
    func groupAlphabetical() {
        for section in FormulaCatalogue.grouped() {
            let names = section.entries.map(\.name)
            #expect(names == names.sorted())
        }
    }

    @Test("every entry appears in exactly one group")
    func everyEntryGrouped() {
        let grouped = FormulaCatalogue.grouped().flatMap(\.entries).map(\.name).sorted()
        let all = FormulaCatalogue.all.map(\.name).sorted()
        #expect(grouped == all)
    }
}
