import SwiftUI

/// A reactive input widget for a single =input span. Drop-in replacement
/// for the pale-green span when the span's call is .input.
///
/// Typing triggers DocumentViewModel.setInputBinding(_:to:) which walks
/// every dependent span (@name refs) and re-evaluates them.
struct InputFieldView: View {
    let name: String
    let type: InputType
    @Binding var value: String

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.formulaAccent)
                .frame(width: 3)
            field
        }
        .background(AppTheme.formulaBackground)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .help("@\(name) — \(type.displayLabel) variable")
    }

    @ViewBuilder
    private var field: some View {
        switch type {
        case .text, .search:
            plainTextField(monospaced: false, minWidth: 120)
        case .email:
            plainTextField(monospaced: false, minWidth: 180)
                .textContentType(.emailAddress)
        case .url:
            plainTextField(monospaced: false, minWidth: 180)
                .textContentType(.URL)
        case .tel:
            plainTextField(monospaced: true, minWidth: 140)
                .textContentType(.telephoneNumber)
        case .password:
            SecureField(name, text: $value)
                .textFieldStyle(.plain)
                .foregroundStyle(AppTheme.formulaAccent)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .frame(minWidth: 140)
        case .textarea:
            TextEditor(text: $value)
                .font(.body)
                .foregroundStyle(AppTheme.formulaAccent)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 4)
                .padding(.vertical, 3)
                .frame(minWidth: 240, minHeight: 60, maxHeight: 160)
        case .number:
            plainTextField(monospaced: true, minWidth: 80)
        case .percent:
            HStack(spacing: 4) {
                plainTextField(monospaced: true, minWidth: 60)
                Text("%").foregroundStyle(AppTheme.formulaAccent).padding(.trailing, 6)
            }
        case .range:
            rangeSlider
        case .boolean, .toggle:
            Toggle(isOn: Binding(
                get: { value == "true" || value == "1" || value == "yes" },
                set: { value = $0 ? "true" : "false" }
            )) { Text(name).font(.caption) }
            .toggleStyle(.switch)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
        case .date:
            datePicker(components: .date, widthHint: 120)
        case .time:
            datePicker(components: .hourAndMinute, widthHint: 100)
        case .datetime:
            datePicker(components: [.date, .hourAndMinute], widthHint: 180)
        case .color:
            colorPicker
        }
    }

    // MARK: - Helpers

    private func plainTextField(monospaced: Bool, minWidth: CGFloat) -> some View {
        let tf = TextField(name, text: $value)
            .textFieldStyle(.plain)
            .foregroundStyle(AppTheme.formulaAccent)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .frame(minWidth: minWidth)
        if monospaced {
            return AnyView(tf.font(.system(.body, design: .monospaced)))
        }
        return AnyView(tf)
    }

    private var rangeSlider: some View {
        HStack(spacing: 8) {
            Slider(
                value: Binding(
                    get: { Double(value) ?? 0 },
                    set: { value = String(Int($0)) }
                ),
                in: 0...100
            )
            .frame(minWidth: 160)
            Text(value.isEmpty ? "0" : value)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(AppTheme.formulaAccent)
                .frame(minWidth: 30, alignment: .trailing)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
    }

    private func datePicker(components: DatePicker.Components, widthHint: CGFloat) -> some View {
        DatePicker(
            "",
            selection: Binding(
                get: { InputFieldView.parseDate(value) ?? Date() },
                set: { value = InputFieldView.formatDate($0, components: components) }
            ),
            displayedComponents: components
        )
        .labelsHidden()
        .foregroundStyle(AppTheme.formulaAccent)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .frame(minWidth: widthHint)
    }

    private var colorPicker: some View {
        ColorPicker(
            "",
            selection: Binding(
                get: { InputFieldView.parseColor(value) },
                set: { value = InputFieldView.formatColor($0) }
            ),
            supportsOpacity: false
        )
        .labelsHidden()
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
    }

    // MARK: - Date / color serialization

    private static let isoDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let isoDateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm"
        return f
    }()

    static func parseDate(_ s: String) -> Date? {
        if let d = isoDateTimeFormatter.date(from: s) { return d }
        if let d = isoDateFormatter.date(from: s) { return d }
        if let d = timeFormatter.date(from: s) { return d }
        return nil
    }

    static func formatDate(_ d: Date, components: DatePicker.Components) -> String {
        if components.contains(.date) && components.contains(.hourAndMinute) {
            return isoDateTimeFormatter.string(from: d)
        } else if components.contains(.date) {
            return isoDateFormatter.string(from: d)
        } else {
            return timeFormatter.string(from: d)
        }
    }

    static func parseColor(_ s: String) -> Color {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("#"), trimmed.count == 7 else {
            return AppTheme.formulaBackground
        }
        let hex = String(trimmed.dropFirst())
        var value: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&value)
        let r = Double((value >> 16) & 0xff) / 255
        let g = Double((value >> 8) & 0xff) / 255
        let b = Double(value & 0xff) / 255
        return Color(red: r, green: g, blue: b)
    }

    static func formatColor(_ c: Color) -> String {
        let ns = NSColor(c).usingColorSpace(.sRGB) ?? NSColor.black
        let r = Int((ns.redComponent * 255).rounded())
        let g = Int((ns.greenComponent * 255).rounded())
        let b = Int((ns.blueComponent * 255).rounded())
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}
