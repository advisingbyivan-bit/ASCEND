import Foundation

/// Manages scan credits — the currency that gates how often users can scan.
///
/// Credit sources:
/// - 1 free scan per week for active subscribers
/// - IAP credit packs (3 / 8 / 20)
/// - XP milestone rewards (Day 7, 21, 42, 90 + every 14-day streak)
///
/// Every scan costs 1 credit. First-ever scan is always free.
@Observable
public final class ScanCreditManager {
    public static let shared = ScanCreditManager()

    // MARK: - Keys

    private enum Keys {
        static let credits = "ascend_scan_credits"
        static let lastFreeReset = "ascend_last_free_credit_date"
        static let totalCreditsEarned = "ascend_total_credits_earned"
        static let totalCreditsSpent = "ascend_total_credits_spent"
        static let milestonesAwarded = "ascend_milestone_credits_awarded"
        static let hasUsedFirstFree = "ascend_first_scan_used"
        static let lastScanTimestamp = "ascend_last_scan_timestamp"
    }

    /// Minimum seconds between scans (1 hour cooldown)
    private static let scanCooldownSeconds: TimeInterval = 3600

    // MARK: - State

    public private(set) var credits: Int {
        get { UserDefaults.standard.integer(forKey: Keys.credits) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.credits) }
    }

    public private(set) var totalEarned: Int {
        get { UserDefaults.standard.integer(forKey: Keys.totalCreditsEarned) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.totalCreditsEarned) }
    }

    public private(set) var totalSpent: Int {
        get { UserDefaults.standard.integer(forKey: Keys.totalCreditsSpent) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.totalCreditsSpent) }
    }

    private var lastFreeResetDate: Date? {
        get { UserDefaults.standard.object(forKey: Keys.lastFreeReset) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lastFreeReset) }
    }

    private var hasUsedFirstFree: Bool {
        get { UserDefaults.standard.bool(forKey: Keys.hasUsedFirstFree) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.hasUsedFirstFree) }
    }

    /// Set of milestone day counts that have already awarded credits
    private var awardedMilestones: Set<Int> {
        get {
            let array = UserDefaults.standard.array(forKey: Keys.milestonesAwarded) as? [Int] ?? []
            return Set(array)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: Keys.milestonesAwarded)
        }
    }

    // MARK: - Computed

    /// Whether the user can perform a scan right now.
    /// Checks both credits and cooldown timer.
    public var canScan: Bool {
        // First scan is always free
        if !hasUsedFirstFree { return true }
        // Must have credits
        guard credits > 0 else { return false }
        // Check cooldown
        return !isOnCooldown
    }

    /// Whether the scan cooldown is active (scanned too recently).
    public var isOnCooldown: Bool {
        guard let lastScan = lastScanTimestamp else { return false }
        return Date().timeIntervalSince(lastScan) < Self.scanCooldownSeconds
    }

    /// Minutes remaining on cooldown, or 0 if none.
    public var cooldownMinutesRemaining: Int {
        guard let lastScan = lastScanTimestamp else { return 0 }
        let elapsed = Date().timeIntervalSince(lastScan)
        let remaining = Self.scanCooldownSeconds - elapsed
        return remaining > 0 ? Int(ceil(remaining / 60)) : 0
    }

    private var lastScanTimestamp: Date? {
        get { UserDefaults.standard.object(forKey: Keys.lastScanTimestamp) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lastScanTimestamp) }
    }

    /// Human-readable credit count for display
    public var displayCredits: String {
        if !hasUsedFirstFree { return "1 FREE" }
        return "\(credits)"
    }

    // MARK: - Init

    private init() {}

    // MARK: - Credit Operations

    /// Consume 1 credit for a scan. Returns true if successful.
    @discardableResult
    public func consumeCredit() -> Bool {
        // First scan is always free
        if !hasUsedFirstFree {
            hasUsedFirstFree = true
            lastScanTimestamp = Date()
            return true
        }

        guard credits > 0, !isOnCooldown else { return false }
        credits -= 1
        totalSpent += 1
        lastScanTimestamp = Date()
        return true
    }

    /// Add credits from any source (IAP, milestone, reward).
    public func addCredits(_ count: Int, source: CreditSource = .other) {
        credits += count
        totalEarned += count
        _lastCreditSource = source
    }

    /// Check and award the weekly free credit for subscribers.
    /// Call this on app launch and after subscription status changes.
    public func checkWeeklyFreeCredit(isSubscriber: Bool) {
        guard isSubscriber else { return }

        let now = Date()
        let calendar = Calendar.current

        if let lastReset = lastFreeResetDate {
            let daysSinceReset = calendar.dateComponents([.day], from: lastReset, to: now).day ?? 0
            if daysSinceReset >= 7 {
                addCredits(1, source: .weeklyFree)
                lastFreeResetDate = now
            }
        } else {
            // First time — grant the weekly free
            addCredits(1, source: .weeklyFree)
            lastFreeResetDate = now
        }
    }

    /// Check and award milestone credits based on current streak.
    /// Returns the number of new credits awarded (0 if none).
    @discardableResult
    public func checkMilestoneRewards(currentStreak: Int) -> Int {
        var awarded = 0
        var milestones = awardedMilestones

        // Fixed milestones: Day 7, 21, 42, 90
        let fixedMilestones: [(day: Int, credits: Int)] = [
            (7, 1),
            (21, 1),
            (42, 1),
            (90, 2),
        ]

        for milestone in fixedMilestones {
            if currentStreak >= milestone.day && !milestones.contains(milestone.day) {
                addCredits(milestone.credits, source: .milestone)
                milestones.insert(milestone.day)
                awarded += milestone.credits
            }
        }

        // Recurring: +1 credit every 14-day streak (starting at day 14)
        // Award at 14, 28, 42 (already handled above so skip), 56, 70, 84, 98, ...
        let streakInterval = 14
        var day = streakInterval
        while day <= currentStreak {
            // Skip if already awarded via fixed milestones (day 42 overlap)
            if !milestones.contains(1000 + day) { // Use 1000+day offset for recurring
                addCredits(1, source: .streakBonus)
                milestones.insert(1000 + day)
                awarded += 1
            }
            day += streakInterval
        }

        awardedMilestones = milestones
        return awarded
    }

    /// Reset all credit data (for account deletion).
    public func reset() {
        credits = 0
        totalEarned = 0
        totalSpent = 0
        lastFreeResetDate = nil
        hasUsedFirstFree = false
        awardedMilestones = []
    }

    // MARK: - Internal

    private var _lastCreditSource: CreditSource = .other
    public var lastCreditSource: CreditSource { _lastCreditSource }
}

