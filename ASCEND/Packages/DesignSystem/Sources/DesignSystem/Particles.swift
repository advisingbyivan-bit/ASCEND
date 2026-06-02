import SwiftUI

public struct DSFloatingParticles: View {
    let particleCount: Int
    let colors: [Color]
    @State private var particles: [Particle] = []
    @Environment(\.scenePhase) private var scenePhase

    public init(count: Int = 30, colors: [Color] = [.ds_purple, .ds_cyan]) {
        self.particleCount = count
        self.colors = colors
    }

    public var body: some View {
        Canvas { context, size in
            for p in particles {
                let rect = CGRect(
                    x: p.position.x - p.size / 2,
                    y: p.position.y - p.size / 2,
                    width: p.size,
                    height: p.size
                )
                context.opacity = p.opacity
                context.fill(Circle().path(in: rect), with: .color(p.color))
            }
        }
        .onAppear {
            let bounds = UIScreen.main.bounds.size
            particles = (0..<particleCount).map { _ in
                Particle.random(in: bounds, colors: colors)
            }
            animateParticles(bounds: bounds)
        }
        .allowsHitTesting(false)
    }

    private func animateParticles(bounds: CGSize) {
        for i in particles.indices {
            let duration = Double.random(in: 8...16)
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                particles[i].position = CGPoint(
                    x: CGFloat.random(in: 0...bounds.width),
                    y: CGFloat.random(in: 0...bounds.height)
                )
                particles[i].opacity = Double.random(in: 0.05...0.2)
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double

    static func random(in bounds: CGSize, colors: [Color]) -> Particle {
        Particle(
            color: colors.randomElement() ?? .ds_purple,
            size: CGFloat.random(in: 2...6),
            position: CGPoint(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: 0...bounds.height)
            ),
            opacity: Double.random(in: 0.05...0.15)
        )
    }
}

public struct DSAmbientBackground: View {
    public init() {}

    public var body: some View {
        ZStack {
            Color.ds_navy.ignoresSafeArea()
            DSFloatingParticles(count: 8, colors: [.ds_purple.opacity(0.6), .ds_cyan.opacity(0.3)])
                .ignoresSafeArea()
        }
    }
}
