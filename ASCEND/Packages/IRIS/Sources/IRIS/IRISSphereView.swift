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

    private var isSmall: Bool {
        size == .badge || size == .tabIcon || size == .notification
    }

    public var body: some View {
        ZStack {
            IRISSceneRepresentable(state: state, isSmall: isSmall)
                .frame(width: size.points, height: size.points)
                .shadow(
                    color: (state == .warning ? Color.ds_purple : Color.ds_cyan)
                        .opacity(state.glowIntensity * (isSmall ? 0.4 : 0.8)),
                    radius: glowRadius
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
    var isSmall: Bool = false

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = IRISSceneBuilder.buildScene(state: state)
        scnView.backgroundColor = .clear
        // Small views (badge/tabIcon): skip expensive AA, lower frame rate
        scnView.antialiasingMode = isSmall ? .none : .multisampling2X
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = false
        scnView.isPlaying = !isSmall  // Static snapshot for tiny views
        scnView.preferredFramesPerSecond = isSmall ? 0 : 30
        scnView.rendersContinuously = !isSmall
        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        guard let scene = scnView.scene else { return }
        IRISSceneBuilder.updateState(scene, to: state)
        // One-shot render for small views after state update
        if isSmall { scnView.setNeedsDisplay() }
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
