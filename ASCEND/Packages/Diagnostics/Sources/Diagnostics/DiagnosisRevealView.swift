import SwiftUI
import StoreKit
import DesignSystem
import IRIS
import BodyModel3D
import Networking

public struct DiagnosisRevealView: View {
    @State private var viewModel: DiagnosisRevealViewModel
    let gender: BodyGender
    let onComplete: (DiagnosisResult) -> Void

    public init(photos: [UIImage], gender: BodyGender = .male, userContext: ClaudeVisionClient.UserContext = ClaudeVisionClient.UserContext(), onComplete: @escaping (DiagnosisResult) -> Void) {
        _viewModel = State(initialValue: DiagnosisRevealViewModel(photos: photos, userContext: userContext))
        self.gender = gender
        self.onComplete = onComplete
    }

    public var body: some View {
        ZStack {
            DSAmbientBackground()

            switch viewModel.stage {
            case .anticipation:
                anticipationStage
            case .reveal:
                revealStage
            case .celebration:
                celebrationStage
            case .error:
                errorStage
            }
        }
        .task {
            await viewModel.startAnalysis()
        }
    }

    // MARK: - Stage 1: Anticipation

    private var anticipationStage: some View {
        VStack(spacing: DSSpacing.xl) {
            Spacer()

            IRISSphereView(state: .processing, size: .full)
                .scaleEffect(pulseScale)

            VStack(spacing: DSSpacing.sm) {
                Text("ANALYZING YOUR BODY")
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_cyan)
                    .tracking(3)

                ProgressView(value: viewModel.analysisProgress)
                    .tint(Color.ds_cyan)
                    .frame(width: 200)

                Text("\(Int(viewModel.analysisProgress * 100))%")
                    .font(DSFont.statSmall)
                    .foregroundStyle(Color.ds_textSecondary)
            }

            Spacer()
            Spacer()
        }
        .transition(.opacity)
    }

    @State private var isPulsing = false

    private var pulseScale: CGFloat {
        isPulsing ? 1.05 : 1.0
    }

    // MARK: - Stage 2: Reveal

    private var revealStage: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: DSSpacing.sm) {
                HStack {
                    IRISSphereView(state: viewModel.irisState, size: .notification)
                    Text("IRIS ANALYSIS")
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_cyan)
                        .tracking(2)
                    Spacer()
                    if let score = viewModel.diagnosis?.overallScore {
                        DSProgressRing(
                            progress: score / 100,
                            size: 44,
                            lineWidth: 4
                        )
                        .overlay {
                            Text("\(Int(score))")
                                .font(DSFont.micro)
                                .foregroundStyle(Color.ds_cyan)
                        }
                    }
                }
                .padding(.horizontal, DSSpacing.screenPadding)
                .padding(.top, DSSpacing.lg)

                if viewModel.showBody {
                    BodyModelView(
                        gender: gender,
                        zones: viewModel.revealedZones,
                        interactive: true,
                        size: .full
                    )
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                }

                // IRIS message fades out once done, replaced by zone grid
                if viewModel.showMessage && !viewModel.showZoneGrid {
                    DSTypewriterText(viewModel.messageText, charDelay: .milliseconds(30)) {
                        viewModel.messageFinished()
                    }
                    .padding(.horizontal, DSSpacing.screenPadding)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Zone grid replaces message after typewriter completes
                if viewModel.showZoneGrid {
                    zoneGridView
                        .padding(.horizontal, DSSpacing.screenPadding)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Extra space for CTA button overlay in celebration stage
                Spacer().frame(height: 80)
            }
        }
        .transition(.opacity)
    }

    private var zoneGridView: some View {
        let sortedZones: [ZoneDiagnosisItem] = viewModel.diagnosis?.zones ?? []

        return LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: DSSpacing.xs),
                GridItem(.flexible(), spacing: DSSpacing.xs)
            ],
            spacing: DSSpacing.xs
        ) {
            ForEach(sortedZones) { item in
                zoneCard(item)
            }
        }
    }

    private func zoneCard(_ item: ZoneDiagnosisItem) -> some View {
        HStack(spacing: 10) {
            // Status color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(item.status.color)
                .frame(width: 4, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.zone.displayName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.ds_textPrimary)

                Text(item.status.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(item.status.color)
            }

            Spacer()

            // Delta indicator
            if item.delta != 0 {
                HStack(spacing: 2) {
                    Image(systemName: item.delta > 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                    Text("\(abs(Int(item.delta)))")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                .foregroundStyle(item.delta > 0 ? Color.ds_green : Color.ds_red)
            } else {
                Image(systemName: "minus")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color.ds_textSecondary.opacity(0.4))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.ds_charcoal.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Stage 3: Celebration

    private var celebrationStage: some View {
        ZStack {
            revealStage

            if viewModel.showConfetti {
                DSConfettiView()
                    .allowsHitTesting(false)
            }

            VStack {
                // Fallback banner at top when using offline analysis
                if viewModel.isUsingFallback {
                    HStack(spacing: 6) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 10))
                        Text("Offline analysis — results are estimated")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(Color.ds_yellow)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.ds_yellow.opacity(0.12))
                    .clipShape(Capsule())
                    .padding(.top, 60)
                }

                Spacer()

                if viewModel.showCTA {
                    DSPrimaryButton("View Results", icon: "chart.line.uptrend.xyaxis") {
                        if let result = viewModel.diagnosis {
                            // Request App Store rating after a positive first experience
                            requestRatingIfAppropriate()
                            onComplete(result)
                        }
                    }
                    .padding(.horizontal, DSSpacing.screenPadding)
                    .padding(.bottom, DSSpacing.xl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    // MARK: - Error Stage

    private var errorStage: some View {
        VStack(spacing: DSSpacing.lg) {
            Spacer()

            IRISSphereView(state: .idle, size: .full)

            VStack(spacing: DSSpacing.sm) {
                Text("ANALYSIS FAILED")
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_red)
                    .tracking(3)

                Text(viewModel.errorMessage)
                    .font(DSFont.caption)
                    .foregroundStyle(Color.ds_textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DSSpacing.xl)
            }

            VStack(spacing: DSSpacing.sm) {
                DSPrimaryButton("Try Again", icon: "arrow.clockwise") {
                    Task { await viewModel.retry() }
                }
                .padding(.horizontal, DSSpacing.screenPadding)

                Button("Use Offline Analysis") {
                    Task { await viewModel.useFallback() }
                }
                .font(DSFont.captionBold)
                .foregroundStyle(Color.ds_textSecondary)
            }

            Spacer()
            Spacer()
        }
        .transition(.opacity)
    }

    // MARK: - App Store Rating

    private func requestRatingIfAppropriate() {
        let key = "ascend_diagnosis_view_count"
        let count = UserDefaults.standard.integer(forKey: key) + 1
        UserDefaults.standard.set(count, forKey: key)

        // Ask on 1st, 5th, and 15th diagnosis — Apple limits to 3/year anyway
        if count == 1 || count == 5 || count == 15 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if let scene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: scene)
                }
            }
        }
    }
}

#Preview("Diagnosis Reveal") {
    DiagnosisRevealView(photos: []) { result in
        print("Complete: \(result.overallScore)")
    }
}
