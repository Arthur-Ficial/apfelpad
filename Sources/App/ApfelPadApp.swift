import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct ApfelPadApp: App {
    @State private var serverManager = ServerManager()
    @State private var documentVM: DocumentViewModel
    @State private var barVM = FormulaBarViewModel()
    @State private var settingsVM: SettingsViewModel
    private let cache: FormulaCache

    init() {
        let cache: FormulaCache
        if let sqlCache = try? SQLiteFormulaCache(path: SQLiteFormulaCache.defaultPath()) {
            cache = sqlCache
        } else {
            cache = InMemoryFallbackCache()
        }
        self.cache = cache
        let runtime = FormulaRuntime(cache: cache)
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
                DocumentView(vm: documentVM, barVM: barVM, settingsVM: settingsVM)
            }
            .task {
                // Start server in background — =apfel becomes available once ready
                Task {
                    let port = await serverManager.start()
                    if let port {
                        let llm = ApfelHTTPService(port: port)
                        let runtime = FormulaRuntime(cache: cache, llm: llm)
                        documentVM.replaceRuntime(runtime)
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

            CommandGroup(after: .newItem) {
                Button("Open…") {
                    openFile()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
        Settings {
            SettingsPanel(vm: settingsVM)
        }
    }

    private func loadWelcome() {
        try? documentVM.load(rawMarkdown: Self.welcomeDocument)
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

    static let welcomeDocument: String = """
    # Welcome to apfelpad

    A formula notepad for thinking. On-device AI as a first-class function.

    ## Arithmetic

    There are =math(365*24) hours in a year.
    That's =math(365*8) working hours.
    And =math((365-104-10)*8) hours after weekends and holidays.

    ## On-device AI

    Every `=apfel(...)` formula runs entirely on your Mac via Foundation
    Models. The prompt is visible. The output is reproducible via seed.
    The source travels with the file.

    =apfel("one sentence — why formulas beat chat for writing", 7)
    """
}

final actor InMemoryFallbackCache: FormulaCache {
    private var store: [String: String] = [:]
    func get(key: CacheKey) async throws -> String? { store[key.hash] }
    func set(key: CacheKey, value: String) async throws { store[key.hash] = value }
    func delete(key: CacheKey) async throws { store.removeValue(forKey: key.hash) }
}
