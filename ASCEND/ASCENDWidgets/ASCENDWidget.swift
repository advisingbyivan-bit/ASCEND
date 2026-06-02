import SwiftUI
import WidgetKit
import Gamification

// MARK: - Timeline Provider

struct ASCENDTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> ASCENDWidgetEntry {
        ASCENDWidgetEntry(
            date: Date(),
            streak: 7,
            score: 72,
            totalScans: 3,
            weekEngagement: [true, true, false, true, true, false, false],
            nextMilestone: 21,
            daysUntilMilestone: 14,
            streakAtRisk: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (ASCENDWidgetEntry) -> Void) {
        completion(currentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ASCENDWidgetEntry>) -> Void) {
        let entry = currentEntry()
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func currentEntry() -> ASCENDWidgetEntry {
        ASCENDWidgetEntry(
            date: Date(),
            streak: WidgetDataStore.streak,
            score: WidgetDataStore.score,
            totalScans: WidgetDataStore.totalScans,
            weekEngagement: WidgetDataStore.weekEngagement,
            nextMilestone: WidgetDataStore.nextMilestone,
            daysUntilMilestone: WidgetDataStore.daysUntilMilestone,
            streakAtRisk: WidgetDataStore.streakAtRisk
        )
    }
}

// MARK: - Entry

struct ASCENDWidgetEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let score: Double
    let totalScans: Int
    let weekEngagement: [Bool]
    let nextMilestone: Int
    let daysUntilMilestone: Int
    let streakAtRisk: Bool
}

// MARK: - Widget

struct ASCENDWidget: Widget {
    let kind = "ASCENDWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ASCENDTimelineProvider()) { entry in
            ASCENDWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("ASCEND")
        .description("Track your streak, score, and weekly consistency.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Entry View (routes to size-specific view)

struct ASCENDWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: ASCENDWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (IRIS Orb + Streak)

struct SmallWidgetView: View {
    let entry: ASCENDWidgetEntry

    private var tierColor: Color { streakTierColor(entry.streak) }

    var body: some View {
        VStack(spacing: 6) {
            // IRIS orb
            IRISOrbCanvas(size: 52)

            // Streak
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(tierColor)
                Text("\(entry.streak)")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }

            Text("day streak")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
        }
        .containerBackground(for: .widget) {
            glassBackground(tierColor: tierColor)
        }
    }
}

// MARK: - Medium Widget (Full Stats Dashboard)

struct MediumWidgetView: View {
    let entry: ASCENDWidgetEntry

    private var tierColor: Color { streakTierColor(entry.streak) }
    private var todayIndex: Int { Calendar.current.component(.weekday, from: Date()) - 1 }

    var body: some View {
        VStack(spacing: 0) {
            // Top row: Streak | Orb | Score Ring
            HStack(spacing: 0) {
                // Streak
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(tierColor)
                            .shadow(color: tierColor.opacity(0.4), radius: 2)
                        Text("\(entry.streak)")
                            .font(.system(size: 30, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    Text("day streak")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // IRIS orb with glow ring
                ZStack {
                    Circle()
                        .stroke(tierColor.opacity(0.2), lineWidth: 1)
                        .frame(width: 42, height: 42)

                    IRISOrbCanvas(size: 34)
                }
                .frame(maxWidth: .infinity)

                // Score ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.06), lineWidth: 3)
                        .frame(width: 44, height: 44)

                    Circle()
                        .trim(from: 0, to: entry.score / 100)
                        .stroke(
                            scoreColor(entry.score),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: scoreColor(entry.score).opacity(0.3), radius: 2)

                    VStack(spacing: -1) {
                        Text("\(Int(entry.score))")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(.white)
                        Text("score")
                            .font(.system(size: 6, weight: .medium))
                            .foregroundStyle(.white.opacity(0.35))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Spacer().frame(height: 8)

            // Glass divider
            Rectangle()
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.0), location: 0),
                            .init(color: Color.white.opacity(0.08), location: 0.3),
                            .init(color: tierColor.opacity(0.10), location: 0.7),
                            .init(color: Color.white.opacity(0.0), location: 1)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)

            Spacer().frame(height: 8)

            // Bottom row: Scans + Milestone + Week Dots
            HStack {
                // Scans count
                HStack(spacing: 3) {
                    Image(systemName: "viewfinder")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.cyan.opacity(0.7))
                    Text("\(entry.totalScans) scans")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                }

                // Divider dot
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 3, height: 3)

                // Milestone
                if entry.streakAtRisk {
                    HStack(spacing: 3) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text("At risk!")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(.orange)
                } else if entry.daysUntilMilestone > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "diamond.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(tierColor)
                        Text("\(entry.daysUntilMilestone)d")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer()

                // Week dots
                HStack(spacing: 3) {
                    ForEach(0..<7, id: \.self) { i in
                        let engaged = i < entry.weekEngagement.count ? entry.weekEngagement[i] : false
                        let isToday = i == todayIndex

                        if engaged {
                            Circle()
                                .fill(tierColor)
                                .frame(width: 6, height: 6)
                        } else if isToday {
                            Circle()
                                .stroke(tierColor.opacity(0.5), lineWidth: 1)
                                .frame(width: 6, height: 6)
                        } else {
                            Circle()
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 6, height: 6)
                        }
                    }
                }
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            glassBackground(tierColor: tierColor)
        }
    }
}

