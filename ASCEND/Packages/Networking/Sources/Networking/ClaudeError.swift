import Foundation

public enum ClaudeError: Error, LocalizedError {
    case noAPIKey
    case invalidResponse
    case networkError(Error)
    case decodingError(String)
    case apiError(String)

    public var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "API key is not set."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        }
    }
}
