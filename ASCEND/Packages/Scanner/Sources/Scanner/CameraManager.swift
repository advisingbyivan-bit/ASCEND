import AVFoundation
import Vision
import UIKit

// MARK: - Tracked Joint Model

public struct TrackedJoint: Identifiable {
    public let id: String
    public var point: CGPoint          // normalized 0–1, SwiftUI-ready (top-left origin)
    public var confidence: Float
    public var isDetected: Bool
    public var isLocked: Bool
    public var lockProgress: CGFloat   // 0 → 1 (fraction of frames stable)
}

// MARK: - Camera Manager

@Observable
public final class CameraManager: NSObject {
    // MARK: Public state
    public var isBodyInFrame = false
    public var cameraAvailable = false
    public var isCapturing = false

    /// Live joint data — updated every processed frame.
    public private(set) var joints: [TrackedJoint] = []

    /// Number of joints currently locked.
    public var lockedCount: Int { joints.filter(\.isLocked).count }

    /// True once enough joints are locked to trigger capture.
    public var allLocked: Bool { lockedCount >= Self.jointsNeededToCapture }

    /// Total joints we track.
    public var totalJoints: Int { Self.trackedJointNames.count }

    /// Called on main thread each time a single joint locks.
    public var onJointLocked: (() -> Void)?

    /// Called on main thread when ALL joints are locked.
    public var onAllLocked: (() -> Void)?

    // MARK: Internal
    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let videoOutput = AVCaptureVideoDataOutput()
    private var photoContinuation: CheckedContinuation<UIImage?, Never>?

    private let processingQueue = DispatchQueue(label: "com.ascend.bodypose", qos: .userInteractive)
    /// Serial queue for all session configuration and start/stop calls — prevents
    /// "stopRunning may not be called between begin/commitConfiguration" crashes.
    private let sessionQueue = DispatchQueue(label: "com.ascend.session", qos: .userInitiated)
    private var isConfiguring = false
    private var isProcessingFrame = false
    private var frameSkipCounter = 0

    // Stability tracking — mutated ONLY on processingQueue
    private var _lastPositions: [String: CGPoint] = [:]
    private var _stableCounts: [String: Int] = [:]
    private var _lockedSet: Set<String> = []
    private var _allLockedFired = false

    // Aspect-fill crop offset (computed once from first frame)
    private var cropOffsetX: CGFloat = 0
    private var visibleWidthFraction: CGFloat = 1
    private var aspectComputed = false
    private var viewAspect: CGFloat = 0  // set from UI

    // Simulator auto-progress
    private var simulatorTimer: Timer?
    private var simulatorStep = 0

    // MARK: - Constants

    static let trackedJointNames: [VNHumanBodyPoseObservation.JointName] = [
        .nose,
        .leftShoulder, .rightShoulder,
        .leftElbow, .rightElbow,
        .leftWrist, .rightWrist,
        .leftHip, .rightHip,
        .leftKnee, .rightKnee,
        .leftAnkle, .rightAnkle
    ]

    /// Joint must stay within this normalised distance to count as "stable".
    /// 0.035 is forgiving enough for natural body sway while still requiring stillness.
    private static let stableThreshold: CGFloat = 0.035
    /// Consecutive stable frames required to lock.
    private static let framesToLock: Int = 10   // ~0.33 s at 30 fps
    /// Minimum Vision confidence to consider a joint detected.
    private static let minConfidence: Float = 0.15

    /// Only need this many joints locked (out of 13) to trigger capture.
    /// Wrists and ankles are naturally jittery — don't require all 13.
    private static let jointsNeededToCapture: Int = 10

    // MARK: - Init

    public override init() {
        super.init()
    }

    // MARK: - Configure

    public func configure() {
        #if targetEnvironment(simulator)
        cameraAvailable = false
        isBodyInFrame = true
        buildEmptyJoints()
        return
        #else
        buildEmptyJoints()
        requestAccessAndConfigure()
        #endif
    }

    /// Request camera permission, then configure the session.
    private func requestAccessAndConfigure() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        if status == .authorized {
            // Permission already granted — configure now
            configureSession()
            return
        }

