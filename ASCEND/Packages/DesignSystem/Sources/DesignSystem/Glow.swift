import SwiftUI

public struct DSGlow: ViewModifier {
    let color: Color
    let radius: CGFloat
    let intensity: CGFloat

    public init(color: Color = .ds_cyan, radius: CGFloat = 12, intensity: CGFloat = 0.6) {
        self.color = color
        self.radius = radius
        self.intensity = intensity
    }

    public func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(intensity * 0.8), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(intensity * 0.4), radius: radius * 2, x: 0, y: 0)
    }
}

public extension View {
    func dsGlow(color: Color = .ds_cyan, radius: CGFloat = 12, intensity: CGFloat = 0.6) -> some View {
        modifier(DSGlow(color: color, radius: radius, intensity: intensity))
    }
}

public struct DSPulsingGlow: ViewModifier {
    let color: Color
    let radius: CGFloat
    @State private var glowing = false

    public init(color: Color = .ds_cyan, radius: CGFloat = 12) {
        self.color = color
        self.radius = radius
    }

    public func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(glowing ? 0.6 : 0.2), radius: glowing ? radius : radius * 0.5)
            .shadow(color: color.opacity(glowing ? 0.3 : 0.1), radius: glowing ? radius * 2 : radius)
            .onAppear {
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    glowing = true
                }
            }
    }
}

public extension View {
    func dsPulsingGlow(color: Color = .ds_cyan, radius: CGFloat = 12) -> some View {
        modifier(DSPulsingGlow(color: color, radius: radius))
    }
}
