import Foundation

protocol UpdateChecking {
    @MainActor
    func fetchLatestRelease(currentVersion: String) async throws -> LatestReleaseInfo
}
