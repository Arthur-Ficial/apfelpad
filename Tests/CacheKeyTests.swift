import Testing
@testable import apfelpad

@Suite("CacheKey")
struct CacheKeyTests {
    @Test("same inputs → same key and same hash")
    func deterministic() {
        let a = CacheKey(formulaSource: "=math(1+1)", context: "", modelVersion: "none", seed: nil)
        let b = CacheKey(formulaSource: "=math(1+1)", context: "", modelVersion: "none", seed: nil)
        #expect(a == b)
        #expect(a.hash == b.hash)
    }

    @Test("different sources → different hashes")
    func differentSources() {
        let a = CacheKey(formulaSource: "=math(1+1)", context: "", modelVersion: "none", seed: nil)
        let b = CacheKey(formulaSource: "=math(2+2)", context: "", modelVersion: "none", seed: nil)
        #expect(a.hash != b.hash)
    }

    @Test("different seeds → different hashes")
    func differentSeeds() {
        let a = CacheKey(formulaSource: "=apfel(\"x\")", context: "c", modelVersion: "m", seed: 1)
        let b = CacheKey(formulaSource: "=apfel(\"x\")", context: "c", modelVersion: "m", seed: 2)
        #expect(a.hash != b.hash)
    }

    @Test("hash is 64-char hex (sha256)")
    func hashFormat() {
        let key = CacheKey(formulaSource: "x", context: "y", modelVersion: "z", seed: nil)
        #expect(key.hash.count == 64)
        #expect(key.hash.allSatisfy { $0.isHexDigit })
    }
}
