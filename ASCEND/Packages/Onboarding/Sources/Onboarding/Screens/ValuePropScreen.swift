import SwiftUI
import DesignSystem

struct ValuePropScreen: View {
    let coordinator: OnboardingCoordinator
    let icon: String
    let title: String
    let subtitle: String

    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showButton = false
    @State private var iconPulse = false
    @State private var ringRotate = false

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            Spacer()

            VStack(spacing: DSSpacing.lg) {
                // Animated icon with orbital ring
                ZStack {
                    // Outer orbital ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [Color.ds_cyan.opacity(0.4), Color.ds_purple.opacity(0.2), Color.ds_cyan.opacity(0.4)],
                                center: .center
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(ringRotate ? 360 : 0))
                        .opacity(showIcon ? 1 : 0)
                        .scaleEffect(showIcon ? 1 : 0.5)

                    // Background glow
                    Circle()
                        .fill(Color.ds_cyan.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(iconPulse ? 1.1 : 1.0)
                        .opacity(showIcon ? 1 : 0)

                    // Icon
                    Image(systemName: icon)
                        .font(.system(size: 48))
                        .foregroundStyle(Color.ds_cyan)
                        .scaleEffect(showIcon ? 1 : 0.3)
                        .opacity(showIcon ? 1 : 0)
                }
                .dsPulsingGlow(color: Color.ds_cyan, radius: 15)

                VStack(spacing: DSSpacing.sm) {
                    Text(title)
                        .font(DSFont.screenTitle)
                        .foregroundStyle(Color.ds_textPrimary)
                        .multilineTextAlignment(.center)
                        .scaleEffect(showTitle ? 1 : 0.9)
                        .opacity(showTitle ? 1 : 0)

                    Text(subtitle)
                        .font(DSFont.body)
                        .foregroundStyle(Color.ds_textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DSSpacing.md)
                        .offset(y: showSubtitle ? 0 : 15)
                        .opacity(showSubtitle ? 1 : 0)
                }
            }

            Spacer()

            VStack(spacing: DSSpacing.sm) {
                DSPrimaryButton("Continue", icon: "arrow.right") {
                    DSHaptic.medium()
                    coordinator.advance()
                }
                .scaleEffect(showButton ? 1 : 0.9)
                .opacity(showButton ? 1 : 0)
            }
            .padding(.horizontal, DSSpacing.screenPadding)
            .padding(.bottom, DSSpacing.xl)
        }
        .onAppear {
            DSHaptic.screenEntry()

            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                showIcon = true
            }

            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                ringRotate = true
            }

            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.3)) {
                iconPulse = true
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                showTitle = true
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
                showSubtitle = true
            }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.8)) {
                showButton = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                DSHaptic.anticipationBuild()
            }
        }
    }
}
