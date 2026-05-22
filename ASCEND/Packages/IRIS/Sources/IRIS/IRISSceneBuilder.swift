import SceneKit
import SwiftUI

final class IRISSceneBuilder {
    static func buildScene(state: IRISState) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 3.5)
        cameraNode.camera?.wantsHDR = true
        cameraNode.camera?.bloomIntensity = 0.8
        cameraNode.camera?.bloomThreshold = 0.3
        scene.rootNode.addChildNode(cameraNode)

        addAmbientLight(to: scene)
        addKeyLights(to: scene)

        let sphereContainer = SCNNode()
        sphereContainer.name = "sphereContainer"
        scene.rootNode.addChildNode(sphereContainer)

        addGlassSphere(to: sphereContainer, state: state)
        addInnerBands(to: sphereContainer, state: state)
        addCoreGlow(to: sphereContainer, state: state)
        addParticles(to: sphereContainer, state: state)

        return scene
    }

    private static func addAmbientLight(to scene: SCNScene) {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.color = UIColor(white: 0.1, alpha: 1)
        scene.rootNode.addChildNode(ambient)
    }

    private static func addKeyLights(to scene: SCNScene) {
        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.color = UIColor(red: 0, green: 0.85, blue: 1, alpha: 1)
        key.light?.intensity = 600
        key.position = SCNVector3(2, 3, 4)
        key.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(key)

        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .directional
        fill.light?.color = UIColor(red: 0.6, green: 0.3, blue: 0.9, alpha: 1)
        fill.light?.intensity = 300
        fill.position = SCNVector3(-2, -1, 3)
        fill.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(fill)

        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light?.type = .directional
        rim.light?.color = UIColor(red: 1, green: 0.84, blue: 0, alpha: 1)
        rim.light?.intensity = 200
        rim.position = SCNVector3(0, 0, -3)
        rim.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(rim)
    }

    private static func addGlassSphere(to parent: SCNNode, state: IRISState) {
        let sphere = SCNSphere(radius: 1.0)
        sphere.segmentCount = 96

        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = UIColor(red: 0.08, green: 0.2, blue: 0.4, alpha: 1)
        material.metalness.contents = 0.15
        material.roughness.contents = 0.08
        material.transparency = 0.35
        material.fresnelExponent = 4.0
        material.isDoubleSided = true

        sphere.materials = [material]

        let node = SCNNode(geometry: sphere)
        node.name = "glassSphere"
        parent.addChildNode(node)
    }

    private static func addInnerBands(to parent: SCNNode, state: IRISState) {
        let bandCount = 5
        let colors: [UIColor] = [
            UIColor(red: 0, green: 0.85, blue: 1, alpha: 1),
            UIColor(red: 0, green: 0.7, blue: 0.95, alpha: 1),
            UIColor(red: 0.4, green: 0.2, blue: 0.9, alpha: 1),
            UIColor(red: 1, green: 0.84, blue: 0, alpha: 0.8),
            UIColor(red: 0, green: 0.9, blue: 0.8, alpha: 1),
        ]

        for i in 0..<bandCount {
            let torus = SCNTorus(ringRadius: CGFloat(0.5 + Double(i) * 0.08), pipeRadius: 0.025)
            torus.ringSegmentCount = 80
            torus.pipeSegmentCount = 16

            let material = SCNMaterial()
            material.lightingModel = .physicallyBased
            material.diffuse.contents = colors[i]
            material.emission.contents = colors[i]
            material.emission.intensity = CGFloat(state.glowIntensity * 1.5)
            material.metalness.contents = 0.7
            material.roughness.contents = 0.15

            torus.materials = [material]

            let bandNode = SCNNode(geometry: torus)
            bandNode.name = "band_\(i)"

            let xAngle = Float.random(in: -Float.pi...Float.pi)
            let yAngle = Float.random(in: -Float.pi...Float.pi)
            let zAngle = Float(i) * Float.pi / Float(bandCount)
            bandNode.eulerAngles = SCNVector3(xAngle, yAngle, zAngle)

            let speed = state.bandSpeed
            let xRot = SCNAction.rotateBy(
                x: CGFloat(Float.random(in: 0.5...1.5)),
                y: CGFloat(Float.random(in: 0.3...1.0)),
                z: CGFloat(Float.random(in: 0.2...0.8)),
                duration: speed * Double.random(in: 0.8...1.2)
            )
            bandNode.runAction(.repeatForever(xRot))

            parent.addChildNode(bandNode)
        }
    }

    private static func addCoreGlow(to parent: SCNNode, state: IRISState) {
        let coreSphere = SCNSphere(radius: 0.25)
        coreSphere.segmentCount = 48

        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = UIColor(red: 0, green: 0.85, blue: 1, alpha: 1)
        material.emission.contents = UIColor(red: 0, green: 0.85, blue: 1, alpha: 1)
        material.emission.intensity = CGFloat(state.glowIntensity * 2.0)
        material.transparency = CGFloat(0.4 + state.glowIntensity * 0.4)

        coreSphere.materials = [material]

        let coreNode = SCNNode(geometry: coreSphere)
        coreNode.name = "coreGlow"

        let pulse = SCNAction.sequence([
            .scale(to: 1.15, duration: 1.5),
            .scale(to: 0.85, duration: 1.5)
        ])
        coreNode.runAction(.repeatForever(pulse))

        parent.addChildNode(coreNode)
    }

    private static func addParticles(to parent: SCNNode, state: IRISState) {
        let particleSystem = SCNParticleSystem()
        particleSystem.particleSize = 0.012
        particleSystem.particleSizeVariation = 0.006
        particleSystem.birthRate = CGFloat(50 * state.particleDensity)
        particleSystem.particleLifeSpan = 3
        particleSystem.particleLifeSpanVariation = 1
        particleSystem.emitterShape = SCNSphere(radius: 1.2)
        particleSystem.spreadingAngle = 180
        particleSystem.particleVelocity = 0.02
        particleSystem.particleVelocityVariation = 0.01
        particleSystem.particleColor = UIColor(red: 0.7, green: 0.9, blue: 1, alpha: 1)
        particleSystem.particleColorVariation = SCNVector4(0.2, 0.1, 0, 0.3)
        particleSystem.blendMode = .additive
        particleSystem.isAffectedByGravity = false
        particleSystem.isAffectedByPhysicsFields = false

        let particleNode = SCNNode()
        particleNode.name = "particles"
        particleNode.addParticleSystem(particleSystem)
        parent.addChildNode(particleNode)
    }

    static func updateState(_ scene: SCNScene, to state: IRISState) {
        guard let container = scene.rootNode.childNode(withName: "sphereContainer", recursively: false) else { return }

        for i in 0..<5 {
            guard let band = container.childNode(withName: "band_\(i)", recursively: false) else { continue }
            band.removeAllActions()

            let speed = state.bandSpeed
            let xRot = SCNAction.rotateBy(
                x: CGFloat(Float.random(in: 0.5...1.5)),
                y: CGFloat(Float.random(in: 0.3...1.0)),
                z: CGFloat(Float.random(in: 0.2...0.8)),
                duration: speed * Double.random(in: 0.8...1.2)
            )
            band.runAction(.repeatForever(xRot))

            if let torus = band.geometry as? SCNTorus,
               let material = torus.materials.first {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.8
                material.emission.intensity = CGFloat(state.glowIntensity * 1.5)
                SCNTransaction.commit()
            }
        }

        if let core = container.childNode(withName: "coreGlow", recursively: false),
           let material = core.geometry?.materials.first {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            material.emission.intensity = CGFloat(state.glowIntensity * 2.0)
            material.transparency = CGFloat(0.4 + state.glowIntensity * 0.4)
            SCNTransaction.commit()

            if state == .warning {
                material.diffuse.contents = UIColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1)
                material.emission.contents = UIColor(red: 0.6, green: 0.2, blue: 0.8, alpha: 1)
            } else {
                material.diffuse.contents = UIColor(red: 0, green: 0.85, blue: 1, alpha: 1)
                material.emission.contents = UIColor(red: 0, green: 0.85, blue: 1, alpha: 1)
            }
        }

        if let particleNode = container.childNode(withName: "particles", recursively: false),
           let system = particleNode.particleSystems?.first {
            system.birthRate = CGFloat(50 * state.particleDensity)
        }

        if state == .celebration {
            performCelebration(container)
        }
    }

    private static func performCelebration(_ container: SCNNode) {
        for i in 0..<5 {
            guard let band = container.childNode(withName: "band_\(i)", recursively: false) else { continue }
            let expand = SCNAction.sequence([
                .scale(to: 1.4, duration: 0.3),
                .scale(to: 1.0, duration: 0.2)
            ])
            band.runAction(expand)
        }

        if let core = container.childNode(withName: "coreGlow", recursively: false) {
            let flash = SCNAction.sequence([
                .scale(to: 2.0, duration: 0.15),
                .scale(to: 1.0, duration: 0.3)
            ])
            core.runAction(flash)
        }
    }
}
