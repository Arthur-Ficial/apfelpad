import Testing
import Foundation
@testable import apfelpad

@Suite("MarkdownDocumentStore", .serialized)
struct MarkdownDocumentStoreTests {
    @Test("round-trip .md file")
    func roundTrip() async throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("doc-\(UUID().uuidString).md")
        let store = MarkdownDocumentStore()
        try await store.save(rawMarkdown: "Hello =math(1+1) world\n", to: tmp)
        let loaded = try await store.load(from: tmp)
        #expect(loaded == "Hello =math(1+1) world\n")
    }

    @Test("save overwrites existing file")
    func overwrite() async throws {
        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("doc-\(UUID().uuidString).md")
        let store = MarkdownDocumentStore()
        try await store.save(rawMarkdown: "first", to: tmp)
        try await store.save(rawMarkdown: "second", to: tmp)
        #expect(try await store.load(from: tmp) == "second")
    }
}
