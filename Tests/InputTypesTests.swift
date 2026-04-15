import Testing
import Foundation
@testable import apfelpad

/// TDD for extended =input types. Every HTML-style input type keyword must
/// parse, reach the VM, and survive a bind + show round-trip.
@Suite("Extended =input types", .serialized)
@MainActor
struct InputTypesTests {

    // Parser must accept every declared InputType case.
    @Test("parser accepts every InputType case")
    func parserAcceptsAllTypes() throws {
        for type in InputType.allCases {
            let source = #"=input("x", \#(type.rawValue), "default")"#
            let call = try FormulaParser.parse(source)
            guard case .input(let name, let parsedType, let def) = call else {
                Issue.record("parse failed for \(source)")
                continue
            }
            #expect(name == "x")
            #expect(parsedType == type)
            #expect(def == "default")
        }
    }

    // Document discovery must find every =input regardless of type.
    @Test("document finds every type")
    func documentFindsAllTypes() throws {
        var markdown = ""
        for type in InputType.allCases {
            markdown += "=input(\"\(type.rawValue)_var\", \(type.rawValue), \"default\")\n"
        }
        let doc = try Document(rawMarkdown: markdown)
        #expect(doc.spans.count == InputType.allCases.count)
        for span in doc.spans {
            guard case .input = span.call else {
                Issue.record("expected .input call, got \(span.call)")
                continue
            }
        }
    }

    // Every type must render a reactive binding through the VM.
    @Test("VM sets and re-evaluates every input type")
    func vmReactsForEveryType() async throws {
        for type in InputType.allCases {
            let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
            let doc = """
            =input("val_\(type.rawValue)", \(type.rawValue), "")
            Value: =show(@val_\(type.rawValue))
            """
            try vm.load(rawMarkdown: doc)
            await vm.evaluateAll()
            vm.setInputBinding("val_\(type.rawValue)", to: "test-value")
            await Task.yield()
            try? await Task.sleep(for: .milliseconds(30))
            // Find the =show span and assert its value is "test-value"
            let showSpan = vm.document.spans.first { span in
                if case .show = span.call { return true }
                return false
            }
            guard let span = showSpan else {
                Issue.record("no =show span found for \(type.rawValue)")
                continue
            }
            guard case .ready(let text) = span.value else {
                Issue.record("expected ready value for \(type.rawValue), got \(span.value)")
                continue
            }
            #expect(text == "test-value", "wrong value for \(type.rawValue)")
        }
    }
}
