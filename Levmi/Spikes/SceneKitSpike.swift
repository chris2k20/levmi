import SwiftUI
import SceneKit
import simd

/// Technischer Spike (kein Produktcode): prüft, ob SceneKit im iOS-26-Simulator
/// HDR-Bloom, Reflexionsboden, Partikel, DoF und Vignette liefert.
struct SceneKitSpikeView: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        let scene = SpikeSceneBuilder.build()
        view.scene = scene
        view.backgroundColor = .black
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 120
        view.rendersContinuously = true
        view.isPlaying = true
        view.allowsCameraControl = false
        view.pointOfView = scene.rootNode.childNode(withName: "camera", recursively: true)
        return view
    }
    func updateUIView(_ uiView: SCNView, context: Context) {}
}

enum SpikeSceneBuilder {
    static func build() -> SCNScene {
        let scene = SCNScene()
        scene.background.contents = UIColor(red: 0.015, green: 0.015, blue: 0.045, alpha: 1)
        scene.fogColor = UIColor(red: 0.015, green: 0.015, blue: 0.05, alpha: 1)
        scene.fogStartDistance = 9
        scene.fogEndDistance = 28
        scene.fogDensityExponent = 1.6

        // Kamera mit Post-Processing
        let cameraNode = SCNNode()
        cameraNode.name = "camera"
        let camera = SCNCamera()
        camera.fieldOfView = 52
        camera.zNear = 0.1
        camera.zFar = 120
        camera.wantsHDR = true
        camera.bloomIntensity = 1.6
        camera.bloomThreshold = 0.5
        camera.bloomBlurRadius = 30
        camera.vignettingPower = 1.2
        camera.vignettingIntensity = 1.0
        camera.colorFringeStrength = 0.3
        camera.screenSpaceAmbientOcclusionIntensity = 1.0
        camera.screenSpaceAmbientOcclusionRadius = 2
        camera.wantsDepthOfField = true
        camera.focusDistance = 7.5
        camera.fStop = 4
        camera.exposureOffset = 0.15
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(0, 2.4, 7.8)
        cameraNode.look(at: SCNVector3(0, 1.1, 0))
        let rig = SCNNode()
        rig.addChildNode(cameraNode)
        scene.rootNode.addChildNode(rig)
        rig.runAction(.repeatForever(.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 70)))

        // Spiegelnder Boden
        let floor = SCNFloor()
        floor.reflectivity = 0.4
        floor.reflectionFalloffEnd = 7
        let floorMat = SCNMaterial()
        floorMat.lightingModel = .physicallyBased
        floorMat.diffuse.contents = UIColor(white: 0.05, alpha: 1)
        floorMat.roughness.contents = 0.2
        floorMat.metalness.contents = 0.15
        floor.materials = [floorMat]
        scene.rootNode.addChildNode(SCNNode(geometry: floor))

