import Foundation

enum WelcomeWorkbook {
    static let sampleFilePlaceholder = "__WELCOME_SAMPLE_FILE__"

    static func template() -> String {
        guard let url = Bundle.module.url(forResource: "WelcomeWorkbook", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return """
            # Welcome to apfelpad

            The bundled welcome workbook is missing.
            """
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
        Bundle.module.url(forResource: "welcome-sample-file", withExtension: "txt")
    }
}
