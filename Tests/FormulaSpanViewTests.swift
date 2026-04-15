import Testing
import SwiftUI
@testable import apfelpad

@Suite("FormulaSpanView visual spec", .serialized)
struct FormulaSpanViewTests {
    @Test("uses shared app theme colors")
    @MainActor
    func colours() {
        #expect(FormulaSpanView.backgroundColour == AppTheme.formulaBackground)
        #expect(FormulaSpanView.accentColour == AppTheme.formulaAccent)
    }

    @Test("displayText shows source in idle state")
    func idleText() {
        let span = FormulaSpan(
            range: 0..<10,
            source: "=math(1+1)",
            call: .math(expression: "1+1"),
            value: .idle
        )
        #expect(span.displayText == "=math(1+1)")
    }

    @Test("displayText shows result in ready state")
    func readyText() {
        let span = FormulaSpan(
            range: 0..<10,
            source: "=math(1+1)",
            call: .math(expression: "1+1"),
            value: .ready(text: "2")
        )
        #expect(span.displayText == "2")
    }

    @Test("displayText shows error message in error state")
    func errorText() {
        let span = FormulaSpan(
            range: 0..<10,
            source: "=math(abc)",
            call: .math(expression: "abc"),
            value: .error(message: "bad expression")
        )
        #expect(span.displayText == "bad expression")
    }
}
