import Testing
@testable import apfelpad

/// Tests for the v0.5 input/variable system:
///   - =input(name, type) declares a variable
///   - @name inside another formula resolves to the current value
///   - Changing an input value re-evaluates dependent formulas
@Suite("InputBindings")
@MainActor
struct InputBindingsTests {
    @Test("parser recognises =input(name, type)")
    func parseInput() throws {
        let call = try FormulaParser.parse(#"=input("hours", number)"#)
        if case .input(let name, let type, let defaultValue) = call {
            #expect(name == "hours")
            #expect(type == .number)
            #expect(defaultValue == nil)
        } else {
            Issue.record("expected .input, got \(call)")
        }
    }

    @Test("parser recognises =input with text type and default")
    func parseInputTextDefault() throws {
        let call = try FormulaParser.parse(#"=input("client", text, "Acme")"#)
        if case .input(let name, let type, let defaultValue) = call {
            #expect(name == "client")
            #expect(type == .text)
            #expect(defaultValue == "Acme")
        } else {
            Issue.record("expected .input, got \(call)")
        }
    }

    @Test("InputBindings stores and retrieves values")
    func bindingsGetSet() {
        let bindings = InputBindings()
        bindings.set("hours", to: "40")
        #expect(bindings.value(for: "hours") == "40")
        bindings.set("hours", to: "50")
        #expect(bindings.value(for: "hours") == "50")
    }

    @Test("InputBindings substitutes @name in a formula source")
    func bindingsSubstitute() {
        let bindings = InputBindings()
        bindings.set("hours", to: "40")
        bindings.set("rate", to: "150")
        let result = bindings.substitute(in: "=math(@hours * @rate)")
        #expect(result == "=math(40 * 150)")
    }

    @Test("InputBindings substitute leaves unknown @names alone")
    func bindingsLeaveUnknown() {
        let bindings = InputBindings()
        let result = bindings.substitute(in: "=math(@unknown * 2)")
        #expect(result == "=math(@unknown * 2)")
    }

    @Test("InputBindings substitute is case-insensitive on the name")
    func bindingsCaseInsensitive() {
        let bindings = InputBindings()
        bindings.set("Client", to: "Acme")
        let result = bindings.substitute(in: #"=concatenate("Hello, ", @client)"#)
        #expect(result == #"=concatenate("Hello, ", Acme)"#)
    }

    @Test("InputBindings substitute handles multiple refs in one formula")
    func bindingsMultipleRefs() {
        let bindings = InputBindings()
        bindings.set("a", to: "1")
        bindings.set("b", to: "2")
        bindings.set("c", to: "3")
        let result = bindings.substitute(in: "=sum(@a, @b, @c)")
        #expect(result == "=sum(1, 2, 3)")
    }

    @Test("InputBindings substitute inside string literals")
    func bindingsInsideString() {
        let bindings = InputBindings()
        bindings.set("client", to: "Acme")
        let result = bindings.substitute(in: #"=apfel("Hello @client, welcome!")"#)
        #expect(result == #"=apfel("Hello Acme, welcome!")"#)
    }

    @Test("InputBindings substitute leaves email addresses alone")
    func bindingsSkipEmails() {
        let bindings = InputBindings()
        bindings.set("test", to: "REPLACED")
        // test@test.com is an email — @test inside it must NOT substitute
        let result = bindings.substitute(in: "Contact test@test.com about @test")
        #expect(result == "Contact test@test.com about REPLACED")
    }

    @Test("InputBindings substitute skips @#section references")
    func bindingsSkipSections() {
        let bindings = InputBindings()
        bindings.set("intro", to: "SHOULD NOT APPEAR")
        let result = bindings.substitute(in: "=ref(@#intro)")
        #expect(result == "=ref(@#intro)")
    }

    @Test("references() ignores email addresses")
    func referencesIgnoreEmails() {
        let refs = InputBindings.references(in: "Email: admin@example.com and @hours")
        #expect(refs.contains("hours"))
        #expect(!refs.contains("example"))
    }

    @Test("references() ignores @#section refs")
    func referencesIgnoreSections() {
        let refs = InputBindings.references(in: "=ref(@#intro) and @hours")
        #expect(refs.contains("hours"))
        #expect(!refs.contains("intro"))
    }

    // MARK: - =show for echoing a variable

    @Test("parser recognises =show(@name)")
    func parseShow() throws {
        let call = try FormulaParser.parse("=show(@hours)")
        if case .show(let name) = call {
            #expect(name == "hours")
        } else {
            Issue.record("expected .show, got \(call)")
        }
    }

    // MARK: - Document-level integration

    @Test("=input renders its value; =math(@hours * @rate) reactive")
    func reactiveMath() async throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: """
        Hours: =input("hours", number, "40")
        Rate: =input("rate", number, "150")

        Total: =math(@hours * @rate)
        """)
        await vm.evaluateAll()
        let totalSpan = vm.document.spans.first { $0.source.contains("@hours") }
        #expect(totalSpan != nil)
        if let span = totalSpan, case .ready(let text) = span.value {
            #expect(text == "6000")
        } else {
            Issue.record("total span not ready: \(String(describing: totalSpan?.value))")
        }
    }

    @Test("updating a binding re-evaluates dependent formulas")
    func reactiveUpdate() async throws {
        let vm = DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
        try vm.load(rawMarkdown: """
        Hours: =input("hours", number, "40")
        Total: =math(@hours * 150)
        """)
        await vm.evaluateAll()
        let totalSpan = vm.document.spans.first { $0.source.contains("@hours") }!
        if case .ready(let text) = totalSpan.value {
            #expect(text == "6000")
        }

        // Change the binding
        vm.setInputBinding("hours", to: "50")
        await vm.evaluateAll()
        let updated = vm.document.spans.first { $0.source.contains("@hours") }!
        if case .ready(let text) = updated.value {
            #expect(text == "7500")
        } else {
            Issue.record("updated span not ready")
        }
    }
}
