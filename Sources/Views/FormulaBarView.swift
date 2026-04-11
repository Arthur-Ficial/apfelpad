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
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(Color(white: 0.97))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.separator),
            alignment: .bottom
        )
    }
}
