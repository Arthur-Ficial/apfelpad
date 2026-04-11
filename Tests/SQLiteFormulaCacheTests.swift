import Testing
import Foundation
@testable import apfelpad

@Suite("SQLiteFormulaCache")
struct SQLiteFormulaCacheTests {
    private func makeTempPath() -> String {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("apfelpad-\(UUID().uuidString).sqlite")
            .path
    }

    @Test("set/get round trip")
    func roundTrip() async throws {
        let cache = try SQLiteFormulaCache(path: makeTempPath())
        let key = CacheKey(formulaSource: "=math(1+1)", context: "", modelVersion: "none", seed: nil)
        try await cache.set(key: key, value: "2")
        let fetched = try await cache.get(key: key)
        #expect(fetched == "2")
    }

    @Test("miss returns nil")
    func miss() async throws {
        let cache = try SQLiteFormulaCache(path: makeTempPath())
        let key = CacheKey(formulaSource: "=math(3)", context: "", modelVersion: "none", seed: nil)
        let fetched = try await cache.get(key: key)
        #expect(fetched == nil)
    }

    @Test("survives reopen")
    func persists() async throws {
        let path = makeTempPath()
        let cache1 = try SQLiteFormulaCache(path: path)
        let key = CacheKey(formulaSource: "=math(7)", context: "", modelVersion: "none", seed: nil)
        try await cache1.set(key: key, value: "7")
        let cache2 = try SQLiteFormulaCache(path: path)
        let fetched = try await cache2.get(key: key)
        #expect(fetched == "7")
    }

    @Test("overwrite updates value")
    func overwrite() async throws {
        let cache = try SQLiteFormulaCache(path: makeTempPath())
        let key = CacheKey(formulaSource: "=math(9)", context: "", modelVersion: "none", seed: nil)
        try await cache.set(key: key, value: "nine")
        try await cache.set(key: key, value: "neun")
        #expect(try await cache.get(key: key) == "neun")
    }
}
