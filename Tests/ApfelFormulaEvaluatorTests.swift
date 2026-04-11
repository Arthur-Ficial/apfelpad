import Testing
@testable import apfelpad

@Suite("ApfelFormulaEvaluator")
struct ApfelFormulaEvaluatorTests {
    @Test("calls LLM and caches the joined result")
    func callsAndCaches() async throws {
        let llm = MockLLMService()
        llm.chunks = ["Hello, ", "world"]
        let cache = InMemoryFormulaCache()
        let evaluator = ApfelFormulaEvaluator(llm: llm, cache: cache, modelVersion: "test")

        let result = try await evaluator.evaluate(
            prompt: "hi",
            source: #"=apfel("hi")"#,
            context: "",
            seed: nil
        )
        #expect(result == "Hello, world")
        #expect(llm.callCount == 1)

        let key = CacheKey(
            formulaSource: #"=apfel("hi")"#,
            context: "",
            modelVersion: "test",
            seed: nil
        )
        #expect(try await cache.get(key: key) == "Hello, world")
    }

    @Test("cache hit skips LLM call")
    func cacheHitSkipsLLM() async throws {
        let llm = MockLLMService()
        llm.chunks = ["SHOULD NOT SEE"]
        let cache = InMemoryFormulaCache()
        let key = CacheKey(
            formulaSource: #"=apfel("hi")"#,
            context: "",
            modelVersion: "test",
            seed: nil
        )
        try await cache.set(key: key, value: "cached answer")

        let evaluator = ApfelFormulaEvaluator(llm: llm, cache: cache, modelVersion: "test")
        let result = try await evaluator.evaluate(
            prompt: "hi",
            source: #"=apfel("hi")"#,
            context: "",
            seed: nil
        )
        #expect(result == "cached answer")
        #expect(llm.callCount == 0)
    }

    @Test("different seeds produce different cache keys")
    func differentSeeds() async throws {
        let llm = MockLLMService()
        llm.chunks = ["seed-call"]
        let cache = InMemoryFormulaCache()
        let evaluator = ApfelFormulaEvaluator(llm: llm, cache: cache, modelVersion: "test")

        // Pre-seed cache for seed=42, then call with seed=7 and verify
        // the LLM is actually called (different cache key).
        let key42 = CacheKey(
            formulaSource: #"=apfel("hi", 42)"#,
            context: "",
            modelVersion: "test",
            seed: 42
        )
        try await cache.set(key: key42, value: "cached for 42")

        _ = try await evaluator.evaluate(
            prompt: "hi",
            source: #"=apfel("hi", 7)"#,
            context: "",
            seed: 7
        )
        #expect(llm.callCount == 1)
        #expect(llm.lastSeed == 7)
    }
}
