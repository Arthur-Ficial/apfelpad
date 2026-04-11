import Testing
import SwiftUI
@testable import apfelpad

@Suite("FormulaSpanView visual spec")
struct FormulaSpanViewTests {
    @Test("uses pale green background and dark green accent")
    func colours() {
        #expect(FormulaSpanView.backgroundColour == Color(red: 0.94, green: 0.98, blue: 0.93))
        #expect(FormulaSpanView.accentColour == Color(red: 0.16, green: 0.49, blue: 0.22))
    }

    @Test("displayText shows source in idle state")
    func idleText() {
        let span = FormulaSpan(
            range: 0..<10,
            source: "=math(1+1)",
            call: .math(expression: "1+1"),
            value: .idle
        )
        #expect(FormulaSpanView.displayText(for: span) == "=math(1+1)")
    }

    @Test("displayText shows result in ready state")
    func readyText() {
        let span = FormulaSpan(
            range: 0..<10,
            source: "=math(1+1)",
            call: .math(expression: "1+1"),
            value: .ready(text: "2")
        )
        #expect(FormulaSpanView.displayText(for: span) == "2")
    }

    @Test("displayText shows error message in error state")
    func errorText() {
        let span = FormulaSpan(
            range: 0..<10,
            source: "=math(abc)",
            call: .math(expression: "abc"),
            value: .error(message: "bad expression")
        )
        #expect(FormulaSpanView.displayText(for: span) == "bad expression")
    }
}
