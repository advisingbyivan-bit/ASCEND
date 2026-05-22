import SwiftUI
import DesignSystem
import BodyModel3D

struct GenderScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showOptions = false
    @State private var showButton = false
    @State private var showMotivation = false
    @State private var selectedScale: BodyGender? = nil
    @State private var glowPulse = false
    @State private var hasSelected = false

    private var motivationalText: String {
        switch coordinator.data.gender {
        case .male:
            return "Building your male physique model..."
        case .female:
            return "Building your female physique model..."
        }
    }

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            Spacer()

            VStack(spacing: DSSpacing.lg) {
                Text("What's your gender?")
                    .font(DSFont.screenTitle)
                    .foregroundStyle(Color.ds_textPrimary)
                    .scaleEffect(showTitle ? 1 : 0.9)
                    .opacity(showTitle ? 1 : 0)

                Text("This helps us build your 3D body model")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textSecondary)
                    .offset(y: showSubtitle ? 0 : 10)
                    .opacity(showSubtitle ? 1 : 0)

                HStack(spacing: DSSpacing.lg) {
                    genderOption("Male", gender: .male)
                    genderOption("Female", gender: .female)
                }
                .padding(.top, DSSpacing.md)
                .opacity(showOptions ? 1 : 0)
                .offset(y: showOptions ? 0 : 20)

                // Dynamic motivational text after selection
                if hasSelected {
                    HStack(spacing: 8) {
                        Image(systemName: "cube.transparent")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.ds_cyan)
                            .symbolEffect(.pulse.byLayer, isActive: true)
                        Text(motivationalText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.ds_cyan.opacity(0.8))
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)).combined(with: .scale(scale: 0.9)))
                }
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

            withAnimation(.easeOut(duration: 0.5)) {
                showTitle = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) {
                showSubtitle = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4)) {
                showOptions = true
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.7)) {
                showButton = true
            }
            withAnimation(.easeOut(duration: 0.4).delay(0.9)) {
                hasSelected = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }

    private func genderOption(_ label: String, gender: BodyGender) -> some View {
        let isSelected = coordinator.data.gender == gender
        return Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                coordinator.data.gender = gender
                selectedScale = gender
            }
            if !hasSelected {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    hasSelected = true
                }
            }
            DSHaptic.optionSelect()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    selectedScale = nil
                }
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    // Breathing glow behind selected model
                    if isSelected {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.ds_cyan.opacity(glowPulse ? 0.2 : 0.08), Color.clear],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 70
                                )
                            )
                            .frame(width: 140, height: 140)
                            .transition(.opacity)
                    }

                    // 3D body model instead of generic icon
                    BodyModelView(
                        gender: gender,
                        zones: [:],
                        interactive: false,
                        size: .card
                    )
                    .frame(height: 140)
                    .allowsHitTesting(false)
                }

                HStack(spacing: 6) {
                    Text(label)
                        .font(DSFont.bodyBold)
                        .foregroundStyle(isSelected ? Color.ds_cyan : Color.ds_textSecondary)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.ds_cyan)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .frame(width: 150, height: 190)
            .background(isSelected ? Color.ds_cyan.opacity(0.1) : Color.ds_charcoal)
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.cardRadius)
                    .stroke(isSelected ? Color.ds_cyan : Color.ds_cardBorder, lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .shadow(color: isSelected ? Color.ds_cyan.opacity(glowPulse ? 0.4 : 0.2) : .clear, radius: 12)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
}
