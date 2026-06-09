import SwiftUI
import Onboarding
import Persistence
import Gamification
import Diagnostics
import BodyModel3D
import Networking
import Notifications
import Paywall
import UserNotifications

// MARK: - Foreground Notification Handler

/// Allows notifications to display as banners even when the app is in the foreground.
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner + sound even when app is open
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // User tapped the notification — just open the app (default behavior)
        completionHandler()
    }
}

@main
struct ASCENDApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    private let notificationDelegate = NotificationDelegate()

    init() {
        // Load API key from Keychain on launch.
        // RevenueCat and other SDK configs happen here but are fast.
        // Heavy data loading (SwiftData, images) is deferred to bootstrap().
        APIKeyManager.bootstrap()

        // Set notification delegate so banners show in foreground
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            ContentSwitcher(hasCompletedOnboarding: $hasCompletedOnboarding)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    // Handle Universal Links from web checkout
                    _ = WebCheckoutManager.shared.handleUniversalLink(url)
                }
        }
    }
}

struct ContentSwitcher: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var appState = AppState()
    @State private var showSplash = true
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            Group {
                if hasCompletedOnboarding {
                    RootView()
                        .environment(appState)
                } else {
                    OnboardingFlowView(
                        googleSignInEnabled: !Secrets.googleClientID.isEmpty,
                        openWebCheckout: { plan in
                            WebCheckoutManager.shared.openCheckout(plan: plan)
                        }
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

            // Set up web checkout return handler
            WebCheckoutManager.shared.onSubscriptionActivated = {
                // User returned from Stripe checkout with active subscription
                appState.onSubscriptionActivated()
            }

            // Hold splash briefly, then fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                // User returned to app — refresh Live Activity with latest data
                // (streak-at-risk may have changed, score may differ, etc.)
                if hasCompletedOnboarding {
                    appState.refreshLiveActivity()
                    appState.checkStreakDanger()
                }
            case .background:
                // App going to background — ensure Live Activity is current
                if hasCompletedOnboarding {
                    appState.refreshLiveActivity()
                } else if !SubscriptionManager.shared.isPremium {
                    // User backgrounded during onboarding without subscribing.
                    // Schedule re-engagement drip now — they may never finish onboarding.
                    let hour = appState.notificationHour > 0 ? appState.notificationHour : 9
                    NotificationScheduler.shared.scheduleReEngagementDrip(notificationHour: hour)
                    print("[Notifications] User backgrounded during onboarding — scheduling re-engagement")
                }
            default:
                break
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
            // Cancel first-scan reminders since they completed it
            NotificationScheduler.shared.cancelFirstScanReminders()
        } else {
            // User skipped the scan — nudge them to come back
            NotificationScheduler.shared.scheduleFirstScanReminder(notificationHour: data.notificationHour)
        }

        // If user skipped the paywall, schedule re-engagement drip.
        // Only check didPurchase (not isPremium) — isPremium can be stale from
        // previous test sessions and would silently block the drip.
        // The drip auto-cancels when they subscribe or scan anyway.
        if !data.didPurchase {
            print("[Notifications] Scheduling re-engagement drip — user skipped paywall")
            NotificationScheduler.shared.scheduleReEngagementDrip(notificationHour: data.notificationHour)
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
