import SwiftUI
import DesignSystem
import Gamification

/// Sheet UI for purchasing scan credit packs.
/// Uses McDonald's decoy pricing: small ($2.99/3) → medium ($5.99/8) → large ($9.99/20).
/// The medium is the decoy; the large is the "steal" we want users to pick.
public struct CreditStoreView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPack: CreditPack = .large
    @State private var isPurchasing = false
    @State private var purchaseSuccess = false
    @State private var creditsAwarded = 0

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.ds_navy.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DSSpacing.lg) {
                        // Header
                        headerSection

                        // Current balance
                        balanceCard

                        // Credit packs
                        VStack(spacing: DSSpacing.sm) {
                            ForEach(CreditPack.allCases) { pack in
                                creditPackCard(pack)
                            }
                        }
                        .padding(.horizontal, DSSpacing.screenPadding)

                        // Purchase button
                        purchaseButton
                            .padding(.horizontal, DSSpacing.screenPadding)

                        // Info
                        infoSection

                        Spacer(minLength: 40)
                    }
                }

                // Success overlay
                if purchaseSuccess {
                    successOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SCAN CREDITS")
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_cyan)
                        .tracking(2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.ds_textSecondary)
                            .frame(width: 28, height: 28)
                            .background(Color.ds_charcoal)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: DSSpacing.xs) {
            Image(systemName: "viewfinder.trianglebadge.exclamationmark")
                .font(.system(size: 40))
                .foregroundStyle(Color.ds_cyan)
                .padding(.top, DSSpacing.md)

            Text("Need More Scans?")
                .font(DSFont.sectionTitle)
                .foregroundStyle(Color.ds_textPrimary)

            Text("Each scan uses 1 credit for AI-powered body analysis")
                .font(DSFont.caption)
                .foregroundStyle(Color.ds_textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DSSpacing.xxl)
        }
    }

    // MARK: - Balance

    private var balanceCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("CURRENT BALANCE")
                    .font(DSFont.micro)
                    .foregroundStyle(Color.ds_textSecondary)
                    .tracking(1)

                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.ds_cyan)
                    Text(ScanCreditManager.shared.displayCredits)
                        .font(DSFont.stat)
                        .foregroundStyle(Color.ds_textPrimary)
                    Text("credits")
                        .font(DSFont.caption)
                        .foregroundStyle(Color.ds_textSecondary)
                }
            }

            Spacer()

            // Streak bonus indicator
            VStack(alignment: .trailing, spacing: 2) {
                Text("NEXT BONUS")
                    .font(DSFont.micro)
                    .foregroundStyle(Color.ds_textSecondary)
                    .tracking(1)
                Text("Day \(nextMilestoneDay)")
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_green)
            }
        }
        .dsCard()
        .padding(.horizontal, DSSpacing.screenPadding)
    }

    private var nextMilestoneDay: Int {
        let streak = UserDefaults.standard.integer(forKey: "ascend_streak")
        let milestones = [7, 21, 42, 90]
        return milestones.first { $0 > streak } ?? 90
    }

    // MARK: - Credit Pack Card

    private func creditPackCard(_ pack: CreditPack) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedPack = pack
            }
        } label: {
            HStack(spacing: DSSpacing.sm) {
                // Credit count
                VStack(spacing: 0) {
                    Text("\(pack.creditCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(pack.isBestValue ? Color.ds_cyan : Color.ds_textPrimary)
                    Text("scans")
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_textSecondary)
                }
                .frame(width: 60)

                // Details
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(pack.displayPrice)
                            .font(DSFont.cardTitle)
                            .foregroundStyle(Color.ds_textPrimary)

                        if let savings = pack.savingsLabel {
                            Text(savings)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(pack.isBestValue ? Color.ds_navy : Color.ds_green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(pack.isBestValue ? Color.ds_cyan : Color.ds_green.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }

                    Text(pack.pricePerScan)
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_textSecondary)
                }

                Spacer()

                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(selectedPack == pack ? Color.ds_cyan : Color.ds_charcoal, lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if selectedPack == pack {
                        Circle()
                            .fill(Color.ds_cyan)
                            .frame(width: 14, height: 14)
                    }
                }
            }
            .padding(DSSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.ds_charcoal.opacity(selectedPack == pack ? 1 : 0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedPack == pack ? Color.ds_cyan.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Purchase Button

    private var purchaseButton: some View {
        Button {
            Task {
                await purchaseSelectedPack()
            }
        } label: {
            HStack(spacing: 8) {
                if isPurchasing {
                    ProgressView()
                        .tint(Color.ds_navy)
                } else {
                    Text("Get \(selectedPack.creditCount) Scans — \(selectedPack.displayPrice)")
                        .font(DSFont.bodyBold)
                        .foregroundStyle(Color.ds_navy)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.ds_cyan)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isPurchasing)
        .opacity(isPurchasing ? 0.7 : 1)
    }

    // MARK: - Info

    private var infoSection: some View {
        VStack(spacing: DSSpacing.xs) {
            infoRow(icon: "gift.fill", text: "Subscribers get 1 free scan every week")
            infoRow(icon: "flame.fill", text: "Earn free scans at Day 7, 21, 42 & 90 streaks")
            infoRow(icon: "repeat", text: "Every 14-day streak = 1 bonus scan credit")
        }
        .padding(.horizontal, DSSpacing.screenPadding)
    }

    private func infoRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.ds_cyan.opacity(0.6))
                .frame(width: 20)

            Text(text)
                .font(DSFont.micro)
                .foregroundStyle(Color.ds_textSecondary)

            Spacer()
        }
    }

    // MARK: - Purchase Logic

    @MainActor
    private func purchaseSelectedPack() async {
        isPurchasing = true
        let awarded = await CreditStore.shared.purchase(pack: selectedPack)
        isPurchasing = false

        if awarded > 0 {
            creditsAwarded = awarded
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                purchaseSuccess = true
            }

            // Auto-dismiss after 2 seconds
            try? await Task.sleep(for: .seconds(2))
            dismiss()
        }
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            VStack(spacing: DSSpacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.ds_green)

                Text("+\(creditsAwarded) Credits")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.ds_textPrimary)

                Text("Ready to scan!")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textSecondary)
            }
        }
    }
}
