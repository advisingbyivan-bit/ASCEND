import SwiftUI
import DesignSystem
import Networking

struct AccountScreen: View {
    let coordinator: OnboardingCoordinator

    @State private var signInManager = AppleSignInManager()
    @State private var showErrorAlert = false
    @State private var showOrbit = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showApple = false
    @State private var showTerms = false
    @State private var showEmailSheet = false
    @State private var showGoogle = false
    @State private var showEmail = false
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)

            // Orbiting preview cards — TimelineView for continuous rotation
            TimelineView(.animation) { timeline in
                let elapsed = timeline.date.timeIntervalSinceReferenceDate
                let angle = elapsed.truncatingRemainder(dividingBy: 20) / 20 * 360
                OrbitingCardsView(angle: angle)
            }
            .frame(height: 240)
            .opacity(showOrbit ? 1 : 0)
            .scaleEffect(showOrbit ? 1 : 0.6)

            Spacer().frame(height: DSSpacing.md)

            // Title
            VStack(spacing: DSSpacing.xs) {
                Text("Your journey is ready")
                    .font(DSFont.screenTitle)
                    .foregroundStyle(Color.ds_textPrimary)
                    .scaleEffect(showTitle ? 1 : 0.9)
                    .opacity(showTitle ? 1 : 0)

                Text("Create an account to unlock everything")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textSecondary)
                    .offset(y: showSubtitle ? 0 : 10)
                    .opacity(showSubtitle ? 1 : 0)
            }
            .padding(.bottom, DSSpacing.xl)

            // Sign in with Apple
            Button {
                DSHaptic.medium()
                signInManager.signIn()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "apple.logo")
                        .font(.system(size: 18))
                    Text("Sign in with Apple")
                        .font(DSFont.bodyBold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.white)
                .foregroundStyle(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: DSSpacing.buttonRadius))
            }
            .disabled(signInManager.isSigningIn)
            .opacity(signInManager.isSigningIn ? 0.6 : 1.0)
            .scaleEffect(showApple ? 1 : 0.9)
            .opacity(showApple ? 1 : 0)
            .padding(.horizontal, DSSpacing.screenPadding)

            Spacer().frame(height: 12)

            // Sign in with Google
            Button {
                DSHaptic.medium()
                // Google sign-in will be wired up with GoogleSignIn SDK
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "g.circle.fill")
                        .font(.system(size: 18))
                    Text("Sign in with Google")
                        .font(DSFont.bodyBold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.ds_charcoal)
                .foregroundStyle(Color.ds_textPrimary)
                .clipShape(RoundedRectangle(cornerRadius: DSSpacing.buttonRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DSSpacing.buttonRadius)
                        .stroke(Color.ds_cardBorder, lineWidth: 1)
                )
            }
            .scaleEffect(showGoogle ? 1 : 0.9)
            .opacity(showGoogle ? 1 : 0)
            .padding(.horizontal, DSSpacing.screenPadding)

            Spacer().frame(height: 12)

            // Sign in with Email
            Button {
                DSHaptic.medium()
                showEmailSheet = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 16))
                    Text("Sign in with Email")
                        .font(DSFont.bodyBold)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.clear)
                .foregroundStyle(Color.ds_textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DSSpacing.buttonRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DSSpacing.buttonRadius)
                        .stroke(Color.ds_textSecondary.opacity(0.3), lineWidth: 1)
                )
            }
            .scaleEffect(showEmail ? 1 : 0.9)
            .opacity(showEmail ? 1 : 0)
            .padding(.horizontal, DSSpacing.screenPadding)

            Spacer()

            Text("By signing in you agree to our Terms of Service and Privacy Policy")
                .font(DSFont.micro)
                .foregroundStyle(Color.ds_textSecondary.opacity(0.4))
                .multilineTextAlignment(.center)
                .padding(.horizontal, DSSpacing.lg)
                .padding(.bottom, DSSpacing.xl)
                .opacity(showTerms ? 1 : 0)
        }
        .sheet(isPresented: $showEmailSheet) {
            EmailAuthSheet(coordinator: coordinator)
        }
        .onAppear {
            DSHaptic.screenEntry()

            withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) { showOrbit = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) { showTitle = true }
            withAnimation(.easeOut(duration: 0.4).delay(0.45)) { showSubtitle = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6)) { showApple = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.7)) { showGoogle = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.8)) { showEmail = true }
            withAnimation(.easeIn(duration: 0.3).delay(1.0)) { showTerms = true }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                DSHaptic.anticipationBuild()
            }
        }
        .onChange(of: signInManager.didSignIn) { _, didSignIn in
            guard didSignIn else { return }
            handleSuccessfulSignIn()
        }
        .onChange(of: signInManager.errorMessage) { _, errorMessage in
            if errorMessage != nil {
                showErrorAlert = true
            }
        }
        .alert("Sign In Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {
                signInManager.errorMessage = nil
            }
        } message: {
            Text(signInManager.errorMessage ?? "An unknown error occurred.")
        }
    }

    // MARK: - Private

    private func handleSuccessfulSignIn() {
        DSHaptic.success()
        coordinator.data.appleUserID = signInManager.userIdentifier

        if let name = signInManager.fullName {
            let formatter = PersonNameComponentsFormatter()
            let displayName = formatter.string(from: name)
            if !displayName.isEmpty {
                coordinator.data.accountDisplayName = displayName
            }
        }

        coordinator.data.accountEmail = signInManager.email

        // Attempt backend authentication
        Task {
            await authenticateWithBackend(provider: .apple)
        }
    }

    private enum AuthProvider {
        case apple
        case google(idToken: String)
        case email(email: String, password: String, displayName: String?, isLogin: Bool)
    }

    private func authenticateWithBackend(provider: AuthProvider) async {
        do {
            let response: AuthResponse
            switch provider {
            case .apple:
                // For Apple, we use the user identifier as the identity token
                // In production, use the actual identityToken from ASAuthorizationAppleIDCredential
                guard let userID = coordinator.data.appleUserID else {
                    coordinator.advance()
                    return
                }
                response = try await AuthClient.shared.signInWithApple(
                    identityToken: userID,
                    displayName: coordinator.data.accountDisplayName,
                    email: coordinator.data.accountEmail
                )

            case .google(let idToken):
                response = try await AuthClient.shared.signInWithGoogle(
                    idToken: idToken,
                    displayName: nil,
                    email: nil
                )

            case .email(let email, let password, let displayName, let isLogin):
                if isLogin {
                    response = try await AuthClient.shared.login(email: email, password: password)
                } else {
                    response = try await AuthClient.shared.register(
                        email: email,
                        password: password,
                        displayName: displayName ?? email.components(separatedBy: "@").first ?? "User"
                    )
                }
            }

            // Store the JWT token
            AuthClient.shared.token = response.token
            coordinator.data.authToken = response.token

            // Update display name from server if available
            if coordinator.data.accountDisplayName == nil || coordinator.data.accountDisplayName?.isEmpty == true {
                coordinator.data.accountDisplayName = response.user.displayName
            }
            coordinator.data.accountEmail = response.user.email

            await MainActor.run {
                if response.user.isNewUser {
                    // New user — continue normal onboarding flow
                    coordinator.advance()
                } else {
                    // Returning user — skip onboarding entirely
                    coordinator.data.isReturningUser = true
                    coordinator.finishOnboarding()
                }
            }
        } catch {
            // Backend unavailable or error — proceed with onboarding anyway
            // The user can still use the app locally
            await MainActor.run {
                coordinator.advance()
            }
        }
    }
}

