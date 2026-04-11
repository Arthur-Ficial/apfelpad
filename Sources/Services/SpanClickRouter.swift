import Foundation

/// Pure routing helper that maps a click on a rendered formula span
/// (exposed as an `apfelpad://span/<uuid>` link in the AttributedString)
/// back to the `FormulaSpan` model object.
///
/// Kept free of SwiftUI so it is trivially unit-testable.
enum SpanClickRouter {
    static let scheme = "apfelpad"
    static let spanHost = "span"

    static func handle(url: URL, in document: Document) -> FormulaSpan? {
        guard url.scheme == scheme, url.host == spanHost else { return nil }
        let uuidString = url.lastPathComponent
        guard !uuidString.isEmpty else { return nil }
        guard let uuid = UUID(uuidString: uuidString) else { return nil }
        return document.spans.first { $0.id == uuid }
    }
}
