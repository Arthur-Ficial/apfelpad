import Testing
import Foundation
import AppKit
@testable import apfelpad

/// Issue #21: per-example thumbnails replace the SF Symbol with a tiny
/// rendered preview of the first 2 lines of each example. Cached to disk
/// so scroll stays smooth.
@Suite("Example thumbnails", .serialized)
@MainActor
struct ExampleThumbnailGeneratorTests {
    private func tmpCacheDir() -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("apfelpad-thumbnail-tests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func cleanup(_ dir: URL) {
        try? FileManager.default.removeItem(at: dir)
    }

    private func sampleExample() -> ExampleDocument {
        ExampleDocument(
            title: "Quick test",
            blurb: "A short example.",
            icon: "doc",
            category: .calculator,
            body: "# Hello\n\nThis is the first prose line of the example body."
        )
    }

    @Test("generate returns an NSImage at the requested size")
    func generateReturnsImage() {
        let dir = tmpCacheDir()
        defer { cleanup(dir) }
        let gen = ExampleThumbnailGenerator(cacheDir: dir, version: "0.6.0")

        let image = gen.thumbnail(for: sampleExample(), size: NSSize(width: 60, height: 40))

        #expect(image.size.width == 60)
        #expect(image.size.height == 40)
    }

    @Test("generate caches to disk — second call hits the cache file")
    func diskCacheRoundTrip() {
        let dir = tmpCacheDir()
        defer { cleanup(dir) }
        let gen1 = ExampleThumbnailGenerator(cacheDir: dir, version: "0.6.0")
        _ = gen1.thumbnail(for: sampleExample(), size: NSSize(width: 60, height: 40))

        // A new generator instance starts with no in-memory state — if the
        // cache file is on disk and named correctly, it should be served
        // from there without re-rendering.
        let gen2 = ExampleThumbnailGenerator(cacheDir: dir, version: "0.6.0")
        #expect(gen2.hasCachedFile(for: sampleExample(), size: NSSize(width: 60, height: 40)))
    }

    @Test("version bump invalidates the cache key")
    func versionBumpInvalidates() {
        let dir = tmpCacheDir()
        defer { cleanup(dir) }
        let gen060 = ExampleThumbnailGenerator(cacheDir: dir, version: "0.6.0")
        _ = gen060.thumbnail(for: sampleExample(), size: NSSize(width: 60, height: 40))
        let gen061 = ExampleThumbnailGenerator(cacheDir: dir, version: "0.6.1")
        // Different version → different cache key → not yet cached.
        #expect(!gen061.hasCachedFile(for: sampleExample(), size: NSSize(width: 60, height: 40)))
    }

    @Test("two generators with the same version produce the same cache key")
    func cacheKeyStability() {
        let dir = tmpCacheDir()
        defer { cleanup(dir) }
        let gen1 = ExampleThumbnailGenerator(cacheDir: dir, version: "0.6.0")
        let gen2 = ExampleThumbnailGenerator(cacheDir: dir, version: "0.6.0")
        let example = sampleExample()
        let size = NSSize(width: 60, height: 40)
        let k1 = gen1.cacheKey(for: example, size: size)
        let k2 = gen2.cacheKey(for: example, size: size)
        #expect(k1 == k2)
    }
}
