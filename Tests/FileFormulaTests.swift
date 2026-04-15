import Testing
import Foundation
@testable import apfelpad

@Suite("FileFormula", .serialized)
struct FileFormulaTests {
    @Test("parser recognises =file(path)")
    func parseFile() throws {
        let call = try FormulaParser.parse(#"=file("/tmp/test.txt")"#)
        #expect(call == .file(path: "/tmp/test.txt"))
    }

    @Test("parser auto-quotes bare path")
    func parseFileBare() throws {
        let call = try FormulaParser.parse("=file(/tmp/test.txt)")
        #expect(call == .file(path: "/tmp/test.txt"))
    }

    @Test("parser rejects =file with no args")
    func parseFileNoArgs() throws {
        #expect(throws: FormulaParser.Error.self) {
            try FormulaParser.parse("=file()")
        }
    }

    @Test("render =file(path)")
    func renderFile() {
        let rendered = FormulaParser.render(.file(path: "/tmp/test.txt"))
        #expect(rendered == #"=file("/tmp/test.txt")"#)
    }

    @Test("evaluator reads an existing file")
    func evaluateExistingFile() throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("apfelpad-test-\(UUID().uuidString).txt")
        try "hello from file".write(to: tmp, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: tmp) }

        let result = try FileFormulaEvaluator.evaluate(path: tmp.path)
        #expect(result == "hello from file")
    }

    @Test("evaluator errors on missing file")
    func evaluateMissingFile() {
        #expect(throws: FileFormulaEvaluator.Error.self) {
            try FileFormulaEvaluator.evaluate(path: "/tmp/nonexistent-apfelpad-test.txt")
        }
    }
}
