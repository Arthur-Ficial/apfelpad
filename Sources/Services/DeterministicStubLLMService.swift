import Foundation

struct DeterministicStubLLMService: LLMService {
    func complete(
        prompt: String,
        context: String,
        seed: Int?
    ) -> AsyncThrowingStream<String, Error> {
        let output = rendered(prompt: prompt, context: context, seed: seed)
        let split = max(1, output.count / 2)

        return AsyncThrowingStream { continuation in
            continuation.yield(String(output.prefix(split)))
            continuation.yield(String(output.dropFirst(split)))
            continuation.finish()
        }
    }

    private func rendered(prompt: String, context: String, seed: Int?) -> String {
        let cleanedPrompt = prompt
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let clippedPrompt = String(cleanedPrompt.prefix(96))
        let hasContext = !context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let contextTag = hasContext ? " with document context" : ""
        return "Stub response \(seed ?? 0)\(contextTag): \(clippedPrompt)"
    }
}
