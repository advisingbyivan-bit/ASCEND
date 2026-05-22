import SwiftUI
import DesignSystem
import IRIS
import BodyModel3D
import Networking

public struct DiagnosisRevealView: View {
    @State private var viewModel: DiagnosisRevealViewModel
    let onComplete: (DiagnosisResult) -> Void

    public init(photos: [UIImage], userContext: ClaudeVisionClient.UserContext = ClaudeVisionClient.UserContext(), onComplete: @escaping (DiagnosisResult) -> Void) {
        _viewModel = State(initialValue: DiagnosisRevealViewModel(photos: photos, userContext: userContext))
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
                    Text("IRIS DIAGNOSIS")
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
                        gender: .male,
                        zones: viewModel.revealedZones,
                        interactive: true,
                        size: .full
                    )
                    .transition(.scale(scale: 0.7).combined(with: .opacity))
                }

                if viewModel.showMessage {
                    DSTypewriterText(viewModel.messageText, charDelay: .milliseconds(30)) {
                        viewModel.messageFinished()
                    }
                    .padding(.horizontal, DSSpacing.screenPadding)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                zoneListView
                    .padding(.vertical, DSSpacing.sm)

                // Extra space for CTA button overlay in celebration stage
                Spacer().frame(height: 80)
            }
        }
        .transition(.opacity)
    }

    private var zoneListView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DSSpacing.xs) {
                ForEach(Array(viewModel.revealedZones.sorted(by: { $0.key.rawValue < $1.key.rawValue })), id: \.key) { zone, status in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(status.color)
                            .frame(width: 10, height: 10)
                        Text(zone.displayName)
                            .font(DSFont.micro)
                            .foregroundStyle(Color.ds_textSecondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.ds_charcoal.opacity(0.6))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal, DSSpacing.screenPadding)
        }
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
}

#Preview("Diagnosis Reveal") {
    DiagnosisRevealView(photos: []) { result in
        print("Complete: \(result.overallScore)")
    }
}
