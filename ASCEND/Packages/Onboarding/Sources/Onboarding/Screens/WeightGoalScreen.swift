import SwiftUI
import DesignSystem

struct WeightGoalScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showCurrentWeight = false
    @State private var showGoalWeight = false
    @State private var showVisual = false
    @State private var showButton = false
    @State private var useLbs = true

    // Display helpers
    private func displayWeight(_ kg: Double) -> String {
        if useLbs {
            return String(format: "%.0f", kg * 2.20462)
        } else {
            return String(format: "%.1f", kg)
        }
    }

    private var unitLabel: String { useLbs ? "lbs" : "kg" }

    private var currentWeightInt: Int {
        useLbs ? Int(round(coordinator.data.weightKg * 2.20462)) : Int(round(coordinator.data.weightKg))
    }

    private var goalWeightInt: Int {
        useLbs ? Int(round(coordinator.data.goalWeight * 2.20462)) : Int(round(coordinator.data.goalWeight))
    }

    private func setCurrentWeight(_ val: Int) {
        coordinator.data.weightKg = useLbs ? Double(val) / 2.20462 : Double(val)
    }

    private func setGoalWeight(_ val: Int) {
        coordinator.data.goalWeight = useLbs ? Double(val) / 2.20462 : Double(val)
    }

    private var weightRange: ClosedRange<Int> {
        useLbs ? 88...330 : 40...150
    }

    private var delta: Double {
        coordinator.data.goalWeight - coordinator.data.weightKg
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)

            // Title + Subtitle
            VStack(spacing: DSSpacing.xs) {
                Text("Weight & Goal")
                    .font(DSFont.screenTitle)
                    .foregroundStyle(Color.ds_textPrimary)
                    .scaleEffect(showTitle ? 1 : 0.9)
                    .opacity(showTitle ? 1 : 0)

                Text("Set your starting point and target")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textSecondary)
                    .opacity(showSubtitle ? 1 : 0)
                    .offset(y: showSubtitle ? 0 : 10)
            }
            .padding(.bottom, DSSpacing.md)

            // Unit toggle
            HStack {
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        useLbs.toggle()
                    }
                    DSHaptic.selection()
                } label: {
                    Text(useLbs ? "lbs" : "kg")
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_cyan)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.ds_cyan.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, DSSpacing.screenPadding)
            .padding(.bottom, DSSpacing.xs)
            .opacity(showSubtitle ? 1 : 0)

            // Current weight ruler
            VStack(spacing: 6) {
                Text("CURRENT WEIGHT")
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_cyan)
                    .tracking(2)

                Text("\(displayWeight(coordinator.data.weightKg)) \(unitLabel)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.ds_textPrimary)
                    .shadow(color: Color.ds_cyan.opacity(0.2), radius: 8)
                    .transaction { $0.animation = nil }

                WeightRulerPicker(
                    value: Binding(
                        get: { currentWeightInt },
                        set: { setCurrentWeight($0) }
                    ),
                    range: weightRange,
                    useLbs: useLbs,
                    accentColor: Color.ds_cyan
                )
                .frame(height: 60)
                .id("current-\(useLbs)")
            }
            .opacity(showCurrentWeight ? 1 : 0)
            .offset(y: showCurrentWeight ? 0 : 20)

            Spacer().frame(height: DSSpacing.lg)

            // Transformation visual
            TransformationVisual(
                currentKg: coordinator.data.weightKg,
                goalKg: coordinator.data.goalWeight,
                useLbs: useLbs
            )
            .frame(height: 150)
            .opacity(showVisual ? 1 : 0)
            .scaleEffect(showVisual ? 1 : 0.8)

            Spacer().frame(height: DSSpacing.lg)

            // Goal weight ruler
            VStack(spacing: 6) {
                Text("GOAL WEIGHT")
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_purple)
                    .tracking(2)

                Text("\(displayWeight(coordinator.data.goalWeight)) \(unitLabel)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.ds_purple)
                    .shadow(color: Color.ds_purple.opacity(0.2), radius: 8)
                    .transaction { $0.animation = nil }

                WeightRulerPicker(
                    value: Binding(
                        get: { goalWeightInt },
                        set: { setGoalWeight($0) }
                    ),
                    range: weightRange,
                    useLbs: useLbs,
                    accentColor: Color.ds_purple
                )
                .frame(height: 60)
                .id("goal-\(useLbs)")
            }
            .opacity(showGoalWeight ? 1 : 0)
            .offset(y: showGoalWeight ? 0 : 20)

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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.4)) { showCurrentWeight = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.6)) { showVisual = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.8)) { showGoalWeight = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.0)) { showButton = true }
        }
    }
}

// MARK: - Transformation Visual

private struct TransformationVisual: View {
    let currentKg: Double
    let goalKg: Double
    let useLbs: Bool

    @State private var glowPulse = false
    @State private var particlePhase = false

    private var deltaKg: Double { goalKg - currentKg }

    // Normalized scale (0.75 = very light, 1.25 = very heavy)
    private func bodyScale(for kg: Double) -> CGFloat {
        let normalized = (kg - 40) / (150 - 40) // 0 to 1
        return 0.8 + CGFloat(normalized) * 0.5 // 0.8 to 1.3
    }

