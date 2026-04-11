import SwiftUI
import UniformTypeIdentifiers

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
        .navigationTitle(vm.windowTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(editing ? "Render" : "Edit source") {
                    if editing { vm.flushPendingReparse() }
                    editing.toggle()
                }
            }
        }
        .frame(minWidth: 720, minHeight: 520)
        .onDrop(of: [UTType.fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
        }
        .environment(\.openURL, OpenURLAction { url in
            if let span = SpanClickRouter.handle(url: url, in: vm.document) {
                barVM.select(span)
                return .handled
            }
            return .systemAction
        })
    }

    private var editor: some View {
        TextEditor(text: Binding(
            get: { vm.rawText },
            set: { vm.textDidChange($0) }
        ))
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

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { data, _ in
            guard let data = data as? Data,
                  let path = URL(dataRepresentation: data, relativeTo: nil) else { return }
            let ext = path.pathExtension.lowercased()
            guard ["md", "markdown", "txt"].contains(ext) else { return }
            Task { @MainActor in
                try? await vm.open(from: path)
            }
        }
        return true
    }
}
