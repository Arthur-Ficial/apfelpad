import Testing
@testable import apfelpad

@Suite("SettingsViewModel")
@MainActor
struct SettingsViewModelTests {
    @Test("newer remote version → updateAvailable")
    func newer() async {
        let vm = SettingsViewModel(
            currentVersion: "0.1.0",
            checker: MockUpdateChecker(result: .success(.init(version: "0.2.0")))
        )
        await vm.checkForUpdate()
        #expect(vm.updateState == .updateAvailable(latest: "0.2.0"))
    }

    @Test("equal version → upToDate")
    func equal() async {
        let vm = SettingsViewModel(
            currentVersion: "0.1.0",
            checker: MockUpdateChecker(result: .success(.init(version: "0.1.0")))
        )
        await vm.checkForUpdate()
        #expect(vm.updateState == .upToDate)
    }

    @Test("older remote version → upToDate")
    func older() async {
        let vm = SettingsViewModel(
            currentVersion: "0.3.0",
            checker: MockUpdateChecker(result: .success(.init(version: "0.1.0")))
        )
        await vm.checkForUpdate()
        #expect(vm.updateState == .upToDate)
    }

    @Test("network error → error state")
    func networkError() async {
        enum E: Error { case nope }
        let vm = SettingsViewModel(
            currentVersion: "0.1.0",
            checker: MockUpdateChecker(result: .failure(E.nope))
        )
        await vm.checkForUpdate()
        if case .error = vm.updateState {
            // pass
        } else {
            Issue.record("expected .error, got \(vm.updateState)")
        }
    }

    @Test("checkForUpdateIfEnabled respects disabled toggle")
    func disabled() async {
        let vm = SettingsViewModel(
            currentVersion: "0.1.0",
            checker: MockUpdateChecker(result: .success(.init(version: "99.0.0")))
        )
        vm.checkOnLaunch = false
        await vm.checkForUpdateIfEnabled()
        #expect(vm.updateState == .idle)
    }

    @Test("semver compare handles patch differences")
    func semverPatch() {
        #expect(SettingsViewModel.semverCompare("0.1.0", "0.1.1") == .orderedAscending)
        #expect(SettingsViewModel.semverCompare("0.1.1", "0.1.0") == .orderedDescending)
        #expect(SettingsViewModel.semverCompare("0.1.0", "0.1.0") == .orderedSame)
    }

    @Test("semver compare handles minor and major differences")
    func semverMinor() {
        #expect(SettingsViewModel.semverCompare("0.1.9", "0.2.0") == .orderedAscending)
        #expect(SettingsViewModel.semverCompare("0.9.9", "1.0.0") == .orderedAscending)
    }
}
