import SwiftUI
import DesignSystem
import IRIS

public struct PaywallView: View {
    @State private var selectedPlan: SubscriptionManager.SubscriptionPlan = .yearly
    @State private var isPurchasing = false
    let onDismiss: () -> Void
    var onTermsTap: (() -> Void)?
    var onPrivacyTap: (() -> Void)?

    public init(
        onDismiss: @escaping () -> Void,
        onTermsTap: (() -> Void)? = nil,
        onPrivacyTap: (() -> Void)? = nil
    ) {
        self.onDismiss = onDismiss
        self.onTermsTap = onTermsTap
        self.onPrivacyTap = onPrivacyTap
    }

    public var body: some View {
        ZStack {
            Color.ds_navy.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: DSSpacing.lg) {
                    // Close button
                    HStack {
                        Spacer()
                        Button {
                            onDismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color.ds_textSecondary)
                        }
                    }
                    .padding(.horizontal, DSSpacing.screenPadding)

                    // Header
                    VStack(spacing: DSSpacing.sm) {
                        IRISSphereView(state: .idle, size: .dashboard)

                        Text("Unlock ASCEND")
                            .font(DSFont.screenTitle)
                            .foregroundStyle(Color.ds_textPrimary)

                        Text("Start your 3-day free trial")
                            .font(DSFont.body)
                            .foregroundStyle(Color.ds_cyan)
                    }

                    // Features
                    VStack(alignment: .leading, spacing: DSSpacing.sm) {
                        featureRow("viewfinder", "Weekly body scans + bonus credits")
                        featureRow("eye.fill", "Full IRIS AI diagnostics")
                        featureRow("chart.line.uptrend.xyaxis", "Week-by-week progress tracking")
                        featureRow("person.3.fill", "Leaderboard & community access")
                        featureRow("diamond.fill", "Diamond milestones & badges")
                        featureRow("bell.fill", "Smart accountability notifications")
                    }
                    .padding(.horizontal, DSSpacing.screenPadding)

                    // Plans
                    VStack(spacing: DSSpacing.sm) {
                        planCard(.yearly, badge: "BEST VALUE")
                        planCard(.monthly, badge: nil)
                    }
                    .padding(.horizontal, DSSpacing.screenPadding)

                    // CTA
                    DSPrimaryButton(
                        isPurchasing ? "Processing..." : "Start Free Trial",
                        icon: isPurchasing ? nil : "lock.open.fill",
                        isLoading: isPurchasing
                    ) {
                        Task {
                            isPurchasing = true
                            let _ = await SubscriptionManager.shared.purchase(plan: selectedPlan)
                            isPurchasing = false
                            onDismiss()
                        }
                    }
                    .padding(.horizontal, DSSpacing.screenPadding)

                    // Restore
                    Button("Restore Purchases") {
                        Task {
                            let _ = await SubscriptionManager.shared.restorePurchases()
                        }
                    }
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_cyan)

                    // Disclosures
                    VStack(spacing: DSSpacing.xs) {
                        Text("No payment due now. After your 3-day free trial, your subscription will automatically renew at the selected price.")
                            .font(DSFont.micro)
                            .foregroundStyle(Color.ds_textSecondary.opacity(0.7))
                            .multilineTextAlignment(.center)

                        Text("Subscription auto-renews unless cancelled at least 24 hours before the end of the current period. Manage in Settings > Apple ID > Subscriptions.")
                            .font(DSFont.micro)
                            .foregroundStyle(Color.ds_textSecondary.opacity(0.5))
                            .multilineTextAlignment(.center)

                        HStack(spacing: DSSpacing.md) {
                            linkButton("Terms of Use")
                            linkButton("Privacy Policy")
                        }
                        .padding(.top, DSSpacing.xs)

                        Text("ASCEND is not a medical device. AI feedback is for fitness guidance only.")
                            .font(DSFont.micro)
                            .foregroundStyle(Color.ds_textSecondary.opacity(0.4))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, DSSpacing.screenPadding)
                    .padding(.bottom, DSSpacing.xl)
                }
            }
        }
    }

    private func featureRow(_ icon: String, _ text: String) -> some View {
        HStack(spacing: DSSpacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(Color.ds_cyan)
            Text(text)
                .font(DSFont.body)
                .foregroundStyle(Color.ds_textPrimary)
            Spacer()
        }
    }

    private func planCard(_ plan: SubscriptionManager.SubscriptionPlan, badge: String?) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            selectedPlan = plan
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(plan.displayName)
                            .font(DSFont.bodyBold)
                            .foregroundStyle(isSelected ? Color.ds_cyan : Color.ds_textPrimary)
                        if let badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.ds_navy)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.ds_cyan)
                                .clipShape(Capsule())
                        }
                    }
                    Text(plan == .yearly ? "Save 75% — just $2.50/mo" : "$119.88/year")
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_textSecondary)
                }
                Spacer()
                Text(plan.price)
                    .font(DSFont.captionBold)
                    .foregroundStyle(isSelected ? Color.ds_cyan : Color.ds_textSecondary)
            }
            .padding(DSSpacing.md)
            .background(isSelected ? Color.ds_cyan.opacity(0.1) : Color.ds_charcoal)
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.cardRadius)
                    .stroke(isSelected ? Color.ds_cyan : Color.ds_cardBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
    }

    private func linkButton(_ title: String) -> some View {
        Button(title) {
            if title == "Terms of Use" {
                onTermsTap?()
            } else {
                onPrivacyTap?()
            }
        }
        .font(DSFont.micro)
        .foregroundStyle(Color.ds_cyan.opacity(0.6))
    }
}
