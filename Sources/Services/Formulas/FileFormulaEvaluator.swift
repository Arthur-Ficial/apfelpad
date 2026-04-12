import Foundation

enum FileFormulaEvaluator {
    enum Error: LocalizedError {
        case notFound(String)
        case notReadable(String)
        case tooLarge(String)

        var errorDescription: String? {
            switch self {
            case .notFound(let p): return "file not found: \(p)"
            case .notReadable(let p): return "file not readable as text: \(p)"
            case .tooLarge(let p): return "file too large (>1 MB): \(p)"
            }
        }
    }

    private static let maxBytes = 1_048_576

    static func evaluate(path: String) throws -> String {
        let expanded = NSString(string: path).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw Error.notFound(path)
        }
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        if let size = attrs[.size] as? Int, size > maxBytes {
            throw Error.tooLarge(path)
        }
        guard let data = FileManager.default.contents(atPath: url.path),
              let text = String(data: data, encoding: .utf8) else {
            throw Error.notReadable(path)
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
