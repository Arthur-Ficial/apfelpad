import Testing
@testable import apfelpad

@Suite("Examples library — every example is loadable and parses cleanly")
struct ExamplesLibraryTests {

    @Test("library exposes at least 25 examples")
    func libraryCount() {
        #expect(ExamplesLibrary.all.count >= 25, "Expected ≥25 examples, got \(ExamplesLibrary.all.count)")
    }

    @Test("every example has the required metadata")
    func metadataIntegrity() {
        for entry in ExamplesLibrary.all {
            #expect(!entry.title.isEmpty, "Empty title")
            #expect(!entry.blurb.isEmpty, "Empty blurb in '\(entry.title)'")
            #expect(!entry.icon.isEmpty, "Empty icon in '\(entry.title)'")
            #expect(!entry.body.isEmpty, "Empty body in '\(entry.title)'")
        }
    }

    @Test("titles are unique")
    func titlesUnique() {
        let titles = ExamplesLibrary.all.map(\.title)
        let unique = Set(titles)
        #expect(titles.count == unique.count, "Duplicate titles in examples library")
    }

    @Test("every example body parses as a Document without throwing")
    func everyExampleParses() throws {
        for entry in ExamplesLibrary.all {
            do {
                _ = try Document(rawMarkdown: entry.body)
            } catch {
                Issue.record("Example '\(entry.title)' failed to parse: \(error)")
            }
        }
    }

    @Test("every formula span in every example has a valid parsed call")
    func everyFormulaParses() throws {
        for entry in ExamplesLibrary.all {
            let document: Document
            do {
                document = try Document(rawMarkdown: entry.body)
            } catch {
                Issue.record("Example '\(entry.title)' failed to load: \(error)")
                continue
            }

            #expect(!document.spans.isEmpty, "Example '\(entry.title)' has no formulas — it should demonstrate at least one")

            for span in document.spans {
                do {
                    _ = try FormulaParser.parse(span.source)
                } catch {
                    Issue.record(
                        "Example '\(entry.title)' has an unparseable formula '\(span.source)': \(error)"
                    )
                }
            }
        }
    }

    @Test("every example renders into a non-empty visible projection")
    @MainActor
    func everyExampleProjects() throws {
        for entry in ExamplesLibrary.all {
            let document = try Document(rawMarkdown: entry.body)
            let projection = RenderProjection(document: document)
            #expect(!projection.visibleText.isEmpty, "Example '\(entry.title)' produced empty projection")
        }
    }

    @Test("grouped() returns sections with at least one entry each")
    func groupedSectionsNonEmpty() {
        for section in ExamplesLibrary.grouped() {
            #expect(!section.entries.isEmpty, "Empty section: \(section.category.title)")
        }
    }
}