// MARK: - Orbiting Cards View

private struct OrbitingCardsView: View {
    let angle: Double

    private let cards: [(icon: String, title: String, color: Color, mockup: CardMockupType)] = [
        ("chart.bar.fill", "Dashboard", Color.ds_cyan, .dashboard),
        ("waveform.path.ecg", "Diagnosis", Color.ds_purple, .diagnosis),
        ("trophy.fill", "Leaderboard", Color.ds_yellow, .leaderboard),
        ("figure.stand", "Body Twin", Color.ds_green, .bodyModel),
    ]

    var body: some View {
        ZStack {
            // Center glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.ds_cyan.opacity(0.12), Color.clear],
                        center: .center,
                        startRadius: 10,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)

            // Center IRIS orb
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.ds_cyan.opacity(0.3), Color.ds_purple.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 8,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)

                // Core sphere
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.white.opacity(0.9), Color.ds_cyan.opacity(0.6), Color.ds_purple.opacity(0.3)],
                            center: UnitPoint(x: 0.35, y: 0.35),
                            startRadius: 2,
                            endRadius: 20
                        )
                    )
                    .frame(width: 36, height: 36)

                // Glass highlight
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.4), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .frame(width: 36, height: 36)

                // Rim glow
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.ds_cyan.opacity(0.6), Color.ds_purple.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 38, height: 38)
            }

            // Orbiting cards
            ForEach(0..<cards.count, id: \.self) { index in
                let cardAngle = angle + Double(index) * (360.0 / Double(cards.count))
                let radians = cardAngle * .pi / 180
                let radius: CGFloat = 95

                // 3D orbit effect: x is circular, y is elliptical (perspective)
                let xOffset = cos(radians) * radius
                let yOffset = sin(radians) * radius * 0.35  // Flatten to ellipse

                // Z-depth: cards in front are larger, cards behind smaller
                let zDepth = sin(radians)  // -1 (back) to 1 (front)
                let scale = 0.7 + (zDepth + 1) * 0.2  // 0.7 to 1.1
                let opacity = 0.4 + (zDepth + 1) * 0.3  // 0.4 to 1.0

                let card = cards[index]

                OrbitCard(
                    icon: card.icon,
                    title: card.title,
                    color: card.color,
                    mockupType: card.mockup
                )
                .scaleEffect(scale)
                .opacity(opacity)
                .offset(x: xOffset, y: yOffset)
                .zIndex(zDepth)
                // Tilt card based on position in orbit
                .rotation3DEffect(
                    .degrees(cos(radians) * 12),
                    axis: (x: 0, y: 1, z: 0)
                )
            }
        }
    }
}

