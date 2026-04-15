import AppKit

protocol ClipboardReading: Sendable {
    func currentString() -> String?
}

struct SystemClipboard: ClipboardReading {
    func currentString() -> String? {
        NSPasteboard.general.string(forType: .string)
    }
}

enum ClipFormulaEvaluator {
    static func evaluate(clipboard: some ClipboardReading = SystemClipboard()) -> String {
        clipboard.currentString() ?? ""
    }
}
