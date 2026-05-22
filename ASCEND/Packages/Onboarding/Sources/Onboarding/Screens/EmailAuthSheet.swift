import SwiftUI
import DesignSystem
import Networking

struct EmailAuthSheet: View {
    let coordinator: OnboardingCoordinator
    @Environment(\.dismiss) private var dismiss

    @State private var isLoginMode = false
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ds_background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DSSpacing.lg) {
                        // Mode toggle
                        Picker("Mode", selection: $isLoginMode) {
                            Text("Sign Up").tag(false)
                            Text("Log In").tag(true)
                        }
                        .pickerStyle(.segmented)
                        .padding(.top, DSSpacing.md)

                        // Form fields
                        VStack(spacing: DSSpacing.md) {
                            if !isLoginMode {
                                AuthTextField(
                                    title: "Display Name",
                                    text: $displayName,
                                    icon: "person.fill",
                                    placeholder: "Your name"
                                )
                            }

                            AuthTextField(
                                title: "Email",
                                text: $email,
                                icon: "envelope.fill",
                                placeholder: "you@example.com",
                                keyboardType: .emailAddress,
                                autocapitalization: .never
                            )

                            AuthTextField(
                                title: "Password",
                                text: $password,
                                icon: "lock.fill",
                                placeholder: "Min 8 characters",
                                isSecure: true
                            )

                            if !isLoginMode {
                                AuthTextField(
                                    title: "Confirm Password",
                                    text: $confirmPassword,
                                    icon: "lock.fill",
                                    placeholder: "Re-enter password",
                                    isSecure: true
                                )
                            }
                        }

                        // Error message
                        if let error = errorMessage {
                            Text(error)
                                .font(DSFont.caption)
                                .foregroundStyle(Color.ds_red)
                                .multilineTextAlignment(.center)
                        }

                        // Submit button
                        DSPrimaryButton(
                            isLoginMode ? "Log In" : "Create Account",
                            icon: isLoginMode ? "arrow.right" : "person.badge.plus"
                        ) {
                            DSHaptic.medium()
                            submit()
                        }
                        .disabled(!isFormValid || isLoading)
                        .opacity(isFormValid ? 1 : 0.5)

                        if isLoading {
                            ProgressView()
                                .tint(Color.ds_cyan)
                        }
                    }
                    .padding(.horizontal, DSSpacing.screenPadding)
                }
            }
            .navigationTitle(isLoginMode ? "Welcome Back" : "Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.ds_textSecondary)
                }
            }
        }
    }

    private var isFormValid: Bool {
        if isLoginMode {
            return !email.isEmpty && !password.isEmpty
        } else {
            return !email.isEmpty && !password.isEmpty &&
                   !displayName.isEmpty && password == confirmPassword &&
                   password.count >= 8
        }
    }

    private func submit() {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                if isLoginMode {
                    let response = try await AuthClient.shared.login(email: email, password: password)
                    AuthClient.shared.token = response.token
                    await MainActor.run {
                        coordinator.data.accountEmail = email
                        coordinator.data.accountDisplayName = response.user.displayName
                        coordinator.data.authToken = response.token
                        isLoading = false
                        dismiss()

                        if response.user.isNewUser {
                            coordinator.advance()
                        } else {
                            // Returning user — skip onboarding
                            coordinator.data.isReturningUser = true
                            coordinator.finishOnboarding()
                        }
                    }
                } else {
                    // Validate
                    if password != confirmPassword {
                        await MainActor.run {
                            errorMessage = "Passwords don't match"
                            isLoading = false
                        }
                        return
                    }

                    let response = try await AuthClient.shared.register(
                        email: email,
                        password: password,
                        displayName: displayName
                    )
                    AuthClient.shared.token = response.token
                    await MainActor.run {
                        coordinator.data.accountEmail = email
                        coordinator.data.accountDisplayName = displayName
                        coordinator.data.authToken = response.token
                        isLoading = false
                        dismiss()
                        coordinator.advance()
                    }
                }
            } catch let error as AuthError {
                await MainActor.run {
                    errorMessage = error.errorDescription
                    isLoading = false
                }
            } catch {
                // Backend unavailable — allow proceeding with local-only mode
                await MainActor.run {
                    coordinator.data.accountEmail = email
                    coordinator.data.accountDisplayName = displayName.isEmpty ? email.components(separatedBy: "@").first : displayName
                    isLoading = false
                    dismiss()
                    coordinator.advance()
                }
            }
        }
    }
}

// MARK: - Auth Text Field

private struct AuthTextField: View {
    let title: String
    @Binding var text: String
    let icon: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(DSFont.captionBold)
                .foregroundStyle(Color.ds_textSecondary)

            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.ds_cyan.opacity(0.6))
                    .frame(width: 20)

                if isSecure {
                    SecureField(placeholder, text: $text)
                        .font(DSFont.body)
                        .foregroundStyle(Color.ds_textPrimary)
                } else {
                    TextField(placeholder, text: $text)
                        .font(DSFont.body)
                        .foregroundStyle(Color.ds_textPrimary)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(autocapitalization)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.ds_charcoal)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.ds_cardBorder, lineWidth: 1)
            )
        }
    }
}
