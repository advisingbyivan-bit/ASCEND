import Foundation
import Security
import Networking

/// Manages the Anthropic API key securely via Keychain.
/// On app launch, loads the key and sets it on `ClaudeVisionClient.shared`.
enum APIKeyManager {

    private static let service = "us.ascendapp.apikeys"
    private static let account = "anthropic-api-key"

    // MARK: - Public

    /// Call once at app startup to configure the vision client and auth client.
    /// Sets the proxy URL so API calls go through our Cloudflare Worker
    /// (which holds the API key server-side).
    static func bootstrap() {
        // Set proxy URL — all API calls go through this instead of direct to Anthropic
        let proxyURL = Secrets.proxyBaseURL
        if !proxyURL.isEmpty {
            ClaudeVisionClient.shared.proxyBaseURL = proxyURL
        }

        // Configure auth client with backend URL
        let backendURL = Secrets.backendBaseURL
        if !backendURL.isEmpty {
            AuthClient.shared.backendBaseURL = backendURL
        }

        // Also load any locally stored key (for dev/testing only)
        if let key = load(), !key.isEmpty {
            ClaudeVisionClient.shared.apiKey = key
        }
    }

    /// Save the API key to Keychain and update the live client.
    @discardableResult
    static func setKey(_ key: String) -> Bool {
        let saved = save(key)
        if saved {
            ClaudeVisionClient.shared.apiKey = key
        }
        return saved
    }

    /// Read the currently stored key (or nil).
    static func currentKey() -> String? {
        load()
    }

    /// Remove the stored key.
    static func removeKey() {
        delete()
        ClaudeVisionClient.shared.apiKey = ""
    }

    /// Whether a valid key is configured.
    static var isConfigured: Bool {
        guard let key = load() else { return false }
        return !key.isEmpty && key.hasPrefix("sk-ant-")
    }

    // MARK: - Keychain Helpers

    private static func save(_ value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Delete any existing item first
        delete()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    private static func load() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    private static func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
