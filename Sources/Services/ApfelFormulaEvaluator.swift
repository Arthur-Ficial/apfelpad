import Foundation

/// Evaluates =apfel(...) formulas by dispatching to an LLMService and
/// caching the joined result. Pure Swift — testable with mocks.
struct ApfelFormulaEvaluator: Sendable {
    let llm: LLMService
    let cache: FormulaCache
    let modelVersion: String

    init(llm: LLMService, cache: FormulaCache, modelVersion: String = "apple-foundationmodel") {
        self.llm = llm
        self.cache = cache
        self.modelVersion = modelVersion
    }

    /// Evaluate to a full (non-streaming) final string. Returns cached value
    /// on hit; otherwise streams from the LLM, joins all chunks, caches, returns.
    func evaluate(
        prompt: String,
        source: String,
        context: String,
        seed: Int?
    ) async throws -> String {
        let key = CacheKey(
            formulaSource: source,
            context: context,
            modelVersion: modelVersion,
            seed: seed
        )
        if let hit = try await cache.get(key: key) {
            return hit
        }
        var joined = ""
        for try await chunk in llm.complete(prompt: prompt, context: context, seed: seed) {
            joined += chunk
        }
        try await cache.set(key: key, value: joined)
        return joined
    }

    /// Stream evaluation: yields each incremental chunk AND the final joined
    /// value (as the last yield) to the UI so the span can show progressive
    /// text. Caches on completion.
    func evaluateStreaming(
        prompt: String,
        source: String,
        context: String,
        seed: Int?
    ) -> AsyncThrowingStream<String, Error> {
        let key = CacheKey(
            formulaSource: source,
            context: context,
            modelVersion: modelVersion,
            seed: seed
        )
        let cache = self.cache
        let llm = self.llm
        return AsyncThrowingStream { continuation in
            Task {
                let cachedHit: String? = (try? await cache.get(key: key)) ?? nil
                if let hit = cachedHit {
                    continuation.yield(hit)
                    continuation.finish()
                    return
                }
                var joined = ""
                do {
                    for try await chunk in llm.complete(prompt: prompt, context: context, seed: seed) {
                        joined += chunk
                        continuation.yield(joined)
                    }
                    try? await cache.set(key: key, value: joined)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
