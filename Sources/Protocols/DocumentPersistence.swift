import Foundation

protocol DocumentPersistence: Sendable {
    func load(from url: URL) async throws -> String
    func save(rawMarkdown: String, to url: URL) async throws
}
