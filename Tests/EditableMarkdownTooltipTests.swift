import Testing
import Foundation
@testable import apfelpad

@Suite("Editable markdown tooltip", .serialized)
struct EditableMarkdownTooltipTests {

    @Test("formula chip tooltip shows the formula source, not the apfelpad:// URL")
    func formulaTooltipReturnsSource() throws {
        var document = try Document(rawMarkdown: "Total: =math(40+2) units")
        document.spans[0].value = .ready(text: "42")
        let projection = RenderProjection(document: document)

        let formulaSegment = try #require(projection.segments.first {
            if case .formula = $0.kind { return true }
            return false
        })
        let midpoint = (formulaSegment.visibleRange.lowerBound + formulaSegment.visibleRange.upperBound) / 2

        let tip = EditableMarkdownView.toolTipString(in: projection, at: midpoint)

        #expect(tip == "=math(40+2)")
        #expect(tip?.contains("apfelpad://") == false)
        #expect(tip?.contains("UUID") == false)
    }

    @Test("plain text returns nil so AppKit shows no link tooltip")
    func plainTextReturnsNil() throws {
        var document = try Document(rawMarkdown: "Total: =math(40+2) units")
        document.spans[0].value = .ready(text: "42")
        let projection = RenderProjection(document: document)

        let plainSegment = try #require(projection.segments.first {
            if case .plain = $0.kind { return true }
            return false
        })
        // Pick a character in plain text, away from the formula.
        let location = plainSegment.visibleRange.lowerBound

        let tip = EditableMarkdownView.toolTipString(in: projection, at: location)

        #expect(tip == nil)
    }

    @Test("input span tooltip is suppressed (no URL leak from input chips)")
    func inputSpanReturnsNil() throws {
        var document = try Document(rawMarkdown: "Name: =input(name, text, \"Alice\")")
        let projection = RenderProjection(document: document)

        let inputSegment = try #require(projection.segments.first {
            if case .input = $0.kind { return true }
            return false
        })
        let midpoint = (inputSegment.visibleRange.lowerBound + inputSegment.visibleRange.upperBound) / 2

        let tip = EditableMarkdownView.toolTipString(in: projection, at: midpoint)

        // Input segments don't carry an apfelpad:// link in render mode, so no
        // tooltip override is needed and the helper returns nil.
        #expect(tip == nil)
    }

    @Test("character index out of range returns nil")
    func outOfRangeReturnsNil() throws {
        let document = try Document(rawMarkdown: "Plain text only")
        let projection = RenderProjection(document: document)

        let tip = EditableMarkdownView.toolTipString(in: projection, at: 9_999)

        #expect(tip == nil)
    }
}
