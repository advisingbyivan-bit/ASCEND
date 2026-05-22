import SwiftUI
import SceneKit
import DesignSystem

public struct BodyModelView: View {
    let gender: BodyGender
    let zones: [BodyZone: ZoneStatus]
    let interactive: Bool
    let size: BodyModelSize

    public init(
        gender: BodyGender = .male,
        zones: [BodyZone: ZoneStatus] = [:],
        interactive: Bool = true,
        size: BodyModelSize = .full
    ) {
        self.gender = gender
        self.zones = zones
        self.interactive = interactive
        self.size = size
    }

    /// Whether the model should initially face away to show back-facing zones
    private var shouldShowBack: Bool {
        let activeZones = zones.filter { $0.value != .base }
        guard !activeZones.isEmpty else { return false }
        // If ALL active zones are back-facing (back, glutes), show the back
        return activeZones.keys.allSatisfy { $0.isBackFacing }
    }

    public var body: some View {
        BodyModelSceneRepresentable(
            gender: gender,
            zones: zones,
            interactive: interactive,
            showBack: shouldShowBack
        )
        .frame(width: size.width, height: size.height)
    }
}

public enum BodyModelSize {
    case full
    case dashboard
    case card

    var width: CGFloat {
        switch self {
        case .full: 320
        case .dashboard: 160
        case .card: 100
        }
    }

    var height: CGFloat {
        switch self {
        case .full: 480
        case .dashboard: 240
        case .card: 150
        }
    }
}

struct BodyModelSceneRepresentable: UIViewRepresentable {
    let gender: BodyGender
    let zones: [BodyZone: ZoneStatus]
    let interactive: Bool
    var showBack: Bool = false

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = BodyModelBuilder.buildScene(gender: gender, zones: zones, showBack: showBack)
        scnView.backgroundColor = .clear
        scnView.antialiasingMode = .multisampling4X
        scnView.allowsCameraControl = interactive
        scnView.autoenablesDefaultLighting = false
        scnView.isPlaying = true
        scnView.defaultCameraController.interactionMode = .orbitTurntable
        scnView.defaultCameraController.inertiaEnabled = true

        // Track applied zones to avoid redundant shader re-applications
        context.coordinator.appliedZones = zones
        context.coordinator.appliedShowBack = showBack

        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        guard let scene = scnView.scene else { return }

        // Only re-apply zone shader if zones actually changed — prevents
        // stacking pulse animations that cause increasing brightness
        if context.coordinator.appliedZones != zones {
            context.coordinator.appliedZones = zones
            BodyModelBuilder.applyZoneColors(scene, zones: zones, animated: true, gender: gender)
        }

        // Only rotate if showBack changed
        if context.coordinator.appliedShowBack != showBack {
            context.coordinator.appliedShowBack = showBack
            BodyModelBuilder.rotateToShowBack(scene, showBack: showBack)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var appliedZones: [BodyZone: ZoneStatus] = [:]
        var appliedShowBack: Bool = false
    }
}

#Preview("Body Model - Male") {
    ZStack {
        Color(red: 10.0/255, green: 14.0/255, blue: 39.0/255).ignoresSafeArea()
        BodyModelView(
            gender: .male,
            zones: [
                .shoulders: .strong,
                .chest: .moderate,
                .arms: .target,
                .abs: .weak,
                .legs: .moderate
            ],
            interactive: true,
            size: .full
        )
    }
}
