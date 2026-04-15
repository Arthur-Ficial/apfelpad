import AppKit
import SwiftUI

enum AppTheme {
    static let formulaBackgroundNSColor = dynamicColor(
        light: 0xF0FAED,
        dark: 0x1B2A1E,
        lightHighContrast: 0xE4F6E1,
        darkHighContrast: 0x0F1A12
    )
    static let formulaAccentNSColor = dynamicColor(
        light: 0x297D38,
        dark: 0xBFF7C7,
        lightHighContrast: 0x174F22,
        darkHighContrast: 0xE4FFE7
    )
    static let errorBackgroundNSColor = dynamicColor(
        light: 0xFDEDED,
        dark: 0x351616,
        lightHighContrast: 0xF9DEDE,
        darkHighContrast: 0x250C0C
    )
    static let errorAccentNSColor = dynamicColor(
        light: 0xA61B1B,
        dark: 0xFFB4B4,
        lightHighContrast: 0x7A0D0D,
        darkHighContrast: 0xFFDCDC
    )
    static let staleBorderNSColor = dynamicColor(
        light: 0x9C5A00,
        dark: 0xFFC36B,
        lightHighContrast: 0x6F3F00,
        darkHighContrast: 0xFFE0AE
    )
    static let chromeBackgroundNSColor = dynamicColor(
        light: 0xF7F7F7,
        dark: 0x1A1A1A,
        lightHighContrast: 0xF2F2F2,
        darkHighContrast: 0x101010
    )
    static let invalidChromeBackgroundNSColor = dynamicColor(
        light: 0xFFF5F5,
        dark: 0x301717,
        lightHighContrast: 0xFDE9E9,
        darkHighContrast: 0x200C0C
    )

    static let formulaBackground = Color(nsColor: formulaBackgroundNSColor)
    static let formulaAccent = Color(nsColor: formulaAccentNSColor)
    static let errorBackground = Color(nsColor: errorBackgroundNSColor)
    static let errorAccent = Color(nsColor: errorAccentNSColor)
    static let staleBorder = Color(nsColor: staleBorderNSColor)
    static let chromeBackground = Color(nsColor: chromeBackgroundNSColor)
    static let invalidChromeBackground = Color(nsColor: invalidChromeBackgroundNSColor)
    static let noticeBorder = formulaAccent.opacity(0.35)

    static func formulaChipBackground(for span: FormulaSpan) -> Color {
        Color(nsColor: formulaChipBackgroundNSColor(for: span))
    }

    static func formulaChipForeground(for span: FormulaSpan) -> Color {
        Color(nsColor: formulaChipForegroundNSColor(for: span))
    }

    static func formulaChipBorder(for span: FormulaSpan) -> Color? {
        if span.isError {
            return errorAccent
        }
        if span.isStale {
            return staleBorder
        }
        return nil
    }

    static func formulaChipBackgroundNSColor(for span: FormulaSpan) -> NSColor {
        span.isError ? errorBackgroundNSColor : formulaBackgroundNSColor
    }

    static func formulaChipForegroundNSColor(for span: FormulaSpan) -> NSColor {
        span.isError ? errorAccentNSColor : formulaAccentNSColor
    }

    private static func dynamicColor(
        light: Int,
        dark: Int,
        lightHighContrast: Int,
        darkHighContrast: Int
    ) -> NSColor {
        NSColor(name: nil) { appearance in
            let useDark = isDark(appearance)
            let useHighContrast = NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast
            let hex: Int

            switch (useDark, useHighContrast) {
            case (false, false):
                hex = light
            case (false, true):
                hex = lightHighContrast
            case (true, false):
                hex = dark
            case (true, true):
                hex = darkHighContrast
            }

            return nsColor(hex: hex)
        }
    }

    private static func isDark(_ appearance: NSAppearance) -> Bool {
        let match = appearance.bestMatch(from: [.darkAqua, .vibrantDark, .aqua, .vibrantLight])
        return match == .darkAqua || match == .vibrantDark
    }

    private static func nsColor(hex: Int) -> NSColor {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        return NSColor(srgbRed: red, green: green, blue: blue, alpha: 1)
    }
}
