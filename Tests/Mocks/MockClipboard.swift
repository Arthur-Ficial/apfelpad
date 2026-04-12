@testable import apfelpad

struct MockClipboard: ClipboardReading {
    let value: String?
    func currentString() -> String? { value }
}
