import SwiftUI
import DesignSystem

struct Cal04_AffirmationScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var showTitle = false
    @State private var showSubtitle = false
    @State private var showChart = false
    @State private var showButton = false
    @State private var timelineProgress: CGFloat = 0

    var body: some View {
        VStack(spacing: DSSpacing.xl) {
            Spacer()

            VStack(spacing: DSSpacing.sm) {
                Text("You've got this")
                    .font(DSFont.screenTitle)
                    .foregroundStyle(Color.ds_textPrimary)
                    .scaleEffect(showTitle ? 1 : 0.9)
                    .opacity(showTitle ? 1 : 0)

                Text("Consistency in the early weeks matters most")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DSSpacing.md)
                    .offset(y: showSubtitle ? 0 : 10)
                    .opacity(showSubtitle ? 1 : 0)
            }

            // Timeline chart
            CalHeroCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your transformation timeline")
                        .font(DSFont.cardTitle)
                        .foregroundStyle(Color.ds_textPrimary)

                    AffirmationTimeline(progress: timelineProgress)
                        .frame(height: 170)

                    Text("* Lally et al., 2010 — habits take ~66 days to form")
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_textSecondary.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding(.horizontal, DSSpacing.screenPadding)
            .opacity(showChart ? 1 : 0)
            .scaleEffect(showChart ? 1 : 0.95)

            Spacer()

            DSPrimaryButton("Continue", icon: "arrow.right") {
                DSHaptic.medium()
                coordinator.advance()
            }
            .padding(.horizontal, DSSpacing.screenPadding)
            .padding(.bottom, DSSpacing.xl)
            .opacity(showButton ? 1 : 0)
            .scaleEffect(showButton ? 1 : 0.9)
        }
        .onAppear {
            DSHaptic.screenEntry()
            withAnimation(.easeOut(duration: 0.5)) { showTitle = true }
            withAnimation(.easeOut(duration: 0.4).delay(0.2)) { showSubtitle = true }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4)) { showChart = true }
            withAnimation(.easeInOut(duration: 2.0).delay(0.6)) { timelineProgress = 1.0 }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6)) { showButton = true }
        }
    }
}

private struct AffirmationTimeline: View {
    let progress: CGFloat

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let pad: CGFloat = 24
            let drawW = w - 2 * pad
            let drawH = h - 2 * pad

            let points: [(CGFloat, CGFloat)] = [
                (0, 0.9), (0.15, 0.75), (0.35, 0.55), (0.55, 0.38),
                (0.75, 0.22), (0.9, 0.12), (1.0, 0.05)
            ]

            var curvePath = Path()
            for (i, point) in points.enumerated() {
                let x = pad + point.0 * drawW * progress
                let y = pad + point.1 * drawH
                if i == 0 {
                    curvePath.move(to: CGPoint(x: x, y: y))
                } else {
                    let prev = points[i - 1]
                    let prevX = pad + prev.0 * drawW * progress
                    let prevY = pad + prev.1 * drawH
                    let cpX = (prevX + x) / 2
                    curvePath.addCurve(
                        to: CGPoint(x: x, y: y),
                        control1: CGPoint(x: cpX, y: prevY),
                        control2: CGPoint(x: cpX, y: y)
                    )
                }
            }

            if progress > 0.1 {
                var fillPath = curvePath
                let lastX = pad + progress * drawW
                fillPath.addLine(to: CGPoint(x: lastX, y: pad + drawH))
                fillPath.addLine(to: CGPoint(x: pad, y: pad + drawH))
                fillPath.closeSubpath()
                context.fill(fillPath, with: .linearGradient(
                    Gradient(colors: [Color.ds_cyan.opacity(0.2), Color.ds_cyan.opacity(0.02)]),
                    startPoint: CGPoint(x: w / 2, y: pad),
                    endPoint: CGPoint(x: w / 2, y: pad + drawH)
                ))
            }

            context.stroke(curvePath, with: .color(Color.ds_cyan),
                          style: StrokeStyle(lineWidth: 3, lineCap: .round))

            let waypoints: [(CGFloat, CGFloat, String)] = [
                (0.15, 0.75, "3 Days"), (0.5, 0.42, "7 Days"), (0.85, 0.14, "30 Days")
            ]
            for wp in waypoints where progress >= wp.0 {
                let x = pad + wp.0 * drawW
                let y = pad + wp.1 * drawH
                let dotRect = CGRect(x: x - 5, y: y - 5, width: 10, height: 10)
                context.stroke(Circle().path(in: dotRect), with: .color(Color.ds_cyan), lineWidth: 2.5)
                context.fill(Circle().path(in: CGRect(x: x - 3, y: y - 3, width: 6, height: 6)),
                            with: .color(Color.ds_navy))
                context.draw(
                    Text(wp.2).font(.system(size: 11, weight: .semibold)).foregroundColor(Color.ds_textSecondary),
                    at: CGPoint(x: x, y: pad + drawH + 14), anchor: .center
                )
            }

            if progress > 0.95 {
                context.draw(
                    Text("🏆").font(.system(size: 22)),
                    at: CGPoint(x: pad + drawW + 2, y: pad + 0.05 * drawH - 18), anchor: .center
                )
            }
        }
    }
}
