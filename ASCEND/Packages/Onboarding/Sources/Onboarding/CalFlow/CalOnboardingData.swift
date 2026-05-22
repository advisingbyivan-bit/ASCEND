import Foundation
import UIKit
import Diagnostics

public struct CalOnboardingData {
    // Screen 2: Blockers
    public var selectedBlocker: CalBlocker?

    // Screen 3: Goals
    public var selectedGoal: CalGoal?

    // Apple Health
    public var healthKitGranted = false

    // Notifications
    public var notificationsGranted = false

    // Account
    public var appleUserID: String?
    public var accountDisplayName: String?
    public var accountEmail: String?

    // Scan (from body scan integration)
    public var scanPhotos: [UIImage] = []
    public var diagnosisResult: DiagnosisResult?

    // Paywall
    public var selectedPlan: CalPlan = .yearly
    public var didPurchase = false

    public init() {}
}

public enum CalBlocker: String, CaseIterable, Identifiable {
    case consistency = "Lack of consistency"
    case noDirection = "No clear direction"
    case lowMotivation = "Low motivation"
    case distractions = "Too many distractions"
    case dontKnow = "Don't know where to start"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .consistency: "chart.bar.fill"
        case .noDirection: "location.slash.fill"
        case .lowMotivation: "flame.fill"
        case .distractions: "iphone.gen3"
        case .dontKnow: "questionmark.circle.fill"
        }
    }
}

public enum CalGoal: String, CaseIterable, Identifiable {
    case habits = "Build better habits"
    case energy = "Boost focus and energy"
    case accountable = "Stay accountable to my goals"
    case grow = "Grow in all areas of life"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .habits: "checkmark.circle.fill"
        case .energy: "bolt.fill"
        case .accountable: "target"
        case .grow: "arrow.up.right"
        }
    }
}

public enum CalPlan: String, Identifiable {
    case monthly = "Monthly"
    case yearly = "Yearly"

    public var id: String { rawValue }
}
