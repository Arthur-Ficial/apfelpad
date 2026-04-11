import Foundation

/// Dispatches a parsed `FormulaCall` to the right evaluator and caches results.
/// Pure Swift — no HTTP, no FoundationModels, no UI. Unit-testable with any
/// `FormulaCache` mock.
final class FormulaRuntime: Sendable {
    private let cache: FormulaCache
    private let llm: LLMService?
    private let modelVersion: String
    private let apfelEvaluator: ApfelFormulaEvaluator?

    init(
        cache: FormulaCache,
        llm: LLMService? = nil,
        modelVersion: String = "apple-foundationmodel"
    ) {
        self.cache = cache
        self.llm = llm
        self.modelVersion = modelVersion
        if let llm {
            self.apfelEvaluator = ApfelFormulaEvaluator(
                llm: llm,
                cache: cache,
                modelVersion: modelVersion
            )
        } else {
            self.apfelEvaluator = nil
        }
    }

    /// Fully-evaluate a formula call. Used by the non-streaming code paths.
    func evaluate(
        call: FormulaCall,
        source: String,
        context: String
    ) async throws -> FormulaValue {
        let seed = extractSeed(call)
        let key = CacheKey(
            formulaSource: source,
            context: context,
            modelVersion: modelVersion,
            seed: seed
        )
        if let hit = try await cache.get(key: key) {
            return .ready(text: hit)
        }
        do {
            let text = try await computeValue(for: call, source: source, context: context, seed: seed)
            try await cache.set(key: key, value: text)
            return .ready(text: text)
        } catch {
            return .error(message: error.localizedDescription)
        }
    }

    /// Streaming evaluator: yields progressive FormulaValue states for a
    /// single call. UI subscribers should replace the span value on each yield.
    func evaluateStreaming(
        call: FormulaCall,
        source: String,
        context: String
    ) -> AsyncThrowingStream<FormulaValue, Error> {
        AsyncThrowingStream { continuation in
            Task {
                let seed = extractSeed(call)
                let key = CacheKey(
                    formulaSource: source,
                    context: context,
                    modelVersion: modelVersion,
                    seed: seed
                )
                let cachedHit: String? = (try? await cache.get(key: key)) ?? nil
                if let hit = cachedHit {
                    continuation.yield(.ready(text: hit))
                    continuation.finish()
                    return
                }
                continuation.yield(.evaluating)
                do {
                    switch call {
                    case .apfel(let prompt, _):
                        guard let apfelEvaluator else {
                            throw RuntimeError.llmNotConfigured
                        }
                        for try await partial in apfelEvaluator.evaluateStreaming(
                            prompt: prompt,
                            source: source,
                            context: context,
                            seed: seed
                        ) {
                            continuation.yield(.streaming(partial: partial))
                        }
                        // Final state: cached full text
                        let cachedFinal: String? = (try? await cache.get(key: key)) ?? nil
                        if let final = cachedFinal {
                            continuation.yield(.ready(text: final))
                        }
                    default:
                        // All non-streaming formulas share the same synchronous path.
                        let text = try synchronousCompute(for: call)
                        try await cache.set(key: key, value: text)
                        continuation.yield(.ready(text: text))
                    }
                    continuation.finish()
                } catch {
                    continuation.yield(.error(message: error.localizedDescription))
                    continuation.finish()
                }
            }
        }
    }

    /// Evaluate any non-streaming (pure synchronous) formula call.
    /// Centralises the text/math/spreadsheet dispatch so both the streaming
    /// and non-streaming entry points reuse it.
    private func synchronousCompute(for call: FormulaCall) throws -> String {
        switch call {
        case .math(let expression):
            return try MathFormulaEvaluator.evaluate(expression)
        case .upper(let t):
            return try UpperFormulaEvaluator.evaluate(t)
        case .lower(let t):
            return try LowerFormulaEvaluator.evaluate(t)
        case .trim(let t):
            return try TrimFormulaEvaluator.evaluate(t)
        case .len(let t):
            return try LenFormulaEvaluator.evaluate(t)
        case .concat(let parts):
            return try ConcatFormulaEvaluator.evaluate(parts)
        case .replace(let text, let find, let replacement):
            return try ReplaceFormulaEvaluator.evaluate(
                text: text, find: find, replacement: replacement
            )
        case .splitCall(let text, let delim, let index):
            return try SplitFormulaEvaluator.evaluate(
                text: text, delim: delim, index: index
            )
        case .ifCall(let cond, let thenValue, let elseValue):
            return try IfFormulaEvaluator.evaluate(
                cond: cond, thenValue: thenValue, elseValue: elseValue
            )
        case .sum(let args):
            return try SumFormulaEvaluator.evaluate(args)
        case .avg(let args):
            return try AvgFormulaEvaluator.evaluate(args)
        case .apfel:
            throw RuntimeError.apfelRequiresStreamingPath
        case .ref:
            throw RuntimeError.refRequiresDocumentContext
        }
    }

    private func computeValue(
        for call: FormulaCall,
        source: String,
        context: String,
        seed: Int?
    ) async throws -> String {
        if case .apfel(let prompt, _) = call {
            guard let apfelEvaluator else {
                throw RuntimeError.llmNotConfigured
            }
            return try await apfelEvaluator.evaluate(
                prompt: prompt,
                source: source,
                context: context,
                seed: seed
            )
        }
        return try synchronousCompute(for: call)
    }

    private func extractSeed(_ call: FormulaCall) -> Int? {
        if case .apfel(_, let seed) = call { return seed }
        return nil
    }
}

enum RuntimeError: LocalizedError {
    case llmNotConfigured
    case apfelRequiresStreamingPath
    case refRequiresDocumentContext
    case anchorNotFound(String)

    var errorDescription: String? {
        switch self {
        case .llmNotConfigured:
            return "=apfel(...) needs a running apfel server. Start apfel first, then retry."
        case .apfelRequiresStreamingPath:
            return "internal error: .apfel must go through the streaming path"
        case .refRequiresDocumentContext:
            return "internal error: =ref must be resolved at the document layer"
        case .anchorNotFound(let name):
            return "ref: no heading named @\(name) in this document"
        }
    }
}
