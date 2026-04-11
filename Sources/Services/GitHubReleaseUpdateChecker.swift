import Foundation

enum UpdateCheckerError: LocalizedError {
    case unexpectedResponse

    var errorDescription: String? {
        switch self {
        case .unexpectedResponse:
            return "Unexpected response from GitHub"
        }
    }
}

struct GitHubReleaseUpdateChecker: UpdateChecking {
    let session: URLSession
    let apiURL: URL

    init(
        session: URLSession = .shared,
        apiURL: URL = URL(string: "https://api.github.com/repos/Arthur-Ficial/apfelpad/releases/latest")!
    ) {
        self.session = session
        self.apiURL = apiURL
    }

    @MainActor
    func fetchLatestRelease(currentVersion: String) async throws -> LatestReleaseInfo {
        var request = URLRequest(url: apiURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("apfelpad/\(currentVersion)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        let (data, response) = try await session.data(for: request)
        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw UpdateCheckerError.unexpectedResponse
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tagName = json["tag_name"] as? String else {
            throw UpdateCheckerError.unexpectedResponse
        }

        return LatestReleaseInfo(version: Self.normaliseTag(tagName))
    }

    /// Strip a leading "v" from a git tag: "v1.2.3" → "1.2.3".
    static func normaliseTag(_ tag: String) -> String {
        tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
    }
}
