import Foundation
import DesignSystem

@Observable
public final class StreakManager {
    public static let shared = StreakManager()

    public private(set) var currentStreak: Int {
        didSet { UserDefaults.standard.set(currentStreak, forKey: "ascend_streak") }
    }
    public private(set) var longestStreak: Int {
        didSet { UserDefaults.standard.set(longestStreak, forKey: "ascend_longest_streak") }
    }
    public private(set) var totalDiamonds: Int {
        didSet { UserDefaults.standard.set(totalDiamonds, forKey: "ascend_diamonds") }
    }

    /// Last date the user did ANY engagement (scan, workout, weight check-in).
    public private(set) var lastEngagementDate: Date? {
        didSet {
            if let date = lastEngagementDate {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "ascend_last_engagement")
            }
        }
    }

    /// Legacy: last scan date. Still tracked for scan-specific features.
    public private(set) var lastScanDate: Date? {
        didSet {
            if let date = lastScanDate {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "ascend_last_scan")
            }
        }
    }

    /// Whether the user has engaged today (scan, workout, etc.)
    public var hasEngagedToday: Bool {
        guard let last = lastEngagementDate else { return false }
        return Calendar.current.isDateInToday(last)
    }

    private init() {
        currentStreak = UserDefaults.standard.integer(forKey: "ascend_streak")
        longestStreak = UserDefaults.standard.integer(forKey: "ascend_longest_streak")
        totalDiamonds = UserDefaults.standard.integer(forKey: "ascend_diamonds")

        // Load last scan date
        let scanTS = UserDefaults.standard.double(forKey: "ascend_last_scan")
        lastScanDate = scanTS > 0 ? Date(timeIntervalSince1970: scanTS) : nil

        // Load last engagement date — migrate from scan date if needed
        let engTS = UserDefaults.standard.double(forKey: "ascend_last_engagement")
        if engTS > 0 {
            lastEngagementDate = Date(timeIntervalSince1970: engTS)
        } else if let scanDate = lastScanDate {
            // First launch with engagement tracking — migrate from scan history
            lastEngagementDate = scanDate
            UserDefaults.standard.set(scanDate.timeIntervalSince1970, forKey: "ascend_last_engagement")
        } else {
            lastEngagementDate = nil
        }
    }

    // MARK: - Engagement (any daily activity)

    /// Record any engagement activity (workout, weight check-in, etc.)
    /// Updates the streak based on consecutive daily engagement.
    /// Returns a ScanReward (diamonds/milestones still fire from engagement streaks).
    public func recordEngagement() -> ScanReward {
        let today = Calendar.current.startOfDay(for: Date())
        let wasConsecutive: Bool

        if let last = lastEngagementDate {
            let lastDay = Calendar.current.startOfDay(for: last)
            let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if diff == 0 {
                return .alreadyEngaged
            } else if diff == 1 {
                wasConsecutive = true
            } else {
                wasConsecutive = false
            }
        } else {
            wasConsecutive = false
        }

        lastEngagementDate = Date()

        if wasConsecutive {
            currentStreak += 1
        } else {
            currentStreak = 1
        }

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        let milestone = DiamondMilestone.check(streak: currentStreak)
        if milestone != nil {
            totalDiamonds += 1
        }

        let reward = RewardDispatcher.evaluate(streak: currentStreak, milestone: milestone)
        return reward
    }

    // MARK: - Scan (also records engagement)

    /// Record a scan — updates both scan date and engagement streak.
    public func recordScan() -> ScanReward {
        lastScanDate = Date()
        return recordEngagement()
    }

    public var streakTier: StreakTier {
        StreakTier.from(currentStreak)
    }
}

public enum ScanReward: Equatable {
    case alreadyEngaged    // Already checked in today
    case alreadyScanned    // Legacy alias
    case standard
    case bonus
    case mega(DiamondMilestone)

    /// Backward compatibility — treat both "already" cases the same
    public var isAlready: Bool {
        self == .alreadyEngaged || self == .alreadyScanned
    }
}

public enum StreakTier {
    case none      // 0
    case bronze    // 1-7
    case silver    // 8-21
    case gold      // 22+

    public static func from(_ streak: Int) -> StreakTier {
        switch streak {
        case 0: .none
        case 1...7: .bronze
        case 8...21: .silver
        default: .gold
        }
    }

    public var color: Color {
        switch self {
        case .none: Color.ds_textSecondary
        case .bronze: Color.ds_yellow
        case .silver: Color.ds_cyan
        case .gold: Color.ds_gold
        }
    }
}
