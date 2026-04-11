import SwiftUI

struct FormulaBarView: View {
    @Bindable var vm: FormulaBarViewModel

    var body: some View {
        HStack(spacing: 6) {
            Text("ƒ")
                .font(.system(.body, design: .serif))
                .foregroundStyle(.secondary)
                .padding(.leading, 8)
            TextField(vm.placeholder, text: $vm.sourceText)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .monospaced))
                .onSubmit { vm.commitNow() }
            stateBadge
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(background)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.separator),
            alignment: .bottom
        )
    }

    @ViewBuilder
    private var stateBadge: some View {
        switch vm.editState {
        case .idle:
            EmptyView()
        case .valid:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(red: 0.16, green: 0.49, blue: 0.22))
                .help("Formula applied")
        case .invalid(let message):
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .help(message)
        }
    }

    private var background: Color {
        switch vm.editState {
        case .invalid: return Color(red: 1.0, green: 0.96, blue: 0.96)
        default: return Color(white: 0.97)
        }
    }
}
