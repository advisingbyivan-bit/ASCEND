import SwiftUI
import DesignSystem
import Gamification

// MARK: - Community View

struct CommunityView: View {
    @Environment(AppState.self) private var appState
    @State private var showGlow = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ds_navy.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DSSpacing.md) {
                        heroSection
                        featuresPreview
                        earlyAdopterCard
                    }
                    .padding(.bottom, 90)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("COMMUNITY")
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_cyan)
                        .tracking(2)
                }
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: DSSpacing.lg) {
            Spacer().frame(height: DSSpacing.md)

            ZStack {
                // Glow behind icon
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.ds_cyan.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                Image(systemName: "person.3.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.ds_cyan, Color.ds_purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: DSSpacing.xs) {
                Text("Community is Coming")
                    .font(DSFont.screenTitle)
                    .foregroundStyle(Color.ds_textPrimary)

                Text("Compete. Compare. Conquer.")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_cyan)
                    .tracking(1)
            }

            Text("We're building something big — a global leaderboard where your consistency speaks louder than your genetics. Get ahead of the pack by scanning now.")
                .font(DSFont.caption)
                .foregroundStyle(Color.ds_textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DSSpacing.lg)
        }
        .padding(.horizontal, DSSpacing.screenPadding)
    }

    // MARK: - Features Preview

    private var featuresPreview: some View {
        VStack(spacing: DSSpacing.sm) {
            HStack {
                Text("WHAT'S COMING")
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_cyan)
                    .tracking(2)
                Spacer()
            }

            featureRow(
                icon: "chart.bar.fill",
                title: "Global Leaderboard",
                description: "Rank against thousands based on your score, streak, and consistency"
            )

            featureRow(
                icon: "person.2.fill",
                title: "Accountability Partners",
                description: "Pair up with someone at your level and push each other daily"
            )

            featureRow(
                icon: "trophy.fill",
                title: "Weekly Challenges",
                description: "Compete in time-limited challenges with exclusive badge rewards"
            )

            featureRow(
                icon: "target",
                title: "Goal Area Groups",
                description: "Join communities focused on the same body zones as you"
            )
        }
        .dsCard()
        .padding(.horizontal, DSSpacing.screenPadding)
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: DSSpacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.ds_cyan)
                .frame(width: 28, height: 28)
                .background(Color.ds_cyan.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_textPrimary)
                Text(description)
                    .font(DSFont.micro)
                    .foregroundStyle(Color.ds_textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    // MARK: - Early Adopter Card

    private var earlyAdopterCard: some View {
        VStack(spacing: DSSpacing.sm) {
            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.ds_gold)
                Text("EARLY ADOPTER")
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_gold)
                    .tracking(2)
            }

            Text("You're building your score before anyone else. When the leaderboard launches, you'll already be ahead.")
                .font(DSFont.caption)
                .foregroundStyle(Color.ds_textSecondary)
                .multilineTextAlignment(.center)

            HStack(spacing: DSSpacing.lg) {
                earlyStatItem(value: "\(appState.totalScans)", label: "Scans")
                earlyStatItem(value: "\(appState.currentStreak)", label: "Streak")
                earlyStatItem(value: "\(Int(appState.latestDiagnosis?.overallScore ?? 0))", label: "Score")
            }
            .padding(.top, DSSpacing.xs)
        }
        .dsCard()
        .overlay(
            RoundedRectangle(cornerRadius: DSSpacing.cardRadius)
                .stroke(Color.ds_gold.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, DSSpacing.screenPadding)
    }

    private func earlyStatItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(DSFont.statSmall)
                .foregroundStyle(Color.ds_cyan)
            Text(label)
                .font(DSFont.micro)
                .foregroundStyle(Color.ds_textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}
