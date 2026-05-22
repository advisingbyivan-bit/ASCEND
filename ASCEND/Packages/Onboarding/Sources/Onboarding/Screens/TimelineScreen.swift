import SwiftUI
import DesignSystem

struct TimelineScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var revealedTimelines: Set<GoalTimeline> = []
    @State private var showCountdown = false
    @State private var showButton = false
    @State private var glowPulse = false

    private var selectedTimeline: GoalTimeline {
        coordinator.data.timeline
    }

    private var motivationalMessage: String {
        switch selectedTimeline {
        case .weeks4: return "Bold. No room for excuses."
        case .weeks8: return "Focused intensity. You'll see results fast."
        case .weeks12: return "The sweet spot. Consistency wins."
        case .weeks24: return "Playing the long game. Smart."
        case .noRush: return "No pressure. Every step counts."
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)

            // Title
            VStack(spacing: DSSpacing.xs) {
                Text("Your Timeline")
                    .font(DSFont.screenTitle)
                    .foregroundStyle(Color.ds_textPrimary)
                    .scaleEffect(showTitle ? 1 : 0.9)
                    .opacity(showTitle ? 1 : 0)

                Text("How fast do you want results?")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textSecondary)
                    .offset(y: showSubtitle ? 0 : 10)
                    .opacity(showSubtitle ? 1 : 0)
            }
            .padding(.bottom, DSSpacing.lg)

            // Countdown visual
            TimelineCountdownVisual(
                timeline: selectedTimeline,
                glowPulse: glowPulse
            )
            .frame(height: 140)
            .opacity(showCountdown ? 1 : 0)
            .scaleEffect(showCountdown ? 1 : 0.8)
            .padding(.bottom, DSSpacing.md)

            // Timeline options
            VStack(spacing: 10) {
                ForEach(Array(GoalTimeline.allCases.enumerated()), id: \.element.id) { index, timeline in
                    let isSelected = coordinator.data.timeline == timeline
                    let isRevealed = revealedTimelines.contains(timeline)

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            coordinator.data.timeline = timeline
                        }
                        DSHaptic.optionSelect()
                    } label: {
                        HStack(spacing: 14) {
                            // Timeline icon
                            ZStack {
                                Circle()
                                    .fill(isSelected ? timeline.accentColor.opacity(0.15) : Color.ds_charcoal)
                                    .frame(width: 42, height: 42)

                                Circle()
                                    .stroke(isSelected ? timeline.accentColor.opacity(0.5) : Color.ds_cardBorder, lineWidth: 1.5)
                                    .frame(width: 42, height: 42)

                                Image(systemName: timeline.icon)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(isSelected ? timeline.accentColor : Color.ds_textSecondary.opacity(0.5))
                            }
                            .shadow(color: isSelected ? timeline.accentColor.opacity(0.3) : .clear, radius: 6)

                            // Text
                            VStack(alignment: .leading, spacing: 2) {
                                Text(timeline.rawValue)
                                    .font(DSFont.bodyBold)
                                    .foregroundStyle(isSelected ? Color.ds_textPrimary : Color.ds_textSecondary)

                                Text(timeline.subtitle)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(isSelected ? timeline.accentColor.opacity(0.8) : Color.ds_textSecondary.opacity(0.4))
                            }

                            Spacer()

                            // Intensity badge
                            Text(timeline.intensityLabel)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(isSelected ? timeline.accentColor : Color.ds_textSecondary.opacity(0.4))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? timeline.accentColor.opacity(0.12) : Color.ds_charcoal.opacity(0.5))
                                )

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(timeline.accentColor)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            isSelected
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [timeline.accentColor.opacity(0.10), timeline.accentColor.opacity(0.03)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                : AnyShapeStyle(Color.ds_charcoal)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cardRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: DSSpacing.cardRadius)
                                .stroke(isSelected ? timeline.accentColor.opacity(0.5) : Color.ds_cardBorder, lineWidth: isSelected ? 1.5 : 1)
                        )
                        .shadow(color: isSelected ? timeline.accentColor.opacity(0.15) : .clear, radius: 8)
                        .scaleEffect(isSelected ? 1.02 : 1.0)
                    }
                    .opacity(isRevealed ? 1 : 0)
                    .offset(x: isRevealed ? 0 : -30)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
                }
            }
            .padding(.horizontal, DSSpacing.screenPadding)

            Spacer().frame(height: DSSpacing.md)

            // Dynamic motivational message
            Text(motivationalMessage)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(selectedTimeline.accentColor.opacity(0.8))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(selectedTimeline.accentColor.opacity(0.08))
                        .overlay(
                            Capsule()
                                .stroke(selectedTimeline.accentColor.opacity(0.15), lineWidth: 1)
                        )
                )
                .contentTransition(.numericText())
                .animation(.spring(response: 0.35, dampingFraction: 0.7), value: selectedTimeline)

            Spacer()

            DSPrimaryButton("Continue", icon: "arrow.right") {
                DSHaptic.medium()
                coordinator.advance()
            }
            .padding(.horizontal, DSSpacing.screenPadding)
            .padding(.bottom, DSSpacing.xl)
            .scaleEffect(showButton ? 1 : 0.9)
            .opacity(showButton ? 1 : 0)
        }
        .onAppear {
            DSHaptic.screenEntry()

            withAnimation(.easeOut(duration: 0.5)) { showTitle = true }
            withAnimation(.easeOut(duration: 0.4).delay(0.15)) { showSubtitle = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) { showCountdown = true }

            for (index, timeline) in GoalTimeline.allCases.enumerated() {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.45 + Double(index) * 0.1)) {
                    revealedTimelines.insert(timeline)
                }
            }

            let totalDelay = 0.45 + Double(GoalTimeline.allCases.count) * 0.1 + 0.15
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(totalDelay)) {
                showButton = true
            }

            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}

