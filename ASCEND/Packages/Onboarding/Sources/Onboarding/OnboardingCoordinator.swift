import SwiftUI
import DesignSystem
import BodyModel3D
import Diagnostics

public enum OnboardingScreen: Int, CaseIterable {
    // Phase 1: Welcome + intro
    case welcome = 0
    case intro
    case blockers
    case goals

    // Phase 2: Personal data collection
    case gender
    case ageHeight
    case weightGoal
    case bodyConcerns
    case trainingFrequency
    case timeline
    case preferences

    // Phase 3: Affirmation & permissions
    case affirmation
    case thankYou
    case notifications
    case allDone

    // Phase 4: Account & paywall
    case account
    case paywallIntro
    case trialReminder
    case trialStart
    case monthlyFallback

    // Phase 5: Scan & diagnosis
    case cameraSetup
    case scan
    case diagnosis

    // Phase 6: Results & completion
    case goalSummary
    case complete

    public var progress: Double {
        Double(rawValue + 1) / Double(OnboardingScreen.allCases.count)
    }

    var showsProgressBar: Bool {
        switch self {
        case .welcome, .intro, .scan, .diagnosis,
             .paywallIntro, .trialReminder, .trialStart, .monthlyFallback,
             .goalSummary, .complete:
            return false
        default:
            return true
        }
    }
}

@Observable
public final class OnboardingCoordinator {
    public var currentScreen: OnboardingScreen = .welcome
    public var data = OnboardingData()
    public var scanPhotos: [UIImage] = []
    public var diagnosisResult: DiagnosisResult?
    public var isComplete = false

    public init() {}

    public init(data: OnboardingData) {
        self.data = data
    }

    public func advance() {
        guard let next = OnboardingScreen(rawValue: currentScreen.rawValue + 1) else {
            isComplete = true
            return
        }

        // If user already purchased, skip remaining paywall screens
        if data.didPurchase && isPaywallScreen(next) {
            currentScreen = .scan
            return
        }

        if next == .cameraSetup {
            currentScreen = .scan
        } else {
            currentScreen = next
        }
    }

    private func isPaywallScreen(_ screen: OnboardingScreen) -> Bool {
        switch screen {
        case .paywallIntro, .trialReminder, .trialStart, .monthlyFallback:
            return true
        default:
            return false
        }
    }

    public func goBack() {
        if currentScreen == .monthlyFallback {
            currentScreen = .trialStart
            return
        }
        guard let prev = OnboardingScreen(rawValue: currentScreen.rawValue - 1) else { return }
        if prev == .cameraSetup {
            currentScreen = .monthlyFallback
        } else {
            currentScreen = prev
        }
    }

    func jumpTo(_ screen: OnboardingScreen) {
        currentScreen = screen
    }

    public func finishOnboarding() {
        isComplete = true
    }
}
