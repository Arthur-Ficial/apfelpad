import Testing
import Foundation
@testable import apfelpad

@Suite("Render projection")
struct RenderProjectionTests {

    @Test("render replaces formula source with display text")
    func formulaBecomesRenderedChipText() throws {
        var document = try Document(rawMarkdown: "Total: =math(40+2)")
        document.spans[0].value = .ready(text: "42")

        let projection = RenderProjection(document: document)

        #expect(projection.visibleText == "Total:  42 ")
    }

    @Test("plain text edit maps back into raw markdown")
    func plainTextEditMapsToRawRange() throws {
        var document = try Document(rawMarkdown: "Hello =math(40+2) world")
        document.spans[0].value = .ready(text: "42")

        let projection = RenderProjection(document: document)
        let visibleRange = NSRange(location: 0, length: 5)
        let rawRange = try #require(projection.rawEditRange(forVisibleRange: visibleRange))

        #expect(rawRange == NSRange(location: 0, length: 5))
    }

    @Test("full chip selection can replace the raw formula")
    func fullChipSelectionMapsToFormulaSource() throws {
        var document = try Document(rawMarkdown: "A =math(40+2) B")
        document.spans[0].value = .ready(text: "42")

        let projection = RenderProjection(document: document)
        let formulaSegment = try #require(projection.segments.first {
            if case .formula = $0.kind { return true }
            return false
        })

        let rawRange = try #require(projection.rawEditRange(forVisibleRange: NSRange(
            location: formulaSegment.visibleRange.lowerBound,
            length: formulaSegment.visibleRange.upperBound - formulaSegment.visibleRange.lowerBound
        )))

        #expect(rawRange.location == document.spans[0].range.lowerBound)
        #expect(rawRange.length == document.spans[0].range.upperBound - document.spans[0].range.lowerBound)
    }

    @Test("partial chip edit is rejected")
    func partialChipEditIsRejected() throws {
        var document = try Document(rawMarkdown: "A =math(40+2) B")
        document.spans[0].value = .ready(text: "42")

        let projection = RenderProjection(document: document)
        let formulaSegment = try #require(projection.segments.first {
            if case .formula = $0.kind { return true }
            return false
        })

        let partial = NSRange(location: formulaSegment.visibleRange.lowerBound + 1, length: 1)
        #expect(projection.rawEditRange(forVisibleRange: partial) == nil)
    }

    @Test("raw and visible boundaries round-trip around chips")
    func boundariesRoundTrip() throws {
        var document = try Document(rawMarkdown: "Hi =math(1+1) there")
        document.spans[0].value = .ready(text: "2")

        let projection = RenderProjection(document: document)
        let rawLocation = document.spans[0].range.upperBound
        let visibleLocation = projection.visibleLocation(forRawLocation: rawLocation)
        let mappedBack = try #require(projection.rawBoundary(forVisibleLocation: visibleLocation))

        #expect(mappedBack == rawLocation)
    }

    @Test("input spans reserve dedicated render segments")
    func inputSegmentsAreDistinct() throws {
        var document = try Document(rawMarkdown: #"Hours: =input("hours", number, "40")"#)
        document.spans[0].value = .ready(text: "40")

        let projection = RenderProjection(document: document)
        let inputSegments = projection.inputSegments()

        #expect(inputSegments.count == 1)
        if case .input(let spec) = inputSegments[0].kind {
            #expect(spec.name == "hours")
            #expect(spec.type == .number)
            #expect(spec.placeholder.contains("hours"))
        } else {
            Issue.record("expected input segment")
        }
    }
}
