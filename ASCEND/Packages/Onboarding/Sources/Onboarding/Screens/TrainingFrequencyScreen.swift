import SwiftUI
import DesignSystem

struct TrainingFrequencyScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var revealedOptions: Set<TrainingFrequency> = []
    @State private var showButton = false
    @State private var ringPulse = false
    @State private var showMotivation = false

    private var motivationalMessage: (String, String) {
        switch coordinator.data.trainingFrequency {
        case .sedentary:
            return ("flame.fill", "Everyone starts somewhere. IRIS will push you.")
        case .light:
            return ("sparkles", "Good foundation. Time to level up.")
        case .moderate:
            return ("bolt.fill", "Solid discipline. Let's optimize.")
        case .active:
            return ("trophy.fill", "Serious commitment. IRIS respects that.")
        case .athlete:
            return ("crown.fill", "Elite level. Built for competition.")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)

            // Title
            VStack(spacing: DSSpacing.xs) {
                Text("How often do you train?")
                    .font(DSFont.screenTitle)
                    .foregroundStyle(Color.ds_textPrimary)
                    .scaleEffect(showTitle ? 1 : 0.9)
                    .opacity(showTitle ? 1 : 0)

                Text("This calibrates your program intensity")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textSecondary)
                    .opacity(showSubtitle ? 1 : 0)
                    .offset(y: showSubtitle ? 0 : 10)
            }
            .padding(.bottom, DSSpacing.lg)

            // Frequency options
            VStack(spacing: 12) {
                ForEach(Array(TrainingFrequency.allCases.enumerated()), id: \.element.id) { index, freq in
                    let isSelected = coordinator.data.trainingFrequency == freq
                    let isRevealed = revealedOptions.contains(freq)

                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            coordinator.data.trainingFrequency = freq
                        }
                        DSHaptic.optionSelect()
                    } label: {
                        HStack(spacing: 14) {
                            // Activity ring + icon
                            ZStack {
                                // Background ring
                                Circle()
                                    .stroke(Color.ds_charcoal, lineWidth: 3)
                                    .frame(width: 46, height: 46)

                                // Active ring
                                Circle()
                                    .trim(from: 0, to: isSelected ? freq.intensityLevel : 0)
                                    .stroke(
                                        freq.accentColor,
                                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                    )
                                    .rotationEffect(.degrees(-90))
                                    .frame(width: 46, height: 46)

                                // Icon
                                Image(systemName: freq.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(isSelected ? freq.accentColor : Color.ds_textSecondary.opacity(0.5))
                            }
                            .shadow(color: isSelected ? freq.accentColor.opacity(0.4) : .clear, radius: 8)
                            .scaleEffect(isSelected && ringPulse ? 1.05 : 1.0)

                            // Text content
                            VStack(alignment: .leading, spacing: 3) {
                                Text(freq.rawValue)
                                    .font(DSFont.bodyBold)
                                    .foregroundStyle(isSelected ? Color.ds_textPrimary : Color.ds_textSecondary)

                                Text(freq.subtitle)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundStyle(isSelected ? freq.accentColor.opacity(0.8) : Color.ds_textSecondary.opacity(0.4))
                            }

                            Spacer()

                            // Intensity dots
                            HStack(spacing: 4) {
                                ForEach(0..<5, id: \.self) { dot in
                                    Circle()
                                        .fill(dot < freq.intensityDots
                                            ? (isSelected ? freq.accentColor : Color.ds_textSecondary.opacity(0.3))
                                            : Color.ds_charcoal
                                        )
                                        .frame(width: 6, height: 6)
                                }
                            }

                            if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(freq.accentColor)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            isSelected
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [freq.accentColor.opacity(0.12), freq.accentColor.opacity(0.04)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                : AnyShapeStyle(Color.ds_charcoal)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cardRadius))
                        .overlay(
                            RoundedRectangle(cornerRadius: DSSpacing.cardRadius)
                                .stroke(isSelected ? freq.accentColor.opacity(0.6) : Color.ds_cardBorder, lineWidth: isSelected ? 1.5 : 1)
                        )
                        .shadow(color: isSelected ? freq.accentColor.opacity(0.2) : .clear, radius: 10)
                        .scaleEffect(isSelected ? 1.02 : 1.0)
                    }
                    .opacity(isRevealed ? 1 : 0)
                    .offset(x: isRevealed ? 0 : 40)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
                }
            }
            .padding(.horizontal, DSSpacing.screenPadding)

            Spacer().frame(height: DSSpacing.md)

            // Dynamic motivational message
            HStack(spacing: 8) {
                Image(systemName: motivationalMessage.0)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(coordinator.data.trainingFrequency.accentColor.opacity(0.7))
                Text(motivationalMessage.1)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.ds_textSecondary.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(coordinator.data.trainingFrequency.accentColor.opacity(0.08))
            )
            .contentTransition(.numericText())
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: coordinator.data.trainingFrequency)

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
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) { showSubtitle = true }

            for (index, freq) in TrainingFrequency.allCases.enumerated() {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.3 + Double(index) * 0.1)) {
                    revealedOptions.insert(freq)
                }
            }

            let totalDelay = 0.3 + Double(TrainingFrequency.allCases.count) * 0.1 + 0.15
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(totalDelay)) {
                showButton = true
            }

            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                ringPulse = true
            }
        }
    }
}

// MARK: - TrainingFrequency Extensions

extension TrainingFrequency {
    var icon: String {
        switch self {
        case .sedentary: return "bed.double.fill"
        case .light: return "figure.walk"
        case .moderate: return "figure.run"
        case .active: return "flame.fill"
        case .athlete: return "bolt.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .sedentary: return "Mostly desk work, minimal activity"
        case .light: return "Light walks, stretching, casual movement"
        case .moderate: return "Consistent gym sessions, structured training"
        case .active: return "Serious training program, high commitment"
        case .athlete: return "Peak performance, competitive level"
        }
    }

    var intensityLevel: CGFloat {
        switch self {
        case .sedentary: return 0.15
        case .light: return 0.35
        case .moderate: return 0.55
        case .active: return 0.78
        case .athlete: return 1.0
        }
    }

    var intensityDots: Int {
        switch self {
        case .sedentary: return 1
        case .light: return 2
        case .moderate: return 3
        case .active: return 4
        case .athlete: return 5
        }
    }

    var accentColor: Color {
        switch self {
        case .sedentary: return Color.ds_textSecondary
        case .light: return Color.ds_cyan
        case .moderate: return Color.ds_cyan
        case .active: return Color.ds_purple
        case .athlete: return Color.ds_red
        }
    }
}
