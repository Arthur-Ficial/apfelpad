import Testing
@testable import apfelpad

@Suite("UpdateChecker")
@MainActor
struct UpdateCheckerTests {
    @Test("mock returns configured version")
    func mockWorks() async throws {
        let mock = MockUpdateChecker(result: .success(LatestReleaseInfo(version: "9.9.9")))
        let info = try await mock.fetchLatestRelease(currentVersion: "0.1.0")
        #expect(info.version == "9.9.9")
    }

    @Test("strips leading v from tag name")
    func stripV() {
        #expect(GitHubReleaseUpdateChecker.normaliseTag("v1.2.3") == "1.2.3")
        #expect(GitHubReleaseUpdateChecker.normaliseTag("1.2.3") == "1.2.3")
        #expect(GitHubReleaseUpdateChecker.normaliseTag("v0.1.0") == "0.1.0")
    }
}
