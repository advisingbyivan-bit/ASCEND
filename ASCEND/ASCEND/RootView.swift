import SwiftUI
import DesignSystem
import Scanner
import Diagnostics
import Gamification
import Paywall
import Networking
import Persistence

struct RootView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: Tab = .home
    @State private var showScanner = false
    @State private var showCreditStore = false
    @State private var showCooldownAlert = false
    @State private var showWeightCheckIn = false

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tag(Tab.home)
                .toolbar(.hidden, for: .tabBar)

            ProgressTabView()
                .tag(Tab.progress)
                .toolbar(.hidden, for: .tabBar)

            ScanView()
                .tag(Tab.scan)
                .toolbar(.hidden, for: .tabBar)

            CommunityView()
                .tag(Tab.community)
                .toolbar(.hidden, for: .tabBar)

            ProfileView()
                .tag(Tab.profile)
                .toolbar(.hidden, for: .tabBar)
        }
        .overlay(alignment: .bottom) {
            glassTabBar
        }
        .overlay {
            // Diamond celebration overlay
            if appState.showCelebration, let milestone = appState.pendingCelebration {
                DiamondCelebrationView(milestone: milestone) {
                    appState.dismissCelebration()
                }
                .transition(.opacity)
            }
        }
        .ignoresSafeArea(.keyboard)
        .animation(.easeInOut(duration: 0.3), value: appState.showCelebration)
        .fullScreenCover(isPresented: $showScanner) {
            ScanFlowNavigator(appState: appState)
        }
        .sheet(isPresented: $showWeightCheckIn) {
            WeightCheckInSheet(
                onConfirm: { showScanner = true },
                onSkip: { showScanner = true }
            )
            .environment(appState)
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
        .alert("Scan Cooldown", isPresented: $showCooldownAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You scanned recently. Wait \(ScanCreditManager.shared.cooldownMinutesRemaining) minutes before your next scan for the most accurate comparison.")
        }
    }

    // MARK: - Frosted Glass Tab Bar

    private var glassTabBar: some View {
        HStack(spacing: 0) {
            tabIcon(.home)
            tabIcon(.progress)
            centerScanButton
            tabIcon(.community)
            tabIcon(.profile)
        }
        .padding(.top, 2)
        .padding(.bottom, 4)
        .background(
            Color.ds_navy.opacity(0.85)
                .ignoresSafeArea(.all, edges: .bottom)
        )
        .contentShape(Rectangle())
    }

    private func tabIcon(_ tab: Tab) -> some View {
        Button {
            selectedTab = tab
            DSHaptic.selection()
        } label: {
            VStack(spacing: 2) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18))
                    .foregroundStyle(selectedTab == tab ? Color.ds_cyan : Color.ds_textSecondary.opacity(0.35))

                Text(tab.title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(selectedTab == tab ? Color.ds_cyan : Color.ds_textSecondary.opacity(0.35))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 32)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var centerScanButton: some View {
        Button {
            DSHaptic.heavy()
            if ScanCreditManager.shared.isOnCooldown {
                // Cooldown active — show alert
                DSHaptic.warning()
                showCooldownAlert = true
            } else if appState.canScan {
                // Consume credit before opening scanner
                if appState.tryScanCredit() {
                    if WeightCheckInSheet.shouldShow {
                        showWeightCheckIn = true
                    } else {
                        showScanner = true
                    }
                }
            } else {
                // No credits — show credit store
                DSHaptic.warning()
                showCreditStore = true
            }
        } label: {
            ZStack {
                Circle()
                    .stroke(Color.ds_cyan.opacity(0.1), lineWidth: 1)
                    .frame(width: 52, height: 52)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: appState.canScan
                                ? [Color.ds_cyan, Color.ds_cyan.opacity(0.8)]
                                : [Color.ds_charcoal, Color.ds_charcoal.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 42, height: 42)
                    .shadow(color: (appState.canScan ? Color.ds_cyan : Color.clear).opacity(0.3), radius: 6, x: 0, y: 2)

                Image(systemName: "viewfinder")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(appState.canScan ? Color.ds_navy : Color.ds_textSecondary)
            }
            .offset(y: -16)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Start Scan")
        .sheet(isPresented: $showCreditStore) {
            CreditStoreView()
                .environment(appState)
        }
    }

    private var bottomSafeAreaInset: CGFloat {
        (UIApplication.shared.connectedScenes.first as? UIWindowScene)?
            .keyWindow?.safeAreaInsets.bottom ?? 0
    }
}

// MARK: - Scan Flow Navigator

private struct ScanFlowNavigator: View {
    let appState: AppState
    @State private var scanPhotos: [UIImage] = []
    @State private var showDiagnosis = false
    @Environment(\.dismiss) private var dismiss

    /// Build user context from AppState for enriched AI analysis.
    private var userContext: ClaudeVisionClient.UserContext {
        // Get previous zone data for delta tracking
        var previousZones: [(zone: String, status: String, score: Double)]? = nil
        if let prev = appState.latestDiagnosis {
            previousZones = prev.zones.map { item in
                let statusStr: String = switch item.status {
                case .strong: "strong"
                case .moderate: "moderate"
                case .weak: "weak"
                case .target: "target"
                case .base: "base"
                }
                return (zone: item.zone.rawValue, status: statusStr, score: item.delta)
            }
        }

        // Load profile data
        let profile = try? DataStore.shared.fetchProfile()

        return ClaudeVisionClient.UserContext(
            heightCm: profile?.heightCm ?? 0,
            weightKg: profile?.weightKg ?? 0,
            goalWeightKg: profile?.goalWeightKg ?? 0,
            age: profile?.age ?? 0,
            gender: profile?.gender ?? "male",
            scanNumber: appState.totalScans + 1,
            currentStreak: appState.currentStreak,
            bodyConcerns: profile?.bodyConcerns ?? "",
            trainingFrequency: profile?.trainingFrequency ?? "",
            timeline: profile?.timeline ?? "",
            previousZones: previousZones
        )
    }

    var body: some View {
        if showDiagnosis {
            DiagnosisRevealView(photos: scanPhotos, userContext: userContext) { result in
                appState.completeScan(photos: scanPhotos, diagnosis: result)
                dismiss()
            }
        } else {
            ScanFlowView(onComplete: { photos in
                scanPhotos = photos
                showDiagnosis = true
            }, onDismiss: {
                dismiss()
            })
            .ignoresSafeArea()
        }
    }
}

// MARK: - Tab Enum

enum Tab: Int, CaseIterable {
    case home, progress, scan, community, profile

    var title: String {
        switch self {
        case .home: "Home"
        case .scan: "Scan"
        case .progress: "Progress"
        case .community: "Community"
        case .profile: "Profile"
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .scan: "viewfinder"
        case .progress: "chart.line.uptrend.xyaxis"
        case .community: "person.3.fill"
        case .profile: "person.crop.circle.fill"
        }
    }
}