// MARK: - Credit Source

public enum CreditSource: String {
    case weeklyFree = "weekly_free"
    case iapSmall = "iap_small"     // 3 credits
    case iapMedium = "iap_medium"   // 8 credits
    case iapLarge = "iap_large"     // 20 credits
    case milestone = "milestone"
    case streakBonus = "streak_bonus"
    case other = "other"
}

// MARK: - Credit Pack Definitions

public enum CreditPack: String, CaseIterable, Identifiable {
    case small = "us.ascendapp.credits.3"
    case medium = "us.ascendapp.credits.8"
    case large = "us.ascendapp.credits.20"

    public var id: String { rawValue }

    public var creditCount: Int {
        switch self {
        case .small: 3
        case .medium: 8
        case .large: 20
        }
    }

    public var displayPrice: String {
        switch self {
        case .small: "$2.99"
        case .medium: "$5.99"
        case .large: "$9.99"
        }
    }

    public var pricePerScan: String {
        switch self {
        case .small: "$1.00/scan"
        case .medium: "$0.75/scan"
        case .large: "$0.50/scan"
        }
    }

    public var source: CreditSource {
        switch self {
        case .small: .iapSmall
        case .medium: .iapMedium
        case .large: .iapLarge
        }
    }

    /// Whether this is the "best value" pack (used for UI highlighting)
    public var isBestValue: Bool {
        self == .large
    }

    /// Whether this is the decoy pack
    public var isDecoy: Bool {
        self == .medium
    }

    public var savingsLabel: String? {
        switch self {
        case .small: nil
        case .medium: "Save 25%"
        case .large: "BEST VALUE - Save 50%"
        }
    }
}
