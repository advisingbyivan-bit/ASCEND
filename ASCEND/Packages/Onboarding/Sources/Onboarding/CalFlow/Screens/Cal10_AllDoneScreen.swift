import SwiftUI
import DesignSystem

struct Cal10_AllDoneScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var showHero = false
    @State private var showBadge = false
    @State private var showTitle = false
    @State private var showButton = false
    @State private var gradientRotation: Double = 0

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                Color.ds_cyan.opacity(0.3),
                                Color.ds_purple.opacity(0.3),
                                Color.ds_cyan.opacity(0.2),
                                Color.ds_purple.opacity(0.2),
                                Color.ds_cyan.opacity(0.3)
                            ],
                            center: .center,
                            startAngle: .degrees(gradientRotation),
                            endAngle: .degrees(gradientRotation + 360)
                        )
                    )
                    .frame(width: 180, height: 180)
                    .blur(radius: 25)

                Text("🫰")
                    .font(.system(size: 72))
            }
            .scaleEffect(showHero ? 1 : 0.3)
            .opacity(showHero ? 1 : 0)

            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.ds_cyan)
                Text("All done!")
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_cyan)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.ds_cyan.opacity(0.1))
            .clipShape(Capsule())
            .opacity(showBadge ? 1 : 0)
            .scaleEffect(showBadge ? 1 : 0.8)

            VStack(spacing: DSSpacing.sm) {
                Text("Time for your first scan!")
                    .font(DSFont.screenTitle)
                    .foregroundStyle(Color.ds_textPrimary)
                    .scaleEffect(showTitle ? 1 : 0.9)
                    .opacity(showTitle ? 1 : 0)

                Text("Let's see where you're starting from")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textSecondary)
                    .opacity(showTitle ? 1 : 0)
            }

            Spacer()

            DSPrimaryButton("Continue", icon: "arrow.right") {
                DSHaptic.medium()
                coordinator.advance()
            }
            .padding(.horizontal, DSSpacing.screenPadding)
            .padding(.bottom, DSSpacing.xl)
            .opacity(showButton ? 1 : 0)
            .scaleEffect(showButton ? 1 : 0.9)
        }
        .onAppear {
            DSHaptic.celebration()
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) { showHero = true }
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) { gradientRotation = 360 }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.4)) { showBadge = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.6)) { showTitle = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.9)) { showButton = true }
        }
    }
}
