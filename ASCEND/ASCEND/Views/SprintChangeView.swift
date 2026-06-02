import SwiftUI
import DesignSystem
import Gamification

struct SprintChangeView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeline: String = ""
    @State private var showConfirm = false

    private let sprints: [SprintOption] = [
        SprintOption(
            timeline: "4 Weeks",
            title: "Quick Sprint",
            subtitle: "Intense focus, fast feedback loop",
            icon: "bolt.fill",
            color: .ds_yellow,
            description: "Best for short-term cuts or a focused push. You'll scan frequently and see rapid visual feedback.",
            pace: "5-7 scans total"
        ),
        SprintOption(
            timeline: "8 Weeks",
            title: "Standard",
            subtitle: "Balanced pace, steady progress",
            icon: "flame.fill",
            color: Color(red: 1, green: 140.0/255, blue: 0),
            description: "Enough time to build real habits without losing urgency. Most users start here.",
            pace: "8-12 scans total"
        ),
        SprintOption(
            timeline: "12 Weeks",
            title: "Recommended",
            subtitle: "Visible transformation window",
            icon: "star.fill",
            color: .ds_cyan,
            description: "The gold standard for body recomposition. Enough time for muscle growth and fat loss to show.",
            pace: "12-16 scans total",
            isRecommended: true
        ),
        SprintOption(
            timeline: "24 Weeks",
            title: "Long Game",
            subtitle: "Patient approach, lasting results",
            icon: "trophy.fill",
            color: .ds_purple,
            description: "For major transformations or lifestyle changes. Sustainable habits over dramatic cuts.",
            pace: "20-30 scans total"
        ),
        SprintOption(
            timeline: "No Rush",
            title: "Open-Ended",
            subtitle: "No deadline, your own pace",
            icon: "infinity",
            color: .ds_green,
            description: "Scan when you want, track progress indefinitely. No pressure, no countdown.",
            pace: "Unlimited"
        ),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                DSAnimatedBackground()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DSSpacing.lg) {
                        // Current progress summary
                        currentProgressCard

                        // What happens section
                        softResetInfo

                        // Sprint options
                        VStack(spacing: DSSpacing.sm) {
                            ForEach(sprints) { sprint in
                                sprintCard(sprint)
                            }
                        }
                        .padding(.horizontal, DSSpacing.screenPadding)

                        // Confirm button
                        if !selectedTimeline.isEmpty && selectedTimeline != appState.timeline {
                            confirmButton
                                .padding(.horizontal, DSSpacing.screenPadding)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("CHANGE SPRINT")
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_cyan)
                        .tracking(2)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.ds_textSecondary)
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                }
            }
            .onAppear {
                selectedTimeline = appState.timeline
            }
        }
    }

    // MARK: - Current Progress Card

    private var currentProgressCard: some View {
        VStack(spacing: DSSpacing.sm) {
            HStack {
                Text("CURRENT SPRINT")
                    .font(DSFont.micro)
                    .foregroundStyle(Color.ds_textSecondary)
                    .tracking(1)
                Spacer()
                Text(appState.timeline)
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_cyan)
            }

            HStack(spacing: DSSpacing.lg) {
                progressStat(value: "Week \(appState.weekNumber)", label: "of \(appState.sprintWeeks)")
                progressStat(value: "\(appState.totalScans)", label: "scans")
                progressStat(value: "\(appState.currentStreak)", label: "day streak")
                if let score = appState.latestDiagnosis?.overallScore {
                    progressStat(value: "\(Int(score))", label: "score")
                }
            }
        }
        .dsCard()
        .padding(.horizontal, DSSpacing.screenPadding)
        .padding(.top, DSSpacing.sm)
    }

    private func progressStat(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.ds_textPrimary)
            Text(label)
                .font(DSFont.micro)
                .foregroundStyle(Color.ds_textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Soft Reset Info

    private var softResetInfo: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 16))
                .foregroundStyle(Color.ds_cyan)

            VStack(alignment: .leading, spacing: 2) {
                Text("Your data carries over")
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_textPrimary)
                Text("Scan history, streak, and scores stay. Only the week counter resets to Week 1.")
                    .font(DSFont.micro)
                    .foregroundStyle(Color.ds_textSecondary)
            }
        }
        .padding(DSSpacing.sm)
        .background(Color.ds_cyan.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, DSSpacing.screenPadding)
    }

    // MARK: - Sprint Card

    private func sprintCard(_ sprint: SprintOption) -> some View {
        let isSelected = selectedTimeline == sprint.timeline
        let isCurrent = appState.timeline == sprint.timeline

        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedTimeline = sprint.timeline
            }
        } label: {
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                HStack {
                    Image(systemName: sprint.icon)
                        .font(.system(size: 16))
                        .foregroundStyle(sprint.color)

                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 6) {
                            Text(sprint.title)
                                .font(DSFont.cardTitle)
                                .foregroundStyle(Color.ds_textPrimary)

                            if sprint.isRecommended {
                                Text("BEST")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(Color.ds_navy)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.ds_cyan)
                                    .clipShape(Capsule())
                            }

                            if isCurrent {
                                Text("CURRENT")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundStyle(Color.ds_green)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.ds_green.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }

                        Text(sprint.subtitle)
                            .font(DSFont.micro)
                            .foregroundStyle(Color.ds_textSecondary)
                    }

                    Spacer()

                    // Selection indicator
                    ZStack {
                        Circle()
                            .stroke(isSelected ? Color.ds_cyan : Color.white.opacity(0.06), lineWidth: 2)
                            .frame(width: 20, height: 20)

                        if isSelected {
                            Circle()
                                .fill(Color.ds_cyan)
                                .frame(width: 12, height: 12)
                        }
                    }
                }

                Text(sprint.description)
                    .font(DSFont.caption)
                    .foregroundStyle(Color.ds_textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 4) {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.ds_cyan.opacity(0.6))
                    Text(sprint.pace)
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_cyan.opacity(0.7))
                }
            }
            .padding(DSSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.06).opacity(isSelected ? 1 : 0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.ds_cyan.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Confirm Button

    private var confirmButton: some View {
        Button {
            DSHaptic.success()
            appState.updateTimeline(selectedTimeline)
            // Soft reset: update memberSince to now so week counter resets to 1
            appState.softResetSprint()
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "flag.checkered")
                    .font(.system(size: 14))
                Text("Start \(selectedTimeline) Sprint")
                    .font(DSFont.bodyBold)
            }
            .foregroundStyle(Color.ds_navy)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.ds_cyan)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Sprint Option Model

private struct SprintOption: Identifiable {
    let timeline: String
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let description: String
    let pace: String
    var isRecommended: Bool = false

    var id: String { timeline }
}
