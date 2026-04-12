import SwiftUI

/// A reactive input widget for a single =input span. Used as a drop-in
/// replacement for the pale-green span when the span's call is .input.
///
/// Typing triggers DocumentViewModel.setInputBinding(_:to:) which walks
/// every dependent span (@name refs) and re-evaluates them — the whole
/// reactive recomputation loop.
struct InputFieldView: View {
    let name: String
    let type: InputType
    @Binding var value: String

    private static let paleGreen = Color(red: 0.94, green: 0.98, blue: 0.93)
    private static let darkGreen = Color(red: 0.16, green: 0.49, blue: 0.22)

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(Self.darkGreen)
                .frame(width: 3)
            field
        }
        .background(Self.paleGreen)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .help("@\(name) — \(type.displayLabel) variable")
    }

    @ViewBuilder
    private var field: some View {
        switch type {
        case .text:
            TextField(name, text: $value)
                .textFieldStyle(.plain)
                .foregroundStyle(Self.darkGreen)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .frame(minWidth: 120)
        case .number:
            TextField(name, text: $value)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Self.darkGreen)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .frame(minWidth: 80)
        case .boolean:
            Toggle(isOn: Binding(
                get: { value == "true" || value == "1" || value == "yes" },
                set: { value = $0 ? "true" : "false" }
            )) { Text(name).font(.caption) }
            .toggleStyle(.switch)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
        case .date:
            TextField(name, text: $value)
                .textFieldStyle(.plain)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Self.darkGreen)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .frame(minWidth: 100)
        }
    }
}