        if status == .notDetermined {
            // Ask for permission — configure after granted
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else { return }
                // configureSession dispatches to sessionQueue, so schedule start
                // on the same queue so it runs after config completes
                self?.configureSession()
                self?.sessionQueue.async {
                    guard let self, !self.session.isRunning else { return }
                    self.session.startRunning()
                    DispatchQueue.main.async { self.cameraAvailable = true }
                }
            }
            return
        }

        // Denied or restricted
        cameraAvailable = false
    }

    /// Actually set up the AVCaptureSession — only call after permission is granted.
    /// Runs all session work on the dedicated sessionQueue to prevent race conditions.
    private func configureSession() {
        #if !targetEnvironment(simulator)
        // Don't reconfigure if already set up
        guard !cameraAvailable else { return }

        sessionQueue.async { [weak self] in
            guard let self else { return }
            self.isConfiguring = true
            defer { self.isConfiguring = false }

            self.session.beginConfiguration()
            self.session.sessionPreset = .high

            // Remove existing inputs/outputs to start clean
            for input in self.session.inputs { self.session.removeInput(input) }
            for output in self.session.outputs { self.session.removeOutput(output) }

            // Front camera
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                self.session.commitConfiguration()
                DispatchQueue.main.async { self.cameraAvailable = false }
                return
            }

            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if self.session.canAddInput(input) { self.session.addInput(input) }
            } catch {
                self.session.commitConfiguration()
                DispatchQueue.main.async { self.cameraAvailable = false }
                return
            }

            // Photo output
            if self.session.canAddOutput(self.photoOutput) { self.session.addOutput(self.photoOutput) }

            // Video output for body-pose processing
            self.videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.videoOutput.setSampleBufferDelegate(self, queue: self.processingQueue)
            if self.session.canAddOutput(self.videoOutput) {
                self.session.addOutput(self.videoOutput)
                if let connection = self.videoOutput.connection(with: .video) {
                    // Rotate to portrait
                    if connection.isVideoRotationAngleSupported(90) {
                        connection.videoRotationAngle = 90
                    }
                    // Mirror so Vision coords match the mirrored preview
                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = true
                    }
                }
            }

            self.session.commitConfiguration()
            DispatchQueue.main.async { self.cameraAvailable = true }
        }
        #endif
    }

    // MARK: - Start / Stop

    public func start() {
        #if targetEnvironment(simulator)
        startSimulatorMock()
        return
        #else
        guard cameraAvailable else { return }
        if session.isRunning { return }
        sessionQueue.async { [weak self] in
            guard let self, !self.session.isRunning else { return }
            self.session.startRunning()
        }
        #endif
    }

    public func stop() {
        simulatorTimer?.invalidate()
        simulatorTimer = nil
        #if !targetEnvironment(simulator)
        // Dispatch onto sessionQueue so stop waits for any in-progress configuration
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
        }
        #endif
    }

    // MARK: - Reset locks (between angles)

    public func resetLocks() {
        processingQueue.async { [weak self] in
            guard let self else { return }
            self._stableCounts.removeAll()
            self._lockedSet.removeAll()
            self._lastPositions.removeAll()
            self._allLockedFired = false
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            for i in self.joints.indices {
                self.joints[i].isLocked = false
                self.joints[i].lockProgress = 0
            }
        }
        #if targetEnvironment(simulator)
        simulatorStep = 0
        // Restart the mock timer for the next angle
        simulatorTimer?.invalidate()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.restartSimulatorMock()
        }
        #endif
    }

    public func resetLocksAndWait() async {
        resetLocks()
        try? await Task.sleep(for: .milliseconds(50))
    }

    /// Provide the view's aspect ratio so we can adjust for aspect-fill cropping.
    public func setViewAspect(_ aspect: CGFloat) {
        viewAspect = aspect
    }

    // MARK: - Photo Capture

    @MainActor
    public func capturePhoto() async -> UIImage? {
        isCapturing = true
        defer { isCapturing = false }

        guard cameraAvailable else {
            try? await Task.sleep(for: .milliseconds(300))
            return generatePlaceholder()
        }

        return await withCheckedContinuation { continuation in
            self.photoContinuation = continuation

            guard session.isRunning else {
                self.photoContinuation = nil
                continuation.resume(returning: generatePlaceholder())
                return
            }

            let settings = AVCapturePhotoSettings()
            settings.flashMode = .off
            photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }

    // MARK: - Private Helpers

    private func buildEmptyJoints() {
        joints = Self.trackedJointNames.map { name in
            TrackedJoint(
                id: name.rawValue.rawValue,
                point: .zero,
                confidence: 0,
                isDetected: false,
                isLocked: false,
                lockProgress: 0
            )
        }
    }

    private func generatePlaceholder() -> UIImage {
        let size = CGSize(width: 400, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            UIColor(red: 10/255, green: 14/255, blue: 39/255, alpha: 1).setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - Vision Processing (Video Frames)

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Skip frames for performance (process every 2nd frame)
        frameSkipCounter += 1
        guard frameSkipCounter % 2 == 0 else { return }
        guard !isProcessingFrame else { return }
        isProcessingFrame = true

        defer { isProcessingFrame = false }

        // Compute aspect-fill offset once
        if !aspectComputed, viewAspect > 0 {
            if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                let frameW = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
                let frameH = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
                let cameraAspect = frameW / frameH
                if cameraAspect > 0 {
                    visibleWidthFraction = min(1.0, viewAspect / cameraAspect)
                    cropOffsetX = (1.0 - visibleWidthFraction) / 2.0
                    aspectComputed = true
                }
            }
        }

        // Run body pose detection
        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        let request = VNDetectHumanBodyPoseRequest()

        do {
            try handler.perform([request])
        } catch {
            updateNoBody()
            return
        }

        guard let observation = request.results?.first else {
            updateNoBody()
            return
        }

        // Process each tracked joint
        var newJoints: [TrackedJoint] = []
        var detectedCount = 0
        var newlyLocked: [String] = []

        for jointName in Self.trackedJointNames {
            let key = jointName.rawValue.rawValue

            guard let point = try? observation.recognizedPoint(jointName),
                  point.confidence >= Self.minConfidence else {
                // Joint not detected
                _stableCounts[key] = 0
                newJoints.append(TrackedJoint(
                    id: key,
                    point: _lastPositions[key] ?? .zero,
                    confidence: 0,
                    isDetected: false,
                    isLocked: _lockedSet.contains(key),
                    lockProgress: _lockedSet.contains(key) ? 1 : 0
                ))
                continue
            }

            detectedCount += 1

            // Convert Vision coords to SwiftUI-ready normalised coords
            // Vision: (0,0) = bottom-left. SwiftUI: (0,0) = top-left.
            var nx = point.location.x
            var ny = 1.0 - point.location.y

            // Adjust for aspect-fill crop
            if aspectComputed && visibleWidthFraction < 1.0 {
                nx = (nx - cropOffsetX) / visibleWidthFraction
            }

            let screenPoint = CGPoint(x: nx, y: ny)

            // Stability check
            let alreadyLocked = _lockedSet.contains(key)
            var stableCount = _stableCounts[key] ?? 0
            var lockProg: CGFloat = 0

            if !alreadyLocked {
                if let lastPos = _lastPositions[key] {
                    let dx = screenPoint.x - lastPos.x
                    let dy = screenPoint.y - lastPos.y
                    let dist = sqrt(dx * dx + dy * dy)
                    if dist < Self.stableThreshold {
                        stableCount += 1
                    } else {
                        stableCount = max(0, stableCount - 2) // decay on movement
                    }
                }
                _stableCounts[key] = stableCount
                lockProg = min(1.0, CGFloat(stableCount) / CGFloat(Self.framesToLock))

                if stableCount >= Self.framesToLock {
                    _lockedSet.insert(key)
                    newlyLocked.append(key)
                }
            } else {
                lockProg = 1.0
            }

            _lastPositions[key] = screenPoint

            newJoints.append(TrackedJoint(
                id: key,
                point: screenPoint,
                confidence: point.confidence,
                isDetected: true,
                isLocked: _lockedSet.contains(key),
                lockProgress: lockProg
            ))
        }

        let bodyDetected = detectedCount >= 4
        let allNowLocked = _lockedSet.count >= Self.jointsNeededToCapture
        let fireAllLocked = allNowLocked && !_allLockedFired
        if fireAllLocked { _allLockedFired = true }

        // Push UI updates to main thread
        DispatchQueue.main.async { [weak self, newJoints, bodyDetected, newlyLocked, fireAllLocked] in
            guard let self else { return }
            self.joints = newJoints
            self.isBodyInFrame = bodyDetected
            for _ in newlyLocked {
                self.onJointLocked?()
            }
            if fireAllLocked {
                self.onAllLocked?()
            }
        }
    }

    private func updateNoBody() {
        DispatchQueue.main.async { [weak self] in
            self?.isBodyInFrame = false
        }
    }
}

