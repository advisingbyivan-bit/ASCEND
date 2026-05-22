import SwiftUI
import DesignSystem
import IRIS
import BodyModel3D
import Diagnostics
import Networking
import Persistence
import Gamification

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var irisMessage: String = ""
    @State private var displayedIrisMessage: String = ""
    @State private var isLoadingIris = true
    @State private var viewReady = false

    // Entrance animations
    @State private var showXP = false
    @State private var xpFillProgress: Double = 0
    @State private var showFocus = false
    @State private var showStats = false
    @State private var showWeek = false
    @State private var showMilestones = false
    @State private var showIris = false
    @State private var revealedDays: Set<Int> = []

    // Animated counters
    @State private var animatedScans: Int = 0
    @State private var animatedWeekly: Int = 0
    @State private var animatedStreak: Int = 0

    // Breathing / pulse (isolated — NO repeatForever on parent)
    @State private var xpBarGlow = false
    @State private var streakFlicker = false

    private let weekday = Calendar.current.component(.weekday, from: Date())

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.ds_navy, Color.ds_navy.opacity(0.92)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                if viewReady {
                    DSFloatingParticles(count: 12, colors: [Color.ds_purple.opacity(0.4), Color.ds_cyan.opacity(0.2)])
                        .ignoresSafeArea()
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DSSpacing.md) {
                        headerView
                        dailyXPBar
                        if viewReady { focusAreaCard }
                        statsRow
                        weekCalendar
                        milestoneTracker
                        irisInsightCard
                    }
                    .padding(.bottom, 90)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewReady = true
                }
                loadIRISInsight()
                triggerEntranceSequence()
            }
        }
    }

    // MARK: - Entrance Sequence

    private func triggerEntranceSequence() {
        // Staggered card reveals
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.15)) { showXP = true }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) { showFocus = true }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.45)) { showStats = true }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.6)) { showWeek = true }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.75)) { showMilestones = true }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.9)) { showIris = true }

        // XP bar fills after card appears
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.8)) {
                xpFillProgress = 1.0
            }
        }

        // Week calendar dots cascade
        for i in 0..<7 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7 + Double(i) * 0.08) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    _ = revealedDays.insert(i)
                }
            }
        }

        // Stat counters tick up after cards appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            animateCounters()
        }

        // Start breathing effects ONLY on isolated subviews (not parent)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            xpBarGlow = true
            streakFlicker = true
        }
    }

    // MARK: - IRIS Insight

    private func loadIRISInsight() {
        Task { @MainActor in
            let diagnosis = appState.latestDiagnosis
            irisMessage = buildProgressInsight(diagnosis: diagnosis)
            isLoadingIris = false
            animateTypewriter()
        }
    }

    private func buildProgressInsight(diagnosis: DiagnosisResult?) -> String {
        let name = appState.displayName.isEmpty ? "you" : appState.displayName
        let streak = appState.currentStreak
        let scans = appState.totalScans

        guard let diagnosis = diagnosis, scans > 0 else {
            return "No data yet, \(name). Scan to get your baseline. Every transformation starts with knowing where you stand."
        }

        let score = Int(diagnosis.overallScore)
        let weakZones = diagnosis.zones.filter { $0.status == .weak }.map { $0.zone.displayName }
        let strongZones = diagnosis.zones.filter { $0.status == .strong }.map { $0.zone.displayName }

        if !strongZones.isEmpty && !weakZones.isEmpty {
            return "\(strongZones.first!) is your strongest zone at \(score)/100. But \(weakZones.first!) needs work. \(streak > 0 ? "\(streak)-day streak — keep the pressure on." : "Start a streak to lock in progress.")"
        }
        if weakZones.count >= 3 {
            return "Score: \(score). Multiple weak zones detected — \(weakZones.prefix(2).joined(separator: " and ")). This is your starting point, \(name). The only direction is up."
        }
        if score >= 70 {
            return "Score: \(score). Solid foundation. \(strongZones.first.map { "\($0) is responding well." } ?? "Keep pushing.") Week \(appState.weekNumber) — consistency separates good from great."
        }
        return "Current score: \(score)/100. \(weakZones.first.map { "\($0) is your biggest opportunity." } ?? "Room to improve everywhere.") \(streak > 0 ? "Day \(streak) — don't break the chain." : "Start scanning consistently to see real change.")"
    }

    private func animateTypewriter() {
        displayedIrisMessage = ""
        let characters = Array(irisMessage)
        for (index, character) in characters.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.02) {
                displayedIrisMessage.append(character)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Image("AscendLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(dateString)
                    .font(DSFont.micro)
                    .foregroundStyle(Color.ds_textSecondary)
            }
            Spacer()
            diamondCounter
        }
        .padding(.horizontal, DSSpacing.screenPadding)
        .padding(.top, DSSpacing.sm)
    }

    private var diamondCounter: some View {
        HStack(spacing: 4) {
            Image(systemName: "diamond.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color.ds_cyan)
            Text("\(appState.totalDiamonds)")
                .font(DSFont.statSmall)
                .foregroundStyle(Color.ds_cyan)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.ds_cyan.opacity(0.1))
        .clipShape(Capsule())
    }

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: Date())
    }

    // MARK: - Daily XP Bar

    private var dailyXPBar: some View {
        let scannedToday = appState.scanWeekdays.contains(weekday)
        let scanXP = appState.totalScans * 50
        let streakBonus = appState.currentStreak * 10
        let totalXP = scanXP + streakBonus
        let level = max(1, totalXP / 100)
        let xpInLevel = totalXP % 100
        let targetProgress = min(1.0, Double(xpInLevel) / 100.0)

        return VStack(spacing: DSSpacing.xs) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.ds_cyan)
                        .symbolEffect(.pulse, options: .repeating, isActive: xpBarGlow)
                    Text("LEVEL \(level)")
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_cyan)
                        .tracking(2)
                }
                Spacer()
                Text("\(xpInLevel) / 100 XP")
                    .font(DSFont.micro)
                    .foregroundStyle(Color.ds_textSecondary)
            }

            // XP progress bar — fills on entrance, then breathes
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.ds_charcoal)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.ds_cyan, Color.ds_purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * targetProgress * xpFillProgress, height: 8)
                        .shadow(color: Color.ds_cyan.opacity(0.5), radius: xpBarGlow ? 6 : 3)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: xpBarGlow)
                }
            }
            .frame(height: 8)

            // XP breakdown
            HStack(spacing: DSSpacing.md) {
                xpItem(icon: "viewfinder", value: "+\(scanXP)")
                xpItem(icon: "flame.fill", value: "+\(streakBonus)")

                Spacer()

                if scannedToday {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.ds_green)
                        Text("Today done")
                            .font(DSFont.micro)
                            .foregroundStyle(Color.ds_green)
                    }
                } else {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.ds_yellow)
                            .frame(width: 6, height: 6)
                        Text("Scan to earn XP")
                            .font(DSFont.micro)
                            .foregroundStyle(Color.ds_yellow)
                    }
                }
            }
        }
        .dsCard()
        .padding(.horizontal, DSSpacing.screenPadding)
        .opacity(showXP ? 1 : 0)
        .offset(y: showXP ? 0 : 20)
    }

    private func xpItem(icon: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(Color.ds_textSecondary)
            Text(value)
                .font(DSFont.micro)
                .foregroundStyle(Color.ds_textSecondary)
        }
    }

    // MARK: - Focus Area Card

    private var focusAreaCard: some View {
        VStack(spacing: DSSpacing.sm) {
            HStack {
                Text("FOCUS AREA")
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_cyan)
                    .tracking(2)
                Spacer()
                if appState.hasCompletedFirstScan {
                    Text("Week \(appState.weekNumber) of 12")
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_textSecondary)
                }
            }

            if let diagnosis = appState.latestDiagnosis {
                HStack(spacing: 0) {
                    BodyModelView(
                        gender: appState.gender,
                        zones: diagnosis.zoneMap,
                        interactive: false,
                        size: .dashboard
                    )
                    .frame(maxWidth: .infinity)

                    VStack(spacing: DSSpacing.xs) {
                        DSProgressRing(
                            progress: diagnosis.overallScore / 100,
                            size: 70,
                            lineWidth: 5
                        )
                        .overlay {
                            VStack(spacing: 0) {
                                Text("\(Int(diagnosis.overallScore))%")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundStyle(Color.ds_cyan)
                                Text("score")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundStyle(Color.ds_textSecondary)
                            }
                        }

                        VStack(spacing: 4) {
                            ForEach(diagnosis.zones, id: \.zone) { item in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(item.status.color)
                                        .frame(width: 6, height: 6)
                                    Text(item.zone.displayName)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundStyle(Color.ds_textPrimary)
                                    Spacer()
                                    Text(zoneStatusLabel(item.status))
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(item.status.color)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.ds_cyan.opacity(0.5))
                    Text("No Scan Data Yet")
                        .font(DSFont.cardTitle)
                        .foregroundStyle(Color.ds_textPrimary)
                    Text("Complete your first scan to see your body analysis and focus areas.")
                        .font(DSFont.caption)
                        .foregroundStyle(Color.ds_textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, DSSpacing.md)
            }
        }
        .dsCard()
        .padding(.horizontal, DSSpacing.screenPadding)
        .opacity(showFocus ? 1 : 0)
        .offset(y: showFocus ? 0 : 20)
    }

    private func zoneStatusLabel(_ status: ZoneStatus) -> String {
        switch status {
        case .strong: "Strong"
        case .moderate: "Moderate"
        case .weak: "Weak"
        case .target: "Target"
        case .base: "Base"
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: DSSpacing.sm) {
            statCard(
                animatedValue: animatedScans,
                label: "Scans",
                icon: "viewfinder",
                color: animatedScans > 0 ? Color.ds_cyan : Color.ds_textSecondary,
                isActive: animatedScans > 0,
                delay: 0
            )
            statCard(
                animatedValue: animatedWeekly,
                label: "This Week",
                icon: "calendar",
                color: animatedWeekly > 0 ? Color.ds_cyan : Color.ds_textSecondary,
                isActive: animatedWeekly > 0,
                delay: 1
            )
            statCard(
                animatedValue: animatedStreak,
                label: "Day Streak",
                icon: "flame.fill",
                color: streakColor,
                isActive: animatedStreak > 0,
                delay: 2
            )
        }
        .padding(.horizontal, DSSpacing.screenPadding)
        .opacity(showStats ? 1 : 0)
        .offset(y: showStats ? 0 : 20)
    }

    private var streakColor: Color {
        let s = appState.currentStreak
        if s >= 21 { return Color.ds_cyan }
        if s >= 7 { return Color.ds_yellow }
        if s > 0 { return Color.ds_textPrimary }
        return Color.ds_textSecondary
    }

    private func animateCounters() {
        animatedScans = 0
        animatedWeekly = 0
        animatedStreak = 0
        let targets = (appState.totalScans, appState.weeklyScans, appState.currentStreak)
        let steps = 16
        for i in 1...steps {
            let delay = Double(i) * 0.05
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.08)) {
                    animatedScans = min(Int(Double(targets.0) * Double(i) / Double(steps)), targets.0)
                    animatedWeekly = min(Int(Double(targets.1) * Double(i) / Double(steps)), targets.1)
                    animatedStreak = min(Int(Double(targets.2) * Double(i) / Double(steps)), targets.2)
                }
            }
        }
    }

    private func statCard(animatedValue: Int, label: String, icon: String, color: Color, isActive: Bool, delay: Int) -> some View {
        VStack(spacing: 6) {
            // Icon with subtle pulse when active
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .symbolEffect(.pulse, options: .repeating.speed(0.5), isActive: isActive && streakFlicker)

            Text("\(animatedValue)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .transaction { $0.animation = nil }

            Text(label)
                .font(DSFont.micro)
                .foregroundStyle(Color.ds_textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DSSpacing.sm)
        .background(Color.ds_charcoal)
        .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cardRadius))
        .overlay(
            RoundedRectangle(cornerRadius: DSSpacing.cardRadius)
                .stroke(isActive ? color.opacity(0.5) : Color.ds_cardBorder, lineWidth: isActive ? 1.5 : 1)
        )
        .shadow(color: isActive ? color.opacity(0.2) : .clear, radius: 10, x: 0, y: 3)
    }

    // MARK: - Week Calendar

    private var weekCalendar: some View {
        let dayLabels = ["S", "M", "T", "W", "T", "F", "S"]

        return VStack(spacing: DSSpacing.xs) {
            HStack {
                Text("THIS WEEK")
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_cyan)
                    .tracking(2)
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(appState.streakTier.color)
                        .symbolEffect(.pulse, options: .repeating.speed(0.4), isActive: streakFlicker && appState.currentStreak > 0)
                    Text("\(appState.currentStreak) day streak")
                        .font(DSFont.micro)
                        .foregroundStyle(appState.streakTier.color)
                }
            }

            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    let calWeekday = i + 1
                    let isToday = calWeekday == weekday
                    let isScanned = appState.scanWeekdays.contains(calWeekday)
                    let revealed = revealedDays.contains(i)

                    VStack(spacing: 6) {
                        Text(dayLabels[i])
                            .font(DSFont.micro)
                            .foregroundStyle(isToday ? Color.ds_cyan : Color.ds_textSecondary)

                        ZStack {
                            // Glow ring behind scanned days
                            if isScanned {
                                Circle()
                                    .fill(Color.ds_cyan.opacity(0.15))
                                    .frame(width: 36, height: 36)
                            }

                            Circle()
                                .fill(isScanned ? Color.ds_cyan.opacity(0.25) : Color.ds_charcoal.opacity(0.5))
                                .frame(width: 32, height: 32)

                            if isToday {
                                Circle()
                                    .stroke(Color.ds_cyan, lineWidth: 2)
                                    .frame(width: 32, height: 32)
                            }

                            if isScanned {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Color.ds_cyan)
                            }
                        }
                        .scaleEffect(revealed ? 1 : 0.3)
                        .opacity(revealed ? 1 : 0)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .dsCard()
        .padding(.horizontal, DSSpacing.screenPadding)
        .opacity(showWeek ? 1 : 0)
        .offset(y: showWeek ? 0 : 20)
    }

    // MARK: - Milestone Tracker

    private var milestoneTracker: some View {
        VStack(spacing: DSSpacing.xs) {
            HStack {
                Text("MILESTONES")
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_cyan)
                    .tracking(2)
                Spacer()
                if let next = appState.nextMilestone, let days = appState.daysUntilNextMilestone {
                    Text("\(days)d to \(next.displayName)")
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_textSecondary)
                }
            }

            HStack(spacing: DSSpacing.sm) {
                milestoneItem(day: 7, earned: appState.currentStreak >= 7)
                milestoneLine(filled: appState.currentStreak >= 7)
                milestoneItem(day: 21, earned: appState.currentStreak >= 21)
                milestoneLine(filled: appState.currentStreak >= 21)
                milestoneItem(day: 42, earned: appState.currentStreak >= 42)
                milestoneLine(filled: appState.currentStreak >= 42)
                milestoneItem(day: 90, earned: appState.currentStreak >= 90)
            }
        }
        .dsCard()
        .padding(.horizontal, DSSpacing.screenPadding)
        .opacity(showMilestones ? 1 : 0)
        .offset(y: showMilestones ? 0 : 20)
    }

    private func milestoneItem(day: Int, earned: Bool) -> some View {
        VStack(spacing: 4) {
            ZStack {
                if earned {
                    Circle()
                        .fill(Color.ds_cyan.opacity(0.15))
                        .frame(width: 42, height: 42)
                }

                Circle()
                    .fill(earned ? Color.ds_cyan : Color.ds_charcoal)
                    .frame(width: 36, height: 36)

                Image(systemName: earned ? "diamond.fill" : "diamond")
                    .font(.system(size: 14))
                    .foregroundStyle(earned ? Color.ds_navy : Color.ds_textSecondary)
            }
            Text("Day \(day)")
                .font(DSFont.micro)
                .foregroundStyle(earned ? Color.ds_cyan : Color.ds_textSecondary)
        }
    }

    private func milestoneLine(filled: Bool) -> some View {
        Rectangle()
            .fill(filled ? Color.ds_cyan : Color.ds_charcoal)
            .frame(height: 2)
            .frame(maxWidth: .infinity)
    }

    // MARK: - IRIS Insight Card

    private var irisInsightCard: some View {
        HStack(alignment: .top, spacing: DSSpacing.sm) {
            IRISSphereView(state: .idle, size: .badge)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("IRIS")
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_cyan)
                    Text("INSIGHT")
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_textSecondary)
                }

                if isLoadingIris {
                    ProgressView()
                        .tint(Color.ds_cyan)
                } else {
                    Text(displayedIrisMessage)
                        .font(DSFont.caption)
                        .foregroundStyle(Color.ds_textSecondary)
                        .lineLimit(5)
                }
            }
        }
        .dsCard()
        .overlay(
            RoundedRectangle(cornerRadius: DSSpacing.cardRadius)
                .stroke(
                    LinearGradient(
                        colors: [Color.ds_cyan.opacity(0.2), Color.ds_purple.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .padding(.horizontal, DSSpacing.screenPadding)
        .opacity(showIris ? 1 : 0)
        .offset(y: showIris ? 0 : 20)
    }
}
