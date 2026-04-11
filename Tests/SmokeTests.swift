import Testing
@testable import apfelpad

@Suite("Smoke")
struct SmokeTests {
    @Test("package builds and tests run")
    func smoke() {
        #expect(1 + 1 == 2)
    }
}
