import UserNotifications
import Foundation

public final class NotificationScheduler {
    public static let shared = NotificationScheduler()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission

    public func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    public func checkPermission() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Schedule Notifications

    public func scheduleWeeklyScanReminder(weekday: Int, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = "ASCEND — Scan Day"
        content.body = "IRIS is waiting. Time to scan and see what's changed."
        content.sound = .default
        content.categoryIdentifier = "SCAN_REMINDER"

        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly_scan", content: content, trigger: trigger)
        center.add(request)
    }

    /// Schedule mid-week check-in on the user's rest day (not hardcoded Wednesday).
    public func scheduleMidWeekCheckIn(hour: Int, weekday: Int = 4) {
        let content = UNMutableNotificationContent()
        content.title = "Mid-Week Check"
        content.body = "Halfway there. Are you staying on track, or making excuses?"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.weekday = weekday
        dateComponents.hour = hour

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "midweek_checkin", content: content, trigger: trigger)
        center.add(request)
    }

    public func scheduleStreakDanger(hour: Int) {
        // Scheduled dynamically when streak is at risk
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Streak in Danger"
        content.body = "You haven't scanned today. Your \(UserDefaults.standard.integer(forKey: "ascend_streak"))-day streak dies at midnight."
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "streak_danger", content: content, trigger: trigger)
        center.add(request)
    }

    public func scheduleEncouragement(afterDays: Int) {
        // Remove any existing encouragement to avoid stacking
        center.removePendingNotificationRequests(withIdentifiers: ["encouragement_next"])

        let content = UNMutableNotificationContent()

        // Calculate which streak day the user will be on when this fires
        let streakDay = (UserDefaults.standard.integer(forKey: "ascend_streak")) + afterDays

        switch streakDay {
        case 3:
            content.title = "Day 3 — Keep Going"
            content.body = "Most people quit by now. You're still here. That says something."
        case 4:
            content.title = "Day 4 — Building Momentum"
            content.body = "Your body is starting to notice. Don't let it down."
        case 5:
            content.title = "Day 5 — Pressure's On"
            content.body = "Two more days and you unlock your first diamond. Don't stop now."
        case 6:
            content.title = "⚡ Day 6 — One Day Away"
            content.body = "Tomorrow you unlock your first diamond. Scan now to keep the chain alive."
            content.interruptionLevel = .timeSensitive
        case 7:
            content.title = "💎 Day 7 — Diamond Day"
            content.body = "Open ASCEND to claim your first diamond. You earned this."
            content.interruptionLevel = .timeSensitive
        case 8...13:
            content.title = "Day \(streakDay) — On Fire"
            content.body = "\(streakDay) days straight. Most people dream about this consistency. Keep scanning."
        case 14:
            content.title = "🔥 Two Weeks Strong"
            content.body = "14 days. This isn't luck — it's discipline. Your body is changing."
        case 15...20:
            content.title = "Day \(streakDay) — Locked In"
            content.body = "Day 21 diamond is getting closer. Don't break now."
            content.interruptionLevel = .timeSensitive
        case 21:
            content.title = "💎 Day 21 — Habit Formed"
            content.body = "Open ASCEND to claim your diamond. Science says this is a habit now."
            content.interruptionLevel = .timeSensitive
        case 22...41:
            let daysTo42 = 42 - streakDay
            content.title = "Day \(streakDay) — Unstoppable"
            content.body = "\(daysTo42) days until your next diamond. IRIS is watching."
        case 42:
            content.title = "💎 Day 42 — Unstoppable"
            content.body = "6 weeks. You've outlasted 99% of people. Claim your diamond."
            content.interruptionLevel = .timeSensitive
        default:
            // Day 43+ — vary messages to avoid repetition
            let messages = [
                "IRIS is waiting. Don't break the chain — scan today.",
                "Day \(streakDay). Your future self will thank you. Scan now.",
                "\(streakDay)-day streak. That's not normal. That's exceptional.",
                "Your body is your project. Check in today.",
                "Consistency beats intensity. Keep scanning."
            ]
            content.title = "ASCEND — Day \(streakDay)"
            content.body = messages[streakDay % messages.count]
        }

        content.sound = .default

        // Schedule for the notification hour the user set, not exactly N days from now
        let hour = UserDefaults.standard.integer(forKey: "ascend_notification_hour")
        let notificationHour = hour > 0 ? hour : 9  // Default 9 AM

        var dateComponents = DateComponents()
        let targetDate = Calendar.current.date(byAdding: .day, value: afterDays, to: Date()) ?? Date()
        dateComponents.year = Calendar.current.component(.year, from: targetDate)
        dateComponents.month = Calendar.current.component(.month, from: targetDate)
        dateComponents.day = Calendar.current.component(.day, from: targetDate)
        dateComponents.hour = notificationHour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "encouragement_next", content: content, trigger: trigger)
        center.add(request)
    }

    public func scheduleDiamondCelebration(milestone: String) {
        let content = UNMutableNotificationContent()
        content.title = "💎 Diamond Unlocked!"
        content.body = "You just hit \(milestone). Open ASCEND to claim your diamond."
        content.sound = .default
        content.interruptionLevel = .active

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "diamond_\(milestone)", content: content, trigger: trigger)
        center.add(request)
    }

    public func scheduleBadgeUnlock(badgeName: String) {
        let content = UNMutableNotificationContent()
        content.title = "🏅 Badge Unlocked!"
        content.body = "You just earned the \(badgeName) badge. Keep pushing."
        content.sound = .default
        content.interruptionLevel = .active

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "badge_\(badgeName)", content: content, trigger: trigger)
        center.add(request)
    }

    public func scheduleScanComplete(score: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Scan Complete"
        content.body = "Your IRIS score: \(score)/100. Open ASCEND to see the full breakdown."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "scan_complete", content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Cancel

    public func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    public func cancel(identifier: String) {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Smart scheduling

    /// Don't send more than 1 notification per day. Check pending before scheduling.
    public func scheduleSmartReminder(hour: Int) async {
        let pending = await center.pendingNotificationRequests()
        let todayCount = pending.filter { req in
            guard let trigger = req.trigger as? UNCalendarNotificationTrigger else { return false }
            let today = Calendar.current.component(.day, from: Date())
            return trigger.dateComponents.day == today
        }.count

        if todayCount == 0 {
            scheduleStreakDanger(hour: hour)
        }
    }
}
