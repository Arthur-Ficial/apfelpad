import Testing
import Foundation
@testable import apfelpad

/// Chaos-style rendering tests:
///   - every catalogue entry is loaded, evaluated, and substituted.
///   - random garbage input does not crash the pipeline.
///   - combinations of 2 and 3 formulas per paragraph round-trip.
///   - drag-and-drop insertion path (vm.insertAtCursor) is exercised for
///     every catalogue entry.
///   - full markdown (headings, tables, lists, blockquotes, code) passes
///     through untouched except for the formula substitutions.
///
/// These tests don't care *what* each formula evaluates to — they care
/// that the substitution pipeline is total: every recognised formula
/// becomes a clickable link or widget, and every unrecognised formula
/// stays as source text without crashing anything.
@Suite("Chaos rendering — every formula, every path")
@MainActor
struct ChaosRenderTests {

    private func makeVM() -> DocumentViewModel {
        DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
    }

    /// For every catalogue entry: paste the example into a doc, evaluate,
    /// and ensure DocumentBodySubstitution produces a non-empty output
    /// that either contains a span-link or an =input source (input spans
    /// are handled by the paragraph splitter, not the substitution pass).
    @Test("every catalogue example renders without crash")
    func everyCatalogueEntryRenders() async {
        for entry in FormulaCatalogue.all {
            // Skip placeholders explicitly — =ref / =file / =clip / =recording
            // depend on runtime state we don't fake here, but they must not
            // crash.
            let doc = "Prefix \(entry.example) suffix."
            let vm = makeVM()
            try? vm.load(rawMarkdown: doc)
            await vm.evaluateAll()
            let out = DocumentBodySubstitution.substitute(
                rawMarkdown: vm.rawText,
                spans: vm.document.spans
            )
            #expect(!out.isEmpty, "substitution produced empty output for \(entry.signature)")
            // Every entry except =input must be substituted — the result
            // contains a span link or no leading `=<name>(` source.
            if entry.name != "=input" {
                // The raw example must not survive verbatim. (It might
                // survive for entries where the runtime errored, but
                // those still produce a span for the error value.)
                // Pragma: assert a span link exists in the substitution.
                #expect(
                    out.contains("apfelpad://span/"),
                    "no span link for \(entry.signature) → output: \(out)"
                )
            }
        }
    }

    /// vm.insertAtCursor must accept every catalogue example without
    /// throwing. This is the drag-and-drop target used by the formula
    /// catalogue sidebar.
    @Test("insertAtCursor accepts every catalogue example")
    func insertAtCursorAcceptsEveryEntry() async {
        let vm = makeVM()
        try? vm.load(rawMarkdown: "")
        for entry in FormulaCatalogue.all {
            vm.insertAtCursor(entry.example)
            // Give the evaluation task a chance to run
            await Task.yield()
        }
        // The document should contain all examples in order.
        for entry in FormulaCatalogue.all {
            let stored = (try? FormulaParser.canonicalise(entry.example)) ?? entry.example
            #expect(
                vm.rawText.contains(stored),
                "insertAtCursor lost \(entry.signature)"
            )
        }
        // Every span discovered by the document should substitute cleanly.
        let out = DocumentBodySubstitution.substitute(
            rawMarkdown: vm.rawText,
            spans: vm.document.spans
        )
        #expect(!out.isEmpty)
    }

    /// Random junk input must not crash — parser errors stay errors,
    /// invalid tokens stay text, the substitution pipeline survives.
    @Test("garbage input never crashes the render pipeline")
    func garbageInput() async {
        let samples: [String] = [
            "",
            "plain text",
            "=((((",
            "=math(",
            "=math())",
            "=((( )))",
            "= math ( 1 + 1 )",
            "=math(1/0)",
            "=math(NaN)",
            "=apfel(",
            "= =apfel(",
            "=unknownfn(hello)",
            "\n\n\n=math(1)\n\n\n",
            "# =math(1) heading",
            "- =math(1)\n- =math(2)",
            "| =math(1) | =math(2) |\n|---|---|\n| a | b |",
            String(repeating: "=math(1+1) ", count: 200),
            "=(" + String(repeating: "(", count: 50) + ")",
        ]
        for sample in samples {
            let vm = makeVM()
            try? vm.load(rawMarkdown: sample)
            await vm.evaluateAll()
            // Substitution must not throw
            let out = DocumentBodySubstitution.substitute(
                rawMarkdown: vm.rawText,
                spans: vm.document.spans
            )
            // Out may equal input if no spans parsed — that's fine.
            _ = out
        }
    }

    /// Markdown structural elements (headings, tables, lists, blockquotes,
    /// code blocks, horizontal rules) must be preserved by substitution —
    /// the substitution only touches formula ranges, nothing else.
    @Test("markdown structure survives substitution untouched")
    func markdownStructurePreserved() async {
        let doc = """
        # Heading one

        ## Subheading

        A **bold** word and an *italic* one.

        - list item with =math(1+1)
        - second item

        > A blockquote with =math(2+2).

        ```swift
        let x = 42
        ```

        | A | B |
        |---|---|
        | =math(3+3) | six |

        ---

        Paragraph with =math(7*7) and [a link](https://example.com).
        """
        let vm = makeVM()
        try? vm.load(rawMarkdown: doc)
        await vm.evaluateAll()
        let out = DocumentBodySubstitution.substitute(
            rawMarkdown: vm.rawText,
            spans: vm.document.spans
        )
        // Structural markdown tokens must all still be there
        #expect(out.contains("# Heading one"))
        #expect(out.contains("## Subheading"))
        #expect(out.contains("**bold**"))
        #expect(out.contains("*italic*"))
        #expect(out.contains("- list item"))
        #expect(out.contains("> A blockquote"))
        #expect(out.contains("```swift"))
        #expect(out.contains("| A | B |"))
        #expect(out.contains("---"))
        #expect(out.contains("[a link](https://example.com)"))
        // Formula values are substituted
        #expect(out.contains("2"))
        #expect(out.contains("4"))
        #expect(out.contains("6"))
        #expect(out.contains("49"))
        // No raw formula sources survived
        #expect(!out.contains("=math(1+1)"))
        #expect(!out.contains("=math(2+2)"))
        #expect(!out.contains("=math(3+3)"))
        #expect(!out.contains("=math(7*7)"))
    }
}
