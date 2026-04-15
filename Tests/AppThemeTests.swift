import Testing
import AppKit
import SwiftUI
@testable import apfelpad

@Suite("AppTheme", .serialized)
struct AppThemeTests {
    @Test("theme exposes reusable formula colors for every surface")
    func formulaColorsExist() {
        let readySpan = FormulaSpan(
            range: 0..<10,
            source: "=math(1+1)",
            call: .math(expression: "1+1"),
            value: .ready(text: "2")
        )
        let errorSpan = FormulaSpan(
            range: 0..<10,
            source: "=math(bad)",
            call: .math(expression: "bad"),
            value: .error(message: "bad expression")
        )
        let staleSpan = FormulaSpan(
            range: 0..<10,
            source: "=math(1+1)",
            call: .math(expression: "1+1"),
            value: .stale(text: "2")
        )

        #expect(FormulaSpanView.backgroundColour == AppTheme.formulaBackground)
        #expect(FormulaSpanView.accentColour == AppTheme.formulaAccent)
        #expect(InputFieldView.parseColor("") == AppTheme.formulaBackground)
        #expect(AppTheme.formulaBackgroundNSColor.usingColorSpace(.sRGB) != nil)
        #expect(AppTheme.formulaAccentNSColor.usingColorSpace(.sRGB) != nil)
        #expect(AppTheme.errorAccentNSColor.usingColorSpace(.sRGB) != nil)
        #expect(AppTheme.staleBorderNSColor.usingColorSpace(.sRGB) != nil)
        #expect(AppTheme.formulaChipBackgroundNSColor(for: readySpan) == AppTheme.formulaBackgroundNSColor)
        #expect(AppTheme.formulaChipForegroundNSColor(for: readySpan) == AppTheme.formulaAccentNSColor)
        #expect(AppTheme.formulaChipBackgroundNSColor(for: errorSpan) == AppTheme.errorBackgroundNSColor)
        #expect(AppTheme.formulaChipForegroundNSColor(for: errorSpan) == AppTheme.errorAccentNSColor)
        #expect(AppTheme.formulaChipBorder(for: staleSpan) == AppTheme.staleBorder)
        #expect(AppTheme.formulaChipBorder(for: errorSpan) == AppTheme.errorAccent)
    }
}
