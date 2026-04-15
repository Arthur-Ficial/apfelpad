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
                .foregroundStyle(AppTheme.formulaAccent)
                .help("Formula applied")
        case .invalid(let message):
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.errorAccent)
                .help(message)
        }
    }

    private var background: Color {
        switch vm.editState {
        case .invalid: return AppTheme.invalidChromeBackground
        default: return AppTheme.chromeBackground
        }
    }
}
