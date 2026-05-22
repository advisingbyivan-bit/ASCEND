import SwiftUI
import DesignSystem
import Paywall

struct PaywallScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var selectedPlan: SubscriptionManager.SubscriptionPlan = .yearly
    @State private var isPurchasing = false
    @State private var purchaseError: String?
    @State private var showHero = false
    @State private var showTitle = false
    @State private var showTrial = false
    @State private var revealedFeatures: Set<Int> = []
    @State private var showPlans = false
    @State private var showCTA = false
    @State private var showDisclosures = false
    @State private var ctaGlow = false
    @State private var showTerms = false
    @State private var showPrivacy = false
    @State private var transformPulse = false

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
                // Hero — Before/After transformation visual
                PaywallTransformationHero(pulse: transformPulse)
                    .frame(height: 180)
                    .opacity(showHero ? 1 : 0)
                    .scaleEffect(showHero ? 1 : 0.7)
                    .padding(.top, DSSpacing.lg)

                // Title
                VStack(spacing: DSSpacing.xs) {
                    Text("Unlock Full Access")
                        .font(DSFont.screenTitle)
                        .foregroundStyle(Color.ds_textPrimary)
                        .scaleEffect(showTitle ? 1 : 0.9)
                        .opacity(showTitle ? 1 : 0)

                    Text("3-day free trial, cancel anytime")
                        .font(DSFont.body)
                        .foregroundStyle(Color.ds_textSecondary)
                        .offset(y: showTrial ? 0 : 10)
                        .opacity(showTrial ? 1 : 0)
                }

                // Features with staggered reveal
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                        let isRevealed = revealedFeatures.contains(index)
                        featureRow(icon: feature.icon, text: feature.text)
                            .opacity(isRevealed ? 1 : 0)
                            .offset(x: isRevealed ? 0 : -20)
                    }
                }
                .padding(.horizontal, DSSpacing.screenPadding)

                // Plan options
                VStack(spacing: DSSpacing.sm) {
                    planOption(
                        plan: .yearly,
                        title: "Yearly",
                        price: "$29.99/year",
                        detail: "Save 75% — just $2.50/mo",
                        badge: "BEST VALUE"
                    )

                    planOption(
                        plan: .monthly,
                        title: "Monthly",
                        price: "$9.99/month",
                        detail: "$119.88/year",
                        badge: nil
                    )
                }
                .padding(.horizontal, DSSpacing.screenPadding)
                .scaleEffect(showPlans ? 1 : 0.95)
                .opacity(showPlans ? 1 : 0)

                // Purchase error
                if let purchaseError {
                    Text(purchaseError)
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DSSpacing.screenPadding)
                }

                // Glowing CTA
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
                            coordinator.advance()
                        } else if let error = SubscriptionManager.shared.purchaseError {
                            purchaseError = error
                        }
                    }
                }
                .disabled(isPurchasing)
                .padding(.horizontal, DSSpacing.screenPadding)
                .scaleEffect(showCTA ? 1 : 0.9)
                .opacity(showCTA ? 1 : 0)
                .shadow(color: ctaGlow ? Color.ds_cyan.opacity(0.4) : Color.clear, radius: ctaGlow ? 20 : 0)

                // Apple-required disclosures
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
                        Button("Restore Purchases") {
                            Task {
                                isPurchasing = true
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

                        Button("Terms of Use") { showTerms = true }
                            .font(DSFont.micro)
                            .foregroundStyle(Color.ds_cyan.opacity(0.6))

                        Button("Privacy Policy") { showPrivacy = true }
                            .font(DSFont.micro)
                            .foregroundStyle(Color.ds_cyan.opacity(0.6))
                    }
                    .padding(.top, DSSpacing.xs)

                    Text("ASCEND is not a medical device. AI feedback is for fitness guidance only.")
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_textSecondary.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, DSSpacing.screenPadding)
                .opacity(showDisclosures ? 1 : 0)

                // Skip option (Apple-required — must not be hidden)
                Button("Continue with limited access") {
                    coordinator.advance()
                }
                .font(DSFont.caption)
                .foregroundStyle(Color.ds_textSecondary.opacity(0.5))
                .padding(.top, DSSpacing.xs)

                Spacer()
                    .frame(height: DSSpacing.xl)
            }
        }
        .onAppear {
            DSHaptic.paywallReveal()

            // Ensure products are loaded for StoreKit
            Task {
                await SubscriptionManager.shared.loadProducts()
            }

            withAnimation(.spring(response: 0.7, dampingFraction: 0.65)) { showHero = true }
            withAnimation(.easeOut(duration: 0.5).delay(0.25)) { showTitle = true }
            withAnimation(.easeOut(duration: 0.4).delay(0.4)) { showTrial = true }

            // Stagger feature reveals
            for i in 0..<features.count {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.55 + Double(i) * 0.1)) {
                    revealedFeatures.insert(i)
                }
            }

            let featuresDone = 0.55 + Double(features.count) * 0.1
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(featuresDone + 0.1)) {
                showPlans = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(featuresDone + 0.3)) {
                showCTA = true
            }
            withAnimation(.easeIn(duration: 0.4).delay(featuresDone + 0.5)) {
                showDisclosures = true
            }

            // CTA glow pulse
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(featuresDone + 0.5)) {
                ctaGlow = true
            }

            // Transform pulse
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                transformPulse = true
            }

            // Haptic on CTA reveal
            DispatchQueue.main.asyncAfter(deadline: .now() + featuresDone + 0.3) {
                DSHaptic.ctaReady()
            }
        }
        .sheet(isPresented: $showTerms) {
            OnboardingLegalSheet(title: "Terms of Use", sections: Self.termsSections)
        }
        .sheet(isPresented: $showPrivacy) {
            OnboardingLegalSheet(title: "Privacy Policy", sections: Self.privacySections)
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: DSSpacing.sm) {
            ZStack {
                Circle()
                    .fill(Color.ds_cyan.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.ds_cyan)
            }
            Text(text)
                .font(DSFont.body)
                .foregroundStyle(Color.ds_textPrimary)
            Spacer()
        }
    }

    private func planOption(plan: SubscriptionManager.SubscriptionPlan, title: String, price: String, detail: String, badge: String?) -> some View {
        let isSelected = selectedPlan == plan
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedPlan = plan
            }
            DSHaptic.optionSelect()
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(title)
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
                    Text(detail)
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_textSecondary)
                }

                Spacer()

                Text(price)
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
            .shadow(color: isSelected ? Color.ds_cyan.opacity(0.2) : .clear, radius: 10)
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    // MARK: - Legal Content

    static let termsSections: [(String, String)] = [
        ("Acceptance of Terms", "By downloading, installing, or using ASCEND, you agree to be bound by these Terms of Use."),
        ("Description of Service", "ASCEND is a body transformation tracking application that uses AI-powered visual analysis. ASCEND is NOT a medical device."),
        ("Eligibility", "You must be at least 17 years old to use ASCEND."),
        ("Subscriptions & Payments", "ASCEND offers premium features through auto-renewable subscriptions via Apple In-App Purchase. 3-day free trial available. Yearly: $29.99/year. Monthly: $9.99/month. Subscription auto-renews unless cancelled at least 24 hours before the end of the current period. Manage in Settings > Apple ID > Subscriptions."),
        ("User Content", "You retain ownership of photos and data you submit. Your photos are encrypted and never shared with third parties."),
        ("AI Disclaimer", "AI-generated feedback is for fitness guidance only. Consult a healthcare professional for medical advice."),
        ("Limitation of Liability", "ASCEND is provided \"as is\" without warranties. We are not liable for damages arising from use of the App."),
        ("Contact", "For questions: support@ascendapp.us"),
    ]

    static let privacySections: [(String, String)] = [
        ("Information We Collect", "Account information (name, email), body data (scan photos, scores), fitness data (training frequency, progress), usage data (anonymized analytics), subscription data (managed by Apple)."),
        ("How We Use Your Information", "To provide AI-powered diagnostics, generate coaching messages, maintain leaderboards, send notifications, and improve the app."),
        ("Data Security", "Photos are encrypted on-device. All data in transit uses TLS 1.3. Cloud storage uses AES-256 encryption. We never sell or share your data."),
        ("Data Retention", "Data is retained while your account is active. Upon deletion, all data is permanently removed within 30 days."),
        ("Your Rights", "Access your data (Profile > Export My Data). Delete your account (Profile > Account > Delete Account). Opt out of notifications and analytics."),
        ("Third-Party Services", "Apple In-App Purchase, Anthropic Claude API (for AI analysis), Apple Push Notification Service."),
        ("Children's Privacy", "ASCEND is rated 17+ and is not intended for anyone under 17."),
        ("Contact Us", "For privacy inquiries: privacy@ascendapp.us"),
    ]
}

