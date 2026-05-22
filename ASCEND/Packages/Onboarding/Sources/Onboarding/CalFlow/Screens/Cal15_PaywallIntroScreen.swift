import SwiftUI
import DesignSystem
import StoreKit

struct Cal15_PaywallIntroScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var showTitle = false
    @State private var showFeatures = false
    @State private var showCTA = false
    @State private var revealedFeatures: Set<Int> = []
    @State private var ctaGlow = false
    @Environment(\.openURL) private var openURL

    private let features: [(icon: String, text: String)] = [
        ("viewfinder", "Weekly body scans with AI analysis"),
        ("eye.fill", "Full IRIS AI diagnostics"),
        ("chart.line.uptrend.xyaxis", "Week-by-week progress tracking"),
        ("person.3.fill", "Leaderboard & community"),
        ("diamond.fill", "Diamond milestones & badges"),
        ("bell.fill", "Smart accountability notifications"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DSSpacing.lg) {
                Spacer().frame(height: DSSpacing.xl)

                Text("Try ASCEND for free")
                    .font(DSFont.screenTitle)
                    .foregroundStyle(Color.ds_textPrimary)
                    .scaleEffect(showTitle ? 1 : 0.9)
                    .opacity(showTitle ? 1 : 0)

                Text("3-day free trial, cancel anytime")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textSecondary)
                    .opacity(showTitle ? 1 : 0)

                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                        let isRevealed = revealedFeatures.contains(index)
                        HStack(spacing: DSSpacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(Color.ds_cyan.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                Image(systemName: feature.icon)
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.ds_cyan)
                            }
                            Text(feature.text)
                                .font(DSFont.body)
                                .foregroundStyle(Color.ds_textPrimary)
                            Spacer()
                        }
                        .opacity(isRevealed ? 1 : 0)
                        .offset(x: isRevealed ? 0 : -20)
                    }
                }
                .padding(.horizontal, DSSpacing.screenPadding)

                Spacer().frame(height: DSSpacing.md)

                VStack(spacing: DSSpacing.sm) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.ds_cyan)
                        Text("No Payment Due Now")
                            .font(DSFont.caption)
                            .foregroundStyle(Color.ds_textSecondary)
                    }

                    DSPrimaryButton("Try Now", icon: "lock.open.fill") {
                        DSHaptic.medium()
                        coordinator.advance()
                    }
                    .shadow(color: ctaGlow ? Color.ds_cyan.opacity(0.4) : .clear, radius: ctaGlow ? 20 : 0)

                    Text("Just $29.99 per year ($2.49/mo)")
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_textSecondary.opacity(0.4))

                    HStack(spacing: DSSpacing.md) {
                        Button("Restore") {
                            Task { try? await AppStore.sync() }
                        }
                            .font(DSFont.micro)
                            .foregroundStyle(Color.ds_cyan.opacity(0.6))
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
                    }
                }
                .padding(.horizontal, DSSpacing.screenPadding)
                .opacity(showCTA ? 1 : 0)

                Spacer().frame(height: DSSpacing.xl)
            }
        }
        .onAppear {
            DSHaptic.paywallReveal()
            withAnimation(.easeOut(duration: 0.5)) { showTitle = true }
            for i in 0..<features.count {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.3 + Double(i) * 0.1)) {
                    revealedFeatures.insert(i)
                }
            }
            let featuresDone = 0.3 + Double(features.count) * 0.1
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(featuresDone + 0.1)) { showCTA = true }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(featuresDone + 0.3)) { ctaGlow = true }
        }
    }
}
