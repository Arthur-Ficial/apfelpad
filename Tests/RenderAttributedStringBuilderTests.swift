import Testing
import AppKit
@testable import apfelpad

@Suite("RenderAttributedStringBuilder", .serialized)
@MainActor
struct RenderAttributedStringBuilderTests {
    @Test("heading typography spans plain text on both sides of a formula chip")
    func headingTypographyCrossesFormulaBoundaries() throws {
        var document = try Document(rawMarkdown: "# Total =math(1+1) apples")
        document.spans[0].value = .ready(text: "2")

        let projection = RenderProjection(document: document)
        let rendered = RenderAttributedStringBuilder.build(from: projection)
        let ns = rendered.string as NSString
        let totalIndex = try #require(ns.range(of: "Total").location != NSNotFound ? ns.range(of: "Total").location : nil)
        let applesIndex = try #require(ns.range(of: "apples").location != NSNotFound ? ns.range(of: "apples").location : nil)
        let totalFont = rendered.attribute(.font, at: totalIndex, effectiveRange: nil) as? NSFont
        let applesFont = rendered.attribute(.font, at: applesIndex, effectiveRange: nil) as? NSFont

        #expect(totalFont?.pointSize == 28)
        #expect(applesFont?.pointSize == 28)
    }

    @Test("formula chips keep their clickable link attributes")
    func formulaChipsRemainLinked() throws {
        var document = try Document(rawMarkdown: "A =math(1+1) B")
        document.spans[0].value = .ready(text: "2")

        let projection = RenderProjection(document: document)
        let rendered = RenderAttributedStringBuilder.build(from: projection)
        let formulaSegment = try #require(projection.segments.first {
            if case .formula = $0.kind { return true }
            return false
        })
        let link = rendered.attribute(
            .link,
            at: formulaSegment.visibleRange.lowerBound,
            effectiveRange: nil
        ) as? URL

        #expect(link == URL(string: "apfelpad://span/\(document.spans[0].id.uuidString)"))
    }
}
