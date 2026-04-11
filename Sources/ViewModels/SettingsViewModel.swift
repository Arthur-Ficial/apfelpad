import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    enum UpdateState: Equatable {
        case idle
        case checking
        case upToDate
        case updateAvailable(latest: String)
        case error(message: String)
    }

    let currentVersion: String
    var updateState: UpdateState = .idle
    var checkOnLaunch: Bool {
        didSet { UserDefaults.standard.set(checkOnLaunch, forKey: Self.checkOnLaunchKey) }
    }
    var showLineCount: Bool {
        didSet { UserDefaults.standard.set(showLineCount, forKey: Self.showLineCountKey) }
    }
    var sessionDismissedBanner: Bool = false

    private let checker: UpdateChecking
    private static let checkOnLaunchKey = "apfelpad_check_for_updates_on_launch"
    private static let showLineCountKey = "apfelpad_show_line_count"

    init(currentVersion: String, checker: UpdateChecking) {
        self.currentVersion = currentVersion
        self.checker = checker
        if UserDefaults.standard.object(forKey: Self.checkOnLaunchKey) == nil {
            self.checkOnLaunch = true
        } else {
            self.checkOnLaunch = UserDefaults.standard.bool(forKey: Self.checkOnLaunchKey)
        }
        if UserDefaults.standard.object(forKey: Self.showLineCountKey) == nil {
            self.showLineCount = false
        } else {
            self.showLineCount = UserDefaults.standard.bool(forKey: Self.showLineCountKey)
        }
    }

    func checkForUpdateIfEnabled() async {
        guard checkOnLaunch else { return }
        await checkForUpdate()
    }

    func checkForUpdate() async {
        updateState = .checking
        do {
            let latest = try await checker.fetchLatestRelease(currentVersion: currentVersion)
            switch Self.semverCompare(currentVersion, latest.version) {
            case .orderedAscending:
                updateState = .updateAvailable(latest: latest.version)
            case .orderedSame, .orderedDescending:
                updateState = .upToDate
            }
        } catch {
            updateState = .error(message: error.localizedDescription)
        }
    }

    /// Simple semver comparison: "0.1.0" < "0.1.1" < "0.2.0" < "1.0.0".
    /// Returns `.orderedSame` when the normalised numeric components match.
    static func semverCompare(_ a: String, _ b: String) -> ComparisonResult {
        let aParts = a.split(separator: ".").compactMap { Int($0) }
        let bParts = b.split(separator: ".").compactMap { Int($0) }
        let maxLen = max(aParts.count, bParts.count)
        for i in 0..<maxLen {
            let ai = i < aParts.count ? aParts[i] : 0
            let bi = i < bParts.count ? bParts[i] : 0
            if ai < bi { return .orderedAscending }
            if ai > bi { return .orderedDescending }
        }
        return .orderedSame
    }
}
