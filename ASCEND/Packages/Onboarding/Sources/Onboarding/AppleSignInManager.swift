import AuthenticationServices
import Foundation

/// Manages Sign in with Apple authentication flow.
/// Uses ASAuthorizationController to present the system sign-in sheet
/// and stores the resulting credentials in UserDefaults and Keychain.
@Observable
public final class AppleSignInManager: NSObject {

    // MARK: - Published State

    public var isSigningIn = false
    public var didSignIn = false
    public var errorMessage: String?

    // MARK: - Result Properties

    public private(set) var userIdentifier: String?
    public private(set) var fullName: PersonNameComponents?
    public private(set) var email: String?

    // MARK: - UserDefaults Key

    private static let appleUserIDKey = "apple_user_id"

    // MARK: - Keychain

    private static let keychainService = "com.ascend.apple-sign-in"

    // MARK: - Init

    public override init() {
        super.init()
    }

    // MARK: - Public API

    /// Initiates the Sign in with Apple flow.
    public func signIn() {
        isSigningIn = true
        errorMessage = nil

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    /// Returns the stored Apple user ID, if available.
    public static var storedUserID: String? {
        UserDefaults.standard.string(forKey: appleUserIDKey)
    }

    /// Checks if the stored Apple credential is still valid.
    public func checkCredentialState(completion: @escaping (Bool) -> Void) {
        guard let userID = Self.storedUserID else {
            completion(false)
            return
        }

        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userID) { state, _ in
            DispatchQueue.main.async {
                completion(state == .authorized)
            }
        }
    }

    // MARK: - Private Helpers

    private func persistCredentials(userID: String) {
        // Store in UserDefaults
        UserDefaults.standard.set(userID, forKey: Self.appleUserIDKey)

        // Store in Keychain for added security
        saveToKeychain(userID: userID)
    }

    private func saveToKeychain(userID: String) {
        guard let data = userID.data(using: .utf8) else { return }

        // Delete any existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: "apple_user_id"
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: "apple_user_id",
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    /// Reads the Apple user ID from the Keychain.
    public static func readFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: "apple_user_id",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let userID = String(data: data, encoding: .utf8) else {
            return nil
        }
        return userID
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInManager: ASAuthorizationControllerDelegate {

    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        isSigningIn = false

        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Unexpected credential type received."
            return
        }

        // Extract user info
        userIdentifier = credential.user
        fullName = credential.fullName
        email = credential.email

        // Persist the Apple user ID
        persistCredentials(userID: credential.user)

        didSignIn = true
    }

    public func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        isSigningIn = false

        let asError = error as? ASAuthorizationError
        switch asError?.code {
        case .canceled:
            // User dismissed the sheet — not really an error
            errorMessage = nil
        case .failed:
            errorMessage = "Sign in failed. Please try again."
        case .invalidResponse:
            errorMessage = "Invalid response from Apple. Please try again."
        case .notHandled:
            errorMessage = "Sign in request was not handled."
        case .notInteractive:
            errorMessage = "Sign in requires interaction."
        default:
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInManager: ASAuthorizationControllerPresentationContextProviding {

    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the first window scene's key window
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}
