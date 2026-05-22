import UIKit
import CoreHaptics

public enum DSHaptic {
    public static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    public static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    public static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    public static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    public static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    public static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    public static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }

    public static func celebration() {
        Task { @MainActor in
            let g = UIImpactFeedbackGenerator(style: .light)
            g.impactOccurred()
            try? await Task.sleep(for: .milliseconds(80))
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            try? await Task.sleep(for: .milliseconds(80))
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            try? await Task.sleep(for: .milliseconds(120))
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    public static func scanPulse() {
        Task { @MainActor in
            for _ in 0..<3 {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
    }

    public static func zoneReveal() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
    }

    public static func diamondUnlock() {
        Task { @MainActor in
            for i in 0..<5 {
                let style: UIImpactFeedbackGenerator.FeedbackStyle = i < 2 ? .light : i < 4 ? .medium : .heavy
                UIImpactFeedbackGenerator(style: style).impactOccurred()
                try? await Task.sleep(for: .milliseconds(100))
            }
            try? await Task.sleep(for: .milliseconds(200))
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    // MARK: - Onboarding Haptics

    /// Gentle arrival — used when a new onboarding screen appears
    public static func screenEntry() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.6)
    }

    /// Rising build — three ascending taps for anticipation moments
    public static func anticipationBuild() {
        Task { @MainActor in
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.4)
            try? await Task.sleep(for: .milliseconds(120))
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.6)
            try? await Task.sleep(for: .milliseconds(120))
            UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.8)
        }
    }

    /// Option selected — crisp confirmation tap
    public static func optionSelect() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.7)
    }

    /// Slider tick — ultra-light for continuous feedback
    public static func sliderTick() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.3)
    }

    /// CTA ready — signals the continue button is now active
    public static func ctaReady() {
        Task { @MainActor in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.5)
            try? await Task.sleep(for: .milliseconds(60))
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.3)
        }
    }

    /// Iris awakening — dramatic entrance for IRIS intro
    public static func irisAwaken() {
        Task { @MainActor in
            // Deep rumble
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 0.4)
            try? await Task.sleep(for: .milliseconds(200))
            // Expanding pulses
            for i in 0..<4 {
                UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.3 + Double(i) * 0.15)
                try? await Task.sleep(for: .milliseconds(150))
            }
            // Final lock
            try? await Task.sleep(for: .milliseconds(100))
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }

    /// Countdown heartbeat — rhythmic taps for scan prep
    public static func heartbeat() {
        Task { @MainActor in
            UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.8)
            try? await Task.sleep(for: .milliseconds(120))
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
        }
    }

    /// Paywall reveal — premium feel
    public static func paywallReveal() {
        Task { @MainActor in
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.5)
            try? await Task.sleep(for: .milliseconds(100))
            UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: 0.6)
            try? await Task.sleep(for: .milliseconds(100))
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.3)
        }
    }
}
