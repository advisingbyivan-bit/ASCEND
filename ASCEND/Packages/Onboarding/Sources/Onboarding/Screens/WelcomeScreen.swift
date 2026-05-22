import SwiftUI
import DesignSystem
import BodyModel3D

struct WelcomeScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var animate = false
    @State private var showLogo = false
    @State private var showTagline = false
    @State private var showButton = false
    @State private var showTerms = false
    @State private var scanLineOffset: CGFloat = -200
    @State private var scanPhase = 0 // 0 = scanning, 1 = zones lit
    @State private var zoneRevealProgress = 0
    @State private var glowPulse = false

    // Zones light up one by one during the "scan" animation
    // Clear color story: green = strong, yellow = alright, red = needs work
    private var animatedZones: [BodyZone: ZoneStatus] {
        let allZones: [(BodyZone, ZoneStatus)] = [
            (.shoulders, .moderate),  // Yellow — alright
            (.chest, .strong),        // Green — solid
            (.arms, .strong),         // Green — jacked
            (.back, .moderate),       // Yellow — alright
            (.core, .weak),           // Red — needs work
            (.abs, .weak),            // Red — needs work
            (.legs, .weak),           // Red — needs work
        ]
        var map: [BodyZone: ZoneStatus] = [:]
        for (i, pair) in allZones.enumerated() {
            map[pair.0] = i < zoneRevealProgress ? pair.1 : .base
        }
        return map
    }

    var body: some View {
        ZStack {
            Color.ds_navy.ignoresSafeArea()

            // Ambient particles
            DSFloatingParticles(count: 20, colors: [
                Color.ds_purple.opacity(0.5),
                Color.ds_cyan.opacity(0.3)
            ])
            .ignoresSafeArea()
            .opacity(animate ? 1 : 0)

            VStack(spacing: 0) {
                Spacer()

                // Hero: 3D body model with scanning effect
                ZStack {
                    // Glow behind the model
                    Ellipse()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color.ds_cyan.opacity(glowPulse ? 0.25 : 0.1),
                                    Color.ds_purple.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 160
                            )
                        )
                        .frame(width: 320, height: 320)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: glowPulse)

                    // The 3D body model — zones animate in
                    BodyModelView(
                        gender: .male,
                        zones: animatedZones,
                        interactive: false,
                        size: .dashboard
                    )
                    .frame(height: 280)
                    .scaleEffect(animate ? 1 : 0.6)
                    .opacity(animate ? 1 : 0)

                    // Scanning line effect
                    if scanPhase == 0 {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.clear, Color.ds_cyan.opacity(0.6), Color.ds_cyan, Color.ds_cyan.opacity(0.6), Color.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 200, height: 2)
                            .shadow(color: Color.ds_cyan.opacity(0.8), radius: 8, x: 0, y: 0)
                            .offset(y: scanLineOffset)
                    }
                }
                .frame(height: 300)

                // Text section
                VStack(spacing: DSSpacing.sm) {
                    // Brand logo
                    Image("AscendLogo", bundle: .main)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 44)
                        .scaleEffect(showLogo ? 1 : 0.7)
                        .opacity(showLogo ? 1 : 0)

                    // Value prop tagline — tells you exactly what the app does
                    Text("AI-Powered Body Scanner")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.ds_textPrimary)
                        .offset(y: showTagline ? 0 : 15)
                        .opacity(showTagline ? 1 : 0)

                    Text("Scan · Diagnose · Transform")
                        .font(DSFont.caption)
                        .foregroundStyle(Color.ds_cyan)
                        .tracking(1.5)
                        .offset(y: showTagline ? 0 : 10)
                        .opacity(showTagline ? 0.8 : 0)

                    Text("30 seconds. 3 angles. Your full body diagnosis.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.ds_textSecondary.opacity(0.5))
                        .offset(y: showTagline ? 0 : 8)
                        .opacity(showTagline ? 1 : 0)
                }
                .padding(.top, DSSpacing.md)

                Spacer()

                // CTA
                VStack(spacing: DSSpacing.sm) {
                    DSPrimaryButton("Get Started", icon: "arrow.right") {
                        DSHaptic.medium()
                        coordinator.advance()
                    }
                    .scaleEffect(showButton ? 1 : 0.9)
                    .opacity(showButton ? 1 : 0)

                    Text("By continuing, you agree to our Terms & Privacy Policy")
                        .font(DSFont.micro)
                        .foregroundStyle(Color.ds_textSecondary.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .opacity(showTerms ? 1 : 0)
                }
                .padding(.horizontal, DSSpacing.screenPadding)
                .padding(.bottom, DSSpacing.xl)
            }
        }
        .onAppear {
            startEntrySequence()
        }
    }

    private func startEntrySequence() {
        DSHaptic.screenEntry()

        // 1. Body model scales in
        withAnimation(.spring(response: 0.9, dampingFraction: 0.7)) {
            animate = true
        }
        glowPulse = true

        // 2. Scan line sweeps down the body (repeats twice)
        startScanLineAnimation()

        // 3. Logo fades in
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            showLogo = true
        }

        // 4. Tagline slides up
        withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
            showTagline = true
        }

        // 5. Zones light up one by one (after first scan line pass)
        for i in 1...7 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2 + Double(i) * 0.25) {
                withAnimation(.easeOut(duration: 0.3)) {
                    zoneRevealProgress = i
                }
                DSHaptic.light()
            }
        }

        // 6. Stop scan line after zones are revealed
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                scanPhase = 1
            }
        }

        // 7. CTA appears
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.3)) {
            showButton = true
        }

        withAnimation(.easeIn(duration: 0.4).delay(1.5)) {
            showTerms = true
        }

        // Haptic punctuation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            DSHaptic.light()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            DSHaptic.ctaReady()
        }
    }

    private func startScanLineAnimation() {
        scanLineOffset = -140
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            scanLineOffset = 140
        }
    }
}
