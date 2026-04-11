import Testing
@testable import apfelpad

@Suite("NestedFormulaResolver")
struct NestedFormulaResolverTests {
    @Test("flattens =upper(=lower(HELLO)) to =upper(\"hello\")")
    func simpleNesting() async throws {
        let resolved = await NestedFormulaResolver.flatten(
            source: #"=upper(=lower("HELLO"))"#,
            in: ""
        )
        #expect(resolved == #"=upper("hello")"#)
    }

    @Test("flattens two sibling sub-calls")
    func twoSiblings() async throws {
        let resolved = await NestedFormulaResolver.flatten(
            source: #"=concat(=upper("a"), =lower("B"))"#,
            in: ""
        )
        #expect(resolved == #"=concat("A", "b")"#)
    }

    @Test("flattens =ref against a source document")
    func nestedRef() async throws {
        let doc = """
        # Intro

        hello world

        # Body

        other
        """
        let resolved = await NestedFormulaResolver.flatten(
            source: #"=upper(=ref(@intro))"#,
            in: doc
        )
        #expect(resolved == #"=upper("hello world")"#)
    }

    @Test("three levels of nesting")
    func threeLevels() async throws {
        let resolved = await NestedFormulaResolver.flatten(
            source: #"=upper(=trim(=lower("  HELLO  ")))"#,
            in: ""
        )
        #expect(resolved == #"=upper("hello")"#)
    }

    @Test("leaves unknown nested calls alone")
    func unknownNested() async throws {
        let resolved = await NestedFormulaResolver.flatten(
            source: #"=upper(=nosuch("x"))"#,
            in: ""
        )
        // If a nested call cannot be resolved, flatten returns the source
        // unchanged and the outer parse surfaces the error.
        #expect(resolved == #"=upper(=nosuch("x"))"#)
    }

    @Test("no nesting returns source unchanged")
    func noNesting() async throws {
        let resolved = await NestedFormulaResolver.flatten(
            source: #"=upper("hello")"#,
            in: ""
        )
        #expect(resolved == #"=upper("hello")"#)
    }

    @Test("recursion depth is capped")
    func maxDepth() async throws {
        // Even if someone crafts pathological nesting, depth is capped at 10
        // so flatten always terminates.
        let deep = String(repeating: "=upper(", count: 20) + "\"hi\"" + String(repeating: ")", count: 20)
        // Must not hang
        _ = await NestedFormulaResolver.flatten(source: deep, in: "")
    }
}
