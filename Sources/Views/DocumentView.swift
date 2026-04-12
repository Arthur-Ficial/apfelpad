import SwiftUI
import UniformTypeIdentifiers

struct DocumentView: View {
    @Bindable var vm: DocumentViewModel
    @Bindable var barVM: FormulaBarViewModel
    @Bindable var catalogueVM: FormulaCatalogueSidebarViewModel
    var settingsVM: SettingsViewModel? = nil
    @State private var editing: Bool = false

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                FormulaBarView(vm: barVM)
                if editing {
                    editor
                } else {
                    renderedView
                }
                if settingsVM?.showLineCount == true {
                    statusStrip
                }
            }
            .frame(maxWidth: .infinity)
            if catalogueVM.isOpen {
                FormulaCatalogueSidebarView(vm: catalogueVM)
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeOut(duration: 0.18), value: catalogueVM.isOpen)
        .navigationTitle(vm.windowTitle)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(editing ? "Render" : "Edit source") {
                    if editing { vm.flushPendingReparse() }
                    editing.toggle()
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    catalogueVM.toggle()
                } label: {
                    Label("Formulas", systemImage: "function")
                }
                .help("Formula catalogue (⌘⇧F)")
                .keyboardShortcut("f", modifiers: [.command, .shift])
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
        .onAppear {
            // Wire the formula bar's commit callback to the document VM.
            barVM.onCommit = { [vm] id, newSource in
                vm.replaceSpanSource(id: id, with: newSource)
            }
            // Wire the catalogue sidebar's insert callback.
            catalogueVM.onInsert = { [vm] source in
                vm.insertAtCursor(source)
            }
        }
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
        .dropDestination(for: String.self) { items, _ in
            for item in items { vm.insertAtCursor(item) }
            return !items.isEmpty
        }
        .overlay(alignment: .bottomTrailing) {
            if !editing {
                Button {
                    editing = true
                } label: {
                    Label("Edit source", systemImage: "pencil")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.regularMaterial)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(16)
                .help("Edit the markdown source (⌘E)")
                .keyboardShortcut("e", modifiers: [.command])
            }
        }
    }

    private var statusStrip: some View {
        HStack {
            Text("\(lineCount) lines · \(wordCount) words · \(vm.document.spans.count) formulas")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color(white: 0.97))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.separator),
            alignment: .top
        )
    }

    private var lineCount: Int {
        max(1, vm.rawText.split(separator: "\n", omittingEmptySubsequences: false).count)
    }

    private var wordCount: Int {
        vm.rawText.split { $0.isWhitespace }.count
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
