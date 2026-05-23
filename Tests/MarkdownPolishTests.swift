import Testing
import Foundation
import AppKit
@testable import apfelpad

/// Issue #20: lists / thematic breaks must render with proper typography
/// in render mode. The styler operates over the NSAttributedString built
/// from the visible text — modifying glyphs (e.g. `-` → `•`) and
/// applying paragraph styles (hanging indent for wrapped list items).
///
/// These tests run headlessly — no NSTextView, no UI — so they can verify
/// the styler in isolation.
@Suite("Markdown polish: lists, thematic breaks", .serialized)
@MainActor
struct MarkdownPolishTests {
    /// Build the rendered NSAttributedString for the given raw markdown,
    /// with formula spans not evaluated (they're not the focus here).
    private func render(_ markdown: String) -> NSAttributedString {
        let document = try! Document(rawMarkdown: markdown)
        let projection = RenderProjection(document: document)
        return RenderAttributedStringBuilder.build(from: projection)
    }

    // MARK: - Unordered lists: bullet glyph

    @Test("dash bullets are replaced with • in render mode")
    func dashBulletsBecomeRoundDots() {
        let markdown = """
        - first
        - second
        - third
        """
        let rendered = render(markdown)
        let s = rendered.string
        // Each list item should start with "• " in the rendered output;
        // the original "- " should NOT survive.
        #expect(s.contains("• first"), "expected bulleted 'first', got: \(s.debugDescription)")
        #expect(s.contains("• second"))
        #expect(s.contains("• third"))
        #expect(!s.contains("- first"),
                "raw dash marker should be replaced — got: \(s.debugDescription)")
    }

    @Test("star bullets are replaced with • too")
    func starBulletsBecomeRoundDots() {
        let markdown = """
        * one
        * two
        """
        let rendered = render(markdown).string
        #expect(rendered.contains("• one"))
        #expect(rendered.contains("• two"))
        #expect(!rendered.contains("* one"))
    }

    @Test("ordered list items keep their numbering")
    func orderedListsKeepNumbers() {
        let markdown = """
        1. first
        2. second
        """
        let rendered = render(markdown).string
        // Don't strip the "1." — Google Sheets-style ordered lists keep the
        // visible number. We just apply hanging indent (asserted separately).
        #expect(rendered.contains("1. first"))
        #expect(rendered.contains("2. second"))
    }

    @Test("unordered list items get a hanging-indent paragraph style")
    func unorderedListHangingIndent() {
        let markdown = "- first item\n- second item"
        let rendered = render(markdown)
        // Find the start of "first item" and assert a paragraph style is
        // set with headIndent > firstLineHeadIndent (hanging indent).
        let s = rendered.string as NSString
        let firstItemRange = s.range(of: "first item")
        guard firstItemRange.location != NSNotFound else {
            Issue.record("could not find 'first item' in: \(s as String)")
            return
        }
        let style = rendered.attribute(.paragraphStyle,
                                       at: firstItemRange.location,
                                       effectiveRange: nil) as? NSParagraphStyle
        guard let style else {
            Issue.record("no paragraph style on list item")
            return
        }
        let hangingOK = style.headIndent > style.firstLineHeadIndent
        #expect(hangingOK,
                Comment(stringLiteral: "list items need hanging indent — headIndent " +
                        "(\(style.headIndent)) must exceed firstLineHeadIndent " +
                        "(\(style.firstLineHeadIndent))"))
    }

    // MARK: - Thematic breaks

    @Test("thematic break --- is replaced with a centered rule line")
    func thematicBreakBecomesCenteredRule() {
        let markdown = """
        before

        ---

        after
        """
        let rendered = render(markdown)
        let s = rendered.string
        // The literal "---" should NOT appear on its own line — it gets
        // replaced with em-dashes (or similar visible horizontal rule).
        // Easy invariant: the visible text contains "before" and "after"
        // but not the original "---" line.
        #expect(s.contains("before"))
        #expect(s.contains("after"))
        let lines = s.components(separatedBy: "\n")
        let dashOnlyLine = lines.first(where: { $0.trimmingCharacters(in: .whitespaces) == "---" })
        #expect(dashOnlyLine == nil,
                "expected '---' to be replaced — but found bare line: \(dashOnlyLine ?? "nil")")
    }

    @Test("thematic break paragraph has center alignment")
    func thematicBreakCenterAligned() {
        let markdown = "before\n\n---\n\nafter"
        let rendered = render(markdown)
        let s = rendered.string as NSString
        // Find the em-dash characters and check their paragraph style is centered.
        let emDashRange = s.range(of: "\u{2014}")
        guard emDashRange.location != NSNotFound else {
            Issue.record("expected em-dash in: \(s as String)")
            return
        }
        let style = rendered.attribute(.paragraphStyle,
                                       at: emDashRange.location,
                                       effectiveRange: nil) as? NSParagraphStyle
        guard let style else {
            Issue.record("no paragraph style on thematic break")
            return
        }
        #expect(style.alignment == .center)
    }
}
