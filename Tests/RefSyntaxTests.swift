import Testing
@testable import apfelpad

@Suite("RefSyntax — @# for sections, @ for variables", .serialized)
@MainActor
struct RefSyntaxTests {
    @Test("=ref(@#anchor) parses with @# prefix")
    func refWithHash() throws {
        let call = try FormulaParser.parse("=ref(@#intro)")
        #expect(call == .ref(anchor: "intro"))
    }

    @Test("=ref(@anchor) still parses for backwards compat")
    func refLegacy() throws {
        let call = try FormulaParser.parse("=ref(@intro)")
        #expect(call == .ref(anchor: "intro"))
    }

    @Test("render =ref uses @# syntax")
    func renderRef() {
        let rendered = FormulaParser.render(.ref(anchor: "intro"))
        #expect(rendered == "=ref(@#intro)")
    }

    @Test("canonicalise upgrades =ref(@intro) to =ref(@#intro)")
    func canonicaliseRef() throws {
        let canonical = try FormulaParser.canonicalise("=ref(@intro)")
        #expect(canonical == "=ref(@#intro)")
    }

    @Test("InputBindings does NOT substitute @# tokens")
    func bindingsSkipHash() {
        let bindings = InputBindings()
        bindings.set("intro", to: "REPLACED")
        let result = bindings.substitute(in: "=ref(@#intro)")
        #expect(result == "=ref(@#intro)")
    }

    @Test("InputBindings.references skips @# tokens")
    func referencesSkipHash() {
        let refs = InputBindings.references(in: "=ref(@#intro) and @price")
        #expect(refs.contains("price"))
        #expect(!refs.contains("intro"))
        #expect(!refs.contains("#intro"))
    }

    @Test("@ alone is still substituted as input variable")
    func atStillWorks() {
        let bindings = InputBindings()
        bindings.set("price", to: "99")
        let result = bindings.substitute(in: "=math(@price * 2)")
        #expect(result == "=math(99 * 2)")
    }

    @Test("=ref(@#section) resolves in DocumentViewModel")
    func vmRefResolves() async throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: """
        # Intro

        Hello world.

        # Body

        See: =ref(@#intro)
        """)
        await vm.evaluateAll()
        let span = vm.document.spans.first
        #expect(span != nil)
        if let s = span, case .ready(let text) = s.value {
            #expect(text == "Hello world.")
        } else {
            Issue.record("expected .ready, got \(String(describing: span?.value))")
        }
    }

    @Test("@name and @#section coexist in same document")
    func coexistence() async throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: """
        # Prices

        Widget costs $50.

        # Invoice

        =input("qty", number, "10")

        Ref: =ref(@#prices)
        Total: =math(@qty * 50)
        """)
        await vm.evaluateAll()

        let refSpan = vm.document.spans.first { $0.source.contains("ref") }
        let mathSpan = vm.document.spans.first { $0.source.contains("@qty") }

        if let s = refSpan, case .ready(let text) = s.value {
            #expect(text.contains("Widget"))
        }
        if let s = mathSpan, case .ready(let text) = s.value {
            #expect(text == "500")
        }
    }
}
