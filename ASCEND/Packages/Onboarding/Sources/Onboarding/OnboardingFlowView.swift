import SwiftUI
import DesignSystem

public struct OnboardingFlowView: View {
    @State private var coordinator = OnboardingCoordinator()
    let onComplete: (OnboardingData) -> Void

    public init(onComplete: @escaping (OnboardingData) -> Void) {
        self.onComplete = onComplete
    }

    /// Convenience init with no-data callback (backwards compatible)
    public init(onComplete: @escaping () -> Void) {
        self.onComplete = { _ in onComplete() }
    }

    public var body: some View {
        ZStack {
            Color.ds_navy.ignoresSafeArea()

            // Subtle ambient particles throughout onboarding
            if showsParticles {
                DSFloatingParticles(count: 15, colors: [
                    Color.ds_purple.opacity(0.3),
                    Color.ds_cyan.opacity(0.15)
                ])
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            VStack(spacing: 0) {
                if coordinator.currentScreen.showsProgressBar {
                    progressBar
                }

                screenContent
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                    .id(coordinator.currentScreen)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: coordinator.currentScreen)
        .onChange(of: coordinator.currentScreen) { _, _ in
            // Haptic on every screen transition
            DSHaptic.screenEntry()
        }
        .onChange(of: coordinator.isComplete) { _, complete in
            if complete {
                var finalData = coordinator.data
                finalData.scanPhotos = coordinator.scanPhotos
                finalData.diagnosisResult = coordinator.diagnosisResult
                onComplete(finalData)
            }
        }
    }

    private var showsParticles: Bool {
        switch coordinator.currentScreen {
        case .scan, .diagnosis:
            return false // Scanner and diagnosis have their own backgrounds
        default:
            return true
        }
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.ds_charcoal)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.ds_cyan.opacity(0.7), Color.ds_cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geo.size.width * coordinator.currentScreen.progress)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: coordinator.currentScreen.progress)
            }
        }
        .frame(height: 3)
    }

    @ViewBuilder
    private var screenContent: some View {
        switch coordinator.currentScreen {
        // Phase 1: Welcome + intro
        case .welcome:
            WelcomeScreen(coordinator: coordinator)
        case .intro:
            IntroScreen(coordinator: coordinator)
        case .blockers:
            Cal02_BlockersScreen(coordinator: coordinator)
        case .goals:
            Cal03_GoalsScreen(coordinator: coordinator)

        // Phase 2: Personal data collection
        case .gender:
            GenderScreen(coordinator: coordinator)
        case .ageHeight:
            AgeHeightScreen(coordinator: coordinator)
        case .weightGoal:
            WeightGoalScreen(coordinator: coordinator)
        case .bodyConcerns:
            BodyConcernsScreen(coordinator: coordinator)
        case .trainingFrequency:
            TrainingFrequencyScreen(coordinator: coordinator)
        case .timeline:
            TimelineScreen(coordinator: coordinator)
        case .preferences:
            PreferencesScreen(coordinator: coordinator)

        // Phase 3: Affirmation & permissions
        case .affirmation:
            Cal04_AffirmationScreen(coordinator: coordinator)
        case .thankYou:
            Cal05_ThankYouScreen(coordinator: coordinator)
        case .healthConnect:
            Cal06_HealthConnectScreen(coordinator: coordinator)
        case .notifications:
            Cal09_NotificationsScreen(coordinator: coordinator)
        case .allDone:
            Cal10_AllDoneScreen(coordinator: coordinator)

        // Phase 4: Account & paywall
        case .account:
            AccountScreen(coordinator: coordinator)
        case .paywallIntro:
            Cal15_PaywallIntroScreen(coordinator: coordinator)
        case .trialReminder:
            Cal16_TrialReminderScreen(coordinator: coordinator)
        case .trialStart:
            Cal17_TrialStartScreen(coordinator: coordinator)
        case .monthlyFallback:
            Cal18_MonthlyFallbackScreen(coordinator: coordinator)

        // Phase 5: Scan & diagnosis
        case .cameraSetup:
            CameraSetupScreen(coordinator: coordinator)
        case .scan:
            OnboardingScanScreen(coordinator: coordinator)
        case .diagnosis:
            OnboardingDiagnosisScreen(coordinator: coordinator)

        // Phase 6: Results & completion
        case .goalSummary:
            Cal13_GoalSummaryScreen(coordinator: coordinator)
        case .complete:
            OnboardingCompleteScreen(coordinator: coordinator)
        }
    }
}
