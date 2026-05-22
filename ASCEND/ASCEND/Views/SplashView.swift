import SwiftUI
import DesignSystem
import IRIS

/// Animated splash screen shown on app launch.
/// Features the ASCEND logo with a scale + glow entrance, floating particles, and IRIS sphere.
struct SplashView: View {
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var glowRadius: CGFloat = 0
    @State private var showTagline = false
    @State private var showParticles = false
    @State private var irisScale: CGFloat = 0.3
    @State private var irisOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background
            Color.ds_navy
                .ignoresSafeArea()

            // Floating particles
            if showParticles {
                DSFloatingParticles(count: 8, colors: [Color.ds_purple.opacity(0.3), Color.ds_cyan.opacity(0.15)])
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            // Centered content
            VStack(spacing: 24) {
                Spacer()

                // IRIS sphere (small, above logo)
                IRISSphereView(state: .idle, size: .notification)
                    .scaleEffect(irisScale)
                    .opacity(irisOpacity)

                // Logo
                ZStack {
                    // Glow behind logo
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.ds_cyan.opacity(0.2), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: glowRadius
                            )
                        )
                        .frame(width: 200, height: 200)

                    Image("AscendLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 36)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // Tagline
                if showTagline {
                    Text("YOUR BODY. DIAGNOSED.")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.ds_textSecondary)
                        .tracking(4)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            // Logo entrance
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            // Glow expansion
            withAnimation(.easeOut(duration: 1.2).delay(0.2)) {
                glowRadius = 120
            }

            // IRIS sphere
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                irisScale = 1.0
                irisOpacity = 1.0
            }

            // Particles
            withAnimation(.easeIn(duration: 0.6).delay(0.4)) {
                showParticles = true
            }

            // Tagline
            withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
                showTagline = true
            }
        }
    }
}
