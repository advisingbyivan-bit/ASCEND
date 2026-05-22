import SwiftUI
import SceneKit
import DesignSystem

public struct IRISSphereView: View {
    let state: IRISState
    let size: IRISSphereSize

    public init(state: IRISState = .idle, size: IRISSphereSize = .full) {
        self.state = state
        self.size = size
    }

    public var body: some View {
        ZStack {
            IRISSceneRepresentable(state: state)
                .frame(width: size.points, height: size.points)
                .dsGlow(
                    color: state == .warning ? .ds_purple : .ds_cyan,
                    radius: glowRadius,
                    intensity: state.glowIntensity
                )
        }
        .frame(width: size.points, height: size.points)
    }

    private var glowRadius: CGFloat {
        switch size {
        case .full: 20
        case .dashboard: 12
        case .notification: 8
        case .badge: 4
        case .tabIcon: 3
        }
    }
}

struct IRISSceneRepresentable: UIViewRepresentable {
    let state: IRISState

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = IRISSceneBuilder.buildScene(state: state)
        scnView.backgroundColor = .clear
        scnView.antialiasingMode = .multisampling4X
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = false
        scnView.isPlaying = true
        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        guard let scene = scnView.scene else { return }
        IRISSceneBuilder.updateState(scene, to: state)
    }
}

#Preview("IRIS - Idle") {
    ZStack {
        Color.ds_navy.ignoresSafeArea()
        IRISSphereView(state: .idle, size: .full)
    }
}

#Preview("IRIS - Processing") {
    ZStack {
        Color.ds_navy.ignoresSafeArea()
        IRISSphereView(state: .processing, size: .full)
    }
}
