import Foundation

protocol LLMService: Sendable {
    func complete(
        prompt: String,
        context: String,
        seed: Int?
    ) -> AsyncThrowingStream<String, Error>
}
