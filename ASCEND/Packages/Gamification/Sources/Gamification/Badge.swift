import SwiftUI
import DesignSystem

public struct Badge: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let icon: String
    public let requirement: String
    public let isEarned: Bool

    public init(id: String, name: String, icon: String, requirement: String, isEarned: Bool) {
        self.id = id
        self.name = name
        self.icon = icon
        self.requirement = requirement
        self.isEarned = isEarned
    }

    public static func allBadges(streak: Int, totalScans: Int) -> [Badge] {
        [
            Badge(id: "streak_7", name: "7-Day Streak", icon: "flame.fill", requirement: "Scan 7 days in a row", isEarned: streak >= 7),
            Badge(id: "iris_trusted_30", name: "IRIS Trusted", icon: "eye.fill", requirement: "30-day streak", isEarned: streak >= 30),
            Badge(id: "iris_trusted_90", name: "IRIS Veteran", icon: "eye.trianglebadge.exclamationmark", requirement: "90-day streak", isEarned: streak >= 90),
            Badge(id: "iris_trusted_365", name: "IRIS Legend", icon: "crown.fill", requirement: "365-day streak", isEarned: streak >= 365),
            Badge(id: "goal_crusher", name: "Goal Crusher", icon: "target", requirement: "Complete 5 scans", isEarned: totalScans >= 5),
            Badge(id: "rising_challenger", name: "Rising Challenger", icon: "chart.line.uptrend.xyaxis", requirement: "14-day streak", isEarned: streak >= 14),
            Badge(id: "consistency_king", name: "Consistency King", icon: "person.2.fill", requirement: "Complete 20 scans", isEarned: totalScans >= 20),
            Badge(id: "champion", name: "Champion", icon: "trophy.fill", requirement: "42-day streak", isEarned: streak >= 42),
            Badge(id: "first_scan", name: "First Scan", icon: "viewfinder", requirement: "Complete your first scan", isEarned: totalScans >= 1),
            Badge(id: "scanner_10", name: "Dedicated Scanner", icon: "repeat", requirement: "Complete 10 scans", isEarned: totalScans >= 10),
        ]
    }
}

public struct BadgeView: View {
    let badge: Badge
    let size: CGFloat

    public init(badge: Badge, size: CGFloat = 48) {
        self.badge = badge
        self.size = size
    }

    public var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(badge.isEarned ? Color.ds_cyan.opacity(0.2) : Color.ds_charcoal)
                    .frame(width: size, height: size)

                Image(systemName: badge.icon)
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(badge.isEarned ? Color.ds_cyan : Color.ds_textSecondary.opacity(0.3))
            }

            Text(badge.name)
                .font(DSFont.micro)
                .foregroundStyle(badge.isEarned ? Color.ds_textPrimary : Color.ds_textSecondary.opacity(0.5))
                .multilineTextAlignment(.center)
                .frame(width: size + 16)
        }
    }
}
