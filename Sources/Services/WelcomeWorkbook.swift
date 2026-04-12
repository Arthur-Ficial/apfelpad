import Foundation

enum WelcomeWorkbook {
    static let sampleFilePlaceholder = "__WELCOME_SAMPLE_FILE__"

    /// Safe accessor for the SwiftPM resource bundle.
    /// - In SPM test/debug builds: `Bundle.module` works (has hardcoded path).
    /// - In production .app: resource bundle must be in Contents/Resources/.
    /// - If missing in production: returns nil (fallback welcome text).
    static let resourceBundle: Bundle? = {
        let bundleName = "apfelpad_apfelpad"

        // Production: look inside the app bundle.
        let appPath = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Resources/\(bundleName).bundle")
        if FileManager.default.fileExists(atPath: appPath.path) {
            return Bundle(url: appPath)
        }

        // SPM debug/test: Bundle.module uses a hardcoded build-dir path.
        // Only safe to call when we're NOT a production .app bundle
        // (production apps have a bundle identifier; test runners don't).
        if Bundle.main.bundleIdentifier == nil {
            return Bundle.module
        }

        return nil
    }()

    static func template() -> String {
        guard let bundle = resourceBundle,
              let url = bundle.url(forResource: "WelcomeWorkbook", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return fallbackWelcome
        }
        return text
    }

    static func document() -> String {
        template().replacingOccurrences(
            of: sampleFilePlaceholder,
            with: sampleFileURL()?.path ?? "~/welcome-sample-file.txt"
        )
    }

    static func sampleFileURL() -> URL? {
        resourceBundle?.url(forResource: "welcome-sample-file", withExtension: "txt")
    }

    private static let fallbackWelcome = """
    # Welcome to apfelpad

    Type here to get started. Insert formulas from the sidebar (Cmd+Shift+F) or type them directly:

    Simple math: =math(2 + 2)
    Today's date: =date()
    """
}

private final class BundleToken {}
