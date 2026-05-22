import SwiftUI
import DesignSystem
import IRIS

struct OnboardingCompleteScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var showConfetti = false
    @State private var showIris = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showButton = false
    @State private var titleGlow = false

    var body: some View {
        ZStack {
            // Ambient particles for celebration
            if showConfetti {
                DSFloatingParticles(count: 30, colors: [
                    Color.ds_cyan.opacity(0.5),
                    Color.ds_purple.opacity(0.4),
                    Color.ds_green.opacity(0.3)
                ])
                .ignoresSafeArea()
                .transition(.opacity)
            }

            VStack(spacing: DSSpacing.xl) {
                Spacer()

                // Confetti + IRIS celebration
                ZStack {
                    if showConfetti {
                        DSConfettiView()
                            .frame(height: 250)
                            .allowsHitTesting(false)
                    }

                    IRISSphereView(state: .celebration, size: .full)
                        .scaleEffect(showIris ? 1 : 0.2)
                        .opacity(showIris ? 1 : 0)
                }

                VStack(spacing: DSSpacing.sm) {
                    Text("You're In")
                        .font(DSFont.heroTitle)
                        .foregroundStyle(Color.ds_cyan)
                        .tracking(2)
                        .scaleEffect(showTitle ? 1 : 0.5)
                        .opacity(showTitle ? 1 : 0)
                        .shadow(color: titleGlow ? Color.ds_cyan.opacity(0.5) : .clear, radius: titleGlow ? 20 : 0)

                    Text("IRIS is watching. Your 12-week countdown starts now.")
                        .font(DSFont.body)
                        .foregroundStyle(Color.ds_textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DSSpacing.md)
                        .offset(y: showSubtitle ? 0 : 15)
                        .opacity(showSubtitle ? 1 : 0)
                }

                Spacer()

                DSPrimaryButton("Enter ASCEND", icon: "arrow.right") {
                    DSHaptic.celebration()
                    coordinator.finishOnboarding()
                }
                .padding(.horizontal, DSSpacing.screenPadding)
                .padding(.bottom, DSSpacing.xl)
                .scaleEffect(showButton ? 1 : 0.9)
                .opacity(showButton ? 1 : 0)
            }
        }
        .onAppear {
            // Phase 1: IRIS sphere bursts in
            DSHaptic.celebration()

            withAnimation(.spring(response: 0.7, dampingFraction: 0.5)) {
                showIris = true
            }

            // Phase 2: Confetti explosion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showConfetti = true
                }
                DSHaptic.heavy()
            }

            // Phase 3: Title slams in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.6)) {
                showTitle = true
            }

            // Title glow pulse
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.8)) {
                titleGlow = true
            }

            // Subtitle
            withAnimation(.easeOut(duration: 0.5).delay(0.9)) {
                showSubtitle = true
            }

            // CTA
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.3)) {
                showButton = true
            }

            // Final haptic flourish
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                DSHaptic.diamondUnlock()
            }
        }
    }
}