// MARK: - Paywall Transformation Hero

private struct PaywallTransformationHero: View {
    let pulse: Bool

    var body: some View {
        HStack(spacing: 0) {
            // BEFORE — red zones, weak
            VStack(spacing: 6) {
                ZStack {
                    // Glow behind
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.ds_red.opacity(0.15), Color.clear],
                                center: .center,
                                startRadius: 5,
                                endRadius: 45
                            )
                        )
                        .frame(width: 90, height: 90)

                    // Body silhouette
                    Image(systemName: "figure.stand")
                        .font(.system(size: 56, weight: .ultraLight))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.ds_red.opacity(0.6), Color.ds_red.opacity(0.25)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .scaleEffect(x: 1.1, y: 1.0)

                    // Weak zone indicators
                    Circle()
                        .fill(Color.ds_red.opacity(0.8))
                        .frame(width: 5, height: 5)
                        .offset(x: 0, y: -14)

                    Circle()
                        .fill(Color.ds_red.opacity(0.6))
                        .frame(width: 4, height: 4)
                        .offset(x: -7, y: -2)

                    Circle()
                        .fill(Color.ds_yellow.opacity(0.6))
                        .frame(width: 4, height: 4)
                        .offset(x: 7, y: -2)
                }
                .frame(height: 110)