// MARK: - IRIS Orb (Canvas-drawn with sparkles)

struct IRISOrbCanvas: View {
    let size: CGFloat

    var body: some View {
        Canvas { context, canvasSize in
            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let r = min(canvasSize.width, canvasSize.height) / 2

            // Outer glow
            context.fill(
                Circle().path(in: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(red: 0.0, green: 0.6, blue: 0.9).opacity(0.30),
                        Color(red: 0.0, green: 0.5, blue: 0.8).opacity(0.12),
                        Color(red: 0.0, green: 0.4, blue: 0.7).opacity(0.04),
                        Color.clear
                    ]),
                    center: center,
                    startRadius: r * 0.1,
                    endRadius: r
                )
            )

            // Bright core
            let coreCenter = CGPoint(x: center.x - r * 0.05, y: center.y - r * 0.08)
            let coreR = r * 0.65
            context.fill(
                Circle().path(in: CGRect(x: coreCenter.x - coreR, y: coreCenter.y - coreR, width: coreR * 2, height: coreR * 2)),
                with: .radialGradient(
                    Gradient(colors: [
                        Color.white.opacity(0.95),
                        Color(red: 0.4, green: 0.85, blue: 1.0).opacity(0.85),
                        Color(red: 0.0, green: 0.65, blue: 0.95).opacity(0.50),
                        Color(red: 0.0, green: 0.5, blue: 0.85).opacity(0.15),
                        Color.clear
                    ]),
                    center: coreCenter,
                    startRadius: 0,
                    endRadius: coreR
                )
            )

            // Sparkles
            let sparkles: [(x: CGFloat, y: CGFloat, b: CGFloat, s: CGFloat)] = [
                (0.38, 0.28, 1.0, 1.0), (0.62, 0.35, 0.9, 0.8), (0.30, 0.52, 0.8, 0.7),
                (0.22, 0.35, 0.7, 0.6), (0.72, 0.50, 0.7, 0.6), (0.50, 0.68, 0.6, 0.6),
                (0.28, 0.70, 0.6, 0.5), (0.68, 0.65, 0.5, 0.5), (0.45, 0.18, 0.6, 0.5),
                (0.15, 0.50, 0.4, 0.4), (0.82, 0.42, 0.4, 0.4), (0.55, 0.80, 0.3, 0.4),
                (0.20, 0.22, 0.3, 0.35), (0.75, 0.25, 0.35, 0.35), (0.40, 0.78, 0.3, 0.3),
                (0.80, 0.60, 0.25, 0.3), (0.18, 0.62, 0.25, 0.3),
            ]

            for sp in sparkles {
                let pos = CGPoint(x: canvasSize.width * sp.x, y: canvasSize.height * sp.y)
                let sSize = r * 0.08 * sp.s

                // Glow
                let glowR = sSize * 3
                context.fill(
                    Circle().path(in: CGRect(x: pos.x - glowR, y: pos.y - glowR, width: glowR * 2, height: glowR * 2)),
                    with: .radialGradient(
                        Gradient(colors: [Color.white.opacity(sp.b * 0.6), Color.cyan.opacity(sp.b * 0.2), .clear]),
                        center: pos, startRadius: 0, endRadius: glowR
                    )
                )
                // Core dot
                context.fill(
                    Circle().path(in: CGRect(x: pos.x - sSize, y: pos.y - sSize, width: sSize * 2, height: sSize * 2)),
                    with: .color(Color.white.opacity(sp.b * 0.9))
                )
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Shared Glass Background

@ViewBuilder
func glassBackground(tierColor: Color) -> some View {
    ZStack {
        // Navy base
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
            .frame(height: 40)
            Spacer()
        }

        // Ambient tier wash
        RadialGradient(
            colors: [tierColor.opacity(0.06), Color.clear],
            center: .topLeading,
            startRadius: 0,
            endRadius: 200
        )
    }
}

// MARK: - Shared Helpers

func streakTierColor(_ streak: Int) -> Color {
    switch streak {
    case 42...:   return .cyan
    case 21..<42: return Color(red: 1.0, green: 0.84, blue: 0.0)
    case 7..<21:  return Color(red: 1.0, green: 0.75, blue: 0.3)
    case 1..<7:   return .white
    default:      return .white.opacity(0.5)
    }
}

func scoreColor(_ score: Double) -> Color {
    switch score {
    case 80...:   return .green
    case 60..<80: return .cyan
    case 40..<60: return .yellow
    default:      return .orange
    }
}
