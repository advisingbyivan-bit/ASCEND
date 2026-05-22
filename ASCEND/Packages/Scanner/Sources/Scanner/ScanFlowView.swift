import SwiftUI
import DesignSystem

/// Face ID-style body scanner.
///
/// Full-screen camera with rectangular corner-bracket frame.
/// Tick marks along edges fill in a clockwise domino sweep as joints lock.
/// Progress ring + status at the bottom.
public struct ScanFlowView: View {
    @State private var camera = CameraManager()
    @State private var capturedPhotos: [UIImage] = []
    @State private var scanComplete = false
    @State private var showFlash = false

    // Angle tracking
    @State private var currentAngle: Int = 0       // 0 front · 1 side · 2 back
    @State private var showTransition = false
    @State private var transitionIcon: String = ""
    @State private var transitionTitle: String = ""
    @State private var transitionSubtitle: String = ""

    // UI entrance
    @State private var showHUD = false
    @State private var showMesh = false
    @State private var ringPulse = false

    // Step-back hint — shows if body not detected for a few seconds
    @State private var showStepBack = false
    @State private var noBodyTimer: Timer?

    // Photo review
    @State private var reviewPhoto: UIImage?
    @State private var showReview = false
    @State private var isCapturePending = false

    public var onComplete: (([UIImage]) -> Void)?
    public var onDismiss: (() -> Void)?

