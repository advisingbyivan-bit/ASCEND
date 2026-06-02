import ActivityKit
import SwiftUI
import WidgetKit
import Gamification

/// The Live Activity widget — Lock Screen + Dynamic Island.
/// Full dashboard mini with simulated liquid glass treatment,
/// streak-tier color shifts, and mini week engagement dots.
struct ASCENDLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ASCENDActivityAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            let tierColor = streakTierColor(context.state.currentStreak)

            return DynamicIsland {
                // ── Expanded Dynamic Island ──

                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(tierColor)
                            Text("\(context.state.currentStreak)")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        Text("day streak")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .padding(.leading, 2)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("\(Int(context.state.overallScore))")
                            .font(.system(size: 28, weight: .black, design: .rounded))
                            .foregroundStyle(scoreColor(context.state.overallScore))
                        Text("IRIS score")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.45))
                    }
                    .padding(.trailing, 2)
                }

                DynamicIslandExpandedRegion(.center) {
                    ZStack {
                        Circle()
                            .stroke(tierColor.opacity(0.3), lineWidth: 1.5)
                            .frame(width: 32, height: 32)

                        IRISOrbCanvas(size: 24)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 0) {
                        if context.state.streakAtRisk {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 10, weight: .bold))
                                Text("Check in to save your streak!")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundStyle(.orange)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "diamond.fill")
                                    .font(.system(size: 9))
                                    .foregroundStyle(tierColor)
                                if context.state.daysUntilMilestone > 0 {
                                    Text("\(context.state.daysUntilMilestone)d to Day \(context.state.nextMilestone)")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.6))
                                } else {
                                    Text("Diamond day!")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.cyan)
                                }
                            }
                        }

                        Spacer()

                        weekDotsView(
                            engagement: context.state.weekEngagement,
                            tierColor: tierColor,
                            dotSize: 5
                        )
                    }
                    .padding(.horizontal, 4)
                    .padding(.bottom, 2)
                }

            } compactLeading: {
                // IRIS orb + streak number
                HStack(spacing: 4) {
                    IRISOrbCanvas(size: 16)
                    Text("\(context.state.currentStreak)")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundStyle(context.state.streakAtRisk ? .orange : .white)
                }
            } compactTrailing: {
                // Score with tiny progress ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1.5)
                        .frame(width: 22, height: 22)

                    Circle()
                        .trim(from: 0, to: context.state.overallScore / 100)
                        .stroke(
                            scoreColor(context.state.overallScore),
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                        )
                        .frame(width: 22, height: 22)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(context.state.overallScore))")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(.white)
                }
            } minimal: {
                // When sharing Dynamic Island with music:
                // Leading (bigger pill) → orb + streak + score
                // Trailing (smaller pill) → Apple clips to fit
                ZStack {
                    HStack(spacing: 2) {
                        IRISOrbCanvas(size: 14)
                        Text("\(context.state.currentStreak)")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(tierColor)
                    }
                }
            }
        }
    }

    // MARK: - Lock Screen View

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<ASCENDActivityAttributes>) -> some View {
        let streak = context.state.currentStreak
        let score = context.state.overallScore
        let tierColor = streakTierColor(streak)
        let todayWeekday = Calendar.current.component(.weekday, from: Date()) - 1

        ZStack {
            // ── Glass background ──
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.06, green: 0.07, blue: 0.16), location: 0),
                    .init(color: Color(red: 0.07, green: 0.09, blue: 0.20), location: 0.5),
                    .init(color: Color(red: 0.06, green: 0.07, blue: 0.16), location: 1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Top specular highlight
            VStack {
                LinearGradient(
                    colors: [Color.white.opacity(0.06), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 35)
                Spacer()
            }

            // Ambient tier color wash
            RadialGradient(
                colors: [tierColor.opacity(0.06), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 200
            )

            // ── Content ──
            VStack(spacing: 0) {
                // Top row: Streak | IRIS Orb | Score Ring
                HStack(spacing: 0) {
                    // ── Streak (left) ──
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 5) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(tierColor)
                                .shadow(color: tierColor.opacity(0.5), radius: 3)
                            Text("\(streak)")
                                .font(.system(size: 34, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        Text("day streak")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // ── IRIS Orb (center) — zoomed + glow ring ──
                    VStack(spacing: 3) {
                        ZStack {
                            // Outer glow ring in tier color
                            Circle()
                                .stroke(tierColor.opacity(0.25), lineWidth: 1.5)
                                .frame(width: 48, height: 48)
                                .shadow(color: tierColor.opacity(0.2), radius: 4)

                            IRISOrbCanvas(size: 38)
                        }

                        Text("ASCEND")
                            .font(.system(size: 7, weight: .heavy, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(.cyan.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)

                    // ── Score Ring (right) ──
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.06), lineWidth: 3.5)
                            .frame(width: 50, height: 50)

                        Circle()
                            .trim(from: 0, to: score / 100)
                            .stroke(
                                scoreColor(score),
                                style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                            )
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: scoreColor(score).opacity(0.4), radius: 3)

                        VStack(spacing: -1) {
                            Text("\(Int(score))")
                                .font(.system(size: 18, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                            Text("score")
                                .font(.system(size: 7, weight: .medium))
                                .foregroundStyle(.white.opacity(0.35))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Spacer().frame(height: 10)

                // ── Glass divider ──
                Rectangle()
                    .fill(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.0), location: 0),
                                .init(color: Color.white.opacity(0.10), location: 0.3),
                                .init(color: tierColor.opacity(0.12), location: 0.7),
                                .init(color: Color.white.opacity(0.0), location: 1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 0.5)

                Spacer().frame(height: 8)

                // ── Bottom row: Milestone + Week Dots ──
                HStack {
                    if context.state.streakAtRisk {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text("Check in today!")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(.orange)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "diamond.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(tierColor)
                                .shadow(color: tierColor.opacity(0.4), radius: 2)

                            if context.state.daysUntilMilestone > 0 {
                                Text("\(context.state.daysUntilMilestone)d to Day \(context.state.nextMilestone)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.55))
                            } else {
                                Text("Diamond day!")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.cyan)
                            }
                        }
                    }

                    Spacer()

                    weekDotsView(
                        engagement: context.state.weekEngagement,
                        tierColor: tierColor,
                        dotSize: 6,
                        todayIndex: todayWeekday
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        // Glass border
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.16), location: 0),
                            .init(color: Color.white.opacity(0.05), location: 0.3),
                            .init(color: tierColor.opacity(0.06), location: 0.7),
                            .init(color: tierColor.opacity(0.10), location: 1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        )
        .activityBackgroundTint(Color.clear)
    }

    // MARK: - Mini Week Dots

    @ViewBuilder
    private func weekDotsView(
        engagement: [Bool],
        tierColor: Color,
        dotSize: CGFloat,
        todayIndex: Int = -1
    ) -> some View {
        HStack(spacing: 3) {
            ForEach(0..<7, id: \.self) { i in
                let engaged = i < engagement.count ? engagement[i] : false
                let isToday = i == todayIndex

                ZStack {
                    if engaged {
                        Circle()
                            .fill(tierColor)
                            .frame(width: dotSize, height: dotSize)
                    } else if isToday {
                        Circle()
                            .stroke(tierColor.opacity(0.6), lineWidth: 1)
                            .frame(width: dotSize, height: dotSize)
                    } else {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: dotSize, height: dotSize)
                    }
                }
            }
        }
    }

    // MARK: - Streak Tier Colors

    private func streakTierColor(_ streak: Int) -> Color {
        switch streak {
        case 42...:   return .cyan
        case 21..<42: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 7..<21:  return Color(red: 1.0, green: 0.75, blue: 0.3)
        case 1..<7:   return .white
        default:      return .white.opacity(0.5)
        }
    }

    // MARK: - Score Color

    private func scoreColor(_ score: Double) -> Color {
        switch score {
        case 80...:   return .green
        case 60..<80: return .cyan
        case 40..<60: return .yellow
        default:      return .orange
        }
    }
}
