import Testing
import Foundation
@testable import apfelpad

/// Single Source of Truth generator: every formula in
/// `FormulaRegistry.all` is rendered into a bounded section in
/// `README.md` and `docs/formulas.md` between
/// `<!-- begin:formula-catalogue -->` and `<!-- end:formula-catalogue -->`
/// markers.
///
/// Run in **enforce mode** (default): asserts the bounded sections in
/// the source files match what FormulaRegistry would generate today.
/// Drift fails the test.
///
/// Run with `APFELPAD_REGENERATE=1 swift test --filter
/// FormulaCatalogueGeneratorTests` to **regenerate** the bounded sections
/// in place. Re-running the regenerator must produce no diff
/// (idempotency).
@Suite("Formula catalogue generator (SSOT)", .serialized)
struct FormulaCatalogueGeneratorTests {
    private static let repoRoot: URL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()

    private static let beginMarker = "<!-- begin:formula-catalogue -->"
    private static let endMarker = "<!-- end:formula-catalogue -->"

    @Test("README.md formula catalogue block matches FormulaRegistry")
    func readmeMatches() throws {
        try check(file: "README.md", generator: Self.generateReadmeBlock)
    }

    @Test("docs/formulas.md formula catalogue block matches FormulaRegistry")
    func docsMatches() throws {
        try check(file: "docs/formulas.md", generator: Self.generateDocsBlock)
    }

    @Test("regenerator is idempotent — running it twice produces no diff")
    func idempotent() throws {
        let block1 = Self.generateReadmeBlock()
        let block2 = Self.generateReadmeBlock()
        #expect(block1 == block2)
        let dblock1 = Self.generateDocsBlock()
        let dblock2 = Self.generateDocsBlock()
        #expect(dblock1 == dblock2)
    }

    // MARK: - Implementation

    private func check(file: String, generator: () -> String) throws {
        let url = Self.repoRoot.appendingPathComponent(file)
        let text = try String(contentsOf: url, encoding: .utf8)
        let generated = generator()
        let regenerate = ProcessInfo.processInfo.environment["APFELPAD_REGENERATE"] == "1"

        if regenerate {
            let updated = try Self.replaceBetween(
                in: text,
                begin: Self.beginMarker,
                end: Self.endMarker,
                with: generated
            )
            if updated != text {
                try updated.write(to: url, atomically: true, encoding: .utf8)
            }
            // Always succeed in regenerate mode.
            return
        }

        let current = try Self.extractBetween(
            in: text,
            begin: Self.beginMarker,
            end: Self.endMarker
        )
        #expect(current == generated, "drift in \(file) — run APFELPAD_REGENERATE=1 swift test --filter FormulaCatalogueGeneratorTests")
    }

    /// Read the content between begin/end markers (exclusive of the markers
    /// themselves). The bounding newlines surrounding the markers are also
    /// excluded.
    private static func extractBetween(in text: String, begin: String, end: String) throws -> String {
        guard let bRange = text.range(of: begin) else {
            throw GeneratorError.missingMarker(begin)
        }
        guard let eRange = text.range(of: end, range: bRange.upperBound..<text.endIndex) else {
            throw GeneratorError.missingMarker(end)
        }
        let raw = String(text[bRange.upperBound..<eRange.lowerBound])
        // Strip a single leading and trailing newline for stable comparison.
        var trimmed = raw
        if trimmed.hasPrefix("\n") { trimmed.removeFirst() }
        if trimmed.hasSuffix("\n") { trimmed.removeLast() }
        return trimmed
    }

    private static func replaceBetween(
        in text: String,
        begin: String,
        end: String,
        with replacement: String
    ) throws -> String {
        guard let bRange = text.range(of: begin) else {
            throw GeneratorError.missingMarker(begin)
        }
        guard let eRange = text.range(of: end, range: bRange.upperBound..<text.endIndex) else {
            throw GeneratorError.missingMarker(end)
        }
        let prefix = text[..<bRange.upperBound]
        let suffix = text[eRange.lowerBound...]
        return "\(prefix)\n\(replacement)\n\(suffix)"
    }

    enum GeneratorError: Swift.Error, CustomStringConvertible {
        case missingMarker(String)
        var description: String {
            switch self {
            case .missingMarker(let m): return "missing required marker: \(m)"
            }
        }
    }

    // MARK: - Generators

    /// Render the catalogue as a README-style table grouped by category.
    static func generateReadmeBlock() -> String {
        var out: [String] = []
        let grouped = Dictionary(grouping: FormulaRegistry.publicDefinitions, by: \.category)
        let categories = grouped.keys.sorted { $0.order < $1.order }
        for cat in categories {
            let defs = (grouped[cat] ?? [])
                .sorted { $0.displayName < $1.displayName }
            out.append("**\(cat.title)**")
            out.append("")
            out.append("| Formula | Live example | Result |")
            out.append("|---|---|---|")
            for d in defs {
                let example = d.example.replacingOccurrences(of: "|", with: "\\|")
                let result = d.exampleResult.replacingOccurrences(of: "|", with: "\\|")
                out.append("| `\(d.signature)` | `\(example)` | \(result) |")
            }
            out.append("")
        }
        return out.joined(separator: "\n").trimmingCharacters(in: .newlines)
    }

    /// Render the catalogue as a docs index linking each formula to its
    /// own anchored heading further down the file.
    static func generateDocsBlock() -> String {
        var out: [String] = ["Every formula apfelpad ships, generated from `FormulaRegistry.all`.", ""]
        let grouped = Dictionary(grouping: FormulaRegistry.publicDefinitions, by: \.category)
        let categories = grouped.keys.sorted { $0.order < $1.order }
        for cat in categories {
            let defs = (grouped[cat] ?? [])
                .sorted { $0.displayName < $1.displayName }
            out.append("### \(cat.title)")
            out.append("")
            for d in defs {
                out.append("- `\(d.signature)` — \(d.description)")
            }
            out.append("")
        }
        return out.joined(separator: "\n").trimmingCharacters(in: .newlines)
    }
}
