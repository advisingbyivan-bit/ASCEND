import SwiftUI
import DesignSystem

struct AgeHeightScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var showTitle = false
    @State private var showAge = false
    @State private var showHeight = false
    @State private var showButton = false
    @State private var useMetric = false

    private var heightDisplay: String {
        let cm = coordinator.data.heightCm
        if useMetric {
            return "\(cm) cm"
        } else {
            let totalInches = Int(Double(cm) / 2.54)
            let feet = totalInches / 12
            let inches = totalInches % 12
            return "\(feet)'\(inches)\""
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Title
            VStack(spacing: DSSpacing.xs) {
                Text("Age & Height")
                    .font(DSFont.screenTitle)
                    .foregroundStyle(Color.ds_textPrimary)
                    .scaleEffect(showTitle ? 1 : 0.9)
                    .opacity(showTitle ? 1 : 0)

                Text("Used to personalize your diagnosis")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textSecondary)
                    .opacity(showTitle ? 1 : 0)
            }
            .padding(.bottom, DSSpacing.xl)

            // Age — horizontal scroll ruler
            VStack(spacing: DSSpacing.sm) {
                Text("AGE")
                    .font(DSFont.captionBold)
                    .foregroundStyle(Color.ds_cyan)
                    .tracking(2)

                Text("\(coordinator.data.age)")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.ds_textPrimary)
                    .shadow(color: Color.ds_cyan.opacity(0.2), radius: 8)
                    .transaction { $0.animation = nil }

                HorizontalRulerPicker(
                    value: Binding(
                        get: { coordinator.data.age },
                        set: { coordinator.data.age = $0 }
                    ),
                    range: 17...80,
                    majorEvery: 5,
                    labelBuilder: { $0 % 5 == 0 ? "\($0)" : nil }
                )
                .frame(height: 70)
            }
            .opacity(showAge ? 1 : 0)
            .offset(y: showAge ? 0 : 20)

            Spacer().frame(height: DSSpacing.xl)

            // Height — horizontal scroll ruler
            VStack(spacing: DSSpacing.sm) {
                HStack {
                    Text("HEIGHT")
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_cyan)
                        .tracking(2)
                    Spacer()
                    // Imperial / Metric toggle
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            useMetric.toggle()
                        }
                        DSHaptic.selection()
                    } label: {
                        Text(useMetric ? "cm" : "ft/in")
                            .font(DSFont.captionBold)
                            .foregroundStyle(Color.ds_cyan)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.ds_cyan.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, DSSpacing.screenPadding)

                Text(heightDisplay)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.ds_textPrimary)
                    .shadow(color: Color.ds_cyan.opacity(0.2), radius: 8)
                    .transaction { $0.animation = nil }

                HorizontalRulerPicker(
                    value: Binding(
                        get: { coordinator.data.heightCm },
                        set: { coordinator.data.heightCm = $0 }
                    ),
                    range: 120...220,
                    majorEvery: 0, // custom logic
                    labelBuilder: { cm in
                        if useMetric {
                            return cm % 10 == 0 ? "\(cm)" : nil
                        } else {
                            return Self.imperialLabel(for: cm)
                        }
                    },
                    majorCheck: { cm in
                        if useMetric { return cm % 10 == 0 }
                        return Self.imperialLabelCmValues.contains(cm)
                    },
                    mediumCheck: { cm in
                        if useMetric { return cm % 5 == 0 }
                        // Show medium tick at every inch boundary
                        let totalInches = Int(Double(cm) / 2.54)
                        let backToCm = Int(round(Double(totalInches) * 2.54))
                        return backToCm == cm && !Self.imperialLabelCmValues.contains(cm)
                    }
                )
                .frame(height: 70)
                .id(useMetric) // rebuild when unit changes
            }
            .opacity(showHeight ? 1 : 0)
            .offset(y: showHeight ? 0 : 20)

            Spacer()

            // Motivational context
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.ds_purple.opacity(0.6))
                Text("AI calibrates to your exact proportions")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.ds_textSecondary.opacity(0.5))
            }
            .padding(.bottom, DSSpacing.sm)
            .opacity(showButton ? 1 : 0)

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
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.3)) { showAge = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.5)) { showHeight = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.7)) { showButton = true }
        }
    }

    // MARK: - Imperial label helpers

    private static let imperialLabelCmValues: Set<Int> = {
        var result = Set<Int>()
        for feet in 3...7 {
            for inches in [0, 6] {
                let totalInches = feet * 12 + inches
                let cm = Int(round(Double(totalInches) * 2.54))
                if (120...220).contains(cm) {
                    result.insert(cm)
                }
            }
        }
        return result
    }()

    private static func imperialLabel(for cm: Int) -> String? {
        let labelMap: [Int: String] = {
            var result: [Int: String] = [:]
            for feet in 3...7 {
                for inches in [0, 6] {
                    let totalInches = feet * 12 + inches
                    let cmVal = Int(round(Double(totalInches) * 2.54))
                    if (120...220).contains(cmVal) {
                        result[cmVal] = inches == 0 ? "\(feet)'" : "\(feet)'\(inches)\""
                    }
                }
            }
            return result
        }()
        return labelMap[cm]
    }
}

// MARK: - Unified Horizontal Ruler Picker

private struct HorizontalRulerPicker: View {
    @Binding var value: Int
    let range: ClosedRange<Int>
    let majorEvery: Int // set to 0 for custom checks
    let labelBuilder: (Int) -> String?
    var majorCheck: ((Int) -> Bool)? = nil
    var mediumCheck: ((Int) -> Bool)? = nil

    private let tickSpacing: CGFloat = 28
    @State private var scrolledID: Int?
    @State private var lastHapticValue: Int = 0
    @State private var hasInitialized = false

    private func isMajor(_ n: Int) -> Bool {
        if let check = majorCheck { return check(n) }
        return majorEvery > 0 && n % majorEvery == 0
    }

    private func isMedium(_ n: Int) -> Bool {
        if let check = mediumCheck { return check(n) }
        return false
    }

    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    // Leading spacer so first value can center
                    Color.clear.frame(width: centerX)

                    ForEach(range.lowerBound...range.upperBound, id: \.self) { num in
                        let major = isMajor(num)
                        let medium = isMedium(num)
                        VStack(spacing: 4) {
                            Rectangle()
                                .fill(Color.ds_cyan.opacity(major ? 0.8 : (medium ? 0.4 : 0.2)))
                                .frame(width: 1.5, height: major ? 28 : (medium ? 20 : 14))
                            if let lbl = labelBuilder(num) {
                                Text(lbl)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Color.ds_textSecondary)
                                    .fixedSize()
                            }
                        }
                        .frame(width: tickSpacing)
                        .id(num)
                    }

                    // Trailing spacer so last value can center
                    Color.clear.frame(width: centerX)
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrolledID, anchor: .center)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .animation(nil, value: scrolledID)
            .onAppear {
                // Set initial position without animation to prevent spring bounce
                DispatchQueue.main.async {
                    var transaction = Transaction()
                    transaction.disablesAnimations = true
                    withTransaction(transaction) {
                        scrolledID = value
                    }
                    lastHapticValue = value
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
            // Center indicator
            .overlay {
                VStack(spacing: 0) {
                    Triangle()
                        .fill(Color.ds_cyan)
                        .frame(width: 10, height: 6)
                    Rectangle()
                        .fill(Color.ds_cyan)
                        .frame(width: 2, height: 32)
                }
                .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Helpers

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}
