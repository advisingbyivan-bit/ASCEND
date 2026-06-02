import SwiftUI
import DesignSystem
import BodyModel3D
import Persistence
import Gamification

struct ProgressTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedWeek = 0
    @State private var storySnapshot: ScanSnapshot?

    private var hasScans: Bool { appState.hasCompletedFirstScan }

    private var zoneProgress: [(BodyZone, ZoneStatus, Double)] {
        guard let diagnosis = appState.latestDiagnosis else { return [] }
        return diagnosis.zones.map { ($0.zone, $0.status, $0.delta) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DSAnimatedBackground()

                if !hasScans {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: DSSpacing.md) {
                            timelineHeader
                            weekBreakdown
                            bodyPartStatus
                            scanPhotosSection
                            beforeAfterSection
                            consistencyTracker
                            milestoneBadges
                        }
                        .padding(.bottom, 90)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("PROGRESS")
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_cyan)
                        .tracking(2)
                }
            }
            .onAppear {
                selectedWeek = appState.weekNumber
                // Load scan images lazily — only when user visits Progress tab
                appState.loadScanImages()
            }
            .fullScreenCover(item: $storySnapshot) { snap in
                ScanStoryView(snapshot: snap)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 44))
                .foregroundStyle(Color.ds_cyan.opacity(0.5))

            Text("No Progress Yet")
                .font(DSFont.cardTitle)
                .foregroundStyle(Color.ds_textPrimary)

            Text("Complete your first scan to start tracking your body composition over time.")
                .font(DSFont.caption)
                .foregroundStyle(Color.ds_textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DSSpacing.xxl)

            VStack(spacing: 8) {
                Text("Tap the scan button below to begin")
                    .font(DSFont.caption)
                    .foregroundStyle(Color.ds_textSecondary)
                Image(systemName: "arrow.down")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.ds_cyan.opacity(0.5))
            }
            .padding(.top, DSSpacing.md)

            Spacer()
        }
    }

    // MARK: - Timeline Header

    private var timelineHeader: some View {
        let totalWeeks = appState.sprintWeeks
        let currentWeek = min(selectedWeek, totalWeeks)
        // Dynamic milestone markers based on sprint length
        let markers: [Int] = {
            if totalWeeks <= 8 { return [1, 4, totalWeeks] }
            if totalWeeks <= 12 { return [1, 4, 8, totalWeeks] }
            return [1, 4, 8, 12, totalWeeks]
        }()

        return VStack(spacing: DSSpacing.sm) {
            HStack {
                Text("\(totalWeeks)-WEEK SPRINT")
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_cyan)
                    .tracking(2)
                Spacer()
                Text("Week \(currentWeek) of \(totalWeeks)")
                    .font(DSFont.caption)
                    .foregroundStyle(Color.ds_textSecondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.ds_cyan)
                        .frame(width: geo.size.width * CGFloat(currentWeek) / CGFloat(totalWeeks), height: 8)
                        .shadow(color: Color.ds_cyan.opacity(0.4), radius: 4)
                }
            }
            .frame(height: 8)

            HStack {
                ForEach(markers, id: \.self) { week in
                    Text("W\(week)")
                        .font(DSFont.micro)
                        .foregroundStyle(week <= selectedWeek ? Color.ds_cyan : Color.ds_textSecondary)
                    if week < markers.last ?? totalWeeks {
                        Spacer()
                    }
                }
            }
        }
        .dsCard()
        .padding(.horizontal, DSSpacing.screenPadding)
        .padding(.top, DSSpacing.sm)
    }

    // MARK: - Week Breakdown

    private var weekBreakdown: some View {
        VStack(spacing: DSSpacing.sm) {
            HStack {
                Text("WEEK \(min(selectedWeek, appState.sprintWeeks)) SUMMARY")
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_cyan)
                    .tracking(2)
                Spacer()
            }

            HStack(spacing: DSSpacing.sm) {
                weekStat(value: "\(appState.weeklyScans)", label: "Scans", color: Color.ds_cyan)
                weekStat(value: scoreChangeText, label: "Score Δ", color: Color.ds_green)
                weekStat(value: "\(appState.currentStreak)", label: "Streak", color: appState.streakTier.color)
            }
        }
        .dsCard()
        .padding(.horizontal, DSSpacing.screenPadding)
    }

    private var scoreChangeText: String {
        guard let diagnosis = appState.latestDiagnosis else { return "--" }
        let totalDelta = diagnosis.zones.reduce(0.0) { $0 + $1.delta }
        let avg = totalDelta / Double(max(1, diagnosis.zones.count))
        return String(format: "%+.1f", avg)
    }

    private func weekStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(DSFont.statSmall)
                .foregroundStyle(color)
            Text(label)
                .font(DSFont.micro)
                .foregroundStyle(Color.ds_textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Body Part Status

    private var bodyPartStatus: some View {
        VStack(spacing: DSSpacing.xs) {
            HStack {
                Text("ZONE BREAKDOWN")
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_cyan)
                    .tracking(2)
                Spacer()
            }

            if zoneProgress.isEmpty {
                Text("Scan to see zone breakdown")
                    .font(DSFont.caption)
                    .foregroundStyle(Color.ds_textSecondary)
                    .padding(.vertical, DSSpacing.sm)
            } else {
                ForEach(zoneProgress, id: \.0) { zone, status, delta in
                    zoneRow(zone: zone, status: status, delta: delta)
                }
            }
        }
        .dsCard()
        .padding(.horizontal, DSSpacing.screenPadding)
    }

    private func zoneRow(zone: BodyZone, status: ZoneStatus, delta: Double) -> some View {
        HStack(spacing: DSSpacing.sm) {
            Circle()
                .fill(status.color)
                .frame(width: 10, height: 10)

            Text(zone.displayName)
                .font(DSFont.body)
                .foregroundStyle(Color.ds_textPrimary)
                .frame(width: 90, alignment: .leading)

            statusBadge(status)

            Spacer()

            HStack(spacing: 2) {
                Image(systemName: delta >= 0 ? "arrow.up.right" : "arrow.down.right")
                    .font(.system(size: 10, weight: .bold))
                Text(String(format: "%+.0f%%", delta))
                    .font(DSFont.captionBold)
            }
            .foregroundStyle(delta >= 0 ? Color.ds_green : Color.ds_red)
        }
        .padding(.vertical, 4)
    }

    private func statusBadge(_ status: ZoneStatus) -> some View {
        let label: String = switch status {
        case .strong: "Strong"
        case .moderate: "Moderate"
        case .weak: "Weak"
        case .target: "Target"
        case .base: "Base"
        case .covered: "Covered"
        }
        return Text(label)
            .font(DSFont.micro)
            .foregroundStyle(status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(status.color.opacity(0.15))
            .clipShape(Capsule())
    }

    // MARK: - Scan Photos Section

    private var scanPhotosSection: some View {
        VStack(spacing: DSSpacing.xs) {
            HStack {
                Text("YOUR SCANS")
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_cyan)
                    .tracking(2)
                Spacer()
                Text("\(appState.scanHistory.count) total")
                    .font(DSFont.micro)
                    .foregroundStyle(Color.ds_textSecondary)
            }

            if appState.scanHistory.isEmpty {
                Text("Photos will appear here after each scan")
                    .font(DSFont.caption)
                    .foregroundStyle(Color.ds_textSecondary)
                    .padding(.vertical, DSSpacing.sm)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DSSpacing.sm) {
                        ForEach(appState.scanHistory) { scan in
                            Button {
                                storySnapshot = scan
                            } label: {
                                scanCard(scan)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
        .dsCard()
        .padding(.horizontal, DSSpacing.screenPadding)
    }

    private func scanCard(_ scan: ScanSnapshot) -> some View {
        VStack(spacing: 6) {
            // Front photo thumbnail
            if let image = scan.frontImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 80, height: 120)
                    .overlay {
                        Image(systemName: "person.fill")
                            .foregroundStyle(Color.ds_textSecondary.opacity(0.3))
                    }
            }

            Text(scan.formattedDate)
                .font(DSFont.micro)
                .foregroundStyle(Color.ds_textSecondary)

            Text("\(Int(scan.score))")
                .font(DSFont.captionBold)
                .foregroundStyle(Color.ds_cyan)
        }
    }

    // MARK: - Before/After Section

    private var beforeAfterSection: some View {
        VStack(spacing: DSSpacing.xs) {
            HStack {
                Text("BODY MODEL")
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_cyan)
                    .tracking(2)
                Spacer()
            }

            if let diagnosis = appState.latestDiagnosis {
                BodyModelView(
                    gender: appState.gender,
                    zones: diagnosis.zoneMap,
                    interactive: true,
                    size: .dashboard
                )
                .frame(height: 200)

                Text("Rotate to inspect zones")
                    .font(DSFont.micro)
                    .foregroundStyle(Color.ds_textSecondary)
            }
        }
        .dsCard()
        .padding(.horizontal, DSSpacing.screenPadding)
    }

    // MARK: - Sprint Tracker

    private var consistencyTracker: some View {
        let totalWeeks = appState.sprintWeeks
        let currentWeek = min(appState.weekNumber, totalWeeks)
        let cols = totalWeeks <= 8 ? 4 : 6

        return VStack(spacing: DSSpacing.sm) {
            HStack {
                Text("SPRINT TRACKER")
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_cyan)
                    .tracking(2)
                Spacer()
                Text("Week \(currentWeek) of \(totalWeeks)")
                    .font(DSFont.micro)
                    .foregroundStyle(Color.ds_textSecondary)
            }

            // Sprint progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.ds_cyan, Color.ds_purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(currentWeek) / CGFloat(totalWeeks), height: 6)
                        .shadow(color: Color.ds_cyan.opacity(0.3), radius: 4)
                }
            }
            .frame(height: 6)

            // Weekly engagement grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: cols), spacing: 4) {
                ForEach(0..<totalWeeks, id: \.self) { week in
                    let weekNum = week + 1
                    let isCurrent = weekNum == currentWeek
                    let isPast = weekNum < currentWeek
                    let engagedDays = isCurrent ? appState.engagementWeekdays.count : (isPast ? 7 : 0)
                    let intensity = isPast ? 0.5 : (isCurrent ? min(Double(engagedDays) / 7.0, 1.0) : 0)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.ds_cyan.opacity(isPast || isCurrent ? max(intensity, 0.15) : 0.04))
                        .frame(height: 32)
                        .overlay(
                            VStack(spacing: 1) {
                                Text("W\(weekNum)")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundStyle(isPast || isCurrent ? Color.ds_textPrimary : Color.ds_textSecondary.opacity(0.4))
                                if isCurrent {
                                    Text("\(engagedDays)/7")
                                        .font(.system(size: 7, weight: .medium))
                                        .foregroundStyle(Color.ds_cyan)
                                }
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isCurrent ? Color.ds_cyan.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                }
            }

            // Sprint stats
            HStack(spacing: DSSpacing.md) {
                sprintStat(value: "\(currentWeek)", label: "Current Week", color: Color.ds_cyan)
                sprintStat(value: "\(appState.engagementWeekdays.count)", label: "Days This Week", color: Color.ds_green)
                sprintStat(value: "\(appState.currentStreak)", label: "Day Streak", color: appState.streakTier.color)
            }
        }
        .dsCard()
        .padding(.horizontal, DSSpacing.screenPadding)
    }

    private func sprintStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(color)
            Text(label)
                .font(DSFont.micro)
                .foregroundStyle(Color.ds_textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Milestone Badges

    private var milestoneBadges: some View {
        VStack(spacing: DSSpacing.xs) {
            HStack {
                Text("BADGES")
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_cyan)
                    .tracking(2)
                Spacer()
                Text("\(appState.earnedBadgeCount) earned")
                    .font(DSFont.micro)
                    .foregroundStyle(Color.ds_textSecondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DSSpacing.sm) {
                    ForEach(appState.badges) { badge in
                        BadgeView(badge: badge, size: 48)
                    }
                }
            }
        }
        .dsCard()
        .padding(.horizontal, DSSpacing.screenPadding)
    }
}
