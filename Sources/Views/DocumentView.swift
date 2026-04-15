import SwiftUI
import UniformTypeIdentifiers

enum EditingMode: String, CaseIterable {
    case render = "Render"
    case source = "Source"
}

struct DocumentView: View {
    @Bindable var vm: DocumentViewModel
    @Bindable var barVM: FormulaBarViewModel
    @Bindable var catalogueVM: FormulaCatalogueSidebarViewModel
    var settingsVM: SettingsViewModel? = nil
    var onNew: (() -> Void)? = nil
    var onSave: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                FormulaBarView(vm: barVM)
                editorArea
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
            ToolbarItem(placement: .navigation) {
                Button {
                    onNew?()
                } label: {
                    Label("New", systemImage: "doc")
                }
                .help("New document (\u{2318}N)")
            }
            ToolbarItem(placement: .navigation) {
                Button {
                    onSave?()
                } label: {
                    Label("Save", systemImage: "square.and.arrow.down")
                }
                .help("Save (\u{2318}S)")
                .disabled(!vm.isDirty)
            }
            ToolbarItem(placement: .principal) {
                Picker("Mode", selection: Binding(
                    get: { vm.editingMode },
                    set: { vm.setEditingMode($0) }
                )) {
                    ForEach(EditingMode.allCases, id: \.self) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    catalogueVM.toggle()
                } label: {
                    Label("Formulas", systemImage: "function")
                }
                .help("Formula catalogue (\u{2318}\u{21E7}F)")
                .keyboardShortcut("f", modifiers: [.command, .shift])
            }
        }
        .frame(minWidth: 720, minHeight: 520)
        .onDrop(of: [UTType.fileURL], isTargeted: nil) { providers in
            handleDrop(providers)
        }
        .onAppear {
            barVM.onCommit = { [vm] id, newSource in
                vm.replaceSpanSource(id: id, with: newSource)
            }
            catalogueVM.onInsert = { [vm] source in
                vm.insertAtCursor(source)
            }
            vm.requestEditorFocus()
        }
    }

    @ViewBuilder
    private var editorArea: some View {
        switch vm.editingMode {
        case .render:
            renderEditor
        case .source:
            sourceEditor
        }
    }

    /// Render mode is the editable WYSIWYG-ish surface. It renders formulas as
    /// chips but keeps the raw markdown document as the only source of truth.
    private var renderEditor: some View {
        EditableMarkdownView(
            text: Binding(
                get: { vm.rawText },
                set: { vm.textDidChange($0) }
            ),
            document: vm.document,
            documentGeneration: vm.documentGeneration,
            mode: .render,
            focusToken: vm.editorFocusToken,
            focusedInputName: vm.focusedInputName,
            inputFocusToken: vm.inputFocusToken,
            inputValue: { vm.bindings.value(for: $0) },
            onInputChange: { vm.setInputBinding($0, to: $1) },
            onSelectionChange: { vm.setInsertionLocation($0) },
            onFormulaActivate: { span in
                vm.setInsertionLocation(span.range.upperBound)
                barVM.select(span)
            }
        )
    }

    /// Source mode shows the exact markdown bytes with formula source ranges
    /// highlighted, but shares the same editable text-view implementation.
    private var sourceEditor: some View {
        EditableMarkdownView(
            text: Binding(
                get: { vm.rawText },
                set: { vm.textDidChange($0) }
            ),
            document: vm.document,
            documentGeneration: vm.documentGeneration,
            mode: .source,
            focusToken: vm.editorFocusToken,
            focusedInputName: nil,
            inputFocusToken: 0,
            onSelectionChange: { vm.setInsertionLocation($0) }
        )
    }

    private var statusStrip: some View {
        HStack {
            Text("\(lineCount) lines \u{00B7} \(wordCount) words \u{00B7} \(vm.document.spans.count) formulas")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(vm.editingMode.rawValue)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(AppTheme.chromeBackground)
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