    public init(onComplete: (([UIImage]) -> Void)? = nil, onDismiss: (() -> Void)? = nil) {
        self.onComplete = onComplete
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    public var body: some View {
        ZStack {
            // 1. Full-bleed camera
            cameraLayer

            // 2. Flash overlay
            if showFlash {
                Color.white
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            // 3. Corner brackets + tick marks
            if showMesh {
                BodyTrackingOverlay(progress: scanProgress)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .allowsHitTesting(false)
            }

            // 4. Subtle vignette
            scanningVignette

            // 5. Top HUD (angle label)
            if showHUD { topHUD.allowsHitTesting(false) }

            // 6. Bottom HUD (progress ring + status + angle dots)
            if showHUD { bottomHUD.allowsHitTesting(false) }

            // 7. Step-back hint
            if showStepBack {
                stepBackHint
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .allowsHitTesting(false)
            }

            // 8. Angle transition
            if showTransition { transitionOverlay }

            // 9. Photo review overlay
            if showReview, let photo = reviewPhoto {
                photoReviewOverlay(photo: photo)
                    .transition(.opacity)
            }

            // 10. Close button — always on top and tappable
            if !showReview {
                closeButton
            }
        }
        .statusBarHidden()
        .onAppear {
            startCamera()
            setupCallbacks()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeOut(duration: 0.6)) { showHUD = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.8)) { showMesh = true }
                DSHaptic.screenEntry()
            }
        }
        .onDisappear {
            camera.stop()
            noBodyTimer?.invalidate()
        }
        .onChange(of: camera.isBodyInFrame) { _, inFrame in
            handleBodyDetectionChange(inFrame)
        }
    }

    /// Configure + start camera with permission handling.
    private func startCamera() {
        camera.configure()
        if camera.cameraAvailable {
            camera.start()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if !camera.cameraAvailable {
                camera.configure()
            }
            if camera.cameraAvailable && !camera.session.isRunning {
                camera.start()
            }
        }
    }

    private var scanProgress: CGFloat {
        guard camera.totalJoints > 0 else { return 0 }
        // When enough joints lock to trigger capture, show 100% so all ticks fill
        if camera.allLocked { return 1.0 }
        return CGFloat(camera.lockedCount) / CGFloat(camera.totalJoints)
    }

    // MARK: - Step-Back Detection

    private func handleBodyDetectionChange(_ inFrame: Bool) {
        if inFrame {
            // Body found — hide hint, cancel timer
            noBodyTimer?.invalidate()
            noBodyTimer = nil
            if showStepBack {
                withAnimation(.easeOut(duration: 0.3)) { showStepBack = false }
            }
        } else {
            // Body lost — start timer, show hint after 3 seconds
            noBodyTimer?.invalidate()
            noBodyTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
                Task { @MainActor in
                    withAnimation(.easeOut(duration: 0.4)) { showStepBack = true }
                }
            }
        }
    }

    // MARK: - Camera Layer

    private var cameraLayer: some View {
        ZStack {
            Color(red: 0.03, green: 0.03, blue: 0.07)
                .ignoresSafeArea()

            #if !targetEnvironment(simulator)
            GeometryReader { geo in
                CameraPreview(session: camera.session)
                    .ignoresSafeArea()
                    .onAppear {
                        camera.setViewAspect(geo.size.width / geo.size.height)
                    }
            }
            #endif
        }
    }

    // MARK: - Vignette

    private var scanningVignette: some View {
        Rectangle()
            .fill(
                RadialGradient(
                    colors: [.clear, .clear, Color.black.opacity(0.3)],
                    center: .center,
                    startRadius: 200,
                    endRadius: 550
                )
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
    }

    // MARK: - Close Button

    private var closeButton: some View {
        VStack {
            HStack {
                Button {
                    DSHaptic.light()
                    camera.stop()
                    onDismiss?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial.opacity(0.5))
                        .clipShape(Circle())
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)
            Spacer()
        }
    }

    // MARK: - Top HUD

    private var topHUD: some View {
        VStack {
            HStack(alignment: .top) {
                Spacer()

                Text(angleName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.ds_cyan)
                    .tracking(2)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial.opacity(0.5))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.top, 56)

            Spacer()
        }
        .transition(.opacity)
    }

    private var angleName: String {
        switch currentAngle {
        case 0: "FRONT"
        case 1: "SIDE"
        case 2: "BACK"
        default: "DONE"
        }
    }

    // MARK: - Bottom HUD

    private var bottomHUD: some View {
        VStack {
            Spacer()

            VStack(spacing: 20) {
                // Progress ring
                progressRing
                    .frame(width: 64, height: 64)

                // Status pill
                HStack(spacing: 6) {
                    Circle()
                        .fill(camera.isBodyInFrame ? Color.ds_green : Color.ds_red)
                        .frame(width: 6, height: 6)
                    Text(statusText)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(camera.isBodyInFrame ? Color.ds_green : Color.ds_red)
                        .tracking(1.5)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial.opacity(0.5))
                .clipShape(Capsule())
                .animation(.easeOut(duration: 0.3), value: camera.isBodyInFrame)

                // Instruction text
                Text(instructionText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 6)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.3), value: instructionText)

                // Angle dots (F · S · B)
                HStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { i in
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(i < capturedPhotos.count
                                          ? Color.ds_green
                                          : Color.white.opacity(0.12))
                                    .frame(width: 8, height: 8)

                                if i < capturedPhotos.count {
                                    Circle()
                                        .fill(Color.ds_green.opacity(0.2))
                                        .frame(width: 20, height: 20)
                                }

                                if i == currentAngle && !scanComplete {
                                    Circle()
                                        .stroke(Color.ds_cyan.opacity(0.6), lineWidth: 1.5)
                                        .frame(width: 16, height: 16)
                                        .scaleEffect(ringPulse ? 1.2 : 1.0)
                                }
                            }

                            Text(["F", "S", "B"][i])
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundStyle(
                                    i < capturedPhotos.count
                                    ? Color.ds_green.opacity(0.7)
                                    : i == currentAngle
                                        ? Color.ds_cyan.opacity(0.7)
                                        : Color.white.opacity(0.2)
                                )
                        }
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: capturedPhotos.count)
            }
            .padding(.bottom, 40)
        }
        .transition(.opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                ringPulse = true
            }
        }
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 3)

            Circle()
                .trim(from: 0, to: scanProgress)
                .stroke(
                    AngularGradient(
                        colors: [Color.ds_cyan, Color.ds_green],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: (scanProgress > 0.5 ? Color.ds_green : Color.ds_cyan).opacity(0.4), radius: 6)

            Text("\(Int(scanProgress * 100))%")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(scanProgress >= 1 ? Color.ds_green : .white)
                .transaction { $0.animation = nil }
        }
        .animation(.easeOut(duration: 0.25), value: scanProgress)
    }

    private var statusText: String {
        if !camera.isBodyInFrame { return "STEP INTO FRAME" }
        if camera.allLocked { return "CAPTURING" }
        if scanProgress > 0.6 { return "ALMOST THERE" }
        return "HOLD STEADY"
    }

    private var instructionText: String {
        if !camera.isBodyInFrame { return "Stand so your full body is visible" }
        switch currentAngle {
        case 0: return camera.allLocked ? "Got it!" : "Face the camera"
        case 1: return camera.allLocked ? "Got it!" : "Show your side"
        case 2: return camera.allLocked ? "Got it!" : "Face away"
        default: return "Complete!"
        }
    }

    // MARK: - Step-Back Hint

    private var stepBackHint: some View {
        VStack {
            Spacer()
                .frame(height: 200)

            VStack(spacing: 12) {
                Image(systemName: "arrow.up.backward.and.arrow.down.forward")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Color.ds_cyan)

                Text("Try stepping back")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Move further from the camera\nso your full body is visible")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
            .background(.ultraThinMaterial.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer()
        }
    }

    // MARK: - Transition Overlay

    private var transitionOverlay: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.ds_cyan.opacity(0.08))
                        .frame(width: 90, height: 90)

                    Circle()
                        .stroke(Color.ds_cyan.opacity(0.2), lineWidth: 1)
                        .frame(width: 90, height: 90)

                    Image(systemName: transitionIcon)
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(Color.ds_cyan)
                }

                Text(transitionTitle)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)

                Text(transitionSubtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.45))
            }
        }
        .transition(.opacity)
        .allowsHitTesting(false)
    }

    // MARK: - Callbacks

    private func setupCallbacks() {
        camera.onJointLocked = {
            DSHaptic.sliderTick()
        }
        camera.onAllLocked = {
            Task { @MainActor in
                await performCapture()
            }
        }
    }

    // MARK: - Photo Review Overlay

    private func photoReviewOverlay(photo: UIImage) -> some View {
        ZStack {
            // Full-bleed captured photo
            Color.black.ignoresSafeArea()

            Image(uiImage: photo)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .ignoresSafeArea()

            // Top label
            VStack {
                HStack {
                    Spacer()
                    Text(angleName.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.ds_cyan)
                        .tracking(2)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial.opacity(0.5))
                        .clipShape(Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.top, 56)
                Spacer()
            }

            // Bottom buttons
            VStack {
                Spacer()

                Text("Use this photo?")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.6), radius: 6)

                HStack(spacing: 20) {
                    // Retake
                    Button {
                        retakePhoto()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Retake")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.ultraThinMaterial.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Use Photo
                    Button {
                        acceptPhoto()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Use Photo")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(Color.ds_navy)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.ds_cyan)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            }
        }
    }

    // MARK: - Capture Flow

    @MainActor
    private func performCapture() async {
        guard !scanComplete, !isCapturePending, !showReview else { return }
        isCapturePending = true

        DSHaptic.success()

        // Flash
        withAnimation(.easeOut(duration: 0.06)) { showFlash = true }
        try? await Task.sleep(for: .milliseconds(80))
        withAnimation(.easeIn(duration: 0.15)) { showFlash = false }

        // Capture photo while camera is still running, then stop for review
        if let photo = await camera.capturePhoto() {
            camera.stop()
            reviewPhoto = photo
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.easeOut(duration: 0.25)) {
                showReview = true
            }
        } else {
            // Capture failed — reset and let user try again
            await camera.resetLocksAndWait()
            camera.start()
        }
        isCapturePending = false
    }

    // MARK: - Photo Review Actions

    @MainActor
    private func retakePhoto() {
        DSHaptic.light()

        withAnimation(.easeOut(duration: 0.2)) {
            showReview = false
        }
        reviewPhoto = nil

        Task {
            await camera.resetLocksAndWait()
            camera.start()
        }
    }

    @MainActor
    private func acceptPhoto() {
        DSHaptic.medium()

        guard let photo = reviewPhoto else { return }

        // Add accepted photo to the array
        capturedPhotos.append(photo)

        // Dismiss review
        withAnimation(.easeOut(duration: 0.2)) {
            showReview = false
        }
        reviewPhoto = nil

        // Continue the flow
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            await proceedAfterAccept()
        }
    }

    @MainActor
    private func proceedAfterAccept() async {
        if currentAngle < 2 {
            let next = currentAngle + 1

            switch next {
            case 1:
                transitionIcon = "arrow.turn.right.up"
                transitionTitle = "Turn to your side"
                transitionSubtitle = "Rotate slowly to your left"
            default:
                transitionIcon = "arrow.counterclockwise"
                transitionTitle = "Turn around"
                transitionSubtitle = "Face away from the camera"
            }

            currentAngle = next
            withAnimation(.easeOut(duration: 0.3)) { showTransition = true }
            DSHaptic.anticipationBuild()

            try? await Task.sleep(for: .milliseconds(2000))

            await camera.resetLocksAndWait()
            camera.start()

            withAnimation(.easeOut(duration: 0.3)) { showTransition = false }
        } else {
            scanComplete = true
            DSHaptic.celebration()
            try? await Task.sleep(for: .milliseconds(500))
            onComplete?(capturedPhotos)
        }
    }
}
