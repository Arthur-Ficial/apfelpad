import Foundation
import Observation

@Observable
@MainActor
final class DocumentViewModel {
    var document: Document = .empty
    private let runtime: FormulaRuntime

    init(runtime: FormulaRuntime) {
        self.runtime = runtime
    }

    func load(rawMarkdown: String) throws {
        self.document = try Document(rawMarkdown: rawMarkdown)
    }

    func evaluateAll() async {
        var updated = document
        for i in updated.spans.indices {
            do {
                let value = try await runtime.evaluate(
                    call: updated.spans[i].call,
                    source: updated.spans[i].source,
                    context: ""  // v0.1: no context resolution yet
                )
                updated.spans[i].value = value
            } catch {
                updated.spans[i].value = .error(message: String(describing: error))
            }
        }
        self.document = updated
    }
}
