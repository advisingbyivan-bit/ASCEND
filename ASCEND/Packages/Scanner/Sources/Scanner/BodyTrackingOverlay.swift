import SwiftUI
import DesignSystem

/// Face ID-style body scanner frame.
/// Full-screen rectangular frame with corner brackets and tick marks
/// along all four edges. Ticks light up in a domino cascade —
/// sweeping along one edge, jumping to another, filling organically.
struct BodyTrackingOverlay: View {
    let progress: CGFloat          // 0–1 (locked joints / total)

    // ── Tick Configuration ──
    private static let ticksPerLongSide = 40     // left/right edges
    private static let ticksPerShortSide = 24    // top/bottom edges
    static let totalTicks = (ticksPerLongSide * 2) + (ticksPerShortSide * 2) // 128

    /// How many ticks should be filled based on scan progress.
    private var filledCount: Int {
        min(Self.totalTicks, Int(round(progress * CGFloat(Self.totalTicks))))
    }

    // ── Domino fill order ──
    // Sweeps clockwise: top→right→bottom→left, but in staggered bursts
    // so it looks like it starts on one edge, pauses, picks up on another.
    private static let fillOrder: [Int] = {
        let L = ticksPerLongSide
        let S = ticksPerShortSide
        // Layout: top 0..<S, right S..<S+L, bottom S+L..<2S+L, left 2S+L..<2S+2L

        var order: [Int] = []

        // Sweep 1: Top edge left→right
        for i in 0..<S { order.append(i) }
        // Sweep 2: Right edge top→bottom
        for i in 0..<L { order.append(S + i) }
        // Sweep 3: Bottom edge right→left
        for i in stride(from: S + L + S - 1, through: S + L, by: -1) { order.append(i) }
        // Sweep 4: Left edge bottom→top
        for i in stride(from: 2*S + 2*L - 1, through: 2*S + L, by: -1) { order.append(i) }

        // Ensure all ticks are covered
        var seen = Set(order)
        for i in 0..<totalTicks where !seen.contains(i) {
            order.append(i)
            seen.insert(i)
        }
        return order
    }()

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            // Frame rect: generous margin so ticks + corners don't crowd content
            let hInset: CGFloat = 20
            let topInset: CGFloat = 100  // clear of status bar + angle pill
            let bottomInset: CGFloat = 160 // clear of bottom HUD
            let rect = CGRect(
                x: hInset,
                y: topInset,
                width: size.width - hInset * 2,
                height: size.height - topInset - bottomInset
            )
            let cornerLen: CGFloat = 36
            // Ticks start inset from corners so they don't overlap
            let tickInset: CGFloat = cornerLen + 8