        // Kristall (flat shaded Ikosaeder)
        let crystal = SCNNode(geometry: Icosahedron.flatShaded(radius: 1.0))
        let mat = SCNMaterial()
        mat.lightingModel = .physicallyBased
        mat.diffuse.contents = UIColor(red: 0.18, green: 0.55, blue: 1.0, alpha: 1)
        mat.emission.contents = UIColor(red: 0.25, green: 0.7, blue: 1.0, alpha: 1)
        mat.emission.intensity = 1.8
        mat.roughness.contents = 0.15
        mat.metalness.contents = 0.65
        crystal.geometry?.materials = [mat]
        crystal.position = SCNVector3(0, 1.7, 0)
        crystal.runAction(.repeatForever(.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 14)))
        let up = SCNAction.moveBy(x: 0, y: 0.25, z: 0, duration: 2.2)
        up.timingMode = .easeInEaseOut
        crystal.runAction(.repeatForever(.sequence([up, up.reversed()])))
        scene.rootNode.addChildNode(crystal)

        let inner = SCNLight()
        inner.type = .omni
        inner.color = UIColor(red: 0.3, green: 0.7, blue: 1, alpha: 1)
        inner.intensity = 2200
        inner.attenuationEndDistance = 14
        let innerNode = SCNNode()
        innerNode.light = inner
        crystal.addChildNode(innerNode)

        // Key- und Ambient-Licht
        let key = SCNLight()
        key.type = .directional
        key.intensity = 450
        key.color = UIColor(red: 1, green: 0.85, blue: 0.7, alpha: 1)
        key.castsShadow = true
        key.shadowMode = .deferred
        key.shadowRadius = 10
        key.shadowColor = UIColor.black.withAlphaComponent(0.65)
        let keyNode = SCNNode()
        keyNode.light = key
        keyNode.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 4, 0)
        scene.rootNode.addChildNode(keyNode)

        let amb = SCNLight()
        amb.type = .ambient
        amb.intensity = 70
        amb.color = UIColor(red: 0.4, green: 0.5, blue: 0.85, alpha: 1)
        let ambNode = SCNNode()
        ambNode.light = amb
        scene.rootNode.addChildNode(ambNode)

        // Säulenring als Maßstab
        for i in 0..<12 {
            let angle = Float(i) / 12 * .pi * 2
            let h = CGFloat(0.6 + Double((i * 7) % 5) * 0.35)
            let box = SCNBox(width: 0.35, height: h, length: 0.35, chamferRadius: 0.04)
            let m = SCNMaterial()
            m.lightingModel = .physicallyBased
            m.diffuse.contents = UIColor(white: 0.12, alpha: 1)
            m.roughness.contents = 0.5
            if i % 3 == 0 {
                m.emission.contents = UIColor(red: 1.0, green: 0.55, blue: 0.2, alpha: 1)
                m.emission.intensity = 1.0
            }
            box.materials = [m]
            let n = SCNNode(geometry: box)
            n.position = SCNVector3(cos(angle) * 4.2, Float(h / 2), sin(angle) * 4.2)
            scene.rootNode.addChildNode(n)
        }

        // Partikel
        let ps = SCNParticleSystem()
        ps.birthRate = 45
        ps.particleLifeSpan = 8
        ps.particleLifeSpanVariation = 3
        ps.emitterShape = SCNSphere(radius: 5)
        ps.particleSize = 0.07
        ps.particleSizeVariation = 0.04
        ps.particleColor = UIColor(red: 0.6, green: 0.85, blue: 1, alpha: 1)
        ps.blendMode = .additive
        ps.isAffectedByGravity = false
        ps.particleVelocity = 0.15
        ps.particleVelocityVariation = 0.1
        ps.emittingDirection = SCNVector3(0, 1, 0)
        ps.spreadingAngle = 180
        ps.particleImage = ParticleImage.softCircle(diameter: 64)
        ps.isLightingEnabled = false
        let psNode = SCNNode()
        psNode.position = SCNVector3(0, 2, 0)
        psNode.addParticleSystem(ps)
        scene.rootNode.addChildNode(psNode)

        return scene
    }
}

enum ParticleImage {
    static func softCircle(diameter: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter))
        return renderer.image { ctx in
            let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor] as CFArray
            let space = CGColorSpaceCreateDeviceRGB()
            guard let grad = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1]) else { return }
            let c = CGPoint(x: diameter / 2, y: diameter / 2)
            ctx.cgContext.drawRadialGradient(grad, startCenter: c, startRadius: 0, endCenter: c, endRadius: diameter / 2, options: [])
        }
    }
}

enum Icosahedron {
    static func flatShaded(radius: Float) -> SCNGeometry {
        let t = Float((1.0 + sqrt(5.0)) / 2.0)
        let raw: [(Float, Float, Float)] = [
            (-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0),
            (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t),
            (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1)
        ]
        let base = raw.map { simd_normalize(SIMD3<Float>($0.0, $0.1, $0.2)) * radius }
        let faces: [[Int]] = [
            [0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
            [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
            [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
            [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]
        ]
        var vertices: [SCNVector3] = []
        var normals: [SCNVector3] = []
        var indices: [Int32] = []
        for f in faces {
            let a = base[f[0]]
            var b = base[f[1]], c = base[f[2]]
            var n = simd_normalize(simd_cross(b - a, c - a))
            if simd_dot(n, a) < 0 { swap(&b, &c); n = -n }
            for p in [a, b, c] {
                indices.append(Int32(vertices.count))
                vertices.append(SCNVector3(p.x, p.y, p.z))
                normals.append(SCNVector3(n.x, n.y, n.z))
            }
        }
        let vSrc = SCNGeometrySource(vertices: vertices)
        let nSrc = SCNGeometrySource(normals: normals)
        let elem = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        return SCNGeometry(sources: [vSrc, nSrc], elements: [elem])
    }
}
