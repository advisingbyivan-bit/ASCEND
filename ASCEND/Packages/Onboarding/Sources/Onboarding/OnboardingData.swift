import Foundation
import UIKit
import BodyModel3D
import Diagnostics

public struct OnboardingData {
    public var gender: BodyGender = .male
    public var age: Int = 25
    public var heightCm: Int = 175
    public var weightKg: Double = 75
    public var goalWeight: Double = 72
    public var bodyConcerns: [BodyZone] = []
    public var trainingFrequency: TrainingFrequency = .moderate
    public var timeline: GoalTimeline = .weeks12
    public var scanDay: Weekday = .sunday
    public var restDay: Weekday = .wednesday
    public var notificationHour: Int = 8
    public var notificationMinute: Int = 0

    // Cal-style flow: Blockers & Goals
    public var selectedBlocker: CalBlocker?
    public var selectedGoal: CalGoal?
    public var healthKitGranted = false
    public var notificationsGranted = false

    // Account (populated by Sign in with Apple/Google/Email)
    public var appleUserID: String?
    public var accountDisplayName: String?
    public var accountEmail: String?
    public var authToken: String?
    public var isReturningUser: Bool = false

    // Scan (captured during onboarding)
    public var scanPhotos: [UIImage] = []
    public var diagnosisResult: DiagnosisResult?

    // Feature flags (set by host app)
    public var googleSignInEnabled = false

    // Paywall
    public var didPurchase = false

    public init() {}
}

public enum TrainingFrequency: String, CaseIterable, Identifiable {
    case sedentary = "Sedentary"
    case light = "1-2x / week"
    case moderate = "3-4x / week"
    case active = "5-6x / week"
    case athlete = "Daily"

    public var id: String { rawValue }
}

public enum GoalTimeline: String, CaseIterable, Identifiable {
    case weeks4 = "4 Weeks"
    case weeks8 = "8 Weeks"
    case weeks12 = "12 Weeks"
    case weeks24 = "24 Weeks"
    case noRush = "No Rush"

    public var id: String { rawValue }
}

public enum Weekday: String, CaseIterable, Identifiable {
    case sunday = "Sunday"
    case monday = "Monday"
    case tuesday = "Tuesday"
    case wednesday = "Wednesday"
    case thursday = "Thursday"
    case friday = "Friday"
    case saturday = "Saturday"

    public var id: String { rawValue }
}
