import Foundation
@testable import apfelpad

final actor InMemoryFormulaCache: FormulaCache {
    private var store: [String: String] = [:]

    func get(key: CacheKey) async throws -> String? {
        store[key.hash]
    }

    func set(key: CacheKey, value: String) async throws {
        store[key.hash] = value
    }

    func delete(key: CacheKey) async throws {
        store.removeValue(forKey: key.hash)
    }
}
