import SwiftUI

/// Reusable background for all tabs.
/// Dark navy base + static cyan/purple color washes.
/// Zero animation, zero GPU overhead — just painted once.
public struct DSAnimatedBackground: View {

    public init() {}

    public var body: some View {
        ZStack {
            Color.ds_navy.ignoresSafeArea()

            Canvas { context, size in
                let cx = size.width / 2

                // Cyan wash — upper area
                let o1 = CGPoint(x: cx, y: size.height * 0.2)
                context.drawLayer { ctx in
                    let r: CGFloat = size.width * 0.9
                    let rect = CGRect(x: o1.x - r, y: o1.y - r, width: r * 2, height: r * 2)
                    ctx.fill(
                        Circle().path(in: rect),
                        with: .radialGradient(
                            Gradient(colors: [
                                Color.ds_cyan.opacity(0.13),
                                Color.ds_cyan.opacity(0.05),
                                Color.ds_cyan.opacity(0.01),
                                .clear
                            ]),
                            center: o1,
                            startRadius: 0,
                            endRadius: r
                        )
                    )
                }

                // Purple wash — mid-lower area
                let o2 = CGPoint(x: cx, y: size.height * 0.55)
                context.drawLayer { ctx in
                    let r: CGFloat = size.width * 0.8
                    let rect = CGRect(x: o2.x - r, y: o2.y - r, width: r * 2, height: r * 2)
                    ctx.fill(
                        Circle().path(in: rect),
                        with: .radialGradient(
                            Gradient(colors: [
                                Color.ds_purple.opacity(0.11),
                                Color.ds_purple.opacity(0.04),
                                Color.ds_purple.opacity(0.01),
                                .clear
                            ]),
                            center: o2,
                            startRadius: 0,
                            endRadius: r
                        )
                    )
                }

                // Subtle cyan accent — bottom
                let o3 = CGPoint(x: cx, y: size.height * 0.85)
                context.drawLayer { ctx in
                    let r: CGFloat = size.width * 0.6
                    let rect = CGRect(x: o3.x - r, y: o3.y - r, width: r * 2, height: r * 2)
                    ctx.fill(
                        Circle().path(in: rect),
                        with: .radialGradient(
                            Gradient(colors: [
                                Color.ds_cyan.opacity(0.07),
                                Color.ds_cyan.opacity(0.02),
                                .clear
                            ]),
                            center: o3,
                            startRadius: 0,
                            endRadius: r
                        )
                    )
                }
            }
            .ignoresSafeArea()
        }
    }
}
