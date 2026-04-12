import Testing
import Foundation
@testable import apfelpad

@Suite("Welcome workbook")
@MainActor
struct WelcomeWorkbookTests {

    @Test("template mentions every public formula at least once")
    func coversEveryPublicFormula() {
        let template = WelcomeWorkbook.template()

        for definition in FormulaRegistry.publicDefinitions {
            let present: Bool
            if definition.displayName == "=()" {
                present = template.contains("=(")
            } else {
                present = template.contains(definition.displayName)
            }
            #expect(present, "missing \(definition.displayName) from welcome workbook")
        }
    }

    @Test("document interpolates bundled sample file path")
    func interpolatesBundledFilePath() {
        let rendered = WelcomeWorkbook.document()
        #expect(!rendered.contains(WelcomeWorkbook.sampleFilePlaceholder))
        #expect(rendered.contains(WelcomeWorkbook.sampleFileURL().path))
    }

    @Test("workbook evaluates core calculator and stub AI sections")
    func evaluatesWorkbook() async throws {
        let runtime = FormulaRuntime(
            cache: InMemoryFormulaCache(),
            llm: DeterministicStubLLMService()
        )
        let vm = DocumentViewModel(runtime: runtime)
        try vm.load(rawMarkdown: WelcomeWorkbook.document())
        await vm.evaluateAll()

        let rendered = String(InlineFormulaRenderer.render(vm.document).characters)

        #expect(rendered.contains("6480"))
        #expect(rendered.contains("Quote for Acme Corp totals $6480."))
        #expect(rendered.contains("Stub response 7"))
        #expect(rendered.contains("Stub response 3"))
        #expect(rendered.contains("This bundled sample file exists so =file(path) has a stable, working example."))
    }
}
