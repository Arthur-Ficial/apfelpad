import Foundation

/// Dispatches a parsed `FormulaCall` to the right evaluator and caches results.
/// Pure Swift — no HTTP, no FoundationModels, no UI. Unit-testable with any
/// `FormulaCache` mock.
final class FormulaRuntime: Sendable {
    private let cache: FormulaCache
    private let modelVersion: String

    init(cache: FormulaCache, modelVersion: String = "none") {
        self.cache = cache
        self.modelVersion = modelVersion
    }

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
            let text = try computeValue(for: call)
            try await cache.set(key: key, value: text)
            return .ready(text: text)
        } catch {
            return .error(message: String(describing: error))
        }
    }

    private func computeValue(for call: FormulaCall) throws -> String {
        switch call {
        case .math(let expression):
            return try MathFormulaEvaluator.evaluate(expression)
        case .apfel:
            throw RuntimeError.apfelNotSupportedInV01
        }
    }

    private func extractSeed(_ call: FormulaCall) -> Int? {
        if case .apfel(_, let seed) = call { return seed }
        return nil
    }
}

enum RuntimeError: LocalizedError {
    case apfelNotSupportedInV01

    var errorDescription: String? {
        switch self {
        case .apfelNotSupportedInV01:
            return "=apfel(...) is not supported in v0.1. Coming in v0.2."
        }
    }
}
