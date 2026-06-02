import SwiftUI
import DesignSystem
import Gamification

/// Quick daily check-in sheet — log what muscle groups you trained today.
/// Counts as engagement for streak maintenance (no scan credit needed).
struct WorkoutLogSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedGroups: Set<MuscleGroup> = []
    @State private var showConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                DSAnimatedBackground()

                ScrollView {
                    VStack(spacing: DSSpacing.lg) {
                        // Header
                        VStack(spacing: DSSpacing.xs) {
                            Image(systemName: "dumbbell.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(Color.ds_cyan)

                            Text("What did you hit today?")
                                .font(DSFont.cardTitle)
                                .foregroundStyle(Color.ds_textPrimary)

                            Text("Tap the muscle groups you trained. This keeps your streak alive.")
                                .font(DSFont.caption)
                                .foregroundStyle(Color.ds_textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, DSSpacing.md)
                        }
                        .padding(.top, DSSpacing.md)

                        // Muscle group grid
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: DSSpacing.sm),
                            GridItem(.flexible(), spacing: DSSpacing.sm)
                        ], spacing: DSSpacing.sm) {
                            ForEach(MuscleGroup.allCases) { group in
                                muscleGroupButton(group)
                            }
                        }
                        .padding(.horizontal, DSSpacing.screenPadding)

                        // Rest day option
                        Button {
                            DSHaptic.light()
                            selectedGroups = [.restDay]
                        } label: {
                            HStack(spacing: DSSpacing.sm) {
                                Image(systemName: "moon.fill")
                                    .font(.system(size: 16))
                                Text("Rest Day")
                                    .font(DSFont.body)
                            }
                            .foregroundStyle(selectedGroups.contains(.restDay) ? Color.ds_navy : Color.ds_textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DSSpacing.sm)
                            .background(selectedGroups.contains(.restDay) ? Color.ds_cyan : Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cardRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: DSSpacing.cardRadius)
                                    .stroke(selectedGroups.contains(.restDay) ? Color.ds_cyan : Color.ds_cardBorder, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, DSSpacing.screenPadding)

                        // Log button
                        Button {
                            DSHaptic.heavy()
                            logAndDismiss()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18))
                                Text(selectedGroups.isEmpty ? "Just Check In" : "Log Workout")
                                    .font(DSFont.bodyBold)
                            }
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.ds_cyan, Color.ds_cyan.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: Color.ds_cyan.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, DSSpacing.screenPadding)
                        .padding(.bottom, DSSpacing.xxl)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("LOG WORKOUT")
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_cyan)
                        .tracking(2)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .font(DSFont.body)
                        .foregroundStyle(Color.ds_cyan)
                }
            }
            .overlay {
                if showConfirmation {
                    confirmationOverlay
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showConfirmation)
        }
    }

    // MARK: - Muscle Group Button

    private func muscleGroupButton(_ group: MuscleGroup) -> some View {
        let isSelected = selectedGroups.contains(group)

        return Button {
            DSHaptic.light()
            if group == .restDay { return } // Handled by separate button
            if selectedGroups.contains(.restDay) {
                selectedGroups.remove(.restDay)
            }
            if selectedGroups.contains(group) {
                selectedGroups.remove(group)
            } else {
                selectedGroups.insert(group)
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: group.icon)
                    .font(.system(size: 22))
                Text(group.label)
                    .font(DSFont.captionBold)
            }
            .foregroundStyle(isSelected ? Color.ds_navy : Color.ds_textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(isSelected ? Color.ds_cyan : Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.cardRadius)
                    .stroke(isSelected ? Color.ds_cyan : Color.ds_cardBorder, lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.ds_cyan.opacity(0.2) : .clear, radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Confirmation

    private var confirmationOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: DSSpacing.md) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(Color.ds_green)

                Text("Logged!")
                    .font(DSFont.cardTitle)
                    .foregroundStyle(Color.ds_textPrimary)

                if appState.currentStreak > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(appState.streakTier.color)
                        Text("\(appState.currentStreak)-day streak")
                            .font(DSFont.bodyBold)
                            .foregroundStyle(appState.streakTier.color)
                    }
                }
            }
            .padding(DSSpacing.xl)
            .dsCard()
        }
    }

    // MARK: - Log Action

    private func logAndDismiss() {
        let groups = selectedGroups.isEmpty
            ? ["check_in"]
            : selectedGroups.map(\.rawValue)

        appState.logWorkout(muscleGroups: groups)

        showConfirmation = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            dismiss()
        }
    }
}

// MARK: - Muscle Group Enum

enum MuscleGroup: String, CaseIterable, Identifiable, Hashable {
    case chest = "chest"
    case back = "back"
    case shoulders = "shoulders"
    case arms = "arms"
    case legs = "legs"
    case core = "core"
    case cardio = "cardio"
    case restDay = "rest_day"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .chest: "Chest"
        case .back: "Back"
        case .shoulders: "Shoulders"
        case .arms: "Arms"
        case .legs: "Legs"
        case .core: "Core"
        case .cardio: "Cardio"
        case .restDay: "Rest Day"
        }
    }

    var icon: String {
        switch self {
        case .chest: "figure.strengthtraining.traditional"
        case .back: "figure.cross.training"
        case .shoulders: "figure.arms.open"
        case .arms: "dumbbell.fill"
        case .legs: "figure.run"
        case .core: "figure.core.training"
        case .cardio: "heart.fill"
        case .restDay: "moon.fill"
        }
    }

    static var allCases: [MuscleGroup] {
        [.chest, .back, .shoulders, .arms, .legs, .core, .cardio]
        // restDay excluded from grid — it has its own button
    }
}
