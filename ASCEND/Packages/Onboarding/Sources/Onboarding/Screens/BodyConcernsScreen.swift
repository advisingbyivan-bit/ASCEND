import SwiftUI
import DesignSystem
import BodyModel3D

struct BodyConcernsScreen: View {
    let coordinator: OnboardingCoordinator
    private let maxSelections = 3
    @State private var showTitle = false
    @State private var showModel = false
    @State private var showChips = false
    @State private var showTracker = false
    @State private var showButton = false
    @State private var glowPulse = false
    @State private var modelKey = UUID()
    @State private var showTargetLocked = false

    private var zoneColors: [BodyZone: ZoneStatus] {
        var result: [BodyZone: ZoneStatus] = [:]
        for zone in coordinator.data.bodyConcerns {
            result[zone] = .weak
        }
        return result
    }

    private var selectionCount: Int { coordinator.data.bodyConcerns.count }

    var body: some View {
        VStack(spacing: 0) {
            // Title
            VStack(spacing: DSSpacing.xs) {
                Text("Problem Areas")
                    .font(DSFont.screenTitle)
                    .foregroundStyle(Color.ds_textPrimary)
                    .scaleEffect(showTitle ? 1 : 0.9)
                    .opacity(showTitle ? 1 : 0)

                Text("Tap the zones you want to improve")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textSecondary)
                    .opacity(showTitle ? 1 : 0)
            }
            .padding(.top, 28)
            .padding(.bottom, DSSpacing.sm)

            // 3D Body Model — large hero
            ZStack {
                // Pulsing glow behind model when zones selected
                if selectionCount > 0 {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.ds_red.opacity(0.2), Color.clear],
                                center: .center,
                                startRadius: 30,
                                endRadius: 160
                            )
                        )
                        .frame(width: 300, height: 300)
                        .scaleEffect(glowPulse ? 1.05 : 0.95)
                }

                BodyModelView(
                    gender: coordinator.data.gender,
                    zones: zoneColors,
                    interactive: false,
                    size: .full
                )
                .id(modelKey)
                .allowsHitTesting(false)
            }
            .frame(height: 300)
            .opacity(showModel ? 1 : 0)
            .scaleEffect(showModel ? 1 : 0.85)

            // Zone chips
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    zoneChip(.shoulders, icon: "arrow.up.and.down")
                    zoneChip(.chest, icon: "square.grid.2x2")
                    zoneChip(.arms, icon: "figure.arms.open")
                }
                HStack(spacing: 8) {
                    zoneChip(.back, icon: "arrow.uturn.backward")
                    zoneChip(.core, icon: "circle.hexagongrid")
                    zoneChip(.legs, icon: "figure.walk")
                }
                if coordinator.data.gender == .female {
                    HStack(spacing: 8) {
                        zoneChip(.glutes, icon: "figure.strengthtraining.traditional")
                    }
                }
            }
            .padding(.horizontal, DSSpacing.screenPadding)
            .opacity(showChips ? 1 : 0)
            .offset(y: showChips ? 0 : 15)

            Spacer().frame(height: DSSpacing.lg)

            // Target tracker — three animated rings
            HStack(spacing: 16) {
                ForEach(0..<maxSelections, id: \.self) { i in
                    let isActive = i < selectionCount
                    let zoneName = i < coordinator.data.bodyConcerns.count
                        ? coordinator.data.bodyConcerns[i].displayName
                        : ""

                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .stroke(Color.ds_charcoal, lineWidth: 2)
                                .frame(width: 38, height: 38)

                            Circle()
                                .trim(from: 0, to: isActive ? 1.0 : 0.0)
                                .stroke(Color.ds_red, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 38, height: 38)

                            if isActive {
                                Image(systemName: "scope")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.ds_red)
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                Text("\(i + 1)")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(Color.ds_textSecondary.opacity(0.4))
                            }
                        }
                        .shadow(color: isActive ? Color.ds_red.opacity(0.3) : .clear, radius: 6)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isActive)

                        Text(isActive ? zoneName : "—")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundStyle(isActive ? Color.ds_red : Color.ds_textSecondary.opacity(0.3))
                            .frame(width: 70)
                            .lineLimit(1)
                    }
                }
            }
            .opacity(showTracker ? 1 : 0)
            .offset(y: showTracker ? 0 : 10)

            Spacer().frame(height: DSSpacing.sm)

            // Targets locked message
            if selectionCount == maxSelections {
                HStack(spacing: 6) {
                    Image(systemName: "scope")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.ds_red)
                    Text("Targets locked. IRIS is watching.")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.ds_red.opacity(0.8))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.ds_red.opacity(0.08))
                        .overlay(
                            Capsule()
                                .stroke(Color.ds_red.opacity(glowPulse ? 0.3 : 0.1), lineWidth: 1)
                        )
                )
                .transition(.scale.combined(with: .opacity))
            } else if selectionCount > 0 {
                Text("Select \(maxSelections - selectionCount) more area\(maxSelections - selectionCount == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.ds_textSecondary.opacity(0.5))
                    .transition(.opacity)
            }

            Spacer()

            DSPrimaryButton("Continue", icon: "arrow.right") {
                DSHaptic.medium()
                coordinator.advance()
            }
            .padding(.horizontal, DSSpacing.screenPadding)
            .padding(.bottom, DSSpacing.xl)
            .scaleEffect(showButton ? 1 : 0.9)
            .opacity(showButton ? 1 : 0)
        }
        .onAppear {
            DSHaptic.screenEntry()
            withAnimation(.easeOut(duration: 0.5)) { showTitle = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.3)) { showModel = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.5)) { showChips = true }
            withAnimation(.easeOut(duration: 0.4).delay(0.7)) { showTracker = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.9)) { showButton = true }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }

    // MARK: - Zone Chip

    private func zoneChip(_ zone: BodyZone, icon: String) -> some View {
        let isSelected = coordinator.data.bodyConcerns.contains(zone)
        return Button {
            toggleZone(zone)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.ds_red : Color.ds_textSecondary.opacity(0.5))

                Text(zone.displayName)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? Color.ds_textPrimary : Color.ds_textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? AnyShapeStyle(
                        LinearGradient(
                            colors: [Color.ds_red.opacity(0.2), Color.ds_red.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    : AnyShapeStyle(Color.ds_charcoal)
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(
                        isSelected
                            ? Color.ds_red.opacity(0.6)
                            : Color.ds_cardBorder,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(color: isSelected ? Color.ds_red.opacity(0.3) : .clear, radius: 8)
            .scaleEffect(isSelected ? 1.06 : 1.0)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: isSelected)
    }

    // MARK: - Toggle

    private func toggleZone(_ zone: BodyZone) {
        if let idx = coordinator.data.bodyConcerns.firstIndex(of: zone) {
            coordinator.data.bodyConcerns.remove(at: idx)
            modelKey = UUID()
            DSHaptic.light()
        } else if selectionCount < maxSelections {
            coordinator.data.bodyConcerns.append(zone)
            modelKey = UUID()
            DSHaptic.optionSelect()
            if coordinator.data.bodyConcerns.count == maxSelections {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    DSHaptic.medium()
                }
            }
        } else {
            DSHaptic.warning()
        }
    }
}
