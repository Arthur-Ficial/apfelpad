import AppKit
import Foundation

/// Issue #21: renders a small thumbnail per example, replacing the SF
/// Symbol leading visual in the examples sidebar with a tiny preview of
/// the first lines of the example body.
///
/// - Thumbnails are cached to disk under `cacheDir/<key>.png` so scroll
///   stays smooth (no synchronous render in cell).
/// - The cache key includes the app version so a release bump
///   invalidates stale renders.
@MainActor
final class ExampleThumbnailGenerator {
    let cacheDir: URL
    let version: String

    /// In-memory cache hit avoids hitting the filesystem on every redraw.
    private var memoryCache: [String: NSImage] = [:]

    init(cacheDir: URL, version: String) {
        self.cacheDir = cacheDir
        self.version = version
        try? FileManager.default.createDirectory(
            at: cacheDir,
            withIntermediateDirectories: true
        )
    }

    /// Stable key string for an example + size + version triple.
    func cacheKey(for example: ExampleDocument, size: NSSize) -> String {
        // Use a SHA-256-style content hash over title+body so editing the
        // example body without bumping its identifier still invalidates
        // the cache.
        let body = example.body
        let title = example.title
        let dim = "\(Int(size.width))x\(Int(size.height))"
        let combined = "\(version)|\(dim)|\(title)|\(body)".data(using: .utf8) ?? Data()
        return Self.shortHash(combined)
    }

    func cacheFileURL(for example: ExampleDocument, size: NSSize) -> URL {
        cacheDir.appendingPathComponent("thumb-\(cacheKey(for: example, size: size)).png")
    }

    func hasCachedFile(for example: ExampleDocument, size: NSSize) -> Bool {
        FileManager.default.fileExists(atPath: cacheFileURL(for: example, size: size).path)
    }

    /// Get a thumbnail. Loads from in-memory cache, then disk, then
    /// renders fresh and writes to disk.
    func thumbnail(for example: ExampleDocument, size: NSSize) -> NSImage {
        let key = cacheKey(for: example, size: size)
        if let cached = memoryCache[key] {
            return cached
        }
        let url = cacheFileURL(for: example, size: size)
        if let disk = NSImage(contentsOf: url) {
            disk.size = size
            memoryCache[key] = disk
            return disk
        }
        let rendered = renderImage(for: example, size: size)
        memoryCache[key] = rendered
        // Best-effort persist; ignore write errors (just re-render later).
        if let png = pngData(from: rendered) {
            try? png.write(to: url)
        }
        return rendered
    }

    // MARK: - Internals

    private func renderImage(for example: ExampleDocument, size: NSSize) -> NSImage {
        let firstTwoLines = Self.firstNNonBlankLines(of: example.body, n: 2)
        let attr = NSAttributedString(
            string: firstTwoLines,
            attributes: [
                .font: NSFont.systemFont(ofSize: 5.5, weight: .regular),
                .foregroundColor: NSColor.labelColor,
            ]
        )

        let image = NSImage(size: size)
        image.lockFocus()
        defer { image.unlockFocus() }
        NSColor.controlBackgroundColor.setFill()
        NSBezierPath(roundedRect: NSRect(origin: .zero, size: size),
                     xRadius: 3, yRadius: 3).fill()
        let inset = NSRect(x: 3, y: 3, width: size.width - 6, height: size.height - 6)
        attr.draw(in: inset)
        return image
    }

    private func pngData(from image: NSImage) -> Data? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff) else { return nil }
        return rep.representation(using: .png, properties: [:])
    }

    private static func firstNNonBlankLines(of body: String, n: Int) -> String {
        var picked: [String] = []
        for raw in body.split(separator: "\n") {
            let line = String(raw).trimmingCharacters(in: .whitespaces)
            if line.isEmpty { continue }
            // Strip leading markdown header markers so the preview reads
            // as content, not as a sequence of #'s.
            let stripped = line.drop { $0 == "#" }.drop { $0 == " " }
            picked.append(String(stripped))
            if picked.count >= n { break }
        }
        return picked.joined(separator: "\n")
    }

    /// Short hash of `data`. Uses CryptoKit when available, falls back to
    /// a simple djb2 if not — used only for cache key uniqueness, not
    /// security.
    private static func shortHash(_ data: Data) -> String {
        var hash: UInt64 = 5381
        for byte in data {
            hash = ((hash << 5) &+ hash) &+ UInt64(byte)
        }
        return String(hash, radix: 36)
    }
}
