import ActivityKit
import Foundation
import Gamification

/// Manages the ASCEND Live Activity for Dynamic Island and Lock Screen.
/// Shows streak progress, score, and days until next diamond milestone.
@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()
    private init() {}

    private(set) var currentActivity: Activity<ASCENDActivityAttributes>?

    /// Whether there's an active Live Activity running.
    var hasActiveActivity: Bool { currentActivity != nil }

    /// Whether Live Activities are supported on this device.
    var isSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    // MARK: - Start

    /// Start a new Live Activity displaying streak progress.
    func start(
        displayName: String,
        streak: Int,
        score: Double,
        nextMilestone: Int,
        daysUntilMilestone: Int,
        lastScanDate: Date?,
        weekEngagement: [Bool] = Array(repeating: false, count: 7)
    ) {
        guard isSupported else {
            print("[LiveActivity] Not supported on this device")
            return
        }

        // Capture existing activities BEFORE creating the new one.
        // This avoids a race condition where an async endAll() could
        // kill the newly created activity or nil-out currentActivity.
        let existingActivities = Activity<ASCENDActivityAttributes>.activities

        let attributes = ASCENDActivityAttributes(displayName: displayName)
        let state = ASCENDActivityAttributes.ContentState(
            currentStreak: streak,
            overallScore: score,
            nextMilestone: nextMilestone,
            daysUntilMilestone: daysUntilMilestone,
            lastScanDate: lastScanDate,
            streakAtRisk: false,
            weekEngagement: weekEngagement
        )

        let content = ActivityContent(state: state, staleDate: Calendar.current.date(byAdding: .hour, value: 12, to: Date()))

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil  // Local updates only for now
            )
            print("[LiveActivity] Started — streak: \(streak), score: \(score)")

            // Now end old activities (the snapshot was taken before we created the new one)
            for activity in existingActivities {
                Task { await activity.end(nil, dismissalPolicy: .immediate) }
            }
        } catch {
            print("[LiveActivity] Failed to start: \(error.localizedDescription)")
        }
    }

    // MARK: - Update

    /// Update the Live Activity with new streak/score data.
    func update(
        streak: Int,
        score: Double,
        nextMilestone: Int,
        daysUntilMilestone: Int,
        lastScanDate: Date?,
        streakAtRisk: Bool = false,
        weekEngagement: [Bool] = Array(repeating: false, count: 7)
    ) {
        guard let activity = currentActivity else { return }

        let state = ASCENDActivityAttributes.ContentState(
            currentStreak: streak,
            overallScore: score,
            nextMilestone: nextMilestone,
            daysUntilMilestone: daysUntilMilestone,
            lastScanDate: lastScanDate,
            streakAtRisk: streakAtRisk,
            weekEngagement: weekEngagement
        )

        let content = ActivityContent(state: state, staleDate: Calendar.current.date(byAdding: .hour, value: 12, to: Date()))

        Task {
            await activity.update(content)
        }
    }

    // MARK: - End

    /// End the current Live Activity.
    func end() {
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }

    /// End all ASCEND Live Activities.
    func endAll() {
        // Clear reference synchronously so callers see the state change immediately
        currentActivity = nil
        Task {
            for activity in Activity<ASCENDActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
