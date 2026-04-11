import Foundation

/// OpenAI-compatible HTTP client for `apfel --serve`.
/// POSTs to `http://127.0.0.1:<port>/v1/chat/completions` with a streaming
/// body and yields content deltas via `AsyncThrowingStream<String, Error>`.
struct ApfelHTTPService: LLMService {
    let endpointURL: URL
    let session: URLSession

    init(port: Int, session: URLSession = .shared) {
        self.endpointURL = URL(string: "http://127.0.0.1:\(port)/v1/chat/completions")!
        self.session = session
    }

    func complete(
        prompt: String,
        context: String,
        seed: Int?
    ) -> AsyncThrowingStream<String, Error> {
        let body = Self.buildRequestBody(prompt: prompt, context: context, seed: seed)
        let url = endpointURL
        let session = session

        return AsyncThrowingStream { continuation in
            Task {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
                request.httpBody = body
                request.timeoutInterval = 120

                do {
                    let (bytes, response) = try await session.bytes(for: request)
                    if let http = response as? HTTPURLResponse,
                       !(200...299).contains(http.statusCode) {
                        continuation.finish(
                            throwing: ApfelHTTPError.httpStatus(http.statusCode)
                        )
                        return
                    }

                    for try await line in bytes.lines {
                        if let err = SSEParser.parseError(line: line) {
                            continuation.finish(
                                throwing: ApfelHTTPError.serverError(err.message)
                            )
                            return
                        }
                        if let content = SSEParser.parseContent(line: line), !content.isEmpty {
                            continuation.yield(content)
                        }
                        // `data: [DONE]` → parseContent returns nil, loop ends when stream closes
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Build the request body for `/v1/chat/completions`.
    /// System message carries the auto-scoped context (omitted when empty).
    static func buildRequestBody(prompt: String, context: String, seed: Int?) -> Data {
        var messages: [[String: Any]] = []
        if !context.isEmpty {
            messages.append([
                "role": "system",
                "content": "Document context (for reference):\n\n\(context)"
            ])
        }
        messages.append(["role": "user", "content": prompt])

        var body: [String: Any] = [
            "model": "apple-foundationmodel",
            "messages": messages,
            "stream": true
        ]
        if let seed {
            body["seed"] = seed
        }
        return try! JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])
    }
}

enum ApfelHTTPError: LocalizedError {
    case httpStatus(Int)
    case serverError(String)
    case connectionFailed

    var errorDescription: String? {
        switch self {
        case .httpStatus(let code): return "apfel server returned HTTP \(code)"
        case .serverError(let msg): return "apfel server error: \(msg)"
        case .connectionFailed: return "Could not connect to apfel on localhost"
        }
    }
}
