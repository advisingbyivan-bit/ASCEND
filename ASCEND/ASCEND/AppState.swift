import SwiftUI
import Gamification
import Persistence
import Notifications
import BodyModel3D
import Diagnostics
import Paywall

/// Central app state that bridges all modules together.
/// Injected as @Environment into the view hierarchy.
@Observable
@MainActor
public final class AppState {

    // MARK: - Streak & Gamification
    var currentStreak: Int { StreakManager.shared.currentStreak }
    var longestStreak: Int { StreakManager.shared.longestStreak }
    var totalDiamonds: Int { StreakManager.shared.totalDiamonds }
    var streakTier: StreakTier { StreakManager.shared.streakTier }
    var lastScanDate: Date? { StreakManager.shared.lastScanDate }

    // MARK: - Profile
    var displayName: String = ""
    var gender: BodyGender = .male
    var memberSince: Date = Date()
    var scanDay: String = "Sunday"
    var restDay: String = "Wednesday"
    var notificationHour: Int = 8

    // MARK: - Scan History
    var totalScans: Int = 0
    var latestDiagnosis: DiagnosisResult?
    var weeklyScans: Int = 0
    /// Weekday indices (1=Sun, 2=Mon, …, 7=Sat) that had scans this week
    var scanWeekdays: Set<Int> = []
    /// All scan records for progress photo history
    var scanHistory: [ScanSnapshot] = []

    // MARK: - Scan Credits
    var scanCredits: Int { ScanCreditManager.shared.credits }
    var canScan: Bool { ScanCreditManager.shared.canScan }
    var scanCreditsDisplay: String { ScanCreditManager.shared.displayCredits }

    // MARK: - Celebration State
    var pendingCelebration: DiamondMilestone?
    var showCelebration = false

    // MARK: - Computed
    var hasCompletedFirstScan: Bool { totalScans > 0 }

    var badges: [Badge] {
        Badge.allBadges(streak: currentStreak, totalScans: totalScans)
    }

    var earnedBadgeCount: Int {
        badges.filter(\.isEarned).count
    }

    var nextMilestone: DiamondMilestone? {
        DiamondMilestone.next(forStreak: currentStreak)
    }

    var daysUntilNextMilestone: Int? {
        guard let next = nextMilestone else { return nil }
        return next.rawValue - currentStreak
    }

    var weekNumber: Int {
        let days = Calendar.current.dateComponents([.day], from: memberSince, to: Date()).day ?? 0
        return max(1, (days / 7) + 1)
    }

    // MARK: - Init

    init() {
        // Defer heavy data loading so the UI renders immediately.
        // loadProfile and loadScanData will be called from onAppear.
    }

