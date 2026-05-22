import SwiftUI
import DesignSystem
import Paywall

struct Cal18_MonthlyFallbackScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var selectedPlan: SubscriptionManager.SubscriptionPlan = .monthly
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var showTitle = false
    @State private var showFeatures = false
    @State private var showPlans = false
    @State private var showCTA = false
    @Environment(\.openURL) private var openURL

    private let features: [(icon: String, title: String, subtitle: String)] = [
        ("viewfinder", "AI body scanning", "Track your physique with just a photo"),
        ("waveform.path.ecg", "IRIS diagnostics", "Get AI-powered insights on every scan"),
        ("chart.line.uptrend.xyaxis", "Track your progress", "Stay on track with personalized insights"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DSSpacing.lg) {
                Spacer().frame(height: DSSpacing.lg)

                Text("Unlock ASCEND")
                    .font(DSFont.screenTitle)
                    .foregroundStyle(Color.ds_textPrimary)
                    .opacity(showTitle ? 1 : 0)

                Text("Reach your goals faster")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textSecondary)
                    .opacity(showTitle ? 1 : 0)

                VStack(alignment: .leading, spacing: DSSpacing.lg) {
                    ForEach(Array(features.enumerated()), id: \.offset) { _, feature in
                        HStack(alignment: .top, spacing: DSSpacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(Color.ds_cyan.opacity(0.1))
                                    .frame(width: 36, height: 36)
                                Image(systemName: feature.icon)
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color.ds_cyan)
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(feature.title)
                                    .font(DSFont.bodyBold)
                                    .foregroundStyle(Color.ds_textPrimary)
                                Text(feature.subtitle)
                                    .font(DSFont.caption)
                                    .foregroundStyle(Color.ds_textSecondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, DSSpacing.screenPadding)
                .opacity(showFeatures ? 1 : 0)
                .offset(y: showFeatures ? 0 : 15)

                HStack(spacing: DSSpacing.sm) {
                    FallbackPlanCard2(
                        title: "Monthly", price: "$9.99/mo", badge: nil,
                        isSelected: selectedPlan == .monthly
                    ) {
                        DSHaptic.optionSelect()
                        selectedPlan = .monthly
                    }
                    FallbackPlanCard2(
                        title: "Yearly", price: "$29.99", badge: "3 DAYS FREE",
                        isSelected: selectedPlan == .yearly
                    ) {
                        DSHaptic.optionSelect()
                        selectedPlan = .yearly
                    }
                }
                .padding(.horizontal, DSSpacing.screenPadding)
                .opacity(showPlans ? 1 : 0)
                .scaleEffect(showPlans ? 1 : 0.95)

                VStack(spacing: DSSpacing.sm) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Color.ds_cyan)
                        Text("No Commitment — Cancel Anytime")
                            .font(DSFont.caption)
                            .foregroundStyle(Color.ds_textSecondary)
                    }

                    if let error = purchaseError {
                        Text(error)
                            .font(DSFont.micro)
                            .foregroundStyle(Color.ds_red)
                    }

                    DSPrimaryButton(
                        isPurchasing ? "Processing..." : "Start My Journey",
                        icon: isPurchasing ? nil : "arrow.right",
                        isLoading: isPurchasing
                    ) {
                        Task {
                            isPurchasing = true
                            purchaseError = nil
                            let success = await SubscriptionManager.shared.purchase(plan: selectedPlan)
                            isPurchasing = false
                            if success {
                                DSHaptic.celebration()
                                coordinator.data.didPurchase = true
                                coordinator.advance()
                            } else if let err = SubscriptionManager.shared.purchaseError {
                                purchaseError = err
                            }
                        }
                    }
                    .disabled(isPurchasing)

                    Button("Continue with limited access") {
                        coordinator.advance()
                    }
                    .font(DSFont.caption)
                    .foregroundStyle(Color.ds_textSecondary.opacity(0.5))

                    Text(selectedPlan == .monthly
                         ? "$9.99/month. Plan auto-renews unless you cancel."
                         : "3 days free, then $29.99/year. Plan auto-renews unless you cancel.")
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_textSecondary.opacity(0.35))
                        .multilineTextAlignment(.center)

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
                            Task {
                                isPurchasing = true
                                purchaseError = nil
                                let restored = await SubscriptionManager.shared.restorePurchases()
                                isPurchasing = false
                                if restored {
                                    DSHaptic.celebration()
                                    coordinator.advance()
                                }
                            }
                        }
                            .font(DSFont.micro)
                            .foregroundStyle(Color.ds_cyan.opacity(0.6))
                            .disabled(isPurchasing)
                    }

                    Text("ASCEND is not a medical device. AI feedback is for fitness guidance only.")
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_textSecondary.opacity(0.3))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, DSSpacing.screenPadding)
                .opacity(showCTA ? 1 : 0)

                Spacer().frame(height: DSSpacing.xl)
            }
        }
        .onAppear {
            DSHaptic.paywallReveal()
            withAnimation(.easeOut(duration: 0.5)) { showTitle = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) { showFeatures = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) { showPlans = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.7)) { showCTA = true }
        }
    }
}

private struct FallbackPlanCard2: View {
    let title: String
    let price: String
    let badge: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: DSSpacing.xs) {
                if let badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.ds_navy)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.ds_cyan)
                        .clipShape(Capsule())
                } else {
                    Spacer().frame(height: 22)
                }
                Text(title)
                    .font(DSFont.bodyBold)
                    .foregroundStyle(isSelected ? Color.ds_cyan : Color.ds_textPrimary)
                Text(price)
                    .font(DSFont.captionBold)
                    .foregroundStyle(isSelected ? Color.ds_cyan : Color.ds_textSecondary)
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.ds_cyan : Color.ds_textSecondary.opacity(0.3), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.ds_cyan)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.vertical, DSSpacing.md)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.ds_cyan.opacity(0.1) : Color.ds_charcoal)
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.cardRadius)
                    .stroke(isSelected ? Color.ds_cyan : Color.ds_cardBorder, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: isSelected ? Color.ds_cyan.opacity(0.2) : .clear, radius: 10)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}
