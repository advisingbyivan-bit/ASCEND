import SwiftUI
import DesignSystem

struct PreferencesScreen: View {
    @Bindable var coordinator: OnboardingCoordinator
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showWeekStrip = false
    @State private var showNotification = false
    @State private var showButton = false
    @State private var glowPulse = false

    private let weekdayAbbreviations: [(Weekday, String)] = [
        (.sunday, "S"), (.monday, "M"), (.tuesday, "T"),
        (.wednesday, "W"), (.thursday, "T"), (.friday, "F"), (.saturday, "S")
    ]

    private var notificationTimeString: String {
        let hour = coordinator.data.notificationHour
        let minute = coordinator.data.notificationMinute
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
        return String(format: "%d:%02d %@", displayHour, minute, period)
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)

            // Title
            VStack(spacing: DSSpacing.xs) {
                Text("Your Schedule")
                    .font(DSFont.screenTitle)
                    .foregroundStyle(Color.ds_textPrimary)
                    .scaleEffect(showTitle ? 1 : 0.9)
                    .opacity(showTitle ? 1 : 0)

                Text("We'll build your routine around these")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textSecondary)
                    .offset(y: showSubtitle ? 0 : 10)
                    .opacity(showSubtitle ? 1 : 0)
            }
            .padding(.bottom, DSSpacing.xl)

            // Week strip visual
            VStack(spacing: DSSpacing.md) {
                // Scan Day section
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.ds_cyan)
                        Text("SCAN DAY")
                            .font(DSFont.captionBold)
                            .foregroundStyle(Color.ds_cyan)
                            .tracking(2)
                        Spacer()
                    }

                    HStack(spacing: 6) {
                        ForEach(Array(weekdayAbbreviations.enumerated()), id: \.offset) { _, pair in
                            let (day, abbr) = pair
                            let isScanDay = coordinator.data.scanDay == day
                            let isRestDay = coordinator.data.restDay == day

                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                    coordinator.data.scanDay = day
                                }
                                DSHaptic.optionSelect()
                            } label: {
                                Text(abbr)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        isScanDay ? Color.ds_background
                                        : isRestDay ? Color.ds_purple.opacity(0.5)
                                        : Color.ds_textSecondary.opacity(0.5)
                                    )
                                    .frame(width: 40, height: 40)
                                    .background(
                                        isScanDay
                                            ? AnyShapeStyle(Color.ds_cyan)
                                            : AnyShapeStyle(Color.ds_charcoal)
                                    )
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                isScanDay ? Color.ds_cyan : Color.ds_cardBorder,
                                                lineWidth: isScanDay ? 2 : 1
                                            )
                                    )
                                    .shadow(color: isScanDay ? Color.ds_cyan.opacity(0.4) : .clear, radius: 6)
                                    .scaleEffect(isScanDay ? 1.1 : 1.0)
                            }
                        }
                    }
                }

                // Divider
                Rectangle()
                    .fill(Color.ds_cardBorder)
                    .frame(height: 1)
                    .padding(.horizontal, 10)

                // Rest Day section
                VStack(spacing: 10) {
                    HStack {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.ds_purple)
                        Text("REST DAY")
                            .font(DSFont.captionBold)
                            .foregroundStyle(Color.ds_purple)
                            .tracking(2)
                        Spacer()
                    }

                    HStack(spacing: 6) {
                        ForEach(Array(weekdayAbbreviations.enumerated()), id: \.offset) { _, pair in
                            let (day, abbr) = pair
                            let isScanDay = coordinator.data.scanDay == day
                            let isRestDay = coordinator.data.restDay == day

                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                    coordinator.data.restDay = day
                                }
                                DSHaptic.optionSelect()
                            } label: {
                                Text(abbr)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundStyle(
                                        isRestDay ? Color.ds_background
                                        : isScanDay ? Color.ds_cyan.opacity(0.5)
                                        : Color.ds_textSecondary.opacity(0.5)
                                    )
                                    .frame(width: 40, height: 40)
                                    .background(
                                        isRestDay
                                            ? AnyShapeStyle(Color.ds_purple)
                                            : AnyShapeStyle(Color.ds_charcoal)
                                    )
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                isRestDay ? Color.ds_purple : Color.ds_cardBorder,
                                                lineWidth: isRestDay ? 2 : 1
                                            )
                                    )
                                    .shadow(color: isRestDay ? Color.ds_purple.opacity(0.4) : .clear, radius: 6)
                                    .scaleEffect(isRestDay ? 1.1 : 1.0)
                            }
                        }
                    }
                }
            }
            .padding(DSSpacing.md)
            .background(Color.ds_charcoal.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.cardRadius)
                    .stroke(Color.ds_cardBorder, lineWidth: 1)
            )
            .padding(.horizontal, DSSpacing.screenPadding)
            .opacity(showWeekStrip ? 1 : 0)
            .offset(y: showWeekStrip ? 0 : 20)

            Spacer().frame(height: DSSpacing.lg)

            // Notification Time
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.ds_yellow)
                    Text("REMINDER TIME")
                        .font(DSFont.captionBold)
                        .foregroundStyle(Color.ds_yellow)
                        .tracking(2)
                    Spacer()
                }

                // Time display
                Text(notificationTimeString)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.ds_textPrimary)
                    .contentTransition(.numericText())
                    .shadow(color: Color.ds_yellow.opacity(glowPulse ? 0.3 : 0.1), radius: 8)

                // Hour slider
                HStack(spacing: 8) {
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.ds_yellow.opacity(0.5))

                    Slider(value: Binding(
                        get: { Double(coordinator.data.notificationHour) },
                        set: { newVal in
                            let newHour = Int(newVal)
                            if newHour != coordinator.data.notificationHour {
                                DSHaptic.sliderTick()
                            }
                            coordinator.data.notificationHour = newHour
                        }
                    ), in: 6...22, step: 1)
                    .tint(Color.ds_yellow)

                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.ds_purple.opacity(0.5))
                }

                Text("We'll send your daily accountability check")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.ds_textSecondary.opacity(0.5))
            }
            .padding(DSSpacing.md)
            .background(Color.ds_charcoal.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: DSSpacing.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: DSSpacing.cardRadius)
                    .stroke(Color.ds_cardBorder, lineWidth: 1)
            )
            .padding(.horizontal, DSSpacing.screenPadding)
            .opacity(showNotification ? 1 : 0)
            .offset(y: showNotification ? 0 : 20)

            Spacer().frame(height: DSSpacing.md)

            // Plan ready indicator
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.ds_green)
                Text("Your schedule is set. Almost ready.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.ds_textSecondary.opacity(0.6))
            }
            .opacity(showButton ? 1 : 0)

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
            withAnimation(.easeOut(duration: 0.4).delay(0.15)) { showSubtitle = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.3)) { showWeekStrip = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.55)) { showNotification = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.75)) { showButton = true }

            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }
}
