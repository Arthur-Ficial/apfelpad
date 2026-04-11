import Testing
@testable import apfelpad

@Suite("FormulaRuntime")
struct FormulaRuntimeTests {
    @Test("evaluates =math and caches result")
    func mathCached() async throws {
        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let call = FormulaCall.math(expression: "1+1")
        let value = try await runtime.evaluate(call: call, source: "=math(1+1)", context: "")
        #expect(value == .ready(text: "2"))

        // Pre-seed the cache with a different value and assert it is returned on re-run.
        let key = CacheKey(
            formulaSource: "=math(1+1)",
            context: "",
            modelVersion: "none",
            seed: nil
        )
        try await cache.set(key: key, value: "99")
        let second = try await runtime.evaluate(call: call, source: "=math(1+1)", context: "")
        #expect(second == .ready(text: "99"))
    }

    @Test("different contexts → different cache keys")
    func contextSensitive() async throws {
        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let call = FormulaCall.math(expression: "2+2")
        _ = try await runtime.evaluate(call: call, source: "=math(2+2)", context: "a")
        _ = try await runtime.evaluate(call: call, source: "=math(2+2)", context: "b")
        // Both contexts cached independently.
        let ka = CacheKey(formulaSource: "=math(2+2)", context: "a", modelVersion: "none", seed: nil)
        let kb = CacheKey(formulaSource: "=math(2+2)", context: "b", modelVersion: "none", seed: nil)
        #expect(try await cache.get(key: ka) == "4")
        #expect(try await cache.get(key: kb) == "4")
    }

    @Test("math error bubbles up as .error value")
    func mathError() async throws {
        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let call = FormulaCall.math(expression: "abc")
        let value = try await runtime.evaluate(call: call, source: "=math(abc)", context: "")
        if case .error = value {
            // pass
        } else {
            Issue.record("expected .error, got \(value)")
        }
    }
}
