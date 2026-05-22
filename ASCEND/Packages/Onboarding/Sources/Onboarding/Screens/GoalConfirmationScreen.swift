import SwiftUI
import DesignSystem
import BodyModel3D
import Diagnostics

struct GoalConfirmationScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var showTitle = false
    @State private var showModel = false
    @State private var showChips = false
    @State private var showTimeline = false
    @State private var showButton = false
    @State private var modelGlow = false

    private var targetZones: [BodyZone: ZoneStatus] {
        var zones: [BodyZone: ZoneStatus] = [:]
        if let result = coordinator.diagnosisResult {
            zones = result.zoneMap
        }
        for zone in coordinator.data.bodyConcerns {
            zones[zone] = .target
        }
        // If no zones selected, show all as base
        if zones.isEmpty {
            for zone in BodyZone.allCases {
                zones[zone] = .base
            }
        }
        return zones
    }

    var body: some View {
        VStack(spacing: DSSpacing.md) {
            Spacer()

            Text("Your Focus Areas")
                .font(DSFont.screenTitle)
                .foregroundStyle(Color.ds_textPrimary)
                .scaleEffect(showTitle ? 1 : 0.9)
                .opacity(showTitle ? 1 : 0)

            // 3D Body Model with glow entrance
            ZStack {
                // Background glow
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.ds_cyan.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 160
                        )
                    )
                    .frame(width: 320, height: 320)
                    .scaleEffect(modelGlow ? 1.1 : 0.9)

                BodyModelView(
                    gender: coordinator.data.gender,
                    zones: targetZones,
                    interactive: true,
                    size: .full
                )
                .scaleEffect(showModel ? 1 : 0.7)
                .opacity(showModel ? 1 : 0)
            }

            // Zone chips
            if !coordinator.data.bodyConcerns.isEmpty {
                HStack(spacing: DSSpacing.xs) {
                    ForEach(Array(coordinator.data.bodyConcerns.enumerated()), id: \.element) { index, zone in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.ds_cyan)
                                .frame(width: 6, height: 6)
                            Text(zone.displayName)
                                .font(DSFont.micro)
                                .foregroundStyle(Color.ds_cyan)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.ds_cyan.opacity(0.1))
                        .clipShape(Capsule())
                        .scaleEffect(showChips ? 1 : 0.5)
                        .opacity(showChips ? 1 : 0)
                    }
                }
            }

            Text("\(coordinator.data.timeline.rawValue) to transform")
                .font(DSFont.caption)
                .foregroundStyle(Color.ds_textSecondary)
                .offset(y: showTimeline ? 0 : 10)
                .opacity(showTimeline ? 1 : 0)

            Spacer()

            DSPrimaryButton("Commit to the Plan", icon: "checkmark.seal.fill") {
                DSHaptic.celebration()
                coordinator.advance()
            }
            .padding(.horizontal, DSSpacing.screenPadding)
            .padding(.bottom, DSSpacing.xl)
            .scaleEffect(showButton ? 1 : 0.9)
            .opacity(showButton ? 1 : 0)
        }
        .onAppear {
            DSHaptic.anticipationBuild()

            withAnimation(.easeOut(duration: 0.5)) {
                showTitle = true
            }

            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.3)) {
                showModel = true
            }

            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(0.5)) {
                modelGlow = true
            }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.8)) {
                showChips = true
            }

            withAnimation(.easeOut(duration: 0.4).delay(1.0)) {
                showTimeline = true
            }

            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.2)) {
                showButton = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                DSHaptic.success()
            }
        }
    }
}
