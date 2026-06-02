import Foundation
import WidgetKit

/// Shared data store for passing app state to widgets via App Group UserDefaults.
/// The main app writes; widget TimelineProvider reads.
public struct WidgetDataStore {
    public static let appGroupID = "group.us.ascend.app"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }

    // MARK: - Keys

    private enum Key {
        static let streak = "widget_streak"
        static let score = "widget_score"
        static let totalScans = "widget_total_scans"
        static let weekEngagement = "widget_week_engagement"  // [Bool] encoded as [Int]
        static let nextMilestone = "widget_next_milestone"
        static let daysUntilMilestone = "widget_days_until_milestone"
        static let streakAtRisk = "widget_streak_at_risk"
        static let lastUpdated = "widget_last_updated"
    }

    // MARK: - Write (called from main app)

    public static func update(
        streak: Int,
        score: Double,
        totalScans: Int,
        weekEngagement: [Bool],
        nextMilestone: Int,
        daysUntilMilestone: Int,
        streakAtRisk: Bool
    ) {
        guard let defaults = defaults else { return }

        defaults.set(streak, forKey: Key.streak)
        defaults.set(score, forKey: Key.score)
        defaults.set(totalScans, forKey: Key.totalScans)
        defaults.set(weekEngagement.map { $0 ? 1 : 0 }, forKey: Key.weekEngagement)
        defaults.set(nextMilestone, forKey: Key.nextMilestone)
        defaults.set(daysUntilMilestone, forKey: Key.daysUntilMilestone)
        defaults.set(streakAtRisk, forKey: Key.streakAtRisk)
        defaults.set(Date().timeIntervalSince1970, forKey: Key.lastUpdated)

        // Tell WidgetKit to refresh
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Read (called from widget)

    public static var streak: Int {
        defaults?.integer(forKey: Key.streak) ?? 0
    }

    public static var score: Double {
        defaults?.double(forKey: Key.score) ?? 0
    }

    public static var totalScans: Int {
        defaults?.integer(forKey: Key.totalScans) ?? 0
    }

    public static var weekEngagement: [Bool] {
        guard let raw = defaults?.array(forKey: Key.weekEngagement) as? [Int] else {
            return Array(repeating: false, count: 7)
        }
        return raw.map { $0 != 0 }
    }

    public static var nextMilestone: Int {
        defaults?.integer(forKey: Key.nextMilestone) ?? 7
    }

    public static var daysUntilMilestone: Int {
        defaults?.integer(forKey: Key.daysUntilMilestone) ?? 7
    }

    public static var streakAtRisk: Bool {
        defaults?.bool(forKey: Key.streakAtRisk) ?? false
    }
}
