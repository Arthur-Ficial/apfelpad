import SwiftUI

struct DocumentView: View {
    @Bindable var vm: DocumentViewModel
    @Bindable var barVM: FormulaBarViewModel
    @State private var editing: Bool = false

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
                Button(editing ? "Render" : "Edit source") {
                    editing.toggle()
                }
            }
        }
        .frame(minWidth: 720, minHeight: 520)
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
            Text(InlineFormulaRenderer.render(vm.document))
                .font(.body)
                .lineSpacing(6)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
        }
    }
}
