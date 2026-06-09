import SwiftUI
import DesignSystem
import IRIS

public struct PaywallView: View {
    @State private var selectedPlan: SubscriptionManager.SubscriptionPlan = .yearly
    @State private var isPurchasing = false
    @State private var isRestoring = false
    let onDismiss: () -> Void
    var onTermsTap: (() -> Void)?
    var onPrivacyTap: (() -> Void)?
    /// Called to open web checkout in Safari. Set by the parent view.
    var onWebCheckout: ((String) -> Void)?

    public init(
        onDismiss: @escaping () -> Void,
        onTermsTap: (() -> Void)? = nil,
        onPrivacyTap: (() -> Void)? = nil,
        onWebCheckout: ((String) -> Void)? = nil
    ) {
        self.onDismiss = onDismiss
        self.onTermsTap = onTermsTap
        self.onPrivacyTap = onPrivacyTap
        self.onWebCheckout = onWebCheckout
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
                        featureRow("eye.fill", "Full IRIS AI analysis")
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

                    // CTA — redirects to web checkout (Stripe) to avoid App Store fees
                    DSPrimaryButton(
                        isPurchasing ? "Opening checkout..." : "Start Free Trial",
                        icon: isPurchasing ? nil : "lock.open.fill",
                        isLoading: isPurchasing
                    ) {
                        isPurchasing = true
                        let plan = selectedPlan == .yearly ? "yearly" : "monthly"
                        if let onWebCheckout {
                            onWebCheckout(plan)
                        } else {
                            // Fallback: in-app purchase via StoreKit (for contexts without web checkout)
                            Task {
                                let success = await SubscriptionManager.shared.purchase(plan: selectedPlan)
                                isPurchasing = false
                                if success {
                                    onDismiss()
                                }
                            }
                        }
                    }
                    .disabled(isPurchasing || isRestoring)
                    .padding(.horizontal, DSSpacing.screenPadding)

                    // Error feedback
                    if let error = SubscriptionManager.shared.purchaseError {
                        Text(error)
                            .font(DSFont.micro)
                            .foregroundStyle(Color.red.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DSSpacing.screenPadding)
                    }

                    // Restore
                    Button {
                        Task {
                            isRestoring = true
                            let success = await SubscriptionManager.shared.restorePurchases()
                            isRestoring = false
                            if success {
                                onDismiss()
                            }
                        }
                    } label: {
                        if isRestoring {
                            HStack(spacing: 6) {
                                ProgressView()
                                    .tint(Color.ds_cyan)
                                    .scaleEffect(0.7)
                                Text("Restoring...")
                                    .font(DSFont.captionBold)
                                    .foregroundStyle(Color.ds_cyan)
                            }
                        } else {
                            Text("Restore Purchases")
                                .font(DSFont.captionBold)
                                .foregroundStyle(Color.ds_cyan)
                        }
                    }
                    .disabled(isRestoring || isPurchasing)

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
                    Text(planSubtitle(for: plan))
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_textSecondary)
                }
                Spacer()
                Text(livePrice(for: plan))
                    .font(DSFont.captionBold)
                    .foregroundStyle(isSelected ? Color.ds_cyan : Color.ds_textSecondary)
            }
            .padding(DSSpacing.md)
            .dsGlass(tint: isSelected ? .ds_cyan : .clear, tintOpacity: isSelected ? 0.12 : 0)
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.cardRadius)
                    .stroke(isSelected ? Color.ds_cyan : Color.clear, lineWidth: isSelected ? 1.5 : 0)
            )
        }
    }

    private func livePrice(for plan: SubscriptionManager.SubscriptionPlan) -> String {
        let product = plan == .yearly
            ? SubscriptionManager.shared.yearlyProduct
            : SubscriptionManager.shared.monthlyProduct
        if let product {
            return product.displayPrice + (plan == .yearly ? "/year" : "/month")
        }
        return plan.price
    }

    private func planSubtitle(for plan: SubscriptionManager.SubscriptionPlan) -> String {
        if plan == .yearly {
            if let product = SubscriptionManager.shared.yearlyProduct {
                let monthly = product.price / 12
                let formatted = monthly.formatted(.currency(code: product.priceFormatStyle.currencyCode ?? "USD"))
                return "Save 75% — just \(formatted)/mo"
            }
            return "Save 75% — just $2.50/mo"
        } else {
            if let product = SubscriptionManager.shared.monthlyProduct {
                let yearly = product.price * 12
                let formatted = yearly.formatted(.currency(code: product.priceFormatStyle.currencyCode ?? "USD"))
                return "\(formatted)/year"
            }
            return "$119.88/year"
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
