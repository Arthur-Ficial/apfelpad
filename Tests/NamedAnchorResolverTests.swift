import Testing
@testable import apfelpad

@Suite("NamedAnchorResolver")
struct NamedAnchorResolverTests {
    @Test("resolves a simple top-level heading")
    func topLevel() {
        let md = """
        # Intro

        Hello world.

        # Body

        Other content.
        """
        #expect(NamedAnchorResolver.resolve("intro", in: md)?.trimmingCharacters(in: .whitespacesAndNewlines) == "Hello world.")
    }

    @Test("anchor lookup is case-insensitive")
    func caseInsensitive() {
        let md = "# My Section\n\nBody."
        #expect(NamedAnchorResolver.resolve("my-section", in: md) != nil)
        #expect(NamedAnchorResolver.resolve("My Section", in: md) != nil)
        #expect(NamedAnchorResolver.resolve("MY SECTION", in: md) != nil)
    }

    @Test("multiword headings are slugified to kebab case")
    func slugified() {
        let md = "# A Big Deal\n\nStuff."
        // Both the kebab form and the raw form should work
        #expect(NamedAnchorResolver.resolve("a-big-deal", in: md) != nil)
        #expect(NamedAnchorResolver.resolve("a big deal", in: md) != nil)
    }

    @Test("section runs to the next heading of equal or higher level")
    func sectionBoundary() {
        let md = """
        # Intro

        First paragraph.

        ## Subsection

        Nested content.

        # Body

        After body heading.
        """
        let result = NamedAnchorResolver.resolve("intro", in: md)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        #expect(result.contains("First paragraph"))
        #expect(result.contains("Nested content"))
        #expect(!result.contains("After body heading"))
    }

    @Test("nested subsection anchor resolves to just that subsection")
    func subsectionOnly() {
        let md = """
        # Intro
        Top.
        ## Subsection
        Nested only.
        # Body
        Elsewhere.
        """
        let result = NamedAnchorResolver.resolve("subsection", in: md)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        #expect(result.contains("Nested only"))
        #expect(!result.contains("Top"))
        #expect(!result.contains("Elsewhere"))
    }

    @Test("missing anchor returns nil")
    func missing() {
        let md = "# Foo\n\nContent."
        #expect(NamedAnchorResolver.resolve("bar", in: md) == nil)
    }

    @Test("strips leading @ if present")
    func stripAtSign() {
        let md = "# Intro\n\nHi."
        #expect(NamedAnchorResolver.resolve("@intro", in: md) != nil)
    }
}
