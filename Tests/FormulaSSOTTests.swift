import Testing
import Foundation
@testable import apfelpad

/// Single Source of Truth test: every formula name mentioned in README.md,
/// docs/formulas.md, and site/index.html must exist in FormulaCatalogue.
/// This prevents documentation / landing-page drift — if a doc mentions
/// `=foo` that isn't in the catalogue, the test fails.
@Suite("Formula SSOT — catalogue is authoritative", .serialized)
struct FormulaSSOTTests {
    private static let repoRoot: URL = {
        // Resolve the project root by walking up from the current test file.
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // Tests/
            .deletingLastPathComponent()   // repo root
    }()

    /// Regex for `=name(` in markdown / HTML. Captures the name part.
    private static let formulaPattern = "=([a-z]+)\\("

    /// Scan a file for every =name( mention and return the set of unique
    /// formula names found. Ignores names that are clearly placeholders
    /// (e.g. `=name` used as a template variable).
    private static func formulaNames(in fileURL: URL) throws -> Set<String> {
        let text = try String(contentsOf: fileURL, encoding: .utf8)
        let regex = try NSRegularExpression(pattern: formulaPattern)
        let ns = text as NSString
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
        var out: Set<String> = []
        for m in matches {
            guard m.numberOfRanges >= 2 else { continue }
            let name = ns.substring(with: m.range(at: 1))
            out.insert("=\(name)")
        }
        return out
    }

    /// Names we explicitly allow in docs/landing even though they're not
    /// (yet) in the live catalogue — reserved namespaces or future work.
    private static let reserved: Set<String> = [
        "=http",     // v2.0 speculation in BRIEFING
        "=name",     // template placeholder in examples
        "=nosuch",   // test example
    ]

    @Test("README.md only references formulas that exist in the catalogue")
    func readmeMatchesCatalogue() throws {
        let url = Self.repoRoot.appendingPathComponent("README.md")
        let found = try Self.formulaNames(in: url)
        let known = FormulaRegistry.publicNames.union(Self.reserved)
        let unknown = found.subtracting(known)
        if !unknown.isEmpty {
            Issue.record("README.md references unknown formulas: \(unknown.sorted())")
        }
    }

    @Test("docs/formulas.md only references formulas that exist in the catalogue")
    func docsMatchesCatalogue() throws {
        let url = Self.repoRoot.appendingPathComponent("docs/formulas.md")
        let found = try Self.formulaNames(in: url)
        let known = FormulaRegistry.publicNames.union(Self.reserved)
        let unknown = found.subtracting(known)
        if !unknown.isEmpty {
            Issue.record("docs/formulas.md references unknown formulas: \(unknown.sorted())")
        }
    }

    @Test("site/index.html only references formulas that exist in the catalogue")
    func siteMatchesCatalogue() throws {
        let url = Self.repoRoot.appendingPathComponent("site/index.html")
        let found = try Self.formulaNames(in: url)
        let known = FormulaRegistry.publicNames.union(Self.reserved)
        let unknown = found.subtracting(known)
        if !unknown.isEmpty {
            Issue.record("site/index.html references unknown formulas: \(unknown.sorted())")
        }
    }

    @Test("every catalogue formula is mentioned somewhere in public-facing docs")
    func everyCatalogueFormulaDocumented() throws {
        let readme = try Self.formulaNames(in: Self.repoRoot.appendingPathComponent("README.md"))
        let docs = try Self.formulaNames(in: Self.repoRoot.appendingPathComponent("docs/formulas.md"))
        let site = try Self.formulaNames(in: Self.repoRoot.appendingPathComponent("site/index.html"))
        let mentioned = readme.union(docs).union(site)
        let catalogue = Set(FormulaCatalogue.all.map(\.name))
        // =() is the anonymous shortcut — it doesn't parse as =name( so
        // the regex can't match it. Accept it as documented if the string
        // "=(" or "=()" appears in any doc.
        let documentsRaw = try [
            String(contentsOf: Self.repoRoot.appendingPathComponent("README.md"), encoding: .utf8),
            String(contentsOf: Self.repoRoot.appendingPathComponent("docs/formulas.md"), encoding: .utf8),
            String(contentsOf: Self.repoRoot.appendingPathComponent("site/index.html"), encoding: .utf8),
        ].joined()
        var effectivelyMentioned = mentioned
        if documentsRaw.contains("=()") || documentsRaw.contains("=(") {
            effectivelyMentioned.insert("=()")
        }
        let missing = catalogue.subtracting(effectivelyMentioned)
        if !missing.isEmpty {
            Issue.record("catalogue formulas missing from public docs: \(missing.sorted())")
        }
    }
}
