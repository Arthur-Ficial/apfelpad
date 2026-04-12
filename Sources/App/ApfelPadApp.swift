import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct ApfelPadApp: App {
    @State private var serverManager = ServerManager()
    @State private var documentVM: DocumentViewModel
    @State private var barVM = FormulaBarViewModel()
    @State private var catalogueVM = FormulaCatalogueSidebarViewModel()
    @State private var settingsVM: SettingsViewModel
    private let cache: FormulaCache

    init() {
        do {
            self.cache = try SQLiteFormulaCache(path: SQLiteFormulaCache.defaultPath())
        } catch {
            fatalError("SQLite cache init failed: \(error)")
        }
        let runtime = FormulaRuntime(
            cache: cache,
            llm: Self.shouldUseStubLLM ? DeterministicStubLLMService() : nil
        )
        _documentVM = State(initialValue: DocumentViewModel(runtime: runtime))

        let checker = GitHubReleaseUpdateChecker()
        _settingsVM = State(
            initialValue: SettingsViewModel(
                currentVersion: Self.readVersion(),
                checker: checker
            )
        )
    }

    var body: some Scene {
        WindowGroup("apfelpad") {
            VStack(spacing: 0) {
                UpdateBanner(vm: settingsVM)
                DocumentView(vm: documentVM, barVM: barVM, catalogueVM: catalogueVM, settingsVM: settingsVM)
            }
            .task {
                // Start server in background — =apfel becomes available once ready
                if !Self.shouldUseStubLLM, !Self.shouldSkipServer {
                    Task {
                        let port = await serverManager.start()
                        if let port {
                            let llm = ApfelHTTPService(port: port)
                            let runtime = FormulaRuntime(cache: cache, llm: llm)
                            documentVM.replaceRuntime(runtime)
                        }
                    }
                }

                // Check for updates in background
                Task { await settingsVM.checkForUpdateIfEnabled() }

                // Load content immediately — math formulas work without server
                if CommandLine.arguments.count > 1 {
                    let path = CommandLine.arguments[1]
                    let url = URL(fileURLWithPath: path)
                    if FileManager.default.fileExists(atPath: url.path) {
                        try? await documentVM.open(from: url)
                    } else {
                        loadWelcome()
                    }
                } else {
                    loadWelcome()
                }

                documentVM.startAutosave()
            }
            .onOpenURL { url in
                Task { try? await documentVM.open(from: url) }
            }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New") {
                    documentVM.newDocument()
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("Open…") {
                    openFile()
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandGroup(replacing: .saveItem) {
                Button("Save") {
                    Task {
                        if documentVM.fileURL != nil {
                            try? await documentVM.save()
                        } else {
                            saveAs()
                        }
                    }
                }
                .keyboardShortcut("s", modifiers: .command)

                Button("Save As…") {
                    saveAs()
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }

            CommandMenu("View") {
                Button("Render Mode") {
                    documentVM.setEditingMode(.render)
                }
                .keyboardShortcut("1", modifiers: .command)

                Button("Source Mode") {
                    documentVM.setEditingMode(.source)
                }
                .keyboardShortcut("2", modifiers: .command)

                Divider()

                Button("Focus Editor") {
                    documentVM.requestEditorFocus()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])

                Divider()

                Button("Focus First Input") {
                    documentVM.focusFirstInput()
                }
                .keyboardShortcut("i", modifiers: [.command, .option])

                Button("Focus Next Input") {
                    documentVM.focusNextInput()
                }
                .keyboardShortcut("]", modifiers: [.command, .option])

                Button("Focus Previous Input") {
                    documentVM.focusPreviousInput()
                }
                .keyboardShortcut("[", modifiers: [.command, .option])
            }
        }
        Settings {
            SettingsPanel(vm: settingsVM)
        }
    }

    private func loadWelcome() {
        try? documentVM.load(rawMarkdown: WelcomeWorkbook.document())
        Task { await documentVM.evaluateAll() }
    }

    private func saveAs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.plainText]
        panel.allowsOtherFileTypes = true
        panel.nameFieldStringValue = documentVM.fileURL?.lastPathComponent ?? "Untitled.md"
        if panel.runModal() == .OK, let url = panel.url {
            Task { try? await documentVM.save(to: url) }
        }
    }

    private func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType.plainText]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            Task { try? await documentVM.open(from: url) }
        }
    }

    static func readVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }

    static var shouldUseStubLLM: Bool {
        ProcessInfo.processInfo.environment["APFELPAD_USE_STUB_LLM"] == "1"
    }

    static var shouldSkipServer: Bool {
        ProcessInfo.processInfo.environment["APFELPAD_SKIP_SERVER"] == "1"
    }
}
