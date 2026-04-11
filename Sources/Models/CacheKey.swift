import Foundation
import CryptoKit

struct CacheKey: Equatable, Hashable {
    let formulaSource: String
    let context: String
    let modelVersion: String
    let seed: Int?

    var hash: String {
        var hasher = SHA256()
        hasher.update(data: Data(formulaSource.utf8))
        hasher.update(data: Data("\u{1e}".utf8))
        hasher.update(data: Data(context.utf8))
        hasher.update(data: Data("\u{1e}".utf8))
        hasher.update(data: Data(modelVersion.utf8))
        hasher.update(data: Data("\u{1e}".utf8))
        hasher.update(data: Data((seed.map(String.init) ?? "nil").utf8))
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }
}
