import SwiftUI
import DesignSystem
import HealthKit

struct Cal06_HealthConnectScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showButton = false
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

                    Image(systemName: "heart.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.ds_cyan)
                        .scaleEffect(showIcon ? 1 : 0.3)
                        .opacity(showIcon ? 1 : 0)
                }
                .dsPulsingGlow(color: Color.ds_cyan, radius: 15)

                VStack(spacing: DSSpacing.sm) {
                    Text("Connect Apple Health")
                        .font(DSFont.screenTitle)
                        .foregroundStyle(Color.ds_textPrimary)
                        .scaleEffect(showTitle ? 1 : 0.9)
                        .opacity(showTitle ? 1 : 0)

                    Text("Sync your steps, sleep, and activity data for the most thorough tracking.")
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
                DSPrimaryButton("Continue", icon: "heart.fill") {
                    DSHaptic.medium()
                    requestHealthKit()
                }

                Button("Skip") {
                    coordinator.advance()
                }
                .font(DSFont.body)
                .foregroundStyle(Color.ds_textSecondary)
            }
            .padding(.horizontal, DSSpacing.screenPadding)
            .padding(.bottom, DSSpacing.xl)
            .opacity(showButton ? 1 : 0)
            .scaleEffect(showButton ? 1 : 0.9)
        }
        .onAppear {
            DSHaptic.screenEntry()
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) { showIcon = true }
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) { ringRotate = true }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.3)) { iconPulse = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) { showTitle = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6)) { showButton = true }
        }
    }

    private func requestHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else {
            coordinator.advance()
            return
        }
        Task {
            let store = HKHealthStore()
            let readTypes: Set<HKSampleType> = [
                HKQuantityType(.stepCount),
                HKQuantityType(.activeEnergyBurned),
                HKCategoryType(.sleepAnalysis),
            ]
            do {
                try await store.requestAuthorization(toShare: [], read: readTypes)
                coordinator.data.healthKitGranted = true
            } catch {
                coordinator.data.healthKitGranted = false
            }
            coordinator.advance()
        }
    }
}

