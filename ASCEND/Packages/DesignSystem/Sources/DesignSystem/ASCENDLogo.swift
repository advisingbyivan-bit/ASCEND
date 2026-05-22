import SwiftUI
import SceneKit

public struct ASCENDLogoView: View {
    let size: CGFloat

    public init(size: CGFloat = 200) {
        self.size = size
    }

    public var body: some View {
        ASCENDLogoSceneRepresentable()
            .frame(width: size, height: size)
            .dsGlow(color: .ds_cyan, radius: size * 0.08, intensity: 0.4)
    }
}

struct ASCENDLogoSceneRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = ASCENDLogoSceneBuilder.build()
        scnView.backgroundColor = .clear
        scnView.antialiasingMode = .multisampling4X
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = false
        scnView.isPlaying = true
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}

enum ASCENDLogoSceneBuilder {
    static func build() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.wantsHDR = true
        camera.camera?.bloomIntensity = 0.3
        camera.camera?.bloomThreshold = 0.5
        camera.position = SCNVector3(0, 0, 5)
        scene.rootNode.addChildNode(camera)

        addLighting(to: scene)

        let logoNode = buildLetterA()
        logoNode.name = "logo"
        scene.rootNode.addChildNode(logoNode)

        let rotate = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 20)
        logoNode.runAction(.repeatForever(rotate))

        return scene
    }

    private static func addLighting(to scene: SCNScene) {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.color = UIColor(white: 0.2, alpha: 1)
        scene.rootNode.addChildNode(ambient)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.color = UIColor(red: 0.7, green: 0.85, blue: 1, alpha: 1)
        key.light?.intensity = 1000
        key.position = SCNVector3(3, 4, 5)
        key.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(key)

        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .directional
        fill.light?.color = UIColor(red: 0, green: 0.5, blue: 1, alpha: 1)
        fill.light?.intensity = 400
        fill.position = SCNVector3(-3, 2, 3)
        fill.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(fill)

        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light?.type = .directional
        rim.light?.color = UIColor(red: 0, green: 0.85, blue: 1, alpha: 1)
        rim.light?.intensity = 300
        rim.position = SCNVector3(0, -1, -3)
        rim.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(rim)
    }

    private static func chromeMaterial() -> SCNMaterial {
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = UIColor(red: 0.15, green: 0.3, blue: 0.55, alpha: 1)
        mat.metalness.contents = 0.92
        mat.roughness.contents = 0.12
        mat.fresnelExponent = 4
        mat.isDoubleSided = false
        return mat
    }

    private static func buildLetterA() -> SCNNode {
        let container = SCNNode()

        let legWidth: CGFloat = 0.25
        let legHeight: CGFloat = 2.2
        let depth: CGFloat = 0.35
        let halfSpread: CGFloat = 0.7
        let mat = chromeMaterial()

        // Left leg
        let leftLeg = SCNBox(width: legWidth, height: legHeight, length: depth, chamferRadius: 0.04)
        leftLeg.materials = [mat]
        let leftNode = SCNNode(geometry: leftLeg)
        leftNode.position = SCNVector3(-halfSpread * 0.5, 0, 0)
        leftNode.eulerAngles.z = Float.pi * 0.08
        container.addChildNode(leftNode)

        // Right leg
        let rightLeg = SCNBox(width: legWidth, height: legHeight, length: depth, chamferRadius: 0.04)
        rightLeg.materials = [mat]
        let rightNode = SCNNode(geometry: rightLeg)
        rightNode.position = SCNVector3(halfSpread * 0.5, 0, 0)
        rightNode.eulerAngles.z = -Float.pi * 0.08
        container.addChildNode(rightNode)

        // Crossbar
        let crossbar = SCNBox(width: halfSpread * 1.3, height: legWidth * 0.75, length: depth, chamferRadius: 0.04)
        crossbar.materials = [mat]
        let crossNode = SCNNode(geometry: crossbar)
        crossNode.position = SCNVector3(0, -0.15, 0)
        container.addChildNode(crossNode)

        // Apex connector (triangle top)
        let apex = SCNBox(width: legWidth * 1.5, height: legWidth, length: depth, chamferRadius: 0.06)
        apex.materials = [mat]
        let apexNode = SCNNode(geometry: apex)
        apexNode.position = SCNVector3(0, legHeight * 0.48, 0)
        container.addChildNode(apexNode)

        // Subtle glow edge pieces
        let glowMat = SCNMaterial()
        glowMat.lightingModel = .constant
        glowMat.diffuse.contents = UIColor(red: 0, green: 0.85, blue: 1, alpha: 0.3)
        glowMat.emission.contents = UIColor(red: 0, green: 0.85, blue: 1, alpha: 1)
        glowMat.emission.intensity = 0.3
        glowMat.blendMode = .add

        let edgeLeft = SCNBox(width: 0.02, height: legHeight * 0.95, length: depth + 0.02, chamferRadius: 0)
        edgeLeft.materials = [glowMat]
        let edgeLeftNode = SCNNode(geometry: edgeLeft)
        edgeLeftNode.position = SCNVector3(leftNode.position.x - Float(legWidth / 2), 0, 0)
        edgeLeftNode.eulerAngles.z = leftNode.eulerAngles.z
        container.addChildNode(edgeLeftNode)

        let edgeRight = SCNBox(width: 0.02, height: legHeight * 0.95, length: depth + 0.02, chamferRadius: 0)
        edgeRight.materials = [glowMat]
        let edgeRightNode = SCNNode(geometry: edgeRight)
        edgeRightNode.position = SCNVector3(rightNode.position.x + Float(legWidth / 2), 0, 0)
        edgeRightNode.eulerAngles.z = rightNode.eulerAngles.z
        container.addChildNode(edgeRightNode)

        return container
    }
}

#Preview("ASCEND Logo") {
    ZStack {
        Color.ds_navy.ignoresSafeArea()
        ASCENDLogoView(size: 200)
    }
}
