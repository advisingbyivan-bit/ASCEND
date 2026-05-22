import SwiftUI
import DesignSystem

struct IRISIntroScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var showFace = false
    @State private var showMessage = false
    @State private var showButton = false
    @State private var isSpeaking = false
    @State private var glowIntensity = false
    @State private var particlePhase: Double = 0

    var body: some View {
        ZStack {
            // Dark vignette overlay for drama
            RadialGradient(
                colors: [Color.clear, Color.ds_navy.opacity(0.7)],
                center: .center,
                startRadius: 80,
                endRadius: 400
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 0) {
                Spacer()

                // IRIS particle face
                ZStack {
                    // Background glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.ds_cyan.opacity(glowIntensity ? 0.25 : 0.1), Color.clear],
                                center: .center,
                                startRadius: 20,
                                endRadius: 180
                            )
                        )
                        .frame(width: 360, height: 360)

                    // Particle face
                    IRISParticleFace(
                        isVisible: showFace,
                        isSpeaking: isSpeaking,
                        phase: particlePhase
                    )
                    .frame(width: 220, height: 280)
                }
                .opacity(showFace ? 1 : 0)
                .scaleEffect(showFace ? 1 : 0.3)

                Spacer().frame(height: DSSpacing.xl)

                if showMessage {
                    DSTypewriterText(
                        "I see you. Yeah, you \u{2014} the one who's been using those arms to scroll instead of lift. The one making excuses while eating garbage on the couch. That stops now. I'm IRIS. I don't care about your feelings. I care about your results. You wanted change? Prove it.",
                        charDelay: .milliseconds(30)
                    ) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                            showButton = true
                        }
                        isSpeaking = false
                        DSHaptic.ctaReady()
                    }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.ds_textPrimary.opacity(0.9))
                    .lineSpacing(4)
                    .padding(.horizontal, DSSpacing.screenPadding + 4)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()

                if showButton {
                    DSPrimaryButton("Prove It", icon: "bolt.fill") {
                        DSHaptic.heavy()
                        coordinator.advance()
                    }
                    .padding(.horizontal, DSSpacing.screenPadding)
                    .padding(.bottom, DSSpacing.xl)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onAppear {
            DSHaptic.irisAwaken()

            withAnimation(.spring(response: 1.2, dampingFraction: 0.6)) {
                showFace = true
            }

            // Glow pulse
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.5)) {
                glowIntensity = true
            }

            // Particle drift animation
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                particlePhase = .pi * 2
            }

            // Phase 2: IRIS starts speaking
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                isSpeaking = true
                withAnimation(.easeIn(duration: 0.4)) {
                    showMessage = true
                }
            }
        }
    }
}

// MARK: - IRIS Waveform Visualizer

private struct IRISParticleFace: View {
    let isVisible: Bool
    let isSpeaking: Bool
    let phase: Double

    private let barCount = 80

