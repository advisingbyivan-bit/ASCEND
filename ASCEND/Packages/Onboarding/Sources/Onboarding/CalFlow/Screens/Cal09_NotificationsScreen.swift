import SwiftUI
import DesignSystem
import UserNotifications

struct Cal09_NotificationsScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showButtons = false
    @State private var iconPulse = false
    @State private var ringRotate = false

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            Spacer()

            VStack(spacing: DSSpacing.lg) {
                ZStack {
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

                    Circle()
                        .fill(Color.ds_cyan.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(iconPulse ? 1.1 : 1.0)
                        .opacity(showIcon ? 1 : 0)

                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.ds_cyan)
                        .scaleEffect(showIcon ? 1 : 0.3)
                        .opacity(showIcon ? 1 : 0)
                }
                .dsPulsingGlow(color: Color.ds_cyan, radius: 15)

                VStack(spacing: DSSpacing.sm) {
                    Text("Stay on track")
                        .font(DSFont.screenTitle)
                        .foregroundStyle(Color.ds_textPrimary)
                        .scaleEffect(showTitle ? 1 : 0.9)
                        .opacity(showTitle ? 1 : 0)

                    Text("Enable notifications to get scan reminders and streak alerts.")
                        .font(DSFont.body)
                        .foregroundStyle(Color.ds_textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DSSpacing.md)
                        .offset(y: showTitle ? 0 : 10)
                        .opacity(showTitle ? 1 : 0)
                }
            }

            Spacer()

            VStack(spacing: DSSpacing.sm) {
                DSPrimaryButton("Enable Notifications", icon: "bell.fill") {
                    DSHaptic.medium()
                    requestNotifications()
                }

                Button("Skip") {
                    coordinator.advance()
                }
                .font(DSFont.body)
                .foregroundStyle(Color.ds_textSecondary)
            }
            .padding(.horizontal, DSSpacing.screenPadding)
            .padding(.bottom, DSSpacing.xl)
            .opacity(showButtons ? 1 : 0)
            .scaleEffect(showButtons ? 1 : 0.9)
        }
        .onAppear {
            DSHaptic.screenEntry()
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) { showIcon = true }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) { ringRotate = true }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.3)) { iconPulse = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) { showTitle = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6)) { showButtons = true }
        }
    }

    private func requestNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                coordinator.data.notificationsGranted = granted
                coordinator.advance()
            }
        }
    }
}
