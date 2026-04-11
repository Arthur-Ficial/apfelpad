import Foundation
@testable import apfelpad

struct MockUpdateChecker: UpdateChecking {
    let result: Result<LatestReleaseInfo, Error>

    @MainActor
    func fetchLatestRelease(currentVersion: String) async throws -> LatestReleaseInfo {
        try result.get()
    }
}