    var body: some View {
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let s = min(size.width, size.height) / 260

                let innerR: CGFloat = 32 * s
                let mainR: CGFloat = 52 * s
                let maxBar: CGFloat = 38 * s
                let outerR: CGFloat = 98 * s

                // ===== Background glow =====
                for glowR in [outerR * 1.3, outerR, mainR * 1.5] {
                    let alpha = 0.04 - (glowR / (outerR * 3))
                    let gr = CGRect(x: center.x - glowR, y: center.y - glowR,
                                    width: glowR * 2, height: glowR * 2)
                    context.fill(Circle().path(in: gr),
                                 with: .color(Color.ds_cyan.opacity(max(0.01, alpha))))
                }

                // ===== Outer ring (subtle, breathing) =====
                let outerPulse = sin(time * 1.5) * 0.03 + 0.1
                let orRect = CGRect(x: center.x - outerR, y: center.y - outerR,
                                    width: outerR * 2, height: outerR * 2)
                context.stroke(Circle().path(in: orRect),
                               with: .color(Color.ds_cyan.opacity(outerPulse)),
                               lineWidth: 0.8 * s)

                // Second outer ring (offset phase)
                let outerR2 = outerR * 1.08
                let outerPulse2 = sin(time * 1.2 + 1.5) * 0.02 + 0.05
                let or2Rect = CGRect(x: center.x - outerR2, y: center.y - outerR2,
                                     width: outerR2 * 2, height: outerR2 * 2)
                context.stroke(Circle().path(in: or2Rect),
                               with: .color(Color.ds_cyan.opacity(outerPulse2)),
                               lineWidth: 0.5 * s)

                // ===== Core circle =====
                let corePulse = sin(time * 3) * 2.5 * s
                let coreSize = (isSpeaking ? 14 : 10) * s + corePulse
                // Core glow
                let coreGlowSize = coreSize * 3
                let cgr = CGRect(x: center.x - coreGlowSize / 2, y: center.y - coreGlowSize / 2,
                                 width: coreGlowSize, height: coreGlowSize)
                context.fill(Circle().path(in: cgr),
                             with: .color(Color.ds_cyan.opacity(isSpeaking ? 0.12 : 0.06)))
                // Core solid
                let cr = CGRect(x: center.x - coreSize / 2, y: center.y - coreSize / 2,
                                width: coreSize, height: coreSize)
                context.fill(Circle().path(in: cr),
                             with: .color(Color.ds_cyan.opacity(isSpeaking ? 0.75 : 0.5)))

                // ===== Inner ring bars (subtle layer) =====
                for i in 0..<barCount {
                    let angle = CGFloat(i) / CGFloat(barCount) * .pi * 2 - .pi / 2

                    let innerH: CGFloat
                    if isSpeaking {
                        let w1 = sin(CGFloat(i) * 0.4 + time * 5.2) * 0.45
                        let w2 = cos(CGFloat(i) * 0.9 + time * 3.8) * 0.35
                        innerH = 10 * s * max(0.08, (w1 + w2 + 1) / 2)
                    } else {
                        let breath = sin(time * 1.2 + CGFloat(i) * 0.1) * 0.2 + 0.3
                        innerH = 6 * s * breath
                    }

                    let ix = center.x + cos(angle) * innerR
                    let iy = center.y + sin(angle) * innerR
                    let ox = center.x + cos(angle) * (innerR + innerH)
                    let oy = center.y + sin(angle) * (innerR + innerH)

                    var bp = Path()
                    bp.move(to: CGPoint(x: ix, y: iy))
                    bp.addLine(to: CGPoint(x: ox, y: oy))

                    let intensity = innerH / (10 * s)
                    context.stroke(bp,
                                   with: .color(Color.ds_cyan.opacity(0.12 + intensity * 0.18)),
                                   style: StrokeStyle(lineWidth: 1.5 * s, lineCap: .round))
                }

                // ===== Main ring bars (showpiece) =====
                for i in 0..<barCount {
                    let angle = CGFloat(i) / CGFloat(barCount) * .pi * 2 - .pi / 2

                    let barH: CGFloat
                    if isSpeaking {
                        let w1 = sin(CGFloat(i) * 0.25 + time * 4.5) * 0.45
                        let w2 = sin(CGFloat(i) * 0.6 + time * 7.2) * 0.25
                        let w3 = cos(CGFloat(i) * 0.12 + time * 2.8) * 0.35
                        let noise = sin(CGFloat(i) * 1.8 + time * 13) * 0.1
                        barH = maxBar * max(0.06, (w1 + w2 + w3 + noise + 1.2) / 2.4)
                    } else {
                        let breath = sin(time * 1.5 + CGFloat(i) * 0.06) * 0.28 + 0.32
                        barH = maxBar * breath * 0.42
                    }

                    let ix = center.x + cos(angle) * mainR
                    let iy = center.y + sin(angle) * mainR
                    let ox = center.x + cos(angle) * (mainR + barH)
                    let oy = center.y + sin(angle) * (mainR + barH)

                    var bp = Path()
                    bp.move(to: CGPoint(x: ix, y: iy))
                    bp.addLine(to: CGPoint(x: ox, y: oy))

                    let intensity = barH / maxBar
                    let isPurple = i % 6 == 0
                    let barColor = isPurple
                        ? Color.ds_purple.opacity(0.18 + intensity * 0.35)
                        : Color.ds_cyan.opacity(0.22 + intensity * 0.55)

                    context.stroke(bp, with: .color(barColor),
                                   style: StrokeStyle(lineWidth: 2.2 * s, lineCap: .round))

                    // Glowing tips on tall bars
                    if intensity > 0.6 {
                        let tipSize = 3.5 * s * intensity
                        let tr = CGRect(x: ox - tipSize / 2, y: oy - tipSize / 2,
                                        width: tipSize, height: tipSize)
                        context.fill(Circle().path(in: tr),
                                     with: .color(Color.ds_cyan.opacity(intensity * 0.35)))
                    }
                }

                // ===== Orbiting particles =====
                for i in 0..<24 {
                    let baseAngle = CGFloat(i) / 24.0 * .pi * 2
                    let drift = sin(time * 0.7 + Double(i) * 1.4) * 10 * s
                    let pR = outerR + drift
                    let rotSpeed: CGFloat = 0.12 + (isSpeaking ? 0.08 : 0)
                    let px = center.x + cos(baseAngle + CGFloat(time) * rotSpeed) * pR
                    let py = center.y + sin(baseAngle + CGFloat(time) * rotSpeed) * pR
                    let pSize = (1.8 + sin(time * 1.5 + Double(i)) * 0.7) * s
                    let pAlpha = 0.1 + sin(time * 1.2 + Double(i) * 0.7) * 0.06
                    let pr = CGRect(x: px - pSize / 2, y: py - pSize / 2,
                                    width: pSize, height: pSize)
                    context.fill(Circle().path(in: pr),
                                 with: .color(Color.ds_cyan.opacity(pAlpha)))
                }

                // ===== Connecting lines (subtle web between some bars) =====
                if isSpeaking {
                    for i in stride(from: 0, to: barCount, by: 8) {
                        let a1 = CGFloat(i) / CGFloat(barCount) * .pi * 2 - .pi / 2
                        let a2 = CGFloat((i + 4) % barCount) / CGFloat(barCount) * .pi * 2 - .pi / 2
                        let r1 = mainR + maxBar * 0.3
                        let r2 = mainR + maxBar * 0.3
                        var lp = Path()
                        lp.move(to: CGPoint(x: center.x + cos(a1) * r1,
                                            y: center.y + sin(a1) * r1))
                        lp.addLine(to: CGPoint(x: center.x + cos(a2) * r2,
                                               y: center.y + sin(a2) * r2))
                        let lineAlpha = sin(time * 3 + Double(i) * 0.5) * 0.04 + 0.04
                        context.stroke(lp,
                                       with: .color(Color.ds_cyan.opacity(max(0.01, lineAlpha))),
                                       lineWidth: 0.5 * s)
                    }
                }
            }
        }
    }
}
