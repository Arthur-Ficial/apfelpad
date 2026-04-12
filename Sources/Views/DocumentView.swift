import SwiftUI
import UniformTypeIdentifiers

enum EditingMode: String, CaseIterable {
    case markdown = "Markdown"
    case source = "Source"
}

struct DocumentView: View {
    @Bindable var vm: DocumentViewModel
    @Bindable var barVM: FormulaBarViewModel
    @Bindable var catalogueVM: FormulaCatalogueSidebarViewModel
    var settingsVM: SettingsViewModel? = nil
    @State private var mode: EditingMode = .markdown

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
            ToolbarItem(placement: .principal) {
                Picker("Mode", selection: $mode) {
                    ForEach(EditingMode.allCases, id: \.self) { m in
                        Text(m.rawValue).tag(m)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                .onChange(of: mode) { _, _ in
                    vm.flushPendingReparse()
                }
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
        .environment(\.openURL, OpenURLAction { url in
            if let span = SpanClickRouter.handle(url: url, in: vm.document) {
                barVM.select(span)
                return .handled
            }
            return .systemAction
        })
        .onAppear {
            barVM.onCommit = { [vm] id, newSource in
                vm.replaceSpanSource(id: id, with: newSource)
            }
            catalogueVM.onInsert = { [vm] source in
                vm.insertAtCursor(source)
            }
        }
    }

    @ViewBuilder
    private var editorArea: some View {
        switch mode {
        case .markdown:
            markdownEditor
        case .source:
            sourceEditor
        }
    }

    private var markdownEditor: some View {
        EditableMarkdownView(
            text: Binding(
                get: { vm.rawText },
                set: { vm.textDidChange($0) }
            ),
            document: vm.document
        )
        .dropDestination(for: String.self) { items, _ in
            for item in items { vm.insertAtCursor(item) }
            return !items.isEmpty
        }
    }

    private var sourceEditor: some View {
        TextEditor(text: Binding(
            get: { vm.rawText },
            set: { vm.textDidChange($0) }
        ))
        .font(.system(.body, design: .monospaced))
        .padding(16)
    }

    private var statusStrip: some View {
        HStack {
            Text("\(lineCount) lines \u{00B7} \(wordCount) words \u{00B7} \(vm.document.spans.count) formulas")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(mode.rawValue)
                .font(.caption)
                .foregroundStyle(.tertiary)
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
