import SwiftUI
import DesignSystem
import BodyModel3D
import Diagnostics
import Gamification

/// The Scan tab content — shows the 3D body model with zone status from latest scan.
/// The actual scanner is launched from the center tab button (RootView).
struct ScanView: View {
    @Environment(AppState.self) private var appState

    private var activeZones: [BodyZone: ZoneStatus] {
        appState.latestDiagnosis?.zoneMap ?? [:]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ds_navy.ignoresSafeArea()

                DSFloatingParticles(count: 10, colors: [Color.ds_purple.opacity(0.3), Color.ds_cyan.opacity(0.15)])
                    .ignoresSafeArea()

                if activeZones.isEmpty {
                    emptyState
                } else {
                    scanResultView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("BODY MODEL")
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_cyan)
                        .tracking(2)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: DSSpacing.lg) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.ds_cyan.opacity(0.05))
                    .frame(width: 160, height: 160)

                Image(systemName: "figure.stand")
                    .font(.system(size: 70))
                    .foregroundStyle(Color.ds_cyan.opacity(0.3))
            }

            VStack(spacing: DSSpacing.sm) {
                Text("No Scan Yet")
                    .font(DSFont.cardTitle)
                    .foregroundStyle(Color.ds_textPrimary)

                Text("Tap the scan button below to start your first body analysis")
                    .font(DSFont.caption)
                    .foregroundStyle(Color.ds_textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DSSpacing.xxl)
            }

            // Arrow pointing to center tab button
            Image(systemName: "arrow.down")
                .font(.system(size: 24))
                .foregroundStyle(Color.ds_cyan.opacity(0.5))
                .padding(.top, DSSpacing.md)

            Spacer()
        }
    }

    private var scanResultView: some View {
        VStack(spacing: DSSpacing.sm) {
            BodyModelView(
                gender: appState.gender,
                zones: activeZones,
                interactive: true,
                size: .full
            )

            legendView

            if let score = appState.latestDiagnosis?.overallScore {
                HStack(spacing: DSSpacing.xs) {
                    Text("Overall Score:")
                        .font(DSFont.caption)
                        .foregroundStyle(Color.ds_textSecondary)
                    Text("\(Int(score))")
                        .font(DSFont.statSmall)
                        .foregroundStyle(Color.ds_cyan)
                    Text("/ 100")
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_textSecondary)
                }
                .padding(.vertical, DSSpacing.xs)
            }
        }
    }

    private var legendView: some View {
        HStack(spacing: DSSpacing.md) {
            ForEach([(ZoneStatus.strong, "Strong"), (.moderate, "Moderate"), (.weak, "Weak"), (.target, "Target")], id: \.1) { status, label in
                HStack(spacing: 4) {
                    Circle()
                        .fill(status.color)
                        .frame(width: 8, height: 8)
                    Text(label)
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_textSecondary)
                }
            }
        }
    }
}
