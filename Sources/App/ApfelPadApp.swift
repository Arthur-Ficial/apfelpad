import SwiftUI

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
        let runtime = FormulaRuntime(cache: cache)  // no LLM yet — swapped in once server is up
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
                DocumentView(vm: documentVM, barVM: barVM)
            }
            .task {
                let port = await serverManager.start()
                if let port {
                    let llm = ApfelHTTPService(port: port)
                    let runtime = FormulaRuntime(cache: cache, llm: llm)
                    documentVM.replaceRuntime(runtime)
                }
                await settingsVM.checkForUpdateIfEnabled()
                try? documentVM.load(rawMarkdown: Self.welcomeDocument)
                await documentVM.evaluateAll()
            }
        }
        Settings {
            SettingsPanel(vm: settingsVM)
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

    Every =apfel(...) formula runs entirely on your Mac via Foundation
    Models. The prompt is visible. The output is reproducible via seed.
    The source travels with the file.

    =apfel("write a warm two-sentence welcome for a new apfelpad user", 7)
    """
}

/// Fallback used if SQLite open fails at startup.
final actor InMemoryFallbackCache: FormulaCache {
    private var store: [String: String] = [:]
    func get(key: CacheKey) async throws -> String? { store[key.hash] }
    func set(key: CacheKey, value: String) async throws { store[key.hash] = value }
    func delete(key: CacheKey) async throws { store.removeValue(forKey: key.hash) }
}
