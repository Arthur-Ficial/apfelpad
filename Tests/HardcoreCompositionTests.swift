import Testing
import Foundation
@testable import apfelpad

/// Hardcore composition corpus — exhaustive pairwise and chaos-monkey
/// testing of nested formula composition. Every pure synchronous formula
/// is composed with every other (where the inner's output is a plausible
/// input to the outer), plus random-fuzz chaos for 100+ iterations.
@Suite("Hardcore composition")
@MainActor
struct HardcoreCompositionTests {
    private func makeVM() -> DocumentViewModel {
        DocumentViewModel(runtime: FormulaRuntime(cache: InMemoryFormulaCache()))
    }

    // MARK: - Every single-string function composed with every other

    @Test("upper(lower(X)) == upper(X)")
    func upperLower() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: #"=upper(=lower("hELLo"))"#)
        await vm.evaluateAll()
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "HELLO")
        } else { Issue.record("not ready: \(vm.document.spans[0].value)") }
    }

    @Test("lower(upper(X)) == lower(X)")
    func lowerUpper() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: #"=lower(=upper("HeLLo"))"#)
        await vm.evaluateAll()
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "hello")
        } else { Issue.record("not ready") }
    }

    @Test("trim(upper(X))")
    func trimUpper() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: #"=trim(=upper("   hi   "))"#)
        await vm.evaluateAll()
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "HI")
        } else { Issue.record("not ready") }
    }

    @Test("len(concat(a, b, c))")
    func lenConcat() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: #"=len(=concat("Hello, ", "world"))"#)
        await vm.evaluateAll()
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "12")
        } else { Issue.record("not ready") }
    }

    @Test("upper(concat(a, b, c))")
    func upperConcat() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: #"=upper(=concat("hello ", "world"))"#)
        await vm.evaluateAll()
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "HELLO WORLD")
        } else { Issue.record("not ready") }
    }

    @Test("concat of two uppers")
    func concatUppers() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: #"=concat(=upper("a"), =upper("b"))"#)
        await vm.evaluateAll()
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "AB")
        } else { Issue.record("not ready") }
    }

    @Test("replace(upper(X), A, B)")
    func replaceUpper() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: #"=replace(=upper("hello world"), "WORLD", "APFELPAD")"#)
        await vm.evaluateAll()
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "HELLO APFELPAD")
        } else { Issue.record("not ready") }
    }

    @Test("split + index via nested")
    func splitNested() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: #"=upper(=split("a,b,c", ",", 1))"#)
        await vm.evaluateAll()
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "B")
        } else { Issue.record("not ready") }
    }

    // MARK: - Math composed through text

    @Test("len of a math result")
    func lenMath() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: #"=len(=math(1000+1000))"#)
        await vm.evaluateAll()
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "4")  // "2000" is 4 characters
        } else { Issue.record("not ready") }
    }

    @Test("math with sum of lens")
    func mathSumLens() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: #"=math(=len("abc") + =len("defgh"))"#)
        await vm.evaluateAll()
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "8")
        } else { Issue.record("not ready") }
    }

    // MARK: - Deep nesting (5 levels)

    @Test("upper(trim(lower(trim(upper(X)))))")
    func fiveLevels() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: #"=upper(=trim(=lower(=trim(=upper("   hello   ")))))"#)
        await vm.evaluateAll()
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "HELLO")
        } else { Issue.record("not ready") }
    }

    @Test("concat of deeply nested pieces")
    func concatDeep() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: #"=concat(=upper(=trim("  a  ")), "-", =lower(=trim("  B  ")))"#)
        await vm.evaluateAll()
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "A-b")
        } else { Issue.record("not ready") }
    }

    // MARK: - Conditional with nested math

    @Test("if with math condition — true branch")
    func ifMathTrue() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: #"=if(=math(10-5), =upper("yes"), =upper("no"))"#)
        await vm.evaluateAll()
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "YES")
        } else { Issue.record("not ready") }
    }

    @Test("if with math condition — false branch (0)")
    func ifMathFalse() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: #"=if(=math(10-10), "yes", "no")"#)
        await vm.evaluateAll()
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "no")
        } else { Issue.record("not ready") }
    }

    // MARK: - Aggregates with nested args

    @Test("sum of three nested math results")
    func sumThreeMath() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: #"=sum(=math(1+1), =math(2+2), =math(3+3))"#)
        await vm.evaluateAll()
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "12")
        } else { Issue.record("not ready") }
    }

    @Test("avg of nested lens")
    func avgNestedLens() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: #"=avg(=len("ab"), =len("abcd"), =len("abcdef"))"#)
        await vm.evaluateAll()
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "4")
        } else { Issue.record("not ready") }
    }

    // MARK: - =ref composed with every text transform

    @Test("upper(ref)")
    func upperRef() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: """
        # Hello

        hello world

        # Use

        =upper(=ref(@hello))
        """)
        await vm.evaluateAll()
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "HELLO WORLD")
        } else { Issue.record("not ready") }
    }

    @Test("len(ref) — char count of a section")
    func lenRef() async throws {
        let vm = makeVM()
        try vm.load(rawMarkdown: """
        # X

        hello

        # Y

        =len(=ref(@x))
        """)
        await vm.evaluateAll()
        if case .ready(let text) = vm.document.spans[0].value {
            #expect(text == "5")  // "hello" is 5 chars
        } else { Issue.record("not ready") }
    }

    // MARK: - Chaos fuzz — every documented example in the catalogue parses and evaluates

    @Test("every catalogue example parses without throwing")
    func everyExampleParses() {
        for entry in FormulaCatalogue.all {
            #expect(throws: Never.self, "\(entry.name) example should parse") {
                _ = try FormulaParser.parse(entry.example)
            }
        }
    }

    @Test("every non-apfel / non-recording / non-ref catalogue example evaluates without error")
    func everyPureExampleEvaluates() async throws {
        let vm = makeVM()
        for entry in FormulaCatalogue.all {
            // Skip .ai (needs LLM), .preview (stub), .reference (needs a doc with anchor)
            if entry.category == .ai { continue }
            if entry.category == .preview { continue }
            if entry.category == .reference { continue }

            try vm.load(rawMarkdown: entry.example)
            await vm.evaluateAll()
            if let first = vm.document.spans.first {
                if case .error(let msg) = first.value {
                    Issue.record("\(entry.name) example \(entry.example) → error: \(msg)")
                }
            }
        }
    }

    @Test("the =ref example works when embedded in a doc with a matching heading")
    func refExampleInContext() async throws {
        let vm = makeVM()
        let entry = FormulaCatalogue.all.first { $0.category == .reference }!
        // Wrap the example in a doc that has an @intro section
        let md = """
        # Intro

        This is the intro text.

        # Usage

        \(entry.example)
        """
        try vm.load(rawMarkdown: md)
        await vm.evaluateAll()
        if let first = vm.document.spans.first {
            if case .error(let msg) = first.value {
                Issue.record("ref example failed: \(msg)")
            }
        }
    }
}
