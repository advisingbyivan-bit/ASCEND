import SwiftUI
import BodyModel3D
import IRIS
import DesignSystem
import Networking

@Observable
public final class DiagnosisRevealViewModel {
    public enum Stage: Equatable {
        case anticipation
        case reveal
        case celebration
        case error
    }

    public private(set) var stage: Stage = .anticipation
    public private(set) var irisState: IRISState = .processing
    public private(set) var analysisProgress: Double = 0
    public private(set) var diagnosis: DiagnosisResult?
    public private(set) var revealedZones: [BodyZone: ZoneStatus] = [:]
    public private(set) var showBody = false
    public private(set) var showMessage = false
    public private(set) var showConfetti = false
    public private(set) var showCTA = false
    public private(set) var messageText = ""
    public private(set) var errorMessage = ""
    public private(set) var isUsingFallback = false

    private var photos: [UIImage]
    private var hapticTimer: Timer?
    private var userContext: ClaudeVisionClient.UserContext
    private var apiTask: Task<DiagnosisResult, Error>?

    /// Scan counter for varied template selection
    private static var scanCounter: Int {
        get { UserDefaults.standard.integer(forKey: "ascend_scan_count") }
        set { UserDefaults.standard.set(newValue, forKey: "ascend_scan_count") }
    }

    public init(photos: [UIImage], userContext: ClaudeVisionClient.UserContext = ClaudeVisionClient.UserContext()) {
        self.photos = photos
        self.userContext = userContext
    }

    @MainActor
    public func startAnalysis() async {
        stage = .anticipation
        irisState = .processing
        errorMessage = ""
        isUsingFallback = false

        startHapticPulse()

        // Start API call concurrently with progress animation
        let apiResultTask = startAPICall()

        // Animate progress to 80% while API processes
        await animateProgressToHold()

        // Wait for API result
        let result: DiagnosisResult
        do {
            result = try await apiResultTask.value
        } catch {
            // API failed — use smart fallback
            isUsingFallback = true
            let count = Self.scanCounter
            result = DiagnosisResult.generateSmart(scanNumber: count)
            Self.scanCounter = count + 1
        }

        // Finish progress bar 80% → 100%
        await animateProgressToComplete()

        diagnosis = result
        stopHapticPulse()
        await transitionToReveal()
    }

    @MainActor
    public func retry() async {
        revealedZones = [:]
        showBody = false
        showMessage = false
        showConfetti = false
        showCTA = false
        messageText = ""
        analysisProgress = 0
        errorMessage = ""
        await startAnalysis()
    }

    @MainActor
    public func useFallback() async {
        isUsingFallback = true
        let count = Self.scanCounter
        let result = DiagnosisResult.generateSmart(scanNumber: count)
        Self.scanCounter = count + 1
        diagnosis = result
        analysisProgress = 1.0
        await transitionToReveal()
    }

    /// Start the API call as a concurrent task, returns a task handle
    private func startAPICall() -> Task<DiagnosisResult, Error> {
        Task {
            if photos.count >= 3,
               let front = photos[0].jpegData(compressionQuality: 0.8),
               let side = photos[1].jpegData(compressionQuality: 0.8),
               let back = photos[2].jpegData(compressionQuality: 0.8),
               !ClaudeVisionClient.shared.apiKey.isEmpty {
                let response = try await ClaudeVisionClient.shared.analyzeBody(
                    frontImageData: front,
                    sideImageData: side,
                    backImageData: back,
                    context: userContext
                )
                return DiagnosisResult.from(response)
            } else {
                // No API key — use smart varied templates
                let count = Self.scanCounter
                let result = DiagnosisResult.generateSmart(scanNumber: count)
                Self.scanCounter = count + 1
                return result
            }
        }
    }

    @MainActor
    private func animateProgressToHold() async {
        // Animate 0% → 80% in ~2.4 seconds (fast ramp, then slow)
        for i in 1...16 {
            let delay: UInt64 = i <= 10 ? 100 : 200  // Faster early, slower as it holds
            try? await Task.sleep(for: .milliseconds(delay))
            analysisProgress = min(0.80, Double(i) / 20.0)
        }
    }

    @MainActor
    private func animateProgressToComplete() async {
        // Smooth 80% → 100%
        for i in 17...20 {
            try? await Task.sleep(for: .milliseconds(80))
            analysisProgress = Double(i) / 20.0
        }
    }

    @MainActor
    private func transitionToReveal() async {
        stage = .reveal
        irisState = .speaking

        try? await Task.sleep(for: .milliseconds(300))

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showBody = true
        }

        try? await Task.sleep(for: .milliseconds(600))

        guard let zones = diagnosis?.zones else { return }
        for item in zones {
            withAnimation(.easeInOut(duration: 0.4)) {
                revealedZones[item.zone] = item.status
            }
            DSHaptic.zoneReveal()
            try? await Task.sleep(for: .milliseconds(500))
        }

        try? await Task.sleep(for: .milliseconds(400))
        messageText = diagnosis?.irisMessage ?? ""
        withAnimation(.easeIn(duration: 0.3)) {
            showMessage = true
        }
    }

    @MainActor
    public func messageFinished() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(300))
            await transitionToCelebration()
        }
    }

    @MainActor
    private func transitionToCelebration() async {
        stage = .celebration
        irisState = .celebration

        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            showConfetti = true
        }
        DSHaptic.celebration()

        try? await Task.sleep(for: .milliseconds(800))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            showCTA = true
        }
    }

    private func startHapticPulse() {
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            DSHaptic.light()
        }
    }

    private func stopHapticPulse() {
        hapticTimer?.invalidate()
        hapticTimer = nil
    }
}
