import Foundation

struct MarkdownDocumentStore: DocumentPersistence {
    func load(from url: URL) async throws -> String {
        try String(contentsOf: url, encoding: .utf8)
    }

    func save(rawMarkdown: String, to url: URL) async throws {
        try rawMarkdown.write(to: url, atomically: true, encoding: .utf8)
    }
}
