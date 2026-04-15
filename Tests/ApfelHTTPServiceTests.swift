import Testing
import Foundation
@testable import apfelpad

@Suite("ApfelHTTPService", .serialized)
struct ApfelHTTPServiceTests {
    @Test("builds correct request body")
    func requestBody() throws {
        let body = ApfelHTTPService.buildRequestBody(
            prompt: "hello",
            context: "some context",
            seed: 42
        )
        // Request should include the user message, stream=true, model,
        // seed, and a system message containing the context.
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        #expect(json?["model"] as? String == "apple-foundationmodel")
        #expect(json?["stream"] as? Bool == true)
        #expect(json?["seed"] as? Int == 42)
        let messages = json?["messages"] as? [[String: Any]]
        #expect(messages?.count == 2)
        #expect(messages?[0]["role"] as? String == "system")
        #expect((messages?[0]["content"] as? String)?.contains("some context") == true)
        #expect(messages?[1]["role"] as? String == "user")
        #expect(messages?[1]["content"] as? String == "hello")
    }

    @Test("omits seed when nil")
    func noSeed() throws {
        let body = ApfelHTTPService.buildRequestBody(
            prompt: "hi",
            context: "",
            seed: nil
        )
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        #expect(json?["seed"] == nil)
    }

    @Test("omits system message when context is empty")
    func noContext() throws {
        let body = ApfelHTTPService.buildRequestBody(
            prompt: "hi",
            context: "",
            seed: nil
        )
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        let messages = json?["messages"] as? [[String: Any]]
        #expect(messages?.count == 1)
        #expect(messages?[0]["role"] as? String == "user")
    }

    @Test("endpoint URL uses the configured port")
    func endpointURL() {
        let service = ApfelHTTPService(port: 11450)
        #expect(service.endpointURL.absoluteString == "http://127.0.0.1:11450/v1/chat/completions")
    }
}
