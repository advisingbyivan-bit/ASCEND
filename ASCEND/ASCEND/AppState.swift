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
    var lastEngagementDate: Date? { StreakManager.shared.lastEngagementDate }
    var hasEngagedToday: Bool { StreakManager.shared.hasEngagedToday }

    // MARK: - Profile
    var displayName: String = ""
    var gender: BodyGender = .male
    var memberSince: Date = Date()
    var scanDay: String = "Sunday"
    var restDay: String = "Wednesday"
    var notificationHour: Int = 8
    var profileWeightKg: Double = 75
    var profileHeightCm: Int = 175
    var profileAge: Int = 25
    var timeline: String = "12 Weeks"

    // MARK: - Scan History
    var totalScans: Int = 0
    var totalWorkouts: Int = 0
    var latestDiagnosis: DiagnosisResult?
    var weeklyScans: Int = 0
    /// Weekday indices (1=Sun, 2=Mon, …, 7=Sat) that had scans this week
    var scanWeekdays: Set<Int> = []
    /// Weekday indices that had workouts this week
    var workoutWeekdays: Set<Int> = []
    /// Combined engagement weekdays (scans + workouts + weight check-ins)
    var engagementWeekdays: Set<Int> = []
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

    /// Total weeks in the user's sprint, parsed from timeline string (e.g. "12 Weeks" → 12).
    var sprintWeeks: Int {
        if timeline == "No Rush" { return weekNumber } // Open-ended
        let number = timeline.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        return Int(number) ?? 12
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
            self.loadWorkoutData()
            self.checkStreakDanger()

            // Check weekly free credit for subscribers
            let isSubscriber = SubscriptionManager.shared.isPremium
            ScanCreditManager.shared.checkWeeklyFreeCredit(isSubscriber: isSubscriber)

            // Note: Don't cancel re-engagement drip here — it gets cancelled
            // automatically when the user subscribes (onSubscriptionActivated)
            // or completes a scan (completeScan). Cancelling here would kill
            // freshly scheduled drips for users with stale sandbox subscriptions.

            // Check milestone credit rewards
            ScanCreditManager.shared.checkMilestoneRewards(currentStreak: self.currentStreak)

            self.refreshLiveActivity()
            self.refreshWidgetData()
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
                profileWeightKg = profile.weightKg
                profileHeightCm = profile.heightCm
                profileAge = profile.age
                timeline = profile.timeline
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
            engagementWeekdays = engagementWeekdays.union(scanWeekdays)

            // Load latest diagnosis (lightweight — no image data needed)
            if let latest = scans.first, let _ = latest.zoneData {
                latestDiagnosis = decodeDiagnosis(from: latest)
            } else {
                // Show baseline so dashboard isn't empty before first scan
                latestDiagnosis = DiagnosisResult.baseline
            }

            // Build scan history WITHOUT images — they load lazily when Progress tab opens.
            // This avoids decoding every JPEG on launch (was the main startup bottleneck).
            scanHistory = scans.map { record in
                ScanSnapshot(
                    id: record.id,
                    date: record.date,
                    score: record.overallScore,
                    frontImage: nil,
                    sideImage: nil,
                    backImage: nil,
                    irisMessage: record.irisMessage.isEmpty ? nil : record.irisMessage,
                    zoneData: Self.decodeZoneData(record.zoneData)
                )
            }
        } catch {
            totalScans = 0
            weeklyScans = 0
            latestDiagnosis = DiagnosisResult.baseline
            scanHistory = []
        }
    }

    func loadWorkoutData() {
        do {
            workoutWeekdays = try DataStore.shared.workoutWeekdays()
            engagementWeekdays = scanWeekdays.union(workoutWeekdays)
            totalWorkouts = (try? DataStore.shared.fetchWorkouts().count) ?? 0
        } catch {
            workoutWeekdays = []
            engagementWeekdays = scanWeekdays
            totalWorkouts = 0
        }
    }

    /// Load full image data for scan history. Call from Progress tab onAppear.
    func loadScanImages() {
        guard !_imagesLoaded else { return }
        _imagesLoaded = true
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let scans = try DataStore.shared.fetchScans()
                self.scanHistory = scans.map { record in
                    ScanSnapshot(
                        id: record.id,
                        date: record.date,
                        score: record.overallScore,
                        frontImage: record.frontImageData.flatMap { UIImage(data: $0) },
                        sideImage: record.sideImageData.flatMap { UIImage(data: $0) },
                        backImage: record.backImageData.flatMap { UIImage(data: $0) },
                        irisMessage: record.irisMessage.isEmpty ? nil : record.irisMessage,
                        zoneData: Self.decodeZoneData(record.zoneData)
                    )
                }
            } catch {}
        }
    }

    private var _imagesLoaded = false

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
        let todayWeekday = Calendar.current.component(.weekday, from: Date())
        scanWeekdays.insert(todayWeekday)
        engagementWeekdays.insert(todayWeekday)

        // Add to scan history immediately
        let snapshot = ScanSnapshot(
            id: record.id,
            date: record.date,
            score: diagnosis.overallScore,
            frontImage: photos.count >= 1 ? photos[0] : nil,
            sideImage: photos.count >= 2 ? photos[1] : nil,
            backImage: photos.count >= 3 ? photos[2] : nil,
            irisMessage: diagnosis.irisMessage,
            zoneData: diagnosis.zones.map { ($0.zone.rawValue, $0.status.label.lowercased(), $0.delta) }
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
        case .alreadyScanned, .alreadyEngaged:
            break
        }

        // Don't fire scan-complete notification here — user is already in the app
        // looking at results. The "Open ASCEND" text would be confusing.
        // Badge/diamond notifications handle the celebratory feedback.

        // Cancel engagement notifications — user is actively scanning
        NotificationScheduler.shared.cancelReEngagementDrip()
        NotificationScheduler.shared.cancelFirstScanReminders()

        refreshLiveActivity()
        refreshWidgetData()

        // Schedule encouragement notifications based on streak progress
        scheduleStreakNotifications()
    }

    // MARK: - Workout Logging

    /// Log a workout — counts as daily engagement for streak.
    func logWorkout(muscleGroups: [String], notes: String = "") {
        let entry = WorkoutEntry(
            muscleGroups: muscleGroups.joined(separator: ","),
            notes: notes
        )

        do {
            try DataStore.shared.saveWorkout(entry)
        } catch {
            // Silent fail — engagement still counts for current session
        }

        // Record engagement (updates streak)
        let reward = StreakManager.shared.recordEngagement()

        // Check for new milestone credits
        let newCredits = ScanCreditManager.shared.checkMilestoneRewards(currentStreak: currentStreak)
        if newCredits > 0 {
            AnalyticsService.shared.track(.credits_earned, properties: [
                "amount": newCredits,
                "source": "milestone",
                "streak": currentStreak
            ])
        }

        // Update local state
        totalWorkouts += 1
        let today = Calendar.current.component(.weekday, from: Date())
        workoutWeekdays.insert(today)
        engagementWeekdays.insert(today)

        // Handle reward (diamonds, etc.)
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
        case .alreadyEngaged, .alreadyScanned:
            break
        }

        refreshLiveActivity()
        refreshWidgetData()
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
        NotificationScheduler.shared.scheduleDailyCheckIn(hour: notificationHour)
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
        // Update local state immediately so any view reading appState.profileWeightKg updates
        profileWeightKg = weightKg
        do {
            try DataStore.shared.updateProfileWeight(weightKg)
        } catch {
            print("[AppState] Failed to persist weight: \(error)")
        }
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "ascend_last_weight_update")

        // Weight check-in counts as daily engagement
        let reward = StreakManager.shared.recordEngagement()
        let todayWeekday = Calendar.current.component(.weekday, from: Date())
        engagementWeekdays.insert(todayWeekday)

        if case .mega(let milestone) = reward {
            pendingCelebration = milestone
            showCelebration = true
            NotificationScheduler.shared.scheduleDiamondCelebration(milestone: milestone.displayName)
        }
    }

    func updateDisplayName(_ name: String) {
        displayName = name
        do {
            try DataStore.shared.updateProfileField(\.displayName, value: name)
        } catch {
            print("[AppState] Failed to persist display name: \(error)")
        }
    }

    func updateTimeline(_ newTimeline: String) {
        timeline = newTimeline
        do {
            try DataStore.shared.updateProfileField(\.timeline, value: newTimeline)
        } catch {
            print("[AppState] Failed to persist timeline: \(error)")
        }
    }

    /// Soft-reset the sprint: moves memberSince to now so the week counter
    /// resets to Week 1, but keeps all scan history, streak, scores, etc.
    func softResetSprint() {
        let now = Date()
        memberSince = now
        do {
            try DataStore.shared.updateProfileField(\.createdAt, value: now)
        } catch {
            print("[AppState] Failed to persist sprint reset: \(error)")
        }
    }

    /// Called when user subscribes (from any paywall). Cancels re-engagement drip.
    func onSubscriptionActivated() {
        NotificationScheduler.shared.cancelReEngagementDrip()
    }

    /// Dismiss diamond celebration
    func dismissCelebration() {
        showCelebration = false
        pendingCelebration = nil
    }

    // MARK: - Live Activity

    /// Start or update the Live Activity with current streak data.
    /// Only starts a Live Activity after the user has completed at least one scan
    /// so the data shown is always real (never defaults/zeros).
    func refreshLiveActivity() {
        guard hasCompletedFirstScan else {
            // No scan data yet — don't show a Live Activity with empty/default values
            return
        }

        let milestone = DiamondMilestone.next(forStreak: currentStreak)
        let daysUntil = milestone.map { $0.rawValue - currentStreak } ?? 0
        let score = latestDiagnosis?.overallScore ?? 0

        var weekEngagement = Array(repeating: false, count: 7)
        for day in engagementWeekdays {
            let index = day - 1
            if index >= 0 && index < 7 {
                weekEngagement[index] = true
            }
        }

        if LiveActivityManager.shared.isSupported {
            if LiveActivityManager.shared.hasActiveActivity {
                LiveActivityManager.shared.update(
                    streak: currentStreak,
                    score: score,
                    nextMilestone: milestone?.rawValue ?? 7,
                    daysUntilMilestone: daysUntil,
                    lastScanDate: lastScanDate,
                    streakAtRisk: isStreakAtRisk,
                    weekEngagement: weekEngagement
                )
            } else {
                LiveActivityManager.shared.start(
                    displayName: displayName,
                    streak: currentStreak,
                    score: score,
                    nextMilestone: milestone?.rawValue ?? 7,
                    daysUntilMilestone: daysUntil,
                    lastScanDate: lastScanDate,
                    weekEngagement: weekEngagement
                )
            }
        }
    }

    // MARK: - Widget Data

    /// Push current state to home screen widget via App Group UserDefaults.
    func refreshWidgetData() {
        let milestone = DiamondMilestone.next(forStreak: currentStreak)
        let daysUntil = milestone.map { $0.rawValue - currentStreak } ?? 0
        let score = latestDiagnosis?.overallScore ?? 0

        // Convert engagementWeekdays Set<Int> (1=Sun…7=Sat) to [Bool] array (index 0=Sun…6=Sat)
        var weekEngagement = Array(repeating: false, count: 7)
        for day in engagementWeekdays {
            let index = day - 1  // Convert 1-based to 0-based
            if index >= 0 && index < 7 {
                weekEngagement[index] = true
            }
        }

        WidgetDataStore.update(
            streak: currentStreak,
            score: score,
            totalScans: totalScans,
            weekEngagement: weekEngagement,
            nextMilestone: milestone?.rawValue ?? 7,
            daysUntilMilestone: daysUntil,
            streakAtRisk: isStreakAtRisk
        )
    }

    private var isStreakAtRisk: Bool {
        guard currentStreak > 0, let last = lastEngagementDate else { return false }
        let today = Calendar.current.startOfDay(for: Date())
        let lastDay = Calendar.current.startOfDay(for: last)
        return lastDay < today
    }

    /// Check if streak is in danger and schedule notification
    func checkStreakDanger() {
        guard currentStreak > 0 else { return }
        guard let last = lastEngagementDate else { return }
        let today = Calendar.current.startOfDay(for: Date())
        let lastDay = Calendar.current.startOfDay(for: last)
        let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0

        // If user hasn't engaged today and has an active streak, schedule danger notification at 8pm
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
            "ascend_last_engagement",
            "ascend_last_weight_update"
        ]
        for key in keysToRemove {
            UserDefaults.standard.removeObject(forKey: key)
        }

        totalScans = 0
        totalWorkouts = 0
        weeklyScans = 0
        latestDiagnosis = nil
        displayName = ""
        ScanCreditManager.shared.reset()
        APIKeyManager.removeKey()
        NotificationScheduler.shared.cancelAll()
        LiveActivityManager.shared.endAll()
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
        case .covered: "covered"
        }
    }

    private func statusFromString(_ str: String) -> ZoneStatus? {
        switch str {
        case "base": .base
        case "weak": .weak
        case "moderate": .moderate
        case "strong": .strong
        case "target": .target
        case "covered": .covered
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
    let irisMessage: String?
    let zoneData: [(zone: String, status: String, delta: Double)]?

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

extension AppState {
    static func decodeZoneData(_ data: Data?) -> [(zone: String, status: String, delta: Double)]? {
        guard let data else { return nil }
        guard let items = try? JSONDecoder().decode([ZoneDataItem].self, from: data) else { return nil }
        return items.map { ($0.zone, $0.status, $0.delta) }
    }
}
