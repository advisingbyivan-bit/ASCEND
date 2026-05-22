import SwiftUI
import DesignSystem

struct CameraSetupScreen: View {
    let coordinator: OnboardingCoordinator
    @State private var showTitle = false
    @State private var showViewfinder = false
    @State private var showAngles = false
    @State private var showInstructions = false
    @State private var showButton = false
    @State private var scanlineY: CGFloat = -1
    @State private var cornerGlow = false
    @State private var currentAngle = 0

    private let angleTimer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    private let angles = ["FRONT", "SIDE", "BACK"]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 40)

            // Title
            VStack(spacing: DSSpacing.xs) {
                Text("Time for Your First Scan")
                    .font(DSFont.screenTitle)
                    .foregroundStyle(Color.ds_textPrimary)
                    .scaleEffect(showTitle ? 1 : 0.9)
                    .opacity(showTitle ? 1 : 0)

                Text("3 angles · 30 seconds")
                    .font(DSFont.body)
                    .foregroundStyle(Color.ds_textSecondary)
                    .offset(y: showTitle ? 0 : 8)
                    .opacity(showTitle ? 1 : 0)
            }
            .padding(.bottom, DSSpacing.lg)

            // Scan viewfinder mockup
            ZStack {
                // Dark simulated camera preview
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.ds_charcoal.opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.ds_cardBorder, lineWidth: 1)
                    )

                // Corner brackets (viewfinder)
                ViewfinderCorners()
                    .stroke(Color.ds_cyan.opacity(cornerGlow ? 0.8 : 0.4),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .padding(20)

                // Body silhouette
                Image(systemName: "figure.stand")
                    .font(.system(size: 90, weight: .ultraLight))
                    .foregroundStyle(Color.ds_cyan.opacity(0.2))

                // Scan line sweeping
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.ds_cyan.opacity(0.5), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
                    .padding(.horizontal, 30)
                    .offset(y: scanlineY * 90)

                // Angle label at bottom
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.ds_cyan)
                            .frame(width: 6, height: 6)
                        Text(angles[currentAngle])
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .tracking(3)
                            .foregroundStyle(Color.ds_cyan)
                        Circle()
                            .fill(Color.ds_cyan)
                            .frame(width: 6, height: 6)
                    }
                    .contentTransition(.numericText())
                    .padding(.bottom, 14)
                }

                // "REC" indicator
                VStack {
                    HStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.ds_red)
                                .frame(width: 6, height: 6)
                                .opacity(cornerGlow ? 1 : 0.4)
                            Text("REC")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundStyle(Color.ds_red.opacity(0.7))
                        }
                        .padding(.top, 14)
                        .padding(.trailing, 14)
                    }
                    Spacer()
                }
            }
            .frame(height: 240)
            .padding(.horizontal, DSSpacing.screenPadding + 8)
            .scaleEffect(showViewfinder ? 1 : 0.85)
            .opacity(showViewfinder ? 1 : 0)

            Spacer().frame(height: DSSpacing.md)

            // 3-angle indicator circles
            HStack(spacing: 20) {
                ForEach(0..<3, id: \.self) { i in
                    let isActive = currentAngle == i
                    VStack(spacing: 6) {
                        ZStack {
                            Circle()
                                .fill(isActive ? Color.ds_cyan.opacity(0.12) : Color.ds_charcoal)
                                .frame(width: 48, height: 48)

                            Circle()
                                .stroke(isActive ? Color.ds_cyan.opacity(0.5) : Color.ds_cardBorder,
                                        lineWidth: isActive ? 1.5 : 1)
                                .frame(width: 48, height: 48)

                            Image(systemName: "figure.stand")
                                .font(.system(size: 20, weight: .light))
                                .foregroundStyle(isActive ? Color.ds_cyan : Color.ds_textSecondary.opacity(0.3))
                                .rotation3DEffect(
                                    .degrees(i == 1 ? -45 : i == 2 ? 180 : 0),
                                    axis: (x: 0, y: 1, z: 0)
                                )
                        }
                        .shadow(color: isActive ? Color.ds_cyan.opacity(0.3) : .clear, radius: 6)
                        .scaleEffect(isActive ? 1.1 : 1.0)

                        Text(angles[i])
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(isActive ? Color.ds_cyan : Color.ds_textSecondary.opacity(0.3))
                            .tracking(1)
                    }
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentAngle)
                }
            }
            .opacity(showAngles ? 1 : 0)
            .offset(y: showAngles ? 0 : 10)

            Spacer().frame(height: DSSpacing.md)

            // Instruction cards
            VStack(spacing: 8) {
                instructionCard(icon: "arrow.left.and.right", text: "Stand 6–8 feet from camera", color: .ds_cyan)
                instructionCard(icon: "tshirt.fill", text: "Fitted clothing, minimal layers", color: .ds_purple)
                instructionCard(icon: "sun.max.fill", text: "Good lighting, plain background", color: .ds_yellow)
            }
            .padding(.horizontal, DSSpacing.screenPadding)
            .opacity(showInstructions ? 1 : 0)
            .offset(y: showInstructions ? 0 : 15)

            Spacer()

            DSPrimaryButton("Open Camera", icon: "camera.fill") {
                DSHaptic.heavy()
                coordinator.advance()
            }
            .padding(.horizontal, DSSpacing.screenPadding)
            .padding(.bottom, DSSpacing.xl)
            .scaleEffect(showButton ? 1 : 0.9)
            .opacity(showButton ? 1 : 0)
        }
        .onReceive(angleTimer) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                currentAngle = (currentAngle + 1) % 3
            }
            DSHaptic.light()
        }
        .onAppear {
            DSHaptic.screenEntry()

            withAnimation(.easeOut(duration: 0.5)) { showTitle = true }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.2)) { showViewfinder = true }
            withAnimation(.easeOut(duration: 0.4).delay(0.5)) { showAngles = true }
            withAnimation(.easeOut(duration: 0.4).delay(0.7)) { showInstructions = true }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.0)) { showButton = true }

            // Scan line sweep
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true).delay(0.4)) {
                scanlineY = 1
            }

            // Corner bracket pulse
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true).delay(0.3)) {
                cornerGlow = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { DSHaptic.heartbeat() }
        }
    }

    private func instructionCard(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.1))
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.ds_textSecondary)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.ds_charcoal.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.ds_cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Viewfinder Corner Brackets

private struct ViewfinderCorners: Shape {
    func path(in rect: CGRect) -> Path {
        let len: CGFloat = 22
        var path = Path()

        // Top-left
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + len))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX + len, y: rect.minY))

        // Top-right
        path.move(to: CGPoint(x: rect.maxX - len, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + len))

        // Bottom-right
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - len))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - len, y: rect.maxY))

        // Bottom-left
        path.move(to: CGPoint(x: rect.minX + len, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - len))

        return path
    }
}
