import SwiftUI

public struct DSProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let trackColor: Color
    let progressColor: Color
    let size: CGFloat

    public init(
        progress: Double,
        size: CGFloat = 80,
        lineWidth: CGFloat = 6,
        trackColor: Color = .ds_charcoal,
        progressColor: Color = .ds_cyan
    ) {
        self.progress = min(max(progress, 0), 1)
        self.size = size
        self.lineWidth = lineWidth
        self.trackColor = trackColor
        self.progressColor = progressColor
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: progressColor.opacity(0.4), radius: 4)
        }
        .frame(width: size, height: size)
    }
}