    /// Call once from the root view's onAppear to load persisted data.
    /// Runs data loading in a detached task so the first frame renders immediately.
    func bootstrap() {
        guard !_hasBootstrapped else { return }
        _hasBootstrapped = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.loadProfile()
            self.loadScanData()
            self.checkStreakDanger()

            // Check weekly free credit for subscribers
            let isSubscriber = SubscriptionManager.shared.isPremium
            ScanCreditManager.shared.checkWeeklyFreeCredit(isSubscriber: isSubscriber)

            // Check milestone credit rewards
            ScanCreditManager.shared.checkMilestoneRewards(currentStreak: self.currentStreak)
        }
    }

    private var _hasBootstrapped = false

    // MARK: - Data Loading

    func loadProfile() {
        do {
            if let profile = try DataStore.shared.fetchProfile() {
                displayName = profile.displayName
                gender = profile.gender == "female" ? .female : .male
                memberSince = profile.createdAt
                scanDay = profile.scanDay
                restDay = profile.restDay
                notificationHour = profile.notificationHour
            }
        } catch {
            // Use defaults
        }
    }

    func loadScanData() {
        do {
            let scans = try DataStore.shared.fetchScans()
            totalScans = scans.count

            // Count scans this week & record which weekdays had scans
            let startOfWeek = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            let thisWeekScans = scans.filter { $0.date >= startOfWeek }
            weeklyScans = thisWeekScans.count
            scanWeekdays = Set(thisWeekScans.map { Calendar.current.component(.weekday, from: $0.date) })

            // Load latest diagnosis
            if let latest = scans.first, let _ = latest.zoneData {
                latestDiagnosis = decodeDiagnosis(from: latest)
            } else {
                // Show baseline so dashboard isn't empty before first scan
                latestDiagnosis = DiagnosisResult.baseline
            }

            // Build scan history for progress photos
            scanHistory = scans.map { record in
                ScanSnapshot(
                    id: record.id,
                    date: record.date,
                    score: record.overallScore,
                    frontImage: record.frontImageData.flatMap { UIImage(data: $0) },
                    sideImage: record.sideImageData.flatMap { UIImage(data: $0) },
                    backImage: record.backImageData.flatMap { UIImage(data: $0) }
                )
            }
        } catch {
            totalScans = 0
            weeklyScans = 0
            latestDiagnosis = DiagnosisResult.baseline
            scanHistory = []
        }
    }

    // MARK: - Actions

    /// Attempt to consume a scan credit before starting the scan.
    /// Returns true if credit consumed (or first scan free). False if no credits.
    func tryScanCredit() -> Bool {
        return ScanCreditManager.shared.consumeCredit()
    }

    /// Called after a scan completes and diagnosis is received.
    func completeScan(photos: [UIImage], diagnosis: DiagnosisResult) {
        // Record streak
        let reward = StreakManager.shared.recordScan()

        // Check for new milestone credits earned from the streak
        let newCredits = ScanCreditManager.shared.checkMilestoneRewards(currentStreak: currentStreak)
        if newCredits > 0 {
            AnalyticsService.shared.track(.credits_earned, properties: [
                "amount": newCredits,
                "source": "milestone",
                "streak": currentStreak
            ])
        }

        // Save to persistence
        let record = ScanRecord(
            overallScore: diagnosis.overallScore,
            irisMessage: diagnosis.irisMessage,
            zoneData: encodeDiagnosis(diagnosis)
        )

        // Attach photo data (compressed for storage)
        if photos.count >= 1 { record.frontImageData = photos[0].jpegData(compressionQuality: 0.6) }
        if photos.count >= 2 { record.sideImageData = photos[1].jpegData(compressionQuality: 0.6) }
        if photos.count >= 3 { record.backImageData = photos[2].jpegData(compressionQuality: 0.6) }

        do {
            try DataStore.shared.saveScan(record)
        } catch {
            // Silent fail — data still shows in current session
        }

        // Update local state
        totalScans += 1
        weeklyScans += 1
        latestDiagnosis = diagnosis
        scanWeekdays.insert(Calendar.current.component(.weekday, from: Date()))

        // Add to scan history immediately
        let snapshot = ScanSnapshot(
            id: record.id,
            date: record.date,
            score: diagnosis.overallScore,
            frontImage: photos.count >= 1 ? photos[0] : nil,
            sideImage: photos.count >= 2 ? photos[1] : nil,
            backImage: photos.count >= 3 ? photos[2] : nil
        )
        scanHistory.insert(snapshot, at: 0)

        // Check for newly earned badges and fire notifications
        checkBadgeUnlocks()

        // Analytics
        AnalyticsService.shared.track(.scan_completed, properties: [
            "score": diagnosis.overallScore,
            "streak": currentStreak,
            "total_scans": totalScans
        ])

        // Handle reward
        switch reward {
        case .mega(let milestone):
            pendingCelebration = milestone
            showCelebration = true
            NotificationScheduler.shared.scheduleDiamondCelebration(milestone: milestone.displayName)
            AnalyticsService.shared.track(.diamond_earned, "milestone", milestone.displayName)
        case .bonus:
            AnalyticsService.shared.track(.reward_bonus)
        case .standard:
            AnalyticsService.shared.track(.streak_continued, "day", currentStreak)
        case .alreadyScanned:
            break
        }

        // Schedule encouragement notifications based on streak progress
        scheduleStreakNotifications()
    }

    /// Schedule contextual notifications based on current streak day.
    /// Drives the Day 3/4/5/6/7 encouragement series, post-Day-7 momentum,
    /// and streak danger alerts.
    private func scheduleStreakNotifications() {
        let streak = currentStreak

        // Clear any stale streak-danger notifications — user just scanned
        NotificationScheduler.shared.cancel(identifier: "streak_danger")

        // Schedule next-day encouragement based on streak phase
        switch streak {
        case 1...2:
            // Building toward Day 3
            NotificationScheduler.shared.scheduleEncouragement(afterDays: 3 - streak)
        case 3:
            NotificationScheduler.shared.scheduleEncouragement(afterDays: 1)
        case 4:
            NotificationScheduler.shared.scheduleEncouragement(afterDays: 1)
        case 5:
            NotificationScheduler.shared.scheduleEncouragement(afterDays: 1)
        case 6:
            // Tomorrow is Day 7 diamond — schedule urgent reminder
            NotificationScheduler.shared.scheduleEncouragement(afterDays: 1)
        default:
            // Post-Day-7: keep the momentum going with periodic encouragement
            if streak > 7 {
                // Schedule encouragement 1 day out to maintain daily engagement
                NotificationScheduler.shared.scheduleEncouragement(afterDays: 1)
            }
        }
    }

    /// Save user profile from onboarding data
    func saveOnboardingProfile(
        displayName: String,
        gender: String,
        age: Int,
        heightCm: Int,
        weightKg: Double,
        goalWeightKg: Double,
        bodyConcerns: String,
        trainingFrequency: String,
        timeline: String,
        scanDay: String,
        restDay: String,
        notificationHour: Int
    ) {
        let profile = UserProfile(
            displayName: displayName,
            gender: gender,
            age: age,
            heightCm: heightCm,
            weightKg: weightKg,
            goalWeightKg: goalWeightKg,
            bodyConcerns: bodyConcerns,
            trainingFrequency: trainingFrequency,
            timeline: timeline,
            scanDay: scanDay,
            restDay: restDay,
            notificationHour: notificationHour
        )

        do {
            try DataStore.shared.saveProfile(profile)
        } catch {
            // Silent
        }

        // Update local state
        self.displayName = displayName
        self.gender = gender == "female" ? .female : .male
        self.scanDay = scanDay
        self.restDay = restDay
        self.notificationHour = notificationHour
        self.memberSince = Date()

        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "ascend_last_weight_update")
        UserDefaults.standard.set(notificationHour, forKey: "ascend_notification_hour")

        // Schedule notifications
        let weekdayInt = weekdayNumber(from: scanDay)
        let restWeekdayInt = weekdayNumber(from: restDay)
        NotificationScheduler.shared.scheduleWeeklyScanReminder(weekday: weekdayInt, hour: notificationHour, minute: 0)
        NotificationScheduler.shared.scheduleMidWeekCheckIn(hour: notificationHour, weekday: restWeekdayInt)
    }

    /// Check if any badges were newly earned and fire unlock notifications.
    /// Compares current earned badges against previously-seen set stored in UserDefaults.
    private func checkBadgeUnlocks() {
        let currentBadges = badges
        let earnedIDs = Set(currentBadges.filter(\.isEarned).map(\.id))
        let previouslyEarnedIDs = Set(UserDefaults.standard.stringArray(forKey: "ascend_earned_badges") ?? [])

        let newlyEarned = earnedIDs.subtracting(previouslyEarnedIDs)
        for badgeID in newlyEarned {
            if let badge = currentBadges.first(where: { $0.id == badgeID }) {
                NotificationScheduler.shared.scheduleBadgeUnlock(badgeName: badge.name)
            }
        }

        // Persist updated set
        if !newlyEarned.isEmpty {
            UserDefaults.standard.set(Array(earnedIDs), forKey: "ascend_earned_badges")
        }
    }

    func updateWeight(_ weightKg: Double) {
        do {
            try DataStore.shared.updateProfileWeight(weightKg)
        } catch {}
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "ascend_last_weight_update")
    }

    /// Dismiss diamond celebration
    func dismissCelebration() {
        showCelebration = false
        pendingCelebration = nil
    }

    /// Check if streak is in danger and schedule notification
    func checkStreakDanger() {
        guard currentStreak > 0 else { return }
        guard let last = lastScanDate else { return }
        let today = Calendar.current.startOfDay(for: Date())
        let lastDay = Calendar.current.startOfDay(for: last)
        let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0

        // If user hasn't scanned today and has an active streak, schedule danger notification at 8pm
        if diff >= 1 {
            Task {
                await NotificationScheduler.shared.scheduleSmartReminder(hour: 20)
            }
        }
    }

    /// Delete account data
    func deleteAllData() {
        do {
            try DataStore.shared.deleteAllData()
        } catch {}

        // Clear user identity and gamification keys from UserDefaults
        let keysToRemove = [
            "apple_user_id",
            "ascend_streak",
            "ascend_longest_streak",
            "ascend_diamonds",
            "ascend_last_scan",
            "ascend_last_weight_update"
        ]
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }

        totalScans = 0
        weeklyScans = 0
        latestDiagnosis = nil
        displayName = ""
        ScanCreditManager.shared.reset()
        APIKeyManager.removeKey()
        NotificationScheduler.shared.cancelAll()
    }

    // MARK: - Helpers

    private func encodeDiagnosis(_ diagnosis: DiagnosisResult) -> Data? {
        let items = diagnosis.zones.map { item in
            ZoneDataItem(zone: item.zone.rawValue, status: statusString(item.status), delta: item.delta)
        }
        return try? JSONEncoder().encode(items)
    }

    private func decodeDiagnosis(from record: ScanRecord) -> DiagnosisResult? {
        guard let data = record.zoneData,
              let items = try? JSONDecoder().decode([ZoneDataItem].self, from: data) else { return nil }

        let zones = items.compactMap { item -> ZoneDiagnosisItem? in
            guard let zone = BodyZone(rawValue: item.zone),
                  let status = statusFromString(item.status) else { return nil }
            return ZoneDiagnosisItem(zone: zone, status: status, delta: item.delta)
        }

        guard !zones.isEmpty else { return nil }
        return DiagnosisResult(zones: zones, overallScore: record.overallScore, irisMessage: record.irisMessage)
    }

    private func statusString(_ status: ZoneStatus) -> String {
        switch status {
        case .base: "base"
        case .weak: "weak"
        case .moderate: "moderate"
        case .strong: "strong"
        case .target: "target"
        }
    }

    private func statusFromString(_ str: String) -> ZoneStatus? {
        switch str {
        case "base": .base
        case "weak": .weak
        case "moderate": .moderate
        case "strong": .strong
        case "target": .target
        default: nil
        }
    }

    private func weekdayNumber(from name: String) -> Int {
        switch name.lowercased() {
        case "sunday": 1
        case "monday": 2
        case "tuesday": 3
        case "wednesday": 4
        case "thursday": 5
        case "friday": 6
        case "saturday": 7
        default: 1
        }
    }
}

// MARK: - Scan Snapshot (for progress photo display)

struct ScanSnapshot: Identifiable {
    let id: UUID
    let date: Date
    let score: Double
    let frontImage: UIImage?
    let sideImage: UIImage?
    let backImage: UIImage?

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Zone Data Codable

private struct ZoneDataItem: Codable {
    let zone: String
    let status: String
    let delta: Double
}
