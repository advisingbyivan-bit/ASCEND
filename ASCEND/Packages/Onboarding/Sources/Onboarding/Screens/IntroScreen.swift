import SwiftUI
import DesignSystem

struct IntroScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var showTitle = false
    @State private var showSteps = false
    @State private var showCTA = false
    @State private var revealedSteps: Set<Int> = []

    private let steps: [(icon: String, title: String, subtitle: String)] = [
        ("camera.viewfinder", "Scan your body", "Take a quick 3-angle photo scan using your camera"),
        ("eye.fill", "Get AI diagnostics", "IRIS analyzes your physique and gives you a baseline score"),
        ("chart.line.uptrend.xyaxis", "Track your progress", "Scan weekly and watch your transformation over time"),
    ]

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            Spacer()

            VStack(spacing: DSSpacing.sm) {
                Text("How ASCEND works")
                    .font(DSFont.screenTitle)
                    .foregroundStyle(Color.ds_textPrimary)
                    .opacity(showTitle ? 1 : 0)
                    .scaleEffect(showTitle ? 1 : 0.9)

                Text("Your AI-powered body transformation companion")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textSecondary)
                    .multilineTextAlignment(.center)
                    .opacity(showTitle ? 1 : 0)
            }

            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    let isRevealed = revealedSteps.contains(index)
                    HStack(alignment: .top, spacing: DSSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(Color.ds_cyan.opacity(0.1))
                                .frame(width: 48, height: 48)
                            Image(systemName: step.icon)
                                .font(.system(size: 20))
                                .foregroundStyle(Color.ds_cyan)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(step.title)
                                .font(DSFont.bodyBold)
                                .foregroundStyle(Color.ds_textPrimary)
                            Text(step.subtitle)
                                .font(DSFont.caption)
                                .foregroundStyle(Color.ds_textSecondary)
                        }
                    }
                    .opacity(isRevealed ? 1 : 0)
                    .offset(x: isRevealed ? 0 : -20)
                }
            }
            .padding(.horizontal, DSSpacing.screenPadding)

            Spacer()

            DSPrimaryButton("Let's go", icon: "arrow.right") {
                DSHaptic.medium()
                coordinator.advance()
            }
            .padding(.horizontal, DSSpacing.screenPadding)
            .padding(.bottom, DSSpacing.xl)
            .opacity(showCTA ? 1 : 0)
        }
        .onAppear {
            DSHaptic.screenEntry()
            withAnimation(.easeOut(duration: 0.5)) { showTitle = true }
            for i in 0..<steps.count {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.3 + Double(i) * 0.15)) {
                    revealedSteps.insert(i)
                }
            }
            let stepsDone = 0.3 + Double(steps.count) * 0.15
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(stepsDone + 0.1)) { showCTA = true }
        }
    }
}
