import Testing
@testable import apfelpad

@Suite("FormulaRegistry")
struct FormulaRegistryTests {
    @Test("public catalogue entries are derived from the registry")
    func catalogueMatchesRegistry() {
        let registryNames = FormulaRegistry.publicDefinitions.map(\.displayName).sorted()
        let catalogueNames = FormulaCatalogue.all.map(\.name).sorted()
        #expect(catalogueNames == registryNames)
    }

    @Test("discoverable function names match named parser entries")
    func discoverableNames() {
        let expected = Set(
            FormulaRegistry.all
                .filter(\.isDiscoverable)
                .map(\.functionName)
                .filter { !$0.isEmpty }
        )
        #expect(FormulaRegistry.discoverableFunctionNames == expected)
    }

    @Test("anonymous shortcut stays parser-only, not discoverable")
    func anonymousShortcut() {
        let anonymous = FormulaRegistry.definition(forFunctionName: "")
        #expect(anonymous?.displayName == "=()")
        #expect(anonymous?.isDiscoverable == false)
    }
}
