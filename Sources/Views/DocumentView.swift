import SwiftUI

struct DocumentView: View {
    @Bindable var vm: DocumentViewModel
    @Bindable var barVM: FormulaBarViewModel
    @State private var editing: Bool = true

    var body: some View {
        VStack(spacing: 0) {
            FormulaBarView(vm: barVM)
            if editing {
                editor
            } else {
                renderedView
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(editing ? "Render" : "Edit") {
                    editing.toggle()
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    private var editor: some View {
        TextEditor(
            text: Binding(
                get: { vm.document.rawMarkdown },
                set: { newValue in
                    try? vm.load(rawMarkdown: newValue)
                    Task { await vm.evaluateAll() }
                }
            )
        )
        .font(.system(.body, design: .monospaced))
        .padding(16)
    }

    private var renderedView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(vm.document.spans) { span in
                    FormulaSpanView(span: span)
                }
                Text(vm.document.rawMarkdown)
                    .textSelection(.enabled)
                    .font(.body)
            }
            .padding(16)
        }
    }
}
