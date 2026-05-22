import Foundation

public enum DiamondMilestone: Int, CaseIterable, Identifiable {
    case day7 = 7
    case day21 = 21
    case day42 = 42
    case day90 = 90
    case day365 = 365

    public var id: Int { rawValue }

    public var displayName: String {
        "Day \(rawValue)"
    }

    public var description: String {
        switch self {
        case .day7: "First Week Warrior"
        case .day21: "Habit Formed"
        case .day42: "Unstoppable"
        case .day90: "Quarterly Crusher"
        case .day365: "Year of Iron"
        }
    }

    public static func check(streak: Int) -> DiamondMilestone? {
        allCases.first { $0.rawValue == streak }
    }

    public static func earned(forStreak streak: Int) -> [DiamondMilestone] {
        allCases.filter { $0.rawValue <= streak }
    }

    public static func next(forStreak streak: Int) -> DiamondMilestone? {
        allCases.first { $0.rawValue > streak }
    }
}
