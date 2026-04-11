import Testing
@testable import apfelpad

@Suite("ServerManager")
struct ServerManagerTests {
    @Test("buildArguments uses the supplied port and --cors")
    func buildArgs() {
        let args = ServerManager.buildArguments(port: 11450)
        #expect(args.contains("--serve"))
        #expect(args.contains("--port"))
        #expect(args.contains("11450"))
        #expect(args.contains("--cors"))
    }

    @Test("findAvailablePort returns a port in apfelpad's range")
    func portRange() {
        let port = ServerManager.findAvailablePort(startingAt: 11450)
        #expect((11450...11459).contains(port))
    }

    @Test("isPortAvailable does not crash on a high random port")
    func portAvailable() {
        _ = ServerManager.isPortAvailable(49512)
    }
}
