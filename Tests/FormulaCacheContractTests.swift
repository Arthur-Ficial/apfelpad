import Testing
@testable import apfelpad

@Suite("FormulaCache contract")
struct FormulaCacheContractTests {
    @Test("set/get round trip")
    func roundTrip() async throws {
        let cache = InMemoryFormulaCache()
        let key = CacheKey(formulaSource: "=math(1+1)", context: "", modelVersion: "none", seed: nil)
        try await cache.set(key: key, value: "2")
        let fetched = try await cache.get(key: key)
        #expect(fetched == "2")
    }

    @Test("miss returns nil")
    func miss() async throws {
        let cache = InMemoryFormulaCache()
        let key = CacheKey(formulaSource: "=math(3)", context: "", modelVersion: "none", seed: nil)
        let fetched = try await cache.get(key: key)
        #expect(fetched == nil)
    }

    @Test("delete removes entry")
    func delete() async throws {
        let cache = InMemoryFormulaCache()
        let key = CacheKey(formulaSource: "=math(5)", context: "", modelVersion: "none", seed: nil)
        try await cache.set(key: key, value: "5")
        try await cache.delete(key: key)
        let fetched = try await cache.get(key: key)
        #expect(fetched == nil)
    }
}
