import Testing
@testable import apfelpad

@Suite("Smoke", .serialized)
struct SmokeTests {
    @Test("package builds and tests run")
    func smoke() {
        #expect(1 + 1 == 2)
    }
}
