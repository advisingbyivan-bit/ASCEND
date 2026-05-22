import Foundation

// MARK: - Analytics Event Tracking
// Lightweight local analytics buffer. Events are stored locally and can be
// forwarded to Mixpanel, Amplitude, or any backend when integrated.

enum AnalyticsEvent: String {
    // Onboarding funnel
    case onboarding_started = "onboarding_started"
    case onboarding_gender = "onboarding_gender"
    case onboarding_age_height = "onboarding_age_height"
    case onboarding_weight_goal = "onboarding_weight_goal"
    case onboarding_concerns = "onboarding_concerns"
    case onboarding_frequency = "onboarding_frequency"
    case onboarding_timeline = "onboarding_timeline"
    case onboarding_preferences = "onboarding_preferences"
    case onboarding_account_created = "onboarding_account_created"
    case onboarding_account_skipped = "onboarding_account_skipped"
    case onboarding_iris_intro = "onboarding_iris_intro"
    case onboarding_camera_setup = "onboarding_camera_setup"
    case onboarding_scan_started = "onboarding_scan_started"
    case onboarding_scan_completed = "onboarding_scan_completed"
    case onboarding_scan_skipped = "onboarding_scan_skipped"
    case onboarding_diagnosis_viewed = "onboarding_diagnosis_viewed"
    case onboarding_goal_confirmed = "onboarding_goal_confirmed"
    case onboarding_paywall_shown = "onboarding_paywall_shown"
    case onboarding_paywall_purchased = "onboarding_paywall_purchased"
    case onboarding_paywall_skipped = "onboarding_paywall_skipped"
    case onboarding_completed = "onboarding_completed"

    // Core actions
    case scan_started = "scan_started"
    case scan_photo_captured = "scan_photo_captured"
    case scan_completed = "scan_completed"
    case diagnosis_requested = "diagnosis_requested"
    case diagnosis_received = "diagnosis_received"
    case diagnosis_reveal_completed = "diagnosis_reveal_completed"

    // Engagement
    case app_opened = "app_opened"
    case app_backgrounded = "app_backgrounded"
    case tab_switched = "tab_switched"
    case iris_message_viewed = "iris_message_viewed"
    case body_model_interacted = "body_model_interacted"
    case leaderboard_viewed = "leaderboard_viewed"
    case progress_viewed = "progress_viewed"
    case profile_viewed = "profile_viewed"

    // Gamification
    case streak_continued = "streak_continued"
    case streak_broken = "streak_broken"
    case diamond_earned = "diamond_earned"
    case badge_earned = "badge_earned"
    case reward_standard = "reward_standard"
    case reward_bonus = "reward_bonus"
    case reward_mega = "reward_mega"

    // Monetization
    case paywall_shown = "paywall_shown"
    case purchase_started = "purchase_started"
    case purchase_completed = "purchase_completed"
    case purchase_failed = "purchase_failed"
    case purchase_cancelled = "purchase_cancelled"
    case restore_started = "restore_started"
    case restore_completed = "restore_completed"
    case credits_earned = "credits_earned"
    case credits_purchased = "credits_purchased"
    case credit_consumed = "credit_consumed"

    // Retention
    case notification_scheduled = "notification_scheduled"
    case notification_received = "notification_received"
    case notification_opened = "notification_opened"
    case data_exported = "data_exported"
    case account_deleted = "account_deleted"
    case sign_out = "sign_out"
}

final class AnalyticsService {
    static let shared = AnalyticsService()

    private let queue = DispatchQueue(label: "com.ascend.analytics", qos: .utility)
    private var eventBuffer: [[String: Any]] = []
    private let maxBufferSize = 500
    private let bufferKey = "ascend_analytics_buffer"

    private init() {
        // Load any persisted events from last session
        if let data = UserDefaults.standard.data(forKey: bufferKey),
           let events = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            eventBuffer = events
        }
    }

    // MARK: - Track Events

    func track(_ event: AnalyticsEvent, properties: [String: Any]? = nil) {
        queue.async { [weak self] in
            guard let self else { return }

            var eventData: [String: Any] = [
                "event": event.rawValue,
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "session_id": Self.sessionID
            ]

            if let properties {
                eventData["properties"] = properties
            }

            self.eventBuffer.append(eventData)

            // Trim buffer if needed
            if self.eventBuffer.count > self.maxBufferSize {
                self.eventBuffer = Array(self.eventBuffer.suffix(self.maxBufferSize))
            }

            // Persist to disk
            self.persistBuffer()
        }
    }

    func track(_ event: AnalyticsEvent, _ key: String, _ value: Any) {
        track(event, properties: [key: value])
    }

    // MARK: - Funnel Tracking

    func trackOnboardingStep(_ step: Int, screenName: String) {
        track(.onboarding_started, properties: [
            "step": step,
            "screen": screenName,
            "funnel": "onboarding"
        ])
    }

    func trackScanFunnel(angle: String, photoNumber: Int) {
        track(.scan_photo_captured, properties: [
            "angle": angle,
            "photo_number": photoNumber,
            "funnel": "scan"
        ])
    }

    // MARK: - Export (for Mixpanel/backend integration)

    func exportEvents() -> [[String: Any]] {
        queue.sync { eventBuffer }
    }

    func exportEventsJSON() -> Data? {
        queue.sync {
            try? JSONSerialization.data(withJSONObject: eventBuffer, options: .prettyPrinted)
        }
    }

    func clearBuffer() {
        queue.async { [weak self] in
            self?.eventBuffer = []
            UserDefaults.standard.removeObject(forKey: self?.bufferKey ?? "")
        }
    }

    // MARK: - Private

    private func persistBuffer() {
        if let data = try? JSONSerialization.data(withJSONObject: eventBuffer) {
            UserDefaults.standard.set(data, forKey: bufferKey)
        }
    }

    private static var sessionID: String = {
        UUID().uuidString.prefix(8).lowercased()
    }()

    // MARK: - Debug

    var eventCount: Int {
        queue.sync { eventBuffer.count }
    }
}
