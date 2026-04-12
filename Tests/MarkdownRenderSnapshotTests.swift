import Testing
import Foundation
@testable import apfelpad

/// Ground-truth rendering tests. For a given raw markdown input, after
/// evaluation, the rendered plaintext — i.e. what a user SEES on screen
/// in Markdown mode — must equal the declared expected string.
///
/// This is the regression net for "currentlu rendering does not seem to work
/// at all": if these tests pass, the welcome document renders `8760` and
/// `2920` and `2008`, not `=math(365*24)`.
///
/// The plaintext is produced by running the document through the same
/// InlineFormulaRenderer that DocumentBodyView uses for every prose paragraph.
/// If this contract breaks, every Markdown-mode render breaks with it.
@Suite("Markdown render snapshots — what you see vs what you expect")
@MainActor
struct MarkdownRenderSnapshotTests {

    /// Build a VM, load the markdown, evaluate everything, then extract the
    /// plaintext that InlineFormulaRenderer would produce for the whole doc.
    /// The renderer adds a single space of padding around each span; we strip
    /// that padding so snapshots compare against human-readable text.
    private func renderPlainText(_ raw: String) async -> String {
        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let vm = DocumentViewModel(runtime: runtime)
        try? vm.load(rawMarkdown: raw)
        await vm.evaluateAll()
        let attr = InlineFormulaRenderer.render(vm.document)
        return stripSpanPadding(String(attr.characters))
    }

    /// InlineFormulaRenderer wraps every span text in " text " (leading and
    /// trailing space). Collapse those to a single space so the assertions
    /// read naturally.
    private func stripSpanPadding(_ s: String) -> String {
        var out = s
        while out.contains("  ") { out = out.replacingOccurrences(of: "  ", with: " ") }
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @Test("=math arithmetic renders evaluated integer, not source")
    func mathRendersValue() async {
        let out = await renderPlainText("There are =math(365*24) hours in a year.")
        #expect(out.contains("8760"))
        #expect(!out.contains("=math(365*24)"))
    }

    @Test("multiple =math spans all render as their values")
    func multipleMathSpans() async {
        let doc = """
        =math(365*24) hours, =math(365*8) working, =math((365-104-10)*8) after weekends.
        """
        let out = await renderPlainText(doc)
        #expect(out.contains("8760"))
        #expect(out.contains("2920"))
        #expect(out.contains("2008"))
        #expect(!out.contains("=math"))
    }

    @Test("=count() renders a number, not the source")
    func countRendersNumber() async {
        let doc = "This document has =count() words."
        let out = await renderPlainText(doc)
        #expect(!out.contains("=count()"))
        // The count includes the =count() span as one word too, but it's at
        // least 4 (This document has <N> words.)
        // Just assert it rendered SOME number.
        let hasDigits = out.contains { $0.isNumber }
        #expect(hasDigits, "output should contain evaluated word count: \(out)")
    }

    @Test("=date() renders today's date, not source")
    func dateRendersValue() async {
        let out = await renderPlainText("Today is =date().")
        #expect(!out.contains("=date()"))
        // ISO date starts with the current year
        let year = Calendar.current.component(.year, from: Date())
        #expect(out.contains(String(year)))
    }

    @Test("=day() and =cw() render real values")
    func dayAndCwRender() async {
        let out = await renderPlainText("Today is =day(), week =cw().")
        #expect(!out.contains("=day()"))
        #expect(!out.contains("=cw()"))
    }

    @Test("welcome document renders every formula")
    func welcomeDocumentRendersEverything() async {
        let doc = """
        # Welcome to apfelpad

        A formula notepad for thinking. On-device AI as a first-class function.

        ## Arithmetic

        There are =math(365*24) hours in a year.
        That's =math(365*8) working hours.
        And =math((365-104-10)*8) hours after weekends and holidays.

        ## Document info

        This document has =count() words.
        Today is =date() (=day(), week =cw()).
        """
        let out = await renderPlainText(doc)

        // Arithmetic evaluated
        #expect(out.contains("8760"), "=math(365*24) should render 8760\nGot: \(out)")
        #expect(out.contains("2920"), "=math(365*8) should render 2920\nGot: \(out)")
        #expect(out.contains("2008"), "=math((365-104-10)*8) should render 2008\nGot: \(out)")

        // No remaining formula sources should leak into the rendered output
        #expect(!out.contains("=math("), "math sources leaked: \(out)")
        #expect(!out.contains("=count("), "count sources leaked: \(out)")
        #expect(!out.contains("=date("), "date sources leaked: \(out)")
        #expect(!out.contains("=day("), "day sources leaked: \(out)")
        #expect(!out.contains("=cw("), "cw sources leaked: \(out)")
    }

    @Test("text formulas render in prose")
    func textFormulasRender() async {
        let doc = "Shouty: =upper(hello world). Calm: =lower(WORLD)."
        let out = await renderPlainText(doc)
        #expect(out.contains("HELLO WORLD"))
        #expect(out.contains("world"))
        #expect(!out.contains("=upper"))
        #expect(!out.contains("=lower"))
    }

    @Test("reactive =input + =math(@name) renders live value, not source")
    func reactiveInputRendersCurrentValue() async {
        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let vm = DocumentViewModel(runtime: runtime)
        let doc = """
        Hours: =input("hours", number, "40")
        Total: $=math(@hours * 150)
        """
        try? vm.load(rawMarkdown: doc)
        await vm.evaluateAll()
        let first = String(InlineFormulaRenderer.render(vm.document).characters)
        #expect(first.contains("6000"), "first render must compute 40*150=6000, got: \(first)")

        // Now simulate typing in the input widget
        vm.setInputBinding("hours", to: "50")
        // evaluateIndices runs async; wait for it
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(50))
        // Flush any additional evaluations triggered by the binding change
        await vm.evaluateAll()
        let second = String(InlineFormulaRenderer.render(vm.document).characters)
        #expect(second.contains("7500"), "after rebind to 50, must compute 50*150=7500, got: \(second)")
    }

    @Test("=show(@name) echoes the current binding value, never the source")
    func showEchoesValue() async {
        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache)
        let vm = DocumentViewModel(runtime: runtime)
        let doc = """
        =input("name", text, "Alice")
        Hello =show(@name)!
        """
        try? vm.load(rawMarkdown: doc)
        await vm.evaluateAll()
        let out = String(InlineFormulaRenderer.render(vm.document).characters)
        #expect(out.contains("Alice"))
        #expect(!out.contains("=show(@name)"))
    }
}
