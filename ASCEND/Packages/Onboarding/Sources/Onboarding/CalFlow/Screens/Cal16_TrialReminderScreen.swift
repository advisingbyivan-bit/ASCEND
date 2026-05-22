import SwiftUI
import DesignSystem
import StoreKit

struct Cal16_TrialReminderScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var showTitle = false
    @State private var showBell = false
    @State private var showCTA = false
    @State private var bellSwing = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            Spacer()

            Text("We'll remind you\nbefore your trial ends")
                .font(DSFont.screenTitle)
                .foregroundStyle(Color.ds_textPrimary)
                .multilineTextAlignment(.center)
                .opacity(showTitle ? 1 : 0)
                .offset(y: showTitle ? 0 : 15)

            Spacer().frame(height: DSSpacing.lg)

            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.ds_textSecondary.opacity(0.3))
                    .rotationEffect(.degrees(bellSwing ? 8 : -8))

                ZStack {
                    Circle()
                        .fill(Color.ds_red)
                        .frame(width: 28, height: 28)
                    Text("1")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
                .offset(x: 8, y: -8)
            }
            .opacity(showBell ? 1 : 0)
            .scaleEffect(showBell ? 1 : 0.5)

            Spacer()

            VStack(spacing: DSSpacing.sm) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.ds_cyan)
                    Text("No Payment Due Now")
                        .font(DSFont.caption)
                        .foregroundStyle(Color.ds_textSecondary)
                }

                DSPrimaryButton("Continue for FREE", icon: "arrow.right") {
                    DSHaptic.medium()
                    coordinator.advance()
                }

                Text("Billing starts at the end of your free trial unless you cancel. Plans auto-renew.")
                    .font(DSFont.micro)
                    .foregroundStyle(Color.ds_textSecondary.opacity(0.4))
                    .multilineTextAlignment(.center)
                    .padding(.top, DSSpacing.xs)

                HStack(spacing: DSSpacing.md) {
                    Button("Terms") {
                        openURL(URL(string: "https://ascendapp.us/terms")!)
                    }
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_cyan.opacity(0.6))
                    Button("Privacy") {
                        openURL(URL(string: "https://ascendapp.us/privacy")!)
                    }
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_cyan.opacity(0.6))
                    Button("Restore") {
                        Task { try? await AppStore.sync() }
                    }
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_cyan.opacity(0.6))
                }
            }
            .padding(.horizontal, DSSpacing.screenPadding)
            .padding(.bottom, DSSpacing.lg)
            .opacity(showCTA ? 1 : 0)
        }
        .onAppear {
            DSHaptic.screenEntry()
            withAnimation(.easeOut(duration: 0.5)) { showTitle = true }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.5).delay(0.3)) { showBell = true }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) { bellSwing = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) { showCTA = true }
        }
    }
}
