import Foundation

protocol FormulaCache: Sendable {
    func get(key: CacheKey) async throws -> String?
    func set(key: CacheKey, value: String) async throws
    func delete(key: CacheKey) async throws
}