// MARK: - Countdown Visual

private struct TimelineCountdownVisual: View {
    let timeline: GoalTimeline
    let glowPulse: Bool

    private var weeksNumber: String {
        switch timeline {
        case .weeks4: return "4"
        case .weeks8: return "8"
        case .weeks12: return "12"
        case .weeks24: return "24"
        case .noRush: return "~"
        }
    }

    private var progressArc: CGFloat {
        switch timeline {
        case .weeks4: return 1.0
        case .weeks8: return 0.75
        case .weeks12: return 0.55
        case .weeks24: return 0.35
        case .noRush: return 0.15
        }
    }

    var body: some View {
        ZStack {
            // Floating particles
            ForEach(0..<4, id: \.self) { i in
                Circle()
                    .fill(timeline.accentColor.opacity(0.25))
                    .frame(width: CGFloat.random(in: 3...5), height: CGFloat.random(in: 3...5))
                    .offset(
                        x: CGFloat.random(in: -50...50),
                        y: glowPulse
                            ? CGFloat.random(in: -35...35)
                            : CGFloat.random(in: -25...25)
                    )
                    .opacity(glowPulse ? 0.5 : 0.2)
            }

            // Background arc
            Circle()
                .stroke(Color.ds_charcoal, lineWidth: 4)
                .frame(width: 100, height: 100)

            // Progress arc
            Circle()
                .trim(from: 0, to: progressArc)
                .stroke(
                    AngularGradient(
                        colors: [timeline.accentColor.opacity(0.3), timeline.accentColor],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 100, height: 100)
                .shadow(color: timeline.accentColor.opacity(glowPulse ? 0.5 : 0.2), radius: 8)

            // Center content
            VStack(spacing: 2) {
                Text(weeksNumber)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(timeline.accentColor)
                    .contentTransition(.numericText())

                if timeline != .noRush {
                    Text("WEEKS")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(timeline.accentColor.opacity(0.6))
                        .tracking(2)
                } else {
                    Text("FLEXIBLE")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(timeline.accentColor.opacity(0.6))
                        .tracking(1)
                }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: timeline)
    }
}

// MARK: - GoalTimeline Extensions

extension GoalTimeline {
    var icon: String {
        switch self {
        case .weeks4: return "bolt.fill"
        case .weeks8: return "flame.fill"
        case .weeks12: return "target"
        case .weeks24: return "chart.line.uptrend.xyaxis"
        case .noRush: return "leaf.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .weeks4: return "Aggressive — maximum intensity"
        case .weeks8: return "Focused — strong dedication required"
        case .weeks12: return "Balanced — sustainable progress"
        case .weeks24: return "Gradual — steady, long-term gains"
        case .noRush: return "Flexible — go at your own pace"
        }
    }

    var intensityLabel: String {
        switch self {
        case .weeks4: return "INTENSE"
        case .weeks8: return "FOCUSED"
        case .weeks12: return "STEADY"
        case .weeks24: return "GRADUAL"
        case .noRush: return "EASY"
        }
    }

    var accentColor: Color {
        switch self {
        case .weeks4: return Color.ds_red
        case .weeks8: return Color.ds_purple
        case .weeks12: return Color.ds_cyan
        case .weeks24: return Color.ds_green
        case .noRush: return Color.ds_yellow
        }
    }
}
