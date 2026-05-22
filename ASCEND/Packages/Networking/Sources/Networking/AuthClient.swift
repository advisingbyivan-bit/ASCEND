import Foundation
import Security

// MARK: - Auth Response Models

/// Response from the backend auth endpoints
public struct AuthResponse: Codable, Sendable {
    public let token: String
    public let user: AuthUser
}

public struct AuthUser: Codable, Sendable {
    public let id: String
    public let displayName: String
    public let email: String?
    public let isNewUser: Bool
}

/// Full user profile returned from GET /users/me
public struct UserProfile: Codable, Sendable {
    public let id: String
    public let displayName: String
    public let email: String?
    public let gender: String
    public let age: Int
    public let heightCm: Int
    public let weightKg: Double
    public let goalWeightKg: Double
    public let bodyConcerns: String
    public let trainingFrequency: String
    public let timeline: String
    public let scanDay: String
    public let restDay: String
    public let notificationHour: Int
    public let currentStreak: Int
    public let longestStreak: Int
    public let totalDiamonds: Int
    public let lastScanDate: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case email
        case gender
        case age
        case heightCm = "height_cm"
        case weightKg = "weight_kg"
        case goalWeightKg = "goal_weight_kg"
        case bodyConcerns = "body_concerns"
        case trainingFrequency = "training_frequency"
        case timeline
        case scanDay = "scan_day"
        case restDay = "rest_day"
        case notificationHour = "notification_hour"
        case currentStreak = "current_streak"
        case longestStreak = "longest_streak"
        case totalDiamonds = "total_diamonds"
        case lastScanDate = "last_scan_date"
    }
}

/// Wrapper for GET /users/me response: { user: {...} }
private struct UserProfileWrapper: Codable {
    let user: UserProfile
}

// MARK: - Auth Errors

public enum AuthError: LocalizedError, Sendable {
    case noBackendURL
    case invalidResponse
    case serverError(Int, String)
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .noBackendURL:
            return "Backend is not configured."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .serverError(let code, let message):
            return "Server error (\(code)): \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Auth Client

/// Handles authentication API calls to the ASCEND backend.
/// Stores JWT token in Keychain for authenticated requests.
public final class AuthClient: Sendable {
    public static let shared = AuthClient()

    /// Backend API base URL — set from Secrets at app launch.
    public var backendBaseURL: String {
        get { _lock.withLock { _backendBaseURL } }
        set { _lock.withLock { _backendBaseURL = newValue } }
    }

    /// JWT token for authenticated requests — persisted in Keychain.
    public var token: String? {
        get { _lock.withLock { _token } }
        set { _lock.withLock { _token = newValue; if let newValue { Self.saveToken(newValue) } else { Self.deleteToken() } } }
    }

    private let _lock = NSLock()
    private var _backendBaseURL = ""
    private var _token: String?

    private init() {
        // Load persisted token on init
        _token = Self.loadToken()
    }

    // MARK: - Apple Sign-In

    /// Authenticate with Apple identity token.
    /// Returns AuthResponse with JWT + user info.
    public func signInWithApple(
        identityToken: String,
        displayName: String?,
        email: String?
    ) async throws -> AuthResponse {
        var body: [String: Any] = ["identityToken": identityToken]
        if let displayName { body["displayName"] = displayName }
        if let email { body["email"] = email }
        return try await post(path: "/auth/apple", body: body)
    }

    // MARK: - Google Sign-In

    /// Authenticate with Google ID token.
    public func signInWithGoogle(
        idToken: String,
        displayName: String?,
        email: String?
    ) async throws -> AuthResponse {
        var body: [String: Any] = ["idToken": idToken]
        if let displayName { body["displayName"] = displayName }
        if let email { body["email"] = email }
        return try await post(path: "/auth/google", body: body)
    }

    // MARK: - Email Register

    /// Register with email/password.
    public func register(
        email: String,
        password: String,
        displayName: String
    ) async throws -> AuthResponse {
        let body: [String: Any] = [
            "email": email,
            "password": password,
            "displayName": displayName
        ]
        return try await post(path: "/auth/register", body: body)
    }

    // MARK: - Email Login

    /// Log in with email/password.
    public func login(
        email: String,
        password: String
    ) async throws -> AuthResponse {
        let body: [String: Any] = [
            "email": email,
            "password": password
        ]
        return try await post(path: "/auth/login", body: body)
    }

    // MARK: - Fetch Profile

    /// Fetch the authenticated user's full profile.
    /// Requires a valid JWT token.
    public func fetchProfile() async throws -> UserProfile {
        let base = backendBaseURL
        guard !base.isEmpty else { throw AuthError.noBackendURL }

        let url = URL(string: "\(base)/users/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AuthError.networkError(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AuthError.serverError(http.statusCode, message)
        }

        // Backend wraps response in { user: {...} }
        let wrapper = try JSONDecoder().decode(UserProfileWrapper.self, from: data)
        return wrapper.user
    }

    // MARK: - Sync Onboarding Profile

    /// Push onboarding profile data to the backend after completing onboarding.
    public func syncProfile(
        gender: String,
        age: Int,
        heightCm: Int,
        weightKg: Double,
        goalWeightKg: Double,
        bodyConcerns: String,
        trainingFrequency: String,
        timeline: String,
        scanDay: String,
        restDay: String,
        notificationHour: Int
    ) async throws {
        let base = backendBaseURL
        guard !base.isEmpty else { return } // Silently skip if no backend

        let body: [String: Any] = [
            "gender": gender,
            "age": age,
            "height_cm": heightCm,
            "weight_kg": weightKg,
            "goal_weight_kg": goalWeightKg,
            "body_concerns": bodyConcerns,
            "training_frequency": trainingFrequency,
            "timeline": timeline,
            "scan_day": scanDay,
            "rest_day": restDay,
            "notification_hour": notificationHour
        ]

        let url = URL(string: "\(base)/users/me")!
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // Fire and forget — don't block onboarding on backend sync
        let _ = try await URLSession.shared.data(for: request)
    }

    /// Whether the user has a stored JWT (potentially a returning user).
    public var hasStoredSession: Bool {
        token != nil && !(token?.isEmpty ?? true)
    }

    /// Clear stored session data (for logout).
    public func logout() {
        token = nil
    }

    // MARK: - Private Helpers

    private func post<T: Decodable>(path: String, body: [String: Any]) async throws -> T {
        let base = backendBaseURL
        guard !base.isEmpty else { throw AuthError.noBackendURL }

        let url = URL(string: "\(base)\(path)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AuthError.networkError(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AuthError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            let message: String
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let msg = json["message"] as? String {
                message = msg
            } else {
                message = String(data: data, encoding: .utf8) ?? "Unknown error"
            }
            throw AuthError.serverError(http.statusCode, message)
        }

        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Keychain Token Storage

    private static let keychainService = "us.ascendapp.auth"
    private static let keychainAccount = "jwt-token"

    private static func saveToken(_ token: String) {
        guard let data = token.data(using: .utf8) else { return }
        deleteToken()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    private static func loadToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }

    private static func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
