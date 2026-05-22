import SceneKit
import SceneKit.ModelIO
import ModelIO
import UIKit
import Foundation

final class BodyModelBuilder {

    // MARK: - Build Scene

    static func buildScene(gender: BodyGender, zones: [BodyZone: ZoneStatus], showBack: Bool = false) -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear

        // Camera
        let camera = SCNNode()
        camera.camera = SCNCamera()
        // HDR DISABLED — its auto-exposure adaptation was the root cause of
        // the model getting progressively brighter. The dark background made
        // the exposure ramp up over ~10 seconds, washing out zone colors to
        // solid bright blue. Emissive materials provide the glow look instead.
        camera.camera?.wantsHDR = false
        camera.camera?.fieldOfView = 55
        camera.position = SCNVector3(0, 0.0, 3.0)
        scene.rootNode.addChildNode(camera)

        addLighting(to: scene)

        // Body container
        let bodyContainer = SCNNode()
        bodyContainer.name = "bodyContainer"
        scene.rootNode.addChildNode(bodyContainer)

        // If showing back zones, start rotated 180°
        if showBack {
            bodyContainer.eulerAngles.y = Float.pi
        }

        // Load 3D model
        if let modelNode = loadModel(gender: gender) {
            modelNode.name = "bodyMesh"
            bodyContainer.addChildNode(modelNode)
            applyMatteMaterial(to: modelNode)
            // Paint zone colors directly onto the mesh via shader modifier
            applyZoneShader(to: modelNode, zones: zones, gender: gender)
        } else {
            // Procedural fallback
            buildProceduralBody(gender: gender, zones: zones, parent: bodyContainer)
        }

        // Floating particles
        addAmbientParticles(to: scene)