    // Arc progress (1.0 = at goal, 0.0 = very far)
    private var arcProgress: CGFloat {
        let diff = abs(deltaKg)
        return max(0.05, min(1.0, 1.0 - diff / 50.0))
    }

    // Delta color
    private var deltaColor: Color {
        let absDiff = abs(deltaKg)
        if absDiff < 3 { return Color.ds_green }
        if absDiff < 15 { return Color.ds_cyan }
        return Color.ds_yellow
    }

    private var deltaText: String {
        let diff: Double
        let unit: String
        if useLbs {
            diff = abs(deltaKg * 2.20462)
            unit = "lbs"
        } else {
            diff = abs(deltaKg)
            unit = "kg"
        }
        if abs(deltaKg) < 0.5 {
            return "You're at your goal!"
        }
        let verb = deltaKg > 0 ? "to gain" : "to lose"
        return String(format: "%.0f %@ %@", diff, unit, verb)
    }

    var body: some View {
        VStack(spacing: 14) {
            // Circle + figures
            ZStack {
                // Floating particles
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(i % 2 == 0 ? Color.ds_cyan.opacity(0.3) : Color.ds_purple.opacity(0.3))
                        .frame(width: CGFloat.random(in: 3...6), height: CGFloat.random(in: 3...6))
                        .offset(
                            x: CGFloat.random(in: -60...60),
                            y: particlePhase
                                ? CGFloat.random(in: -40...40)
                                : CGFloat.random(in: -30...30)
                        )
                        .opacity(particlePhase ? 0.6 : 0.2)
                }

                // Progress arc (background track)
                Circle()
                    .stroke(Color.ds_charcoal, lineWidth: 3)
                    .frame(width: 90, height: 90)

                // Progress arc (active)
                Circle()
                    .trim(from: 0, to: arcProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Color.ds_cyan, Color.ds_purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 90, height: 90)
                    .shadow(color: Color.ds_cyan.opacity(glowPulse ? 0.5 : 0.2), radius: 6)

                // Current body silhouette (cyan, solid)
                Image(systemName: "figure.stand")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(Color.ds_cyan.opacity(0.7))
                    .scaleEffect(x: bodyScale(for: currentKg), y: 1.0)
                    .offset(x: -8)

                // Goal body silhouette (purple, ghost outline)
                Image(systemName: "figure.stand")
                    .font(.system(size: 36, weight: .ultraLight))
                    .foregroundStyle(Color.ds_purple.opacity(glowPulse ? 0.7 : 0.35))
                    .scaleEffect(x: bodyScale(for: goalKg), y: 1.0)
                    .offset(x: 8)

                // Arrow between figures
                if abs(deltaKg) > 1 {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.ds_textSecondary.opacity(0.5))
                }
            }
            .frame(height: 100)

            // Delta pill — separate, below the circle
            HStack(spacing: 5) {
                Image(systemName: abs(deltaKg) < 0.5 ? "checkmark.circle.fill" : (deltaKg > 0 ? "arrow.up.right" : "arrow.down.right"))
                    .font(.system(size: 12, weight: .bold))
                Text(deltaText)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(deltaColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(deltaColor.opacity(0.12))
            )
            .overlay(
                Capsule()
                    .stroke(deltaColor.opacity(glowPulse ? 0.5 : 0.2), lineWidth: 1)
            )
            .scaleEffect(glowPulse ? 1.02 : 0.98)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: deltaKg)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentKg)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: goalKg)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                particlePhase = true
            }
        }
    }
}

// MARK: - Weight Ruler Picker

private struct WeightRulerPicker: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let useLbs: Bool
    var accentColor: Color = Color.ds_cyan

    private let tickSpacing: CGFloat = 20
    @State private var scrolledID: Int?
    @State private var lastHapticValue: Int = 0
    @State private var hasInitialized = false

    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    Color.clear.frame(width: centerX)

                    ForEach(range.lowerBound...range.upperBound, id: \.self) { num in
                        let isMajor = num % 10 == 0
                        let isMedium = num % 5 == 0 && !isMajor
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(accentColor.opacity(isMajor ? 0.8 : (isMedium ? 0.4 : 0.2)))
                                .frame(width: 1.5, height: isMajor ? 28 : (isMedium ? 20 : 14))
                            if isMajor {
                                Text("\(num)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Color.ds_textSecondary)
                                    .fixedSize()
                            }
                        }
                        .frame(width: tickSpacing)
                        .id(num)
                    }

                    Color.clear.frame(width: centerX)
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrolledID, anchor: .center)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .onAppear {
                scrolledID = value
                lastHapticValue = value
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    hasInitialized = true
                }
            }
            .onChange(of: scrolledID) { _, newID in
                guard let newID else { return }
                if newID != value {
                    value = newID
                    if hasInitialized && newID != lastHapticValue {
                        lastHapticValue = newID
                        DSHaptic.sliderTick()
                    }
                }
            }
            .overlay {
                VStack(spacing: 0) {
                    RulerTriangle()
                        .fill(accentColor)
                        .frame(width: 10, height: 6)
                    Rectangle()
                        .fill(accentColor)
                        .frame(width: 2, height: 32)
                }
                .allowsHitTesting(false)
            }
        }
    }
}

private struct RulerTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}
