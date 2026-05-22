import SwiftUI
import DesignSystem

struct Cal03_GoalsScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showCards = false

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            Spacer()

            VStack(spacing: DSSpacing.lg) {
                Text("What's your goal?")
                    .font(DSFont.screenTitle)
                    .foregroundStyle(Color.ds_textPrimary)
                    .scaleEffect(showTitle ? 1 : 0.9)
                    .opacity(showTitle ? 1 : 0)

                Text("Pick the one that resonates most")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textSecondary)
                    .offset(y: showSubtitle ? 0 : 10)
                    .opacity(showSubtitle ? 1 : 0)
            }

            VStack(spacing: 12) {
                ForEach(CalGoal.allCases) { goal in
                    CalOptionCard(
                        icon: goal.icon,
                        label: goal.rawValue,
                        isSelected: coordinator.data.selectedGoal == goal
                    ) {
                        DSHaptic.optionSelect()
                        coordinator.data.selectedGoal = goal
                    }
                }
            }
            .padding(.horizontal, DSSpacing.screenPadding)
            .opacity(showCards ? 1 : 0)
            .offset(y: showCards ? 0 : 15)

            Spacer()

            if coordinator.data.selectedGoal != nil {
                DSPrimaryButton("Continue", icon: "arrow.right") {
                    DSHaptic.medium()
                    coordinator.advance()
                }
                .padding(.horizontal, DSSpacing.screenPadding)
                .padding(.bottom, DSSpacing.xl)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            } else {
                DSDisabledButton("Select a goal")
                    .padding(.horizontal, DSSpacing.screenPadding)
                    .padding(.bottom, DSSpacing.xl)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: coordinator.data.selectedGoal != nil)
        .onAppear {
            DSHaptic.screenEntry()
            withAnimation(.easeOut(duration: 0.5)) { showTitle = true }
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) { showSubtitle = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.4)) { showCards = true }
        }
    }
}
