import Testing
import Foundation
@testable import apfelpad

/// TDD pin: every example in the library, after load + evaluate, has all of
/// its non-AI formulas resolved to a real value (not `.error`, not `.idle`).
/// =apfel formulas are exempted because they require a live on-device LLM —
/// in CI they stay `.idle` until a server is wired in.
@Suite("Examples library — every example evaluates without errors", .serialized)
@MainActor
struct ExamplesLibraryEvaluationTests {

    @Test("every example resolves all non-AI formulas without errors")
    func everyExampleEvaluates() async throws {
        for entry in ExamplesLibrary.all {
            let vm = makeVM()
            do {
                try vm.load(rawMarkdown: entry.body)
            } catch {
                Issue.record("'\(entry.title)' failed to load: \(error)")
                continue
            }
            await vm.evaluateAll()

            for span in vm.document.spans {
                if isAICall(span.call) { continue }      // AI needs a live server
                if isInputDeclaration(span.call) { continue } // declares a variable, no value to assert

                switch span.value {
                case .ready:
                    continue
                case .error(let message):
                    Issue.record(
                        "'\(entry.title)' formula `\(span.source)` errored: \(message)"
                    )
                case .idle, .evaluating, .streaming, .stale:
                    Issue.record(
                        "'\(entry.title)' formula `\(span.source)` did not produce a value (state: \(span.value))"
                    )
                }
            }
        }
    }

    // MARK: - Helpers (kept tiny to make the failure messages above readable)

    private func makeVM() -> DocumentViewModel {
        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        return DocumentViewModel(runtime: runtime)
    }

    private func isAICall(_ call: FormulaCall) -> Bool {
        if case .apfel = call { return true }
        return false
    }

    private func isInputDeclaration(_ call: FormulaCall) -> Bool {
        if case .input = call { return true }
        return false
    }
}