        // Slow idle rotation
        let idle = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 25)
        bodyContainer.runAction(.repeatForever(idle))

        return scene
    }

    // MARK: - Load Model

    private static func loadModel(gender: BodyGender) -> SCNNode? {
        let fileName = gender == .male ? "male_body" : "female_body"

        // Try SCN first, then USDZ, then OBJ via ModelIO.
        let meshNode: SCNNode? =
            loadFromSCN(fileName: fileName) ??
            loadFromUSDZ(fileName: fileName) ??
            loadFromOBJ(fileName: fileName)

        guard let meshNode else {
            #if DEBUG
            NSLog("‼️ FAILED to load \(fileName) from ANY format (scn/usdz/obj) — using procedural fallback")
            #endif
            return nil
        }

        // Count vertices for verification
        var totalVerts = 0
        meshNode.enumerateChildNodes { child, _ in
            if let geo = child.geometry {
                totalVerts += geo.sources(for: .vertex).first?.vectorCount ?? 0
            }
        }
        if let geo = meshNode.geometry {
            totalVerts += geo.sources(for: .vertex).first?.vectorCount ?? 0
        }
        #if DEBUG
        NSLog("✅ Loaded \(fileName) — \(totalVerts) vertices")
        #endif

        // Normalize: center precisely and scale to fit camera view
        let (min, max) = meshNode.boundingBox
        let height = max.y - min.y
        let centerY = (max.y + min.y) / 2.0
        let centerX = (max.x + min.x) / 2.0
        let centerZ = (max.z + min.z) / 2.0

        let targetHeight: Float = 1.7
        let scale = targetHeight / height
        meshNode.scale = SCNVector3(scale, scale, scale)
        // Center the model precisely at origin (critical — models have very different coordinate spaces)
        meshNode.position = SCNVector3(-centerX * scale, -centerY * scale, -centerZ * scale)

        return meshNode
    }

    /// Load from SCN (SceneKit archive) format.
    private static func loadFromSCN(fileName: String) -> SCNNode? {
        guard let url = Bundle.module.url(forResource: fileName, withExtension: "scn") else {
            #if DEBUG
            NSLog("⚠️ \(fileName).scn not found in bundle")
            #endif
            return nil
        }

        guard let scene = try? SCNScene(url: url) else {
            #if DEBUG
            NSLog("⚠️ \(fileName).scn found but SCNScene(url:) failed to load it")
            #endif
            return nil
        }

        let meshNode = SCNNode()
        for child in scene.rootNode.childNodes {
            meshNode.addChildNode(child.clone())
        }

        // Verify we got actual geometry
        var hasGeometry = false
        meshNode.enumerateChildNodes { child, stop in
            if child.geometry != nil { hasGeometry = true; stop.pointee = true }
        }
        guard hasGeometry else {
            #if DEBUG
            NSLog("⚠️ \(fileName).scn loaded but contains no geometry")
            #endif
            return nil
        }

        #if DEBUG
        NSLog("✅ Loaded \(fileName).scn")
        #endif
        return meshNode
    }

    /// Load from USDZ format (iOS-native 3D format).
    private static func loadFromUSDZ(fileName: String) -> SCNNode? {
        guard let url = Bundle.module.url(forResource: fileName, withExtension: "usdz") else {
            #if DEBUG
            NSLog("⚠️ \(fileName).usdz not found in bundle")
            #endif
            return nil
        }

        guard let scene = try? SCNScene(url: url) else {
            #if DEBUG
            NSLog("⚠️ \(fileName).usdz found but SCNScene(url:) failed to load it")
            #endif
            return nil
        }

        let meshNode = SCNNode()
        for child in scene.rootNode.childNodes {
            meshNode.addChildNode(child.clone())
        }

        var hasGeometry = false
        meshNode.enumerateChildNodes { child, stop in
            if child.geometry != nil { hasGeometry = true; stop.pointee = true }
        }
        guard hasGeometry else {
            #if DEBUG
            NSLog("⚠️ \(fileName).usdz loaded but contains no geometry")
            #endif
            return nil
        }

        #if DEBUG
        NSLog("✅ Loaded \(fileName).usdz")
        #endif
        return meshNode
    }

    /// Load from OBJ format using ModelIO (supports .obj natively).
    private static func loadFromOBJ(fileName: String) -> SCNNode? {
        guard let url = Bundle.module.url(forResource: fileName, withExtension: "obj") else {
            #if DEBUG
            NSLog("⚠️ \(fileName).obj not found in bundle")
            #endif
            return nil
        }

        let asset = MDLAsset(url: url)
        asset.loadTextures()

        guard asset.count > 0 else {
            #if DEBUG
            NSLog("⚠️ \(fileName).obj loaded but MDLAsset contains no objects")
            #endif
            return nil
        }

        let scene = SCNScene(mdlAsset: asset)
        let meshNode = SCNNode()
        for child in scene.rootNode.childNodes {
            meshNode.addChildNode(child.clone())
        }

        var hasGeometry = false
        meshNode.enumerateChildNodes { child, stop in
            if child.geometry != nil { hasGeometry = true; stop.pointee = true }
        }
        guard hasGeometry else {
            #if DEBUG
            NSLog("⚠️ \(fileName).obj loaded but no geometry found after conversion")
            #endif
            return nil
        }

        #if DEBUG
        NSLog("✅ Loaded \(fileName).obj via ModelIO")
        #endif
        return meshNode
    }

    // MARK: - Solid Matte Material (sci-fi medical scanner aesthetic)

    private static func applyMatteMaterial(to node: SCNNode) {
        node.enumerateChildNodes { child, _ in
            guard let geometry = child.geometry else { return }

            let mat = SCNMaterial()
            mat.lightingModel = .physicallyBased
            mat.isDoubleSided = true

            // Brighter navy base — visible but not overpowering
            mat.diffuse.contents = UIColor(red: 0.10, green: 0.14, blue: 0.32, alpha: 1)
            mat.metalness.contents = 0.25
            mat.roughness.contents = 0.65
            mat.transparency = 0.92  // Nearly opaque

            // Subtle constant emission for sci-fi inner glow.
            // This is a FIXED value — does not change over time.
            mat.emission.contents = UIColor(red: 0.02, green: 0.04, blue: 0.12, alpha: 1)
            mat.emission.intensity = 0.3

            // Fresnel for sci-fi rim glow
            mat.fresnelExponent = 3.5

            geometry.materials = [mat]
        }
    }

    // MARK: - Zone Colors (painted directly on mesh via shader)

    /// Zone Y-ranges in normalized body space (height ~2.0, centered at 0).
    /// Each zone is defined by a Y-band so the shader paints color conforming to
    /// the actual mesh surface — no floating boxes.
    /// Normalized with scale = 2.0/height, Y range approx [-1.0, 1.0].
    /// Gender-specific because male and female models have different proportions.
    private static func zoneYRanges(for gender: BodyGender) -> [(zone: BodyZone, yMin: Float, yMax: Float)] {
        if gender == .female {
            return [
                (.shoulders, 0.65, 0.72),    // Tighter bottom — bigger gap from chest to prevent bleeding
                (.chest,     0.42, 0.58),    // Lowered top slightly — bigger gap to shoulders
                (.arms,      0.08, 0.54),    // Lowered top — less overlap with shoulder region
                (.back,      0.28, 0.60),    // Lowered top to match chest and avoid shoulder bleed
                (.core,      0.18, 0.36),    // Good — no change
                (.abs,       0.18, 0.36),    // Good — no change
                (.glutes,    0.06, 0.22),    // Tighter range to reduce overlap with core
                (.legs,     -0.75, 0.00),    // Good — no change
            ]
        }
        // Male ranges (original tuning)
        return [
            (.shoulders, 0.52, 0.74),
            (.chest,     0.52, 0.68),
            (.arms,     -0.05, 0.50),
            (.back,      0.18, 0.64),
            (.core,      0.18, 0.36),
            (.abs,       0.18, 0.36),
            (.glutes,   -0.15, 0.06),
            (.legs,     -0.75, -0.08),
        ]
    }

    /// Arms are distinguished from torso by X-distance from center.
    /// Female model has arms starting at wider X due to different body proportions.
    private static func armXThreshold(for gender: BodyGender) -> Float {
        gender == .female ? 0.21 : 0.18
    }

    /// Determine which zone a vertex belongs to based on its normalized position.
    /// Returns the zone color and blend weight (0-1).
    ///
    /// Coordinate system (after child-to-mesh transform + normalization):
    ///   Y: up/down (-1 feet, +1 head)
    ///   X: left/right (0 = center, positive = wider)
    ///   Z: positive = FRONT (chest/face side, toward camera), negative = BACK
    private static func zoneForVertex(ny: Float, nx: Float, nz: Float,
                                       zones: [BodyZone: ZoneStatus],
                                       gender: BodyGender) -> (r: Float, g: Float, b: Float, strength: Float) {
        let absX = abs(nx)
        let armX = armXThreshold(for: gender)
        let isFemale = gender == .female

        var bestColor: (Float, Float, Float) = (0, 0, 0)
        var bestStrength: Float = 0

        for entry in zoneYRanges(for: gender) {
            guard let status = zones[entry.zone], status != .base else { continue }

            // Check Y range with soft edges (tighter fade for female to prevent bleed)
            let fade: Float = isFemale ? 0.025 : 0.04
            let yIn = smoothstep(entry.yMin - fade, entry.yMin + fade, ny)
                    * (1.0 - smoothstep(entry.yMax - fade, entry.yMax + fade, ny))
            guard yIn > 0.01 else { continue }

            var mask = yIn

            switch entry.zone {
            case .arms:
                // Only vertices far from center on X (the actual arm geometry)
                mask *= smoothstep(armX - 0.03, armX + 0.03, absX)

            case .shoulders:
                // Delt caps + traps — show on front AND back (traps are on the back)
                // No Z-filter: shoulders/traps wrap around
                // Female shoulders are tighter to avoid bleeding into arms/chest
                let xMin: Float = isFemale ? 0.20 : 0.22
                let xMax: Float = isFemale ? 0.25 : 0.30
                let xFade = 1.0 - smoothstep(xMin, xMax, absX)
                mask *= xFade

            case .chest:
                // Front-facing only (positive Z = front) — wider filter for full glow
                let front = smoothstep(-0.05, 0.02, nz)
                mask *= front
                // Exclude arm region — softer edge
                mask *= (1.0 - smoothstep(armX, armX + 0.05, absX))
                // Boost brightness
                mask = min(mask * 1.5, yIn)

            case .back:
                // Back-facing only (negative Z = back) — wider transition for full glow
                let back = 1.0 - smoothstep(-0.05, 0.02, nz)
                mask *= back
                // Exclude arm region — female needs tighter cutoff to avoid tricep bleed
                if isFemale {
                    mask *= (1.0 - smoothstep(armX - 0.06, armX - 0.01, absX))
                } else {
                    mask *= (1.0 - smoothstep(armX - 0.03, armX + 0.03, absX))
                }
                // Boost: back gets extra strength so it reads as bright as front zones
                mask = min(mask * 1.3, yIn)

            case .core, .abs:
                // Front-facing only — deep Z cutoff so ALL front+side vertices
                // get full brightness (fixes left/right asymmetry from mesh imperfections)
                let front: Float = nz > -0.10 ? 1.0 : 0.0
                mask *= front
                // Generous X range — abs are wide, only cut off at actual arm geometry
                mask *= (1.0 - smoothstep(armX + 0.02, armX + 0.08, absX))
                // Strong brightness boost — make it pop
                mask = min(mask * 1.6, yIn)

            case .glutes:
                // Back-facing only (butt is on the back side)
                let back = 1.0 - smoothstep(-0.03, 0.03, nz)
                mask *= back
                // Exclude arm region
                mask *= (1.0 - smoothstep(armX - 0.03, armX + 0.03, absX))

            case .legs:
                break // Pure Y band, no X/Z filtering needed
            }

            if mask > bestStrength {
                bestStrength = mask
                let (r, g, b) = statusToRGB(status)
                bestColor = (r, g, b)
            }
        }

        return (bestColor.0, bestColor.1, bestColor.2, min(bestStrength, 1.0))
    }

    /// CPU-side smoothstep matching GLSL behavior.
    private static func smoothstep(_ edge0: Float, _ edge1: Float, _ x: Float) -> Float {
        let t = min(max((x - edge0) / (edge1 - edge0), 0), 1)
        return t * t * (3 - 2 * t)
    }

    /// Apply zone colors by rebuilding each child geometry with per-vertex colors.
    /// KEY FIX: transforms vertex positions from each child node's LOCAL space
    /// into meshNode's space before applying zone ranges. Without this, child
    /// nodes with position/rotation transforms cause zones to map to wrong body parts.
    private static func applyZoneShader(to meshNode: SCNNode, zones: [BodyZone: ZoneStatus], gender: BodyGender) {
        let activeZones = zones.filter { $0.value != .base }
        guard !activeZones.isEmpty else { return }

        // Bounding box is in meshNode's local space (accounts for child transforms)
        let (bbMin, bbMax) = meshNode.boundingBox
        let height = bbMax.y - bbMin.y
        let centerY = (bbMax.y + bbMin.y) / 2.0
        let centerX = (bbMax.x + bbMin.x) / 2.0
        let centerZ = (bbMax.z + bbMin.z) / 2.0
        let scale = 2.0 / height

        // Pre-compute meshNode's inverse world transform (used to convert child positions)
        let meshWorldInverse = simd_inverse(meshNode.simdWorldTransform)

        meshNode.enumerateChildNodes { child, _ in
            guard let geometry = child.geometry else { return }
            guard let posSource = geometry.sources(for: .vertex).first else { return }

            // Transform from child's local space → meshNode's local space
            // This is critical: without it, vertex Z/Y values are in the wrong coordinate space
            let childToMesh = simd_mul(meshWorldInverse, child.simdWorldTransform)

            let vertexCount = posSource.vectorCount
            let stride = posSource.dataStride
            let offset = posSource.dataOffset
            let data = posSource.data

            // Build color array based on TRANSFORMED vertex positions
            var colors: [Float] = []
            colors.reserveCapacity(vertexCount * 4)

            data.withUnsafeBytes { rawBuffer in
                let bytes = rawBuffer.baseAddress!
                for i in 0..<vertexCount {
                    let vertexPtr = bytes.advanced(by: i * stride + offset)
                    let rawX = vertexPtr.load(fromByteOffset: 0, as: Float.self)
                    let rawY = vertexPtr.load(fromByteOffset: 4, as: Float.self)
                    let rawZ = vertexPtr.load(fromByteOffset: 8, as: Float.self)

                    // Transform vertex from child's local space to meshNode's space
                    let localPos = simd_float4(rawX, rawY, rawZ, 1.0)
                    let meshPos = simd_mul(childToMesh, localPos)

                    // Normalize to zone-range space using meshNode's bounding box
                    let nx = (meshPos.x - centerX) * scale
                    let ny = (meshPos.y - centerY) * scale
                    let nz = (meshPos.z - centerZ) * scale

                    let (r, g, b, rawStrength) = zoneForVertex(ny: ny, nx: nx, nz: nz, zones: zones, gender: gender)

                    // Boost strength with power curve so zone colors pop harder
                    let strength = min(rawStrength * 1.8, 1.0)

                    // Vertex color: zone color at zone strength, base dark otherwise
                    // Brighter base so the model is clearly visible against dark background
                    let baseR: Float = 0.08, baseG: Float = 0.12, baseB: Float = 0.30
                    colors.append(baseR + (r - baseR) * strength)
                    colors.append(baseG + (g - baseG) * strength)
                    colors.append(baseB + (b - baseB) * strength)
                    colors.append(1.0) // alpha
                }
            }

            // Create color geometry source
            let colorData = Data(bytes: colors, count: colors.count * MemoryLayout<Float>.size)
            let colorSource = SCNGeometrySource(
                data: colorData,
                semantic: .color,
                vectorCount: vertexCount,
                usesFloatComponents: true,
                componentsPerVector: 4,
                bytesPerComponent: MemoryLayout<Float>.size,
                dataOffset: 0,
                dataStride: MemoryLayout<Float>.size * 4
            )

            // Rebuild geometry with vertex colors added
            var sources = geometry.sources.filter { $0.semantic != .color }
            sources.append(colorSource)

            let newGeometry = SCNGeometry(sources: sources, elements: geometry.elements.map { $0 })

            // Build fresh materials that use vertex colors for both diffuse and emission.
            // Do NOT copy from origMat — old material's emission.contents (blue tint)
            // would carry over and tint everything blue regardless of zone color.
            let mat = SCNMaterial()
            mat.diffuse.contents = UIColor.white   // Vertex colors show through
            mat.multiply.contents = UIColor.white
            mat.lightingModel = .physicallyBased
            mat.isDoubleSided = true
            mat.metalness.contents = 0.25
            mat.roughness.contents = 0.55
            mat.transparency = 0.92
            mat.fresnelExponent = 3.5
            // Subtle constant emission so zone colors glow slightly.
            // Fixed value — does NOT animate or change over time.
            mat.emission.contents = UIColor(red: 0.03, green: 0.05, blue: 0.14, alpha: 1)
            mat.emission.intensity = 0.25
            newGeometry.materials = [mat]

            child.geometry = newGeometry

            // Remove any existing actions to prevent stacking
            child.removeAllActions()
        }
    }

    // MARK: - Ambient Particles

    private static func addAmbientParticles(to scene: SCNScene) {
        let ps = SCNParticleSystem()
        ps.particleColor = UIColor(red: 0.4, green: 0.2, blue: 0.8, alpha: 0.25)
        ps.particleColorVariation = SCNVector4(0.1, 0.1, 0.2, 0.1)
        ps.particleSize = 0.005
        ps.particleSizeVariation = 0.003
        ps.birthRate = 10
        ps.particleLifeSpan = 8
        ps.particleLifeSpanVariation = 3
        ps.emitterShape = SCNSphere(radius: 2.0)
        ps.spreadingAngle = 180
        ps.particleVelocity = 0.015
        ps.particleVelocityVariation = 0.008
        // Alpha blending instead of additive — prevents particles from
        // adding brightness to the model as it rotates through them
        ps.blendMode = .alpha
        ps.isAffectedByGravity = false

        let node = SCNNode()
        node.addParticleSystem(ps)
        scene.rootNode.addChildNode(node)
    }

    // MARK: - Lighting

    private static func addLighting(to scene: SCNScene) {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.color = UIColor(red: 0.05, green: 0.08, blue: 0.20, alpha: 1)
        ambient.light?.intensity = 600
        scene.rootNode.addChildNode(ambient)

        // Cyan key light — bright enough to make the model pop
        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .directional
        key.light?.color = UIColor(red: 0, green: 0.6, blue: 1, alpha: 1)
        key.light?.intensity = 800
        key.position = SCNVector3(3, 3, 5)
        key.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(key)

        // Purple fill — enough to add depth without overpowering zone colors
        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .directional
        fill.light?.color = UIColor(red: 0.5, green: 0.1, blue: 0.9, alpha: 1)
        fill.light?.intensity = 550
        fill.position = SCNVector3(-3, 1, 3)
        fill.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(fill)

        // Cyan rim (behind for edge glow) — visible silhouette pop
        let rim = SCNNode()
        rim.light = SCNLight()
        rim.light?.type = .directional
        rim.light?.color = UIColor(red: 0, green: 0.9, blue: 1, alpha: 1)
        rim.light?.intensity = 450
        rim.position = SCNVector3(0, 1, -5)
        rim.look(at: SCNVector3Zero)
        scene.rootNode.addChildNode(rim)
    }

    // MARK: - Color Helpers

    static func statusToRGB(_ status: ZoneStatus) -> (Float, Float, Float) {
        switch status {
        case .base:     return (0.08, 0.16, 0.38)    // Visible blue base
        case .weak:     return (1.00, 0.09, 0.27)    // RED — weak areas
        case .moderate: return (1.00, 0.76, 0.03)    // YELLOW — alright
        case .strong:   return (0.22, 1.00, 0.08)    // GREEN — strong areas
        case .target:   return (0.00, 0.85, 1.00)    // CYAN — target areas
        }
    }

    // MARK: - Update Zones

    static func rotateToShowBack(_ scene: SCNScene, showBack: Bool) {
        guard let container = scene.rootNode.childNode(withName: "bodyContainer", recursively: false) else { return }
        // Remove existing rotation actions and smoothly rotate to target
        let targetY: Float = showBack ? Float.pi : 0
        // Only animate if we need to change — compare ignoring full rotations
        let currentY = container.eulerAngles.y.truncatingRemainder(dividingBy: Float.pi * 2)
        let diff = abs(currentY - targetY)
        guard diff > 0.1 else { return }

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.6
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        container.eulerAngles.y = targetY
        SCNTransaction.commit()

        // Restart idle rotation from new position
        container.removeAllActions()
        let idle = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 2, z: 0, duration: 25)
        container.runAction(.repeatForever(idle))
    }

    static func applyZoneColors(_ scene: SCNScene, zones: [BodyZone: ZoneStatus], animated: Bool, gender: BodyGender = .male) {
        guard let container = scene.rootNode.childNode(withName: "bodyContainer", recursively: false) else { return }
        guard let meshNode = container.childNode(withName: "bodyMesh", recursively: false) else { return }

        if animated {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.6
        }

        // Re-apply zone shader to mesh (replaces old shader modifier)
        applyZoneShader(to: meshNode, zones: zones, gender: gender)

        if animated {
            SCNTransaction.commit()
        }
    }

    static func sequentialReveal(_ scene: SCNScene, zones: [(BodyZone, ZoneStatus)], perZoneDelay: TimeInterval = 0.5, gender: BodyGender = .male) {
        for (index, (zone, status)) in zones.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + perZoneDelay * Double(index)) {
                applyZoneColors(scene, zones: [zone: status], animated: true, gender: gender)
            }
        }
    }

    // MARK: - Procedural Fallback

    private static func buildProceduralBody(gender: BodyGender, zones: [BodyZone: ZoneStatus], parent: SCNNode) {
        let isMale = gender == .male

        func mat(for zone: BodyZone) -> SCNMaterial {
            let status = zones[zone] ?? .base
            let (r, g, b) = statusToRGB(status)
            let m = SCNMaterial()
            m.lightingModel = .physicallyBased
            m.diffuse.contents = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)
            m.emission.contents = UIColor(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1)
            m.emission.intensity = status == .base ? 0.5 : 1.0
            m.metalness.contents = 0.5
            m.roughness.contents = 0.3
            m.transparency = 0.85
            m.fresnelExponent = 2.5
            m.isDoubleSided = true
            return m
        }

        // Head
        let head = SCNCapsule(capRadius: 0.14, height: 0.32)
        head.materials = [mat(for: .shoulders)]
        let headNode = SCNNode(geometry: head)
        headNode.position = SCNVector3(0, 0.84, 0)
        parent.addChildNode(headNode)

        // Torso/Chest
        let torso = SCNBox(width: isMale ? 0.55 : 0.48, height: 0.45, length: 0.22, chamferRadius: 0.05)
        torso.materials = [mat(for: .chest)]
        let torsoNode = SCNNode(geometry: torso)
        torsoNode.name = "zone_chest"
        torsoNode.position = SCNVector3(0, 0.42, 0)
        parent.addChildNode(torsoNode)

        // Abs/Core
        let abs = SCNBox(width: isMale ? 0.42 : 0.38, height: 0.3, length: 0.2, chamferRadius: 0.04)
        abs.materials = [mat(for: .abs)]
        let absNode = SCNNode(geometry: abs)
        absNode.name = "zone_abs"
        absNode.position = SCNVector3(0, 0.1, 0.01)
        parent.addChildNode(absNode)

        // Shoulders + Arms
        for side: Float in [-1, 1] {
            let s = SCNSphere(radius: 0.09)
            s.materials = [mat(for: .shoulders)]
            let sn = SCNNode(geometry: s)
            sn.position = SCNVector3(side * 0.32, 0.6, 0)
            parent.addChildNode(sn)

            let a = SCNCapsule(capRadius: isMale ? 0.055 : 0.045, height: 0.6)
            a.materials = [mat(for: .arms)]
            let an = SCNNode(geometry: a)
            an.position = SCNVector3(side * 0.38, 0.25, 0)
            parent.addChildNode(an)
        }

        // Glutes (behind the hips)
        for side: Float in [-1, 1] {
            let g = SCNSphere(radius: isMale ? 0.08 : 0.10)
            g.materials = [mat(for: .glutes)]
            let gn = SCNNode(geometry: g)
            gn.position = SCNVector3(side * 0.10, -0.05, 0.08) // slightly behind center
            parent.addChildNode(gn)
        }

        // Legs
        for side: Float in [-1, 1] {
            let l = SCNCapsule(capRadius: isMale ? 0.08 : 0.085, height: 0.7)
            l.materials = [mat(for: .legs)]
            let ln = SCNNode(geometry: l)
            ln.position = SCNVector3(side * 0.14, -0.4, 0)
            parent.addChildNode(ln)
        }
    }
}
