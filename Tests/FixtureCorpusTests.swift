import Testing
import Foundation
@testable import apfelpad

/// Chaos-monkey corpus: every `.md` in `Tests/Fixtures/` has a sibling
/// `.expected.json` that describes what Document.discover + the math
/// evaluator should produce. The tests iterate the corpus so adding a
/// new fixture to the directory automatically extends the coverage.
@Suite("Fixture corpus")
struct FixtureCorpusTests {
    private struct Expected: Decodable {
        let description: String?
        let spans: [ExpectedSpan]?
        let spanCount: Int?

        struct ExpectedSpan: Decodable {
            let source: String
            let kind: String
            let expression: String?
            let prompt: String?
            let seed: Int?
            let renderedValue: String?
            let hasError: Bool?
        }
    }

    private static let fixturesDir: URL = {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Fixtures", isDirectory: true)
    }()

    private static func loadFixtures() throws -> [(name: String, markdown: String, expected: Expected)] {
        let fm = FileManager.default
        let contents = try fm.contentsOfDirectory(atPath: fixturesDir.path)
        let mds = contents.filter { $0.hasSuffix(".md") }.sorted()
        return try mds.map { mdName in
            let mdURL = fixturesDir.appendingPathComponent(mdName)
            let expectedName = mdName.replacingOccurrences(of: ".md", with: ".expected.json")
            let expectedURL = fixturesDir.appendingPathComponent(expectedName)
            let md = try String(contentsOf: mdURL, encoding: .utf8)
            let expectedData = try Data(contentsOf: expectedURL)
            let expected = try JSONDecoder().decode(Expected.self, from: expectedData)
            return (mdName, md, expected)
        }
    }

    @Test("every fixture discovers the expected spans")
    func everyFixtureMatches() async throws {
        let fixtures = try Self.loadFixtures()
        #expect(fixtures.count >= 15)

        let cache = InMemoryFormulaCache()
        let runtime = FormulaRuntime(cache: cache, modelVersion: "fixture")

        for fixture in fixtures {
            let doc: Document
            do {
                doc = try Document(rawMarkdown: fixture.markdown)
            } catch {
                Issue.record("\(fixture.name): Document init threw \(error)")
                continue
            }

            // Validate span count (either explicit, or derived from spans[])
            if let count = fixture.expected.spanCount {
                #expect(
                    doc.spans.count == count,
                    "\(fixture.name): expected \(count) spans, got \(doc.spans.count)"
                )
            }
            if let expectedSpans = fixture.expected.spans {
                #expect(
                    doc.spans.count == expectedSpans.count,
                    "\(fixture.name): expected \(expectedSpans.count) spans, got \(doc.spans.count) — sources: \(doc.spans.map { $0.source })"
                )
                // Sanity-check each span's source matches
                for (i, expected) in expectedSpans.enumerated() where i < doc.spans.count {
                    let actual = doc.spans[i]
                    #expect(
                        actual.source == expected.source,
                        "\(fixture.name) span \(i): source mismatch — got \(actual.source), expected \(expected.source)"
                    )
                    switch expected.kind {
                    case "math":
                        if case .math(let expression) = actual.call {
                            #expect(
                                expression == expected.expression,
                                "\(fixture.name) span \(i): math expression mismatch"
                            )
                        } else {
                            Issue.record("\(fixture.name) span \(i): expected .math, got \(actual.call)")
                        }
                    case "apfel":
                        if case .apfel(let prompt, let seed) = actual.call {
                            #expect(
                                prompt == expected.prompt,
                                "\(fixture.name) span \(i): apfel prompt mismatch — got \(prompt), expected \(expected.prompt ?? "nil")"
                            )
                            #expect(
                                seed == expected.seed,
                                "\(fixture.name) span \(i): apfel seed mismatch"
                            )
                        } else {
                            Issue.record("\(fixture.name) span \(i): expected .apfel, got \(actual.call)")
                        }
                    default:
                        Issue.record("\(fixture.name) span \(i): unknown kind \(expected.kind)")
                    }
                }

                // Evaluate every math span and compare against renderedValue
                for (i, expected) in expectedSpans.enumerated() where i < doc.spans.count {
                    guard expected.kind == "math" else { continue }
                    let actual = doc.spans[i]
                    let value = try await runtime.evaluate(
                        call: actual.call,
                        source: actual.source,
                        context: ""
                    )
                    if expected.hasError == true {
                        if case .error = value {} else {
                            Issue.record("\(fixture.name) span \(i): expected .error, got \(value)")
                        }
                    } else if let rendered = expected.renderedValue {
                        if case .ready(let text) = value {
                            #expect(
                                text == rendered,
                                "\(fixture.name) span \(i): rendered value mismatch — got \(text), expected \(rendered)"
                            )
                        } else {
                            Issue.record("\(fixture.name) span \(i): expected .ready(\(rendered)), got \(value)")
                        }
                    }
                }
            }
        }
    }
}
