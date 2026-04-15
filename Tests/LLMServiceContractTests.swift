import Testing
@testable import apfelpad

@Suite("LLMService contract", .serialized)
struct LLMServiceContractTests {
    @Test("mock yields configured chunks")
    func mockYields() async throws {
        let mock = MockLLMService()
        mock.chunks = ["Hello, ", "world"]
        var collected = ""
        for try await chunk in mock.complete(prompt: "hi", context: "", seed: 42) {
            collected += chunk
        }
        #expect(collected == "Hello, world")
        #expect(mock.callCount == 1)
        #expect(mock.lastPrompt == "hi")
        #expect(mock.lastSeed == 42)
    }

    @Test("mock throws configured error")
    func mockThrows() async {
        enum E: Error { case nope }
        let mock = MockLLMService()
        mock.throwsError = E.nope
        do {
            for try await _ in mock.complete(prompt: "x", context: "", seed: nil) {}
            Issue.record("expected throw")
        } catch {
            // pass
        }
    }
}
