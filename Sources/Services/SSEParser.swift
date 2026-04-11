import Foundation

enum SSEParser {
    struct SSEError: Sendable, Equatable {
        let message: String
        let type: String?
    }

    private struct ChunkResponse: Decodable {
        let choices: [Choice]?

        struct Choice: Decodable {
            let delta: Delta?
            let finish_reason: String?
        }
        struct Delta: Decodable {
            let content: String?
        }
    }

    private struct ErrorResponse: Decodable {
        let error: ErrorDetail
        struct ErrorDetail: Decodable {
            let message: String
            let type: String?
        }
    }

    /// Extract the content delta from an SSE line like
    /// `data: {"choices":[{"delta":{"content":"Hello"}}]}`. Returns nil on
    /// non-data lines, the terminal `[DONE]` marker, role chunks, or errors.
    static func parseContent(line: String) -> String? {
        guard line.hasPrefix("data: ") else { return nil }
        let payload = String(line.dropFirst(6))
        if payload == "[DONE]" { return nil }
        guard let data = payload.data(using: .utf8) else { return nil }
        guard let chunk = try? JSONDecoder().decode(ChunkResponse.self, from: data) else {
            return nil
        }
        return chunk.choices?.first?.delta?.content
    }

    /// Parse an SSE line carrying an error payload, returning the error.
    static func parseError(line: String) -> SSEError? {
        guard line.hasPrefix("data: ") else { return nil }
        let payload = String(line.dropFirst(6))
        guard let data = payload.data(using: .utf8) else { return nil }
        guard let resp = try? JSONDecoder().decode(ErrorResponse.self, from: data) else {
            return nil
        }
        return SSEError(message: resp.error.message, type: resp.error.type)
    }
}
