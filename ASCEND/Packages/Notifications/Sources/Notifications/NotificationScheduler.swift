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
        content.title = "Streak in Danger"
        content.body = "Your \(UserDefaults.standard.integer(forKey: "ascend_streak"))-day streak dies at midnight. Log a workout or check in to save it."
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
            content.body = "Most people quit by now. You're still here. Log a workout or check in."
        case 4:
            content.title = "Day 4 — Building Momentum"
            content.body = "Your body is starting to notice. Check in today to keep the chain alive."
        case 5:
            content.title = "Day 5 — Pressure's On"
            content.body = "Two more days and you unlock your first diamond. Don't stop now."
        case 6:
            content.title = "Day 6 — One Day Away"
            content.body = "Tomorrow you unlock your first diamond. Check in to keep the chain alive."
            content.interruptionLevel = .timeSensitive
        case 7:
            content.title = "Day 7 — Diamond Day"
            content.body = "Open ASCEND to claim your first diamond. You earned this."
            content.interruptionLevel = .timeSensitive
        case 8...13:
            content.title = "Day \(streakDay) — On Fire"
            content.body = "\(streakDay) days straight. Most people dream about this consistency."
        case 14:
            content.title = "Two Weeks Strong"
            content.body = "14 days. This isn't luck — it's discipline. Your body is changing."
        case 15...20:
            content.title = "Day \(streakDay) — Locked In"
            content.body = "Day 21 diamond is getting closer. Log a workout to keep the chain alive."
            content.interruptionLevel = .timeSensitive
        case 21:
            content.title = "Day 21 — Habit Formed"
            content.body = "Open ASCEND to claim your diamond. Science says this is a habit now."
            content.interruptionLevel = .timeSensitive
        case 22...41:
            let daysTo42 = 42 - streakDay
            content.title = "Day \(streakDay) — Unstoppable"
            content.body = "\(daysTo42) days until your next diamond. IRIS is watching."
        case 42:
            content.title = "Day 42 — Unstoppable"
            content.body = "6 weeks. You've outlasted 99% of people. Claim your diamond."
            content.interruptionLevel = .timeSensitive
        default:
            // Day 43+ — vary messages to avoid repetition
            let messages = [
                "Don't break the chain — log a workout or check in.",
                "Day \(streakDay). Your future self will thank you.",
                "\(streakDay)-day streak. That's not normal. That's exceptional.",
                "Your body is your project. Check in today.",
                "Consistency beats intensity. Keep showing up."
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

    // MARK: - First Scan Reminder

    /// Schedule reminders for users who skipped their first scan during onboarding.
    /// Fires at 2 hours, then next day at their preferred hour.
    public func scheduleFirstScanReminder(notificationHour: Int) {
        // Quick nudge — 2 hours from now
        let quickContent = UNMutableNotificationContent()
        quickContent.title = "IRIS is ready for you"
        quickContent.body = "Your first scan takes 30 seconds. See what IRIS thinks."
        quickContent.sound = .default
        quickContent.interruptionLevel = .timeSensitive

        let quickTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 7200, repeats: false)
        let quickRequest = UNNotificationRequest(identifier: "first_scan_quick", content: quickContent, trigger: quickTrigger)
        center.add(quickRequest)

        // Next day at their preferred hour
        let nextDayContent = UNMutableNotificationContent()
        nextDayContent.title = "Time for your first scan"
        nextDayContent.body = "You paid for ASCEND — now let IRIS show you what to work on."
        nextDayContent.sound = .default
        nextDayContent.interruptionLevel = .timeSensitive

        let targetDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        var dateComponents = DateComponents()
        dateComponents.year = Calendar.current.component(.year, from: targetDate)
        dateComponents.month = Calendar.current.component(.month, from: targetDate)
        dateComponents.day = Calendar.current.component(.day, from: targetDate)
        dateComponents.hour = notificationHour
        dateComponents.minute = 0

        let nextDayTrigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let nextDayRequest = UNNotificationRequest(identifier: "first_scan_nextday", content: nextDayContent, trigger: nextDayTrigger)
        center.add(nextDayRequest)
    }

    /// Cancel first scan reminders (call after first scan completes).
    public func cancelFirstScanReminders() {
        center.removePendingNotificationRequests(withIdentifiers: ["first_scan_quick", "first_scan_nextday"])
    }

    // MARK: - Daily Check-In (every day, not just scan day)

    public func scheduleDailyCheckIn(hour: Int) {
        // Schedule a daily notification that varies its message
        // iOS will fire this every day at the chosen hour
        let content = UNMutableNotificationContent()
        content.title = "ASCEND — Daily Check-In"
        content.body = "Log a workout, check your progress, or scan. Keep the streak alive."
        content.sound = .default
        content.categoryIdentifier = "DAILY_CHECKIN"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_checkin", content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Re-Engagement Drip (paywall skip / lapsed users)

    /// Schedule an aggressive re-engagement drip for users who skipped the paywall.
    /// Phase 1 (urgency): 2 min → 1 hr → 6 hr → 12 hr → 24 hr
    /// Phase 2 (persistence): Day 1 → 3 → 5 → 7, then stops.
    public func scheduleReEngagementDrip(notificationHour: Int) {
        // Cancel any existing drip first to avoid duplicates
        cancelReEngagementDrip()

        print("[NotificationScheduler] Scheduling re-engagement drip (9 notifications)")

        // Phase 1 — time-based, fires fast while they're still warm
        let urgentMessages: [(seconds: TimeInterval, title: String, body: String)] = [
            (120,    "🔥 Get ASCEND — 75% Off",
             "Yearly plan is just $2.50/mo. AI body scans, IRIS coaching, and progress tracking — free for 3 days."),
            (3600,   "Still thinking about it?",
             "One scan. 30 seconds. Full AI breakdown. Try it free for 3 days — cancel anytime."),
            (21600,  "Your body is changing without you",
             "Every day without data is a day training blind. Start your free trial — $0 today."),
            (43200,  "⏳ Don't miss your free trial",
             "3 days of unlimited scans, AI coaching, and progress tracking. No charge unless you love it."),
            (86400,  "24 hours since you left",
             "ASCEND Pro is 75% off yearly. AI scans + IRIS coaching for less than a coffee per month.")
        ]

        for (index, msg) in urgentMessages.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = msg.title
            content.body = msg.body
            content.sound = .default
            if index == 0 {
                content.interruptionLevel = .timeSensitive
            }

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: msg.seconds, repeats: false)
            let request = UNNotificationRequest(identifier: "reengage_u\(index)", content: content, trigger: trigger)
            center.add(request) { error in
                if let error {
                    print("[NotificationScheduler] ❌ Failed to schedule reengage_u\(index): \(error.localizedDescription)")
                } else {
                    print("[NotificationScheduler] ✅ Scheduled reengage_u\(index) in \(Int(msg.seconds))s")
                }
            }
        }

        // Phase 2 — day-based, fires at their preferred notification hour
        let dayMessages: [(days: Int, title: String, body: String)] = [
            (1, "Your first scan is free",
             "IRIS already knows what you look like. Let the AI show you what to fix — no payment needed."),
            (3, "Day 3 — still no scan",
             "3 days. Your physique isn't going to analyze itself. Try ASCEND Pro free for 3 days."),
            (5, "75% off — limited time",
             "5 days without data is 5 days training blind. Yearly plan = $2.50/mo. Start free today."),
            (7, "IRIS is done waiting",
             "A week without a scan. This is your last reminder — start your free trial or miss out.")
        ]

        for (index, msg) in dayMessages.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = msg.title
            content.body = msg.body
            content.sound = .default

            let targetDate = Calendar.current.date(byAdding: .day, value: msg.days, to: Date()) ?? Date()
            var dateComponents = DateComponents()
            dateComponents.year = Calendar.current.component(.year, from: targetDate)
            dateComponents.month = Calendar.current.component(.month, from: targetDate)
            dateComponents.day = Calendar.current.component(.day, from: targetDate)
            dateComponents.hour = notificationHour
            dateComponents.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: "reengage_d\(index)", content: content, trigger: trigger)
            center.add(request) { error in
                if let error {
                    print("[NotificationScheduler] ❌ Failed to schedule reengage_d\(index): \(error.localizedDescription)")
                } else {
                    print("[NotificationScheduler] ✅ Scheduled reengage_d\(index) for day \(msg.days)")
                }
            }
        }
    }

    /// Cancel re-engagement drip (call when user subscribes or scans)
    public func cancelReEngagementDrip() {
        let ids = (0..<5).map { "reengage_u\($0)" } + (0..<4).map { "reengage_d\($0)" }
        center.removePendingNotificationRequests(withIdentifiers: ids)
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
