import AppKit

enum ClipFormulaEvaluator {
    static func evaluate() -> String {
        NSPasteboard.general.string(forType: .string) ?? ""
    }
}
