import Testing
@testable import apfelpad

@Suite("SSEParser", .serialized)
struct SSEParserTests {
    @Test("extracts content delta from a chunk line")
    func contentDelta() {
        let line = #"data: {"id":"x","object":"chat.completion.chunk","choices":[{"index":0,"delta":{"content":"Hello"},"finish_reason":null}]}"#
        #expect(SSEParser.parseContent(line: line) == "Hello")
    }

    @Test("returns nil for [DONE] marker")
    func doneMarker() {
        #expect(SSEParser.parseContent(line: "data: [DONE]") == nil)
    }

    @Test("returns nil for non-data lines")
    func nonData() {
        #expect(SSEParser.parseContent(line: ": heartbeat") == nil)
        #expect(SSEParser.parseContent(line: "") == nil)
    }

    @Test("returns nil when delta has no content")
    func emptyDelta() {
        let line = #"data: {"choices":[{"delta":{"role":"assistant"},"finish_reason":null}]}"#
        #expect(SSEParser.parseContent(line: line) == nil)
    }

    @Test("parses an error line")
    func errorLine() {
        let line = #"data: {"error":{"message":"boom","type":"server_error"}}"#
        #expect(SSEParser.parseError(line: line)?.message == "boom")
    }
}
