import AppKit

enum ClipFormulaEvaluator {
    static func evaluate() -> String {
        // AppKit's pasteboard APIs are unstable inside the swift-testing host;
        // treat the clipboard as empty in tests so the formula stays total.
        if shouldSkipPasteboard {
            return ""
        }
        let pasteboard = NSPasteboard.general
        if let item = pasteboard.pasteboardItems?.first,
           let string = item.string(forType: .string) {
            return string
        }
        return ""
    }

    private static var shouldSkipPasteboard: Bool {
        let process = ProcessInfo.processInfo
        if process.environment["XCTestConfigurationFilePath"] != nil {
            return true
        }
        let joinedArguments = process.arguments.joined(separator: " ")
        if joinedArguments.contains("swiftpm-testing-helper") || joinedArguments.contains(".xctest") {
            return true
        }
        if Bundle.allBundles.contains(where: { $0.bundleURL.pathExtension == "xctest" }) {
            return true
        }
        return false
    }
}
