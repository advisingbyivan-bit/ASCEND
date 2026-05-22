import SwiftUI
import DesignSystem
import Diagnostics

struct Cal13_GoalSummaryScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var showBadge = false
    @State private var showTitle = false
    @State private var showCards = false
    @State private var showButton = false

    private var overallScore: Int {
        Int(coordinator.diagnosisResult?.overallScore ?? 72)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DSSpacing.lg) {
                // Checkmark badge
                ZStack {
                    Circle()
                        .fill(Color.ds_cyan.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.ds_cyan)
                }
                .padding(.top, DSSpacing.lg)
                .opacity(showBadge ? 1 : 0)
                .scaleEffect(showBadge ? 1 : 0.5)

                VStack(spacing: DSSpacing.xs) {
                    Text("Your Plan is Ready")
                        .font(DSFont.screenTitle)
                        .foregroundStyle(Color.ds_textPrimary)
                        .scaleEffect(showTitle ? 1 : 0.9)
                        .opacity(showTitle ? 1 : 0)

                    if let goal = coordinator.data.selectedGoal {
                        Text(goal.rawValue)
                            .font(DSFont.body)
                            .foregroundStyle(Color.ds_cyan)
                            .opacity(showTitle ? 1 : 0)
                    }
                }

                // Score card
                VStack(spacing: DSSpacing.md) {
                    HStack {
                        Text("Baseline Score")
                            .font(DSFont.cardTitle)
                            .foregroundStyle(Color.ds_textPrimary)
                        Spacer()
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(overallScore)")
                            .font(DSFont.display(48, weight: .black))
                            .foregroundStyle(Color.ds_cyan)
                        Text("/ 100")
                            .font(DSFont.body)
                            .foregroundStyle(Color.ds_textSecondary)
                    }

                    HStack(spacing: DSSpacing.sm) {
                        SummaryMetric(icon: "figure.stand", label: "Scanned")
                        SummaryMetric(icon: "flame.fill", label: "Habits set")
                        SummaryMetric(icon: "chart.line.uptrend.xyaxis", label: "Tracking")
                    }
                }
                .padding(DSSpacing.lg)
                .background(Color.ds_charcoal)
                .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DSSpacing.cardRadius)
                        .stroke(Color.ds_cardBorder, lineWidth: 1)
                )
                .padding(.horizontal, DSSpacing.screenPadding)
                .opacity(showCards ? 1 : 0)
                .scaleEffect(showCards ? 1 : 0.95)

                // Info card
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text("Your inputs")
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_textSecondary)

                    if let blocker = coordinator.data.selectedBlocker {
                        SummaryRow(icon: "exclamationmark.triangle.fill", label: "Challenge", value: blocker.rawValue)
                    }
                    SummaryRow(icon: "scalemass.fill", label: "Weight", value: "\(Int(coordinator.data.weightKg)) kg → \(Int(coordinator.data.goalWeight)) kg")
                    SummaryRow(icon: "figure.run", label: "Activity", value: coordinator.data.trainingFrequency.rawValue)
                    SummaryRow(icon: "calendar", label: "Timeline", value: coordinator.data.timeline.rawValue)
                }
                .padding(DSSpacing.lg)
                .background(Color.ds_charcoal)
                .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cardRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: DSSpacing.cardRadius)
                        .stroke(Color.ds_cardBorder, lineWidth: 1)
                )
                .padding(.horizontal, DSSpacing.screenPadding)
                .opacity(showCards ? 1 : 0)

                DSPrimaryButton("Let's get started!", icon: "bolt.fill") {
                    DSHaptic.heavy()
                    coordinator.advance()
                }
                .padding(.horizontal, DSSpacing.screenPadding)
                .opacity(showButton ? 1 : 0)

                Spacer().frame(height: DSSpacing.xl)
            }
        }
        .onAppear {
            DSHaptic.celebration()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { showBadge = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) { showTitle = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4)) { showCards = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.7)) { showButton = true }
        }
    }
}

private struct SummaryMetric: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.ds_cyan)
            Text(label)
                .font(DSFont.micro)
                .foregroundStyle(Color.ds_textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DSSpacing.sm)
        .background(Color.ds_navy.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct SummaryRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Color.ds_cyan)
                .frame(width: 20)
            Text(label)
                .font(DSFont.body)
                .foregroundStyle(Color.ds_textSecondary)
            Spacer()
            Text(value)
                .font(DSFont.bodyBold)
                .foregroundStyle(Color.ds_textPrimary)
                .lineLimit(1)
        }
    }
}
