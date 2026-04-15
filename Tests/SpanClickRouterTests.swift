import Testing
import Foundation
@testable import apfelpad

@Suite("SpanClickRouter", .serialized)
struct SpanClickRouterTests {
    @Test("routes a valid span URL to the matching span")
    func valid() throws {
        var doc = try Document(rawMarkdown: "=math(1+1)")
        let id = doc.spans[0].id
        let url = URL(string: "apfelpad://span/\(id.uuidString)")!
        let span = SpanClickRouter.handle(url: url, in: doc)
        #expect(span?.id == id)
    }

    @Test("returns nil for non-apfelpad scheme")
    func wrongScheme() throws {
        let doc = try Document(rawMarkdown: "=math(1+1)")
        let url = URL(string: "https://example.com/foo")!
        #expect(SpanClickRouter.handle(url: url, in: doc) == nil)
    }

    @Test("returns nil when UUID doesn't match any span")
    func unknownUUID() throws {
        let doc = try Document(rawMarkdown: "=math(1+1)")
        let url = URL(string: "apfelpad://span/00000000-0000-0000-0000-000000000000")!
        #expect(SpanClickRouter.handle(url: url, in: doc) == nil)
    }

    @Test("picks the right span when multiple exist")
    func disambiguates() throws {
        var doc = try Document(rawMarkdown: "=math(1+1) and =math(2+2)")
        let second = doc.spans[1]
        let url = URL(string: "apfelpad://span/\(second.id.uuidString)")!
        let found = SpanClickRouter.handle(url: url, in: doc)
        #expect(found?.id == second.id)
        #expect(found?.source == "=math(2+2)")
    }

    @Test("returns nil for malformed path")
    func malformed() throws {
        let doc = try Document(rawMarkdown: "=math(1+1)")
        let url = URL(string: "apfelpad://span/")!
        #expect(SpanClickRouter.handle(url: url, in: doc) == nil)
    }
}
