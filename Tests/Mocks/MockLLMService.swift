import Foundation
@testable import apfelpad

final class MockLLMService: LLMService, @unchecked Sendable {
    var chunks: [String] = []
    var throwsError: Error? = nil
    private(set) var callCount: Int = 0
    private(set) var lastPrompt: String = ""
    private(set) var lastContext: String = ""
    private(set) var lastSeed: Int? = nil

    func complete(prompt: String, context: String, seed: Int?) -> AsyncThrowingStream<String, Error> {
        callCount += 1
        lastPrompt = prompt
        lastContext = context
        lastSeed = seed
        let chunks = self.chunks
        let throwsError = self.throwsError
        return AsyncThrowingStream { continuation in
            Task {
                if let e = throwsError {
                    continuation.finish(throwing: e)
                    return
                }
                for c in chunks {
                    continuation.yield(c)
                }
                continuation.finish()
            }
        }
    }
}