                Text("NOW")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.ds_red.opacity(0.7))
                    .tracking(2)
            }

            // Arrow transition
            VStack(spacing: 4) {
                // Animated arrow
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.ds_red.opacity(0.5), Color.ds_cyan, Color.ds_green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: pulse ? 3 : -3)

                // Progress dots
                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(
                                i == 0 ? Color.ds_red.opacity(0.5)
                                : i == 1 ? Color.ds_yellow.opacity(0.5)
                                : Color.ds_green.opacity(0.5)
                            )
                            .frame(width: 3, height: 3)
                    }
                }
            }
            .frame(width: 50)
            .offset(y: -10)

            // AFTER — green zones, strong
            VStack(spacing: 6) {
                ZStack {
                    // Glow behind
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.ds_green.opacity(pulse ? 0.2 : 0.1), Color.clear],
                                center: .center,
                                startRadius: 5,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)

                    // Body silhouette — leaner
                    Image(systemName: "figure.stand")
                        .font(.system(size: 56, weight: .thin))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.ds_cyan.opacity(0.8), Color.ds_green.opacity(0.6)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Strong zone indicators
                    Circle()
                        .fill(Color.ds_green.opacity(0.8))
                        .frame(width: 5, height: 5)
                        .offset(x: 0, y: -14)

                    Circle()
                        .fill(Color.ds_green.opacity(0.7))
                        .frame(width: 4, height: 4)
                        .offset(x: -7, y: -2)

                    Circle()
                        .fill(Color.ds_green.opacity(0.7))
                        .frame(width: 4, height: 4)
                        .offset(x: 7, y: -2)

                    // Sparkle particles
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(Color.ds_green.opacity(0.4))
                            .frame(width: 2, height: 2)
                            .offset(
                                x: CGFloat([-15, 18, -10, 12][i]),
                                y: CGFloat([-25, -20, 15, 10][i]) + (pulse ? -3 : 3)
                            )
                    }
                }
                .frame(height: 110)

                Text("GOAL")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.ds_green.opacity(0.8))
                    .tracking(2)
            }
        }
        .padding(.horizontal, DSSpacing.lg)
    }
}

// MARK: - Legal Sheet for Onboarding

private struct OnboardingLegalSheet: View {
    let title: String
    let sections: [(String, String)]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(section.0)
                                .font(DSFont.bodyBold)
                                .foregroundStyle(Color.ds_textPrimary)
                            Text(section.1)
                                .font(DSFont.body)
                                .foregroundStyle(Color.ds_textSecondary)
                                .lineSpacing(3)
                        }
                    }
                }
                .padding(20)
            }
            .background(Color.ds_navy)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.ds_cyan)
                }
            }
        }
    }
}
