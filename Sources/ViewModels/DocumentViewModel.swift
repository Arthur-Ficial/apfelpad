import Foundation
import Observation

@Observable
@MainActor
final class DocumentViewModel {
    var document: Document = .empty
    private var runtime: FormulaRuntime

    init(runtime: FormulaRuntime) {
        self.runtime = runtime
    }

    func replaceRuntime(_ runtime: FormulaRuntime) {
        self.runtime = runtime
    }

    func load(rawMarkdown: String) throws {
        self.document = try Document(rawMarkdown: rawMarkdown)
    }

    func evaluateAll() async {
        // Evaluate each span in its own streaming task so =apfel calls
        // can proceed in parallel and their partial tokens update the UI
        // immediately.
        let snapshot = document
        await withTaskGroup(of: (Int, FormulaValue).self) { group in
            for (i, span) in snapshot.spans.enumerated() {
                let call = span.call
                let source = span.source
                group.addTask { [runtime] in
                    var last: FormulaValue = .idle
                    do {
                        for try await value in runtime.evaluateStreaming(
                            call: call,
                            source: source,
                            context: ""  // v0.2: no context resolution yet; v0.6 adds it
                        ) {
                            last = value
                            await MainActor.run {
                                // Partial updates so streaming feels live
                            }
                        }
                    } catch {
                        last = .error(message: error.localizedDescription)
                    }
                    return (i, last)
                }
            }
            for await (i, value) in group {
                guard i < document.spans.count else { continue }
                document.spans[i].value = value
            }
        }
    }
}
