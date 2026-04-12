import Foundation

enum WelcomeWorkbook {
    static let sampleFilePlaceholder = "__WELCOME_SAMPLE_FILE__"

    /// The SwiftPM resource bundle. In production, build-app.sh copies it to
    /// Contents/Resources/. In SPM test/debug builds, Bundle.module resolves
    /// via a hardcoded build-dir path. If the bundle is missing, the build is
    /// broken — this is intentionally not guarded.
    static let resourceBundle: Bundle = {
        let bundleName = "apfelpad_apfelpad"

        // Production .app: resource bundle lives in Contents/Resources/.
        let appPath = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Resources/\(bundleName).bundle")
        if let bundle = Bundle(url: appPath) {
            return bundle
        }

        // SPM debug/test: Bundle.module has a hardcoded build-dir path.
        return Bundle.module
    }()

    static func template() -> String {
        guard let url = resourceBundle.url(forResource: "WelcomeWorkbook", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            preconditionFailure("WelcomeWorkbook.md missing from resource bundle")
        }
        return text
    }

    static func document() -> String {
        let samplePath = sampleFileURL().path
        return template().replacingOccurrences(of: sampleFilePlaceholder, with: samplePath)
    }

    static func sampleFileURL() -> URL {
        guard let url = resourceBundle.url(forResource: "welcome-sample-file", withExtension: "txt") else {
            preconditionFailure("welcome-sample-file.txt missing from resource bundle")
        }
        return url
    }
}