// MARK: - Photo Capture Delegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            photoContinuation?.resume(returning: nil)
            photoContinuation = nil
            return
        }
        photoContinuation?.resume(returning: image)
        photoContinuation = nil
    }
}

// MARK: - Simulator Mock

extension CameraManager {
    private static let mockPositions: [CGPoint] = [
        CGPoint(x: 0.50, y: 0.12),  // nose
        CGPoint(x: 0.40, y: 0.25),  // left shoulder
        CGPoint(x: 0.60, y: 0.25),  // right shoulder
        CGPoint(x: 0.35, y: 0.38),  // left elbow
        CGPoint(x: 0.65, y: 0.38),  // right elbow
        CGPoint(x: 0.32, y: 0.50),  // left wrist
        CGPoint(x: 0.68, y: 0.50),  // right wrist
        CGPoint(x: 0.43, y: 0.52),  // left hip
        CGPoint(x: 0.57, y: 0.52),  // right hip
        CGPoint(x: 0.42, y: 0.70),  // left knee
        CGPoint(x: 0.58, y: 0.70),  // right knee
        CGPoint(x: 0.41, y: 0.88),  // left ankle
        CGPoint(x: 0.59, y: 0.88),  // right ankle
    ]

    func startSimulatorMock() {
        cameraAvailable = false
        isBodyInFrame = true
        simulatorStep = 0
        setMockJointPositions()
        startMockLockTimer()
    }

    func restartSimulatorMock() {
        setMockJointPositions()
        startMockLockTimer()
    }

    private func setMockJointPositions() {
        for i in joints.indices {
            joints[i].point = Self.mockPositions[i]
            joints[i].confidence = 0.9
            joints[i].isDetected = true
        }
    }

    private func startMockLockTimer() {
        simulatorTimer?.invalidate()
        simulatorTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { [weak self] _ in
            guard let self else { return }
            let step = self.simulatorStep
            guard step < self.joints.count else {
                self.simulatorTimer?.invalidate()
                return
            }
            self.joints[step].isLocked = true
            self.joints[step].lockProgress = 1.0
            self.onJointLocked?()
            self.simulatorStep += 1

            if self.simulatorStep >= self.joints.count {
                self.onAllLocked?()
            }
        }
    }
}
