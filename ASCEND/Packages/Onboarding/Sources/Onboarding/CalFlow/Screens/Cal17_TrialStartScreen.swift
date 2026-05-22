import SwiftUI
import DesignSystem
import Paywall

struct Cal17_TrialStartScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var selectedPlan: SubscriptionManager.SubscriptionPlan = .yearly
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var showTitle = false
    @State private var showTimeline = false
    @State private var showPlans = false
    @State private var showCTA = false
    @Environment(\.openURL) private var openURL

    private var trialEndDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date())
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DSSpacing.lg) {
                Spacer().frame(height: DSSpacing.lg)

                Text("Start your 3-day\nFREE trial")
                    .font(DSFont.screenTitle)
                    .foregroundStyle(Color.ds_textPrimary)
                    .multilineTextAlignment(.center)
                    .opacity(showTitle ? 1 : 0)

                VStack(alignment: .leading, spacing: 0) {
                    TrialTimelineStep(
                        icon: "lock.open.fill", iconColor: Color.ds_cyan,
                        title: "Today",
                        subtitle: "Unlock all features including AI body scanning and IRIS diagnostics.",
                        isLast: false
                    )
                    TrialTimelineStep(
                        icon: "bell.fill", iconColor: Color.ds_cyan,
                        title: "In 2 Days — Reminder",
                        subtitle: "We'll remind you that your trial is ending soon.",
                        isLast: false
                    )
                    TrialTimelineStep(
                        icon: "crown.fill", iconColor: Color.ds_textPrimary,
                        title: "In 3 Days — Billing Starts",
                        subtitle: "You'll be charged on \(trialEndDate) unless you cancel.",
                        isLast: true
                    )
                }
                .padding(.horizontal, DSSpacing.screenPadding + 8)
                .opacity(showTimeline ? 1 : 0)
                .offset(y: showTimeline ? 0 : 15)

                HStack(spacing: DSSpacing.sm) {
                    TrialPlanCard(
                        title: "Monthly", price: "$9.99/mo", badge: nil,
                        isSelected: selectedPlan == .monthly
                    ) {
                        DSHaptic.optionSelect()
                        selectedPlan = .monthly
                    }
                    TrialPlanCard(
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
                        Text("No Payment Due Now")
                            .font(DSFont.caption)
                            .foregroundStyle(Color.ds_textSecondary)
                    }

                    if let error = purchaseError {
                        Text(error)
                            .font(DSFont.micro)
                            .foregroundStyle(Color.ds_red)
                    }

                    DSPrimaryButton(
                        isPurchasing ? "Processing..." : "Start Free Trial",
                        icon: isPurchasing ? nil : "lock.open.fill",
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

                    Button("Already purchased?") {
                        Task {
                            isPurchasing = true
                            let restored = await SubscriptionManager.shared.restorePurchases()
                            isPurchasing = false
                            if restored { coordinator.advance() }
                        }
                    }
                    .font(DSFont.micro)
                    .foregroundStyle(Color.ds_cyan.opacity(0.6))
                    .disabled(isPurchasing)

                    Text(selectedPlan == .yearly
                         ? "3 days free, then $29.99/year. Plan auto-renews unless you cancel."
                         : "Just $9.99/month. Plan auto-renews unless you cancel.")
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
                                let restored = await SubscriptionManager.shared.restorePurchases()
                                isPurchasing = false
                                if restored { coordinator.advance() }
                            }
                        }
                            .font(DSFont.micro)
                            .foregroundStyle(Color.ds_cyan.opacity(0.6))
                            .disabled(isPurchasing)
                    }
                }
                .padding(.horizontal, DSSpacing.screenPadding)
                .opacity(showCTA ? 1 : 0)

                Spacer().frame(height: DSSpacing.xl)
            }
        }
        .onAppear {
            DSHaptic.paywallReveal()
            Task { await SubscriptionManager.shared.loadProducts() }
            withAnimation(.easeOut(duration: 0.5)) { showTitle = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) { showTimeline = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) { showPlans = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.7)) { showCTA = true }
        }
    }
}

private struct TrialTimelineStep: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: DSSpacing.md) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(iconColor)
                }
                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.ds_cyan.opacity(0.3), Color.ds_textSecondary.opacity(0.1)],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 2, height: 40)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(DSFont.bodyBold)
                    .foregroundStyle(Color.ds_textPrimary)
                Text(subtitle)
                    .font(DSFont.caption)
                    .foregroundStyle(Color.ds_textSecondary)
                    .lineSpacing(2)
            }
            .padding(.bottom, isLast ? 0 : DSSpacing.md)
        }
    }
}

private struct TrialPlanCard: View {
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
