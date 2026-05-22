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
    public private(set) var lastScanDate: Date? {
        didSet {
            if let date = lastScanDate {
                UserDefaults.standard.set(date.timeIntervalSince1970, forKey: "ascend_last_scan")
            }
        }
    }

    private init() {
        currentStreak = UserDefaults.standard.integer(forKey: "ascend_streak")
        longestStreak = UserDefaults.standard.integer(forKey: "ascend_longest_streak")
        totalDiamonds = UserDefaults.standard.integer(forKey: "ascend_diamonds")
        let ts = UserDefaults.standard.double(forKey: "ascend_last_scan")
        lastScanDate = ts > 0 ? Date(timeIntervalSince1970: ts) : nil
    }

    public func recordScan() -> ScanReward {
        let today = Calendar.current.startOfDay(for: Date())
        let wasConsecutive: Bool

        if let last = lastScanDate {
            let lastDay = Calendar.current.startOfDay(for: last)
            let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if diff == 0 {
                return .alreadyScanned
            } else if diff == 1 {
                wasConsecutive = true
            } else {
                wasConsecutive = false
            }
        } else {
            wasConsecutive = false
        }

        lastScanDate = Date()

        if wasConsecutive {
            currentStreak += 1
        } else {
            currentStreak = 1
        }

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        let milestone = DiamondMilestone.check(streak: currentStreak)
        if let milestone {
            totalDiamonds += 1
        }

        let reward = RewardDispatcher.evaluate(streak: currentStreak, milestone: milestone)
        return reward
    }

    public var streakTier: StreakTier {
        StreakTier.from(currentStreak)
    }
}

public enum ScanReward: Equatable {
    case alreadyScanned
    case standard
    case bonus
    case mega(DiamondMilestone)
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
