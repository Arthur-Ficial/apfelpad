import SwiftUI

struct FormulaSpanView: View {
    static let backgroundColour = Color(red: 0.94, green: 0.98, blue: 0.93)
    static let accentColour    = Color(red: 0.16, green: 0.49, blue: 0.22)

    let span: FormulaSpan

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Self.accentColour)
                .frame(width: 3)
            Text(span.displayText)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
        }
        .background(Self.backgroundColour)
        .overlay(borderOverlay)
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch span.value {
        case .stale:
            Rectangle().stroke(.orange, lineWidth: 1)
        case .error:
            Rectangle().stroke(.red, lineWidth: 1)
        default:
            EmptyView()
        }
    }
}
