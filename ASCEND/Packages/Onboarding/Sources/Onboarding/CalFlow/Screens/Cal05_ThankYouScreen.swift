import SwiftUI
import DesignSystem

struct Cal05_ThankYouScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var showHero = false
    @State private var showTitle = false
    @State private var showCard = false
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
                                Color.ds_purple.opacity(0.3),
                                Color.ds_cyan.opacity(0.3),
                                Color.ds_purple.opacity(0.2),
                                Color.ds_cyan.opacity(0.2),
                                Color.ds_purple.opacity(0.3)
                            ],
                            center: .center,
                            startAngle: .degrees(gradientRotation),
                            endAngle: .degrees(gradientRotation + 360)
                        )
                    )
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)

                Text("👏")
                    .font(.system(size: 64))
            }
            .scaleEffect(showHero ? 1 : 0.3)
            .opacity(showHero ? 1 : 0)

            VStack(spacing: DSSpacing.sm) {
                Text("Thank you!")
                    .font(DSFont.screenTitle)
                    .foregroundStyle(Color.ds_textPrimary)
                    .scaleEffect(showTitle ? 1 : 0.9)
                    .opacity(showTitle ? 1 : 0)

                Text("Now let's personalize ASCEND for you...")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textSecondary)
                    .opacity(showTitle ? 1 : 0)
            }

            VStack(spacing: DSSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(Color.ds_cyan.opacity(0.1))
                        .frame(width: 48, height: 48)
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.ds_cyan)
                }

                Text("Personalized to your goals")
                    .font(DSFont.cardTitle)
                    .foregroundStyle(Color.ds_textPrimary)

                Text("We'll use your answers to tailor your plan, targets, and recommendations.")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(DSSpacing.lg)
            .background(Color.ds_charcoal)
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.cardRadius)
                    .stroke(Color.ds_cardBorder, lineWidth: 1)
            )
            .padding(.horizontal, DSSpacing.screenPadding)
            .opacity(showCard ? 1 : 0)
            .offset(y: showCard ? 0 : 20)

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
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) { showTitle = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6)) { showCard = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.9)) { showButton = true }
        }
    }
}
