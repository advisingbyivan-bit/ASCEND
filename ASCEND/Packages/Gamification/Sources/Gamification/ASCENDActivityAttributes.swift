import ActivityKit
import Foundation

/// Defines the data for the ASCEND Live Activity (Dynamic Island + Lock Screen).
public struct ASCENDActivityAttributes: ActivityAttributes {
    /// Static context that doesn't change during the activity's lifecycle.
    public struct ContentState: Codable, Hashable {
        public var currentStreak: Int
        public var overallScore: Double
        public var nextMilestone: Int      // e.g., 7, 21, 42
        public var daysUntilMilestone: Int
        public var lastScanDate: Date?
        public var streakAtRisk: Bool       // true if user hasn't engaged today
        /// 7 bools for Sun–Sat: true = user engaged that day this week.
        public var weekEngagement: [Bool]

        public init(
            currentStreak: Int,
            overallScore: Double,
            nextMilestone: Int,
            daysUntilMilestone: Int,
            lastScanDate: Date?,
            streakAtRisk: Bool,
            weekEngagement: [Bool] = Array(repeating: false, count: 7)
        ) {
            self.currentStreak = currentStreak
            self.overallScore = overallScore
            self.nextMilestone = nextMilestone
            self.daysUntilMilestone = daysUntilMilestone
            self.lastScanDate = lastScanDate
            self.streakAtRisk = streakAtRisk
            self.weekEngagement = weekEngagement
        }
    }

    /// The user's display name (set once when activity starts).
    public var displayName: String

    public init(displayName: String) {
        self.displayName = displayName
    }
}
