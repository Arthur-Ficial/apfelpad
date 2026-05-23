import Testing
import Foundation
import AppKit
@testable import apfelpad

/// Issue #16: visual QA over every example in the library. We can't
/// eyeball pixels in a unit test, but we can hard-pin the invariants
/// that #16 explicitly called out as broken or risky:
///
/// - every example renders (no exceptions, non-empty visible text)
/// - every formula in the example becomes a chip — no raw source
///   survives in the rendered output
/// - "Daily standup" textareas open on a fresh line (the #17 fix
///   applies; this is the regression net for it)
/// - examples that should have bullets (e.g. "All formulas at a
///   glance") render with • not -
/// - thematic breaks render as em-dashes (post-#20)
@Suite("Examples library render QA (#16)", .serialized)
@MainActor
struct ExamplesLibraryRenderQATests {
    /// Build the rendered NSAttributedString for an example. No live LLM,
    /// no clipboard, no document filesystem — pure render of the body.
    private func render(_ example: ExampleDocument) async -> NSAttributedString {
        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(
            cache: cache,
            clipboard: MockClipboard(value: "mock-clip")
        )
        let vm = DocumentViewModel(runtime: runtime)
        try? vm.load(rawMarkdown: example.body)
        await vm.evaluateAll()
        let projection = RenderProjection(document: vm.document)
        return RenderAttributedStringBuilder.build(from: projection)
    }

    @Test("every example renders without crash and produces visible text")
    func everyExampleRenders() async {
        for example in ExamplesLibrary.all {
            let rendered = await render(example)
            #expect(rendered.length > 0,
                    Comment(stringLiteral: "'\(example.title)' rendered empty"))
        }
    }

    @Test("Daily standup textareas appear on their own lines (#17 regression net)")
    func dailyStandupTextareasBlockLevel() async throws {
        guard let standup = ExamplesLibrary.all.first(where: { $0.title == "Daily standup" }) else {
            Issue.record("Daily standup example missing from library")
            return
        }
        let rendered = await render(standup)
        let s = rendered.string
        // For every "[<name>:" textarea marker, there must be a newline
        // immediately before it (the leading \n we added in #17).
        let openings = s.ranges(of: "[")
        // Pick the indices that look like our textarea marker pattern,
        // e.g. "[blockers:" or "[notes:" — anything inside square brackets
        // followed by a colon.
        let nsString = s as NSString
        for r in openings {
            let i = s.distance(from: s.startIndex, to: r.lowerBound)
            guard i > 0 else { continue }
            // Skip non-marker brackets — only check ones that look like
            // [name: ...] from the textarea placeholder.
            let nextSlice = nsString.substring(
                with: NSRange(location: i, length: min(40, nsString.length - i))
            )
            guard nextSlice.contains(":") && nextSlice.contains("]") else { continue }
            // Only the textarea placeholders are 3 lines long, so look
            // for the [name: …] marker followed by [text area] inside the
            // 40-char window — that's what identifies a textarea, not
            // some other inline bracket.
            guard nextSlice.contains("[text area]") else { continue }
            // Check that the character immediately before is a newline —
            // the leading \n we added in #17 must be there.
            let prevChar = nsString.character(at: i - 1)
            #expect(prevChar == 0x0A,
                    Comment(stringLiteral: "textarea marker at offset \(i) is not preceded by a newline; got char \(prevChar)"))
        }
    }

    @Test("'All formulas at a glance' renders bullets as • not -")
    func bulletsRender() async throws {
        guard let entry = ExamplesLibrary.all.first(where: { $0.title == "All formulas at a glance" }) else {
            Issue.record("missing example")
            return
        }
        let rendered = await render(entry)
        let s = rendered.string
        // The body of this example uses list items in its prose; #20 says
        // bullets must be •.
        // We assert that no line starts with "- " followed by a letter
        // (the un-replaced unordered list marker). Existing dashes in
        // prose ("foo - bar") are fine; only line-start matters.
        let lines = s.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("- ") && trimmed.count > 2 {
                Issue.record("raw '- ' bullet survived: \(line.debugDescription)")
            }
        }
    }

    @Test("every example's formula spans become chip-styled (non-source) ranges")
    func everySpanIsRendered() async {
        for example in ExamplesLibrary.all {
            let cache = InMemoryFormulaCache()
            let runtime = FormulaRuntime(
                cache: cache,
                clipboard: MockClipboard(value: "mock-clip")
            )
            let vm = DocumentViewModel(runtime: runtime)
            try? vm.load(rawMarkdown: example.body)
            await vm.evaluateAll()
            let projection = RenderProjection(document: vm.document)
            // Every non-empty document should produce at least one segment.
            #expect(!projection.segments.isEmpty,
                    Comment(stringLiteral: "'\(example.title)' produced no segments"))
            // formula segments should produce chips (we don't assert count
            // here — some examples are prose-only — but if any exist, the
            // projection's visible text should not include their raw
            // source).
            for span in vm.document.spans {
                // input spans handled separately by the placeholder path
                if case .input = span.call { continue }
                // recording is a v0.4 placeholder
                if case .recording = span.call { continue }
                // The visible text in render mode should not literally
                // contain the formula source (it gets replaced with
                // displayText).
                if projection.visibleText.contains(span.source) {
                    Issue.record(
                        "'\(example.title)': raw formula source `\(span.source)` survived into visible text"
                    )
                }
            }
        }
    }
}

private extension StringProtocol where Index == String.Index {
    func ranges(of substring: String) -> [Range<Index>] {
        var out: [Range<Index>] = []
        var search = startIndex..<endIndex
        while let r = range(of: substring, range: search) {
            out.append(r)
            search = r.upperBound..<endIndex
        }
        return out
    }
}