// MARK: - Card Mockup Types

private enum CardMockupType {
    case dashboard
    case diagnosis
    case leaderboard
    case bodyModel
}

// MARK: - Orbit Card

private struct OrbitCard: View {
    let icon: String
    let title: String
    let color: Color
    let mockupType: CardMockupType

    var body: some View {
        VStack(spacing: 6) {
            // Mini mockup preview
            mockupContent
                .frame(height: 70)
                .frame(maxWidth: .infinity)
                .clipped()

            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
        }
        .padding(8)
        .frame(width: 110, height: 110)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.ds_charcoal.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.1), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.25), lineWidth: 1)
        )
        .shadow(color: color.opacity(0.2), radius: 10)
    }

    @ViewBuilder
    private var mockupContent: some View {
        switch mockupType {
        case .dashboard:
            DashboardMockup(color: color)
        case .diagnosis:
            DiagnosisMockup(color: color)
        case .leaderboard:
            LeaderboardMockup(color: color)
        case .bodyModel:
            BodyModelMockup(color: color)
        }
    }
}

// MARK: - Mini Mockup Views

private struct DashboardMockup: View {
    let color: Color
    var body: some View {
        VStack(spacing: 4) {
            // Mini stat bars
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(0..<7, id: \.self) { i in
                    let heights: [CGFloat] = [18, 28, 22, 35, 30, 40, 25]
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 6, height: heights[i])
                }
            }
            // Mini progress line
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(color.opacity(0.5))
                    .frame(height: 3)
                    .frame(maxWidth: .infinity)
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.ds_cardBorder)
                    .frame(height: 3)
                    .frame(width: 30)
            }
            .padding(.horizontal, 4)
        }
    }
}

private struct DiagnosisMockup: View {
    let color: Color
    var body: some View {
        ZStack {
            // Mini body silhouette
            Image(systemName: "figure.stand")
                .font(.system(size: 36, weight: .ultraLight))
                .foregroundStyle(color.opacity(0.4))

            // Zone highlight dots
            Circle()
                .fill(Color.ds_red.opacity(0.7))
                .frame(width: 6, height: 6)
                .offset(x: 0, y: -8)

            Circle()
                .fill(Color.ds_green.opacity(0.7))
                .frame(width: 5, height: 5)
                .offset(x: -6, y: 2)

            Circle()
                .fill(Color.ds_yellow.opacity(0.7))
                .frame(width: 5, height: 5)
                .offset(x: 6, y: 2)

            // Scan lines
            ForEach(0..<3, id: \.self) { i in
                Rectangle()
                    .fill(color.opacity(0.1))
                    .frame(height: 1)
                    .offset(y: CGFloat(i - 1) * 18)
            }
        }
    }
}

private struct LeaderboardMockup: View {
    let color: Color
    var body: some View {
        VStack(spacing: 3) {
            // Podium
            HStack(alignment: .bottom, spacing: 3) {
                // 2nd place
                VStack(spacing: 2) {
                    Circle()
                        .fill(Color.ds_textSecondary.opacity(0.3))
                        .frame(width: 10, height: 10)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.ds_textSecondary.opacity(0.3))
                        .frame(width: 18, height: 22)
                }
                // 1st place
                VStack(spacing: 2) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(color)
                    Circle()
                        .fill(color.opacity(0.5))
                        .frame(width: 12, height: 12)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color.opacity(0.4))
                        .frame(width: 18, height: 30)
                }
                // 3rd place
                VStack(spacing: 2) {
                    Circle()
                        .fill(Color.ds_textSecondary.opacity(0.2))
                        .frame(width: 10, height: 10)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.ds_textSecondary.opacity(0.2))
                        .frame(width: 18, height: 16)
                }
            }

            // Rank rows
            ForEach(0..<2, id: \.self) { _ in
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.ds_textSecondary.opacity(0.15))
                        .frame(width: 6, height: 6)
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.ds_textSecondary.opacity(0.15))
                        .frame(height: 4)
                }
                .padding(.horizontal, 6)
            }
        }
    }
}

private struct BodyModelMockup: View {
    let color: Color
    var body: some View {
        ZStack {
            // Glow behind
            Circle()
                .fill(
                    RadialGradient(
                        colors: [color.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 5,
                        endRadius: 30
                    )
                )
                .frame(width: 60, height: 60)

            // Body figure
            Image(systemName: "figure.stand")
                .font(.system(size: 40, weight: .thin))
                .foregroundStyle(
                    LinearGradient(
                        colors: [color.opacity(0.8), Color.ds_purple.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Rotation indicator arc
            Circle()
                .trim(from: 0, to: 0.3)
                .stroke(color.opacity(0.3), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                .frame(width: 50, height: 50)
                .rotationEffect(.degrees(-60))
        }
    }
}