            ZStack {
                // Corner brackets
                Canvas { context, _ in
                    drawCornerBrackets(context: &context, rect: rect, cornerLen: cornerLen)
                }

                // Tick marks along edges (inset from corners)
                Canvas { context, _ in
                    let filledSet = Self.filledSet(count: filledCount)
                    drawEdgeTicks(context: &context, rect: rect, tickInset: tickInset, filledSet: filledSet)
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Corner Brackets

    private func drawCornerBrackets(
        context: inout GraphicsContext,
        rect: CGRect,
        cornerLen: CGFloat
    ) {
        let color = Color.ds_cyan
        let style = StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        let glowStyle = StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)

        let corners: [(CGPoint, CGPoint, CGPoint)] = [
            // Top-left
            (CGPoint(x: rect.minX, y: rect.minY + cornerLen),
             CGPoint(x: rect.minX, y: rect.minY),
             CGPoint(x: rect.minX + cornerLen, y: rect.minY)),
            // Top-right
            (CGPoint(x: rect.maxX - cornerLen, y: rect.minY),
             CGPoint(x: rect.maxX, y: rect.minY),
             CGPoint(x: rect.maxX, y: rect.minY + cornerLen)),
            // Bottom-left
            (CGPoint(x: rect.minX, y: rect.maxY - cornerLen),
             CGPoint(x: rect.minX, y: rect.maxY),
             CGPoint(x: rect.minX + cornerLen, y: rect.maxY)),
            // Bottom-right
            (CGPoint(x: rect.maxX - cornerLen, y: rect.maxY),
             CGPoint(x: rect.maxX, y: rect.maxY),
             CGPoint(x: rect.maxX, y: rect.maxY - cornerLen)),
        ]

        for (start, corner, end) in corners {
            var path = Path()
            path.move(to: start)
            path.addLine(to: corner)
            path.addLine(to: end)

            // Glow
            context.stroke(path, with: .color(color.opacity(0.12)), style: glowStyle)
            // Core
            context.stroke(path, with: .color(color.opacity(0.85)), style: style)
        }
    }

    // MARK: - Edge Ticks

    private func drawEdgeTicks(
        context: inout GraphicsContext,
        rect: CGRect,
        tickInset: CGFloat,
        filledSet: Set<Int>
    ) {
        let L = Self.ticksPerLongSide
        let S = Self.ticksPerShortSide

        // Top edge — ticks point inward (down), spaced between corner brackets
        let topStart = rect.minX + tickInset
        let topEnd = rect.maxX - tickInset
        let topSpan = topEnd - topStart
        for i in 0..<S {
            let t = CGFloat(i) / CGFloat(S - 1)
            let x = topStart + t * topSpan
            drawTick(context: &context, x: x, y: rect.minY, dirX: 0, dirY: 1, filled: filledSet.contains(i))
        }

        // Right edge — ticks point inward (left)
        let rightStart = rect.minY + tickInset
        let rightEnd = rect.maxY - tickInset
        let rightSpan = rightEnd - rightStart
        for i in 0..<L {
            let t = CGFloat(i) / CGFloat(L - 1)
            let y = rightStart + t * rightSpan
            drawTick(context: &context, x: rect.maxX, y: y, dirX: -1, dirY: 0, filled: filledSet.contains(S + i))
        }

        // Bottom edge — ticks point inward (up)
        for i in 0..<S {
            let t = CGFloat(i) / CGFloat(S - 1)
            let x = topStart + t * topSpan
            drawTick(context: &context, x: x, y: rect.maxY, dirX: 0, dirY: -1, filled: filledSet.contains(S + L + i))
        }

        // Left edge — ticks point inward (right)
        for i in 0..<L {
            let t = CGFloat(i) / CGFloat(L - 1)
            let y = rightStart + t * rightSpan
            drawTick(context: &context, x: rect.minX, y: y, dirX: 1, dirY: 0, filled: filledSet.contains(S + L + S + i))
        }
    }

    // MARK: - Single Tick

    private func drawTick(
        context: inout GraphicsContext,
        x: CGFloat, y: CGFloat,
        dirX: CGFloat, dirY: CGFloat,
        filled: Bool
    ) {
        let length: CGFloat = filled ? 14 : 7
        let width: CGFloat = filled ? 1.6 : 0.8
        let opacity: Double = filled ? 0.95 : 0.18

        let color: Color = filled
            ? Color(red: 0.1, green: 1.0, blue: 0.4)
            : .white

        let start = CGPoint(x: x, y: y)
        let end = CGPoint(x: x + dirX * length, y: y + dirY * length)

        var path = Path()
        path.move(to: start)
        path.addLine(to: end)

        // Glow behind filled ticks
        if filled {
            context.stroke(path,
                           with: .color(color.opacity(0.25)),
                           style: StrokeStyle(lineWidth: width + 4, lineCap: .round))
        }

        // Core tick
        context.stroke(path,
                       with: .color(color.opacity(opacity)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    // MARK: - Fill-order helper

    static func filledSet(count: Int) -> Set<Int> {
        var s = Set<Int>()
        for i in 0..<min(count, fillOrder.count) {
            s.insert(fillOrder[i])
        }
        return s
    }
}
