import SwiftUI

struct FormulaSpanView: View {
    static let backgroundColour = AppTheme.formulaBackground
    static let accentColour = AppTheme.formulaAccent

    let span: FormulaSpan

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.formulaChipForeground(for: span))
                .frame(width: 3)
            Text(span.displayText)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
        }
        .background(AppTheme.formulaChipBackground(for: span))
        .overlay(borderOverlay)
    }

    @ViewBuilder
    private var borderOverlay: some View {
        if let border = AppTheme.formulaChipBorder(for: span) {
            Rectangle().stroke(border, lineWidth: 1)
        }
    }
}
