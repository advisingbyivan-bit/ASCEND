import SwiftUI
import Onboarding
import Persistence
import Gamification
import Diagnostics
import BodyModel3D
import Networking

@main
struct ASCENDApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        // Load API key from Keychain on launch
        APIKeyManager.bootstrap()
    }

    var body: some Scene {
        WindowGroup {
            ContentSwitcher(hasCompletedOnboarding: $hasCompletedOnboarding)
                .preferredColorScheme(.dark)
        }
    }
}

struct ContentSwitcher: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var appState = AppState()
    @State private var showSplash = true

    var body: some View {
        ZStack {
            Group {
                if hasCompletedOnboarding {
                    RootView()
                        .environment(appState)
                } else {
                    OnboardingFlowView(
                        googleSignInEnabled: !Secrets.googleClientID.isEmpty
                    ) { data in
                        saveOnboardingData(data)
                        hasCompletedOnboarding = true
                    }
                }
            }
            .opacity(showSplash ? 0 : 1)

            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            appState.bootstrap()

            // Hold splash briefly, then fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }


    private func saveOnboardingData(_ data: OnboardingData) {
        // If this is a returning user, load their profile from the backend
        if data.isReturningUser {
            loadReturningUserProfile()
            return
        }

        appState.saveOnboardingProfile(
            displayName: data.accountDisplayName ?? "Athlete",
            gender: data.gender == .female ? "female" : "male",
            age: data.age,
            heightCm: data.heightCm,
            weightKg: data.weightKg,
            goalWeightKg: data.goalWeight,
            bodyConcerns: data.bodyConcerns.map(\.rawValue).joined(separator: ","),
            trainingFrequency: data.trainingFrequency.rawValue,
            timeline: data.timeline.rawValue,
            scanDay: data.scanDay.rawValue,
            restDay: data.restDay.rawValue,
            notificationHour: data.notificationHour
        )

        // Sync profile to backend (fire and forget)
        Task {
            try? await AuthClient.shared.syncProfile(
                gender: data.gender == .female ? "female" : "male",
                age: data.age,
                heightCm: data.heightCm,
                weightKg: data.weightKg,
                goalWeightKg: data.goalWeight,
                bodyConcerns: data.bodyConcerns.map(\.rawValue).joined(separator: ","),
                trainingFrequency: data.trainingFrequency.rawValue,
                timeline: data.timeline.rawValue,
                scanDay: data.scanDay.rawValue,
                restDay: data.restDay.rawValue,
                notificationHour: data.notificationHour
            )
        }

        // Save the onboarding scan + diagnosis so Progress tab reflects the first scan
        if let diagnosis = data.diagnosisResult {
            appState.completeScan(photos: data.scanPhotos, diagnosis: diagnosis)
        }
    }

    /// Load profile data from backend for a returning user.
    private func loadReturningUserProfile() {
        Task {
            do {
                let profile = try await AuthClient.shared.fetchProfile()
                await MainActor.run {
                    appState.saveOnboardingProfile(
                        displayName: profile.displayName,
                        gender: profile.gender,
                        age: profile.age,
                        heightCm: profile.heightCm,
                        weightKg: profile.weightKg,
                        goalWeightKg: profile.goalWeightKg,
                        bodyConcerns: profile.bodyConcerns,
                        trainingFrequency: profile.trainingFrequency,
                        timeline: profile.timeline,
                        scanDay: profile.scanDay,
                        restDay: profile.restDay,
                        notificationHour: profile.notificationHour
                    )
                    // Re-bootstrap to pick up profile
                    appState.bootstrap()
                }
            } catch {
                // Backend unreachable — use defaults
                await MainActor.run {
                    appState.saveOnboardingProfile(
                        displayName: "Athlete",
                        gender: "male",
                        age: 25,
                        heightCm: 175,
                        weightKg: 75,
                        goalWeightKg: 72,
                        bodyConcerns: "",
                        trainingFrequency: "3-4x / week",
                        timeline: "12 Weeks",
                        scanDay: "Sunday",
                        restDay: "Wednesday",
                        notificationHour: 8
                    )
                }
            }
        }
    }
}
