import SceneKit
import UIKit
import simd

/// Baut und besitzt die komplette SceneKit-Welt der Insel: alle Knoten-Referenzen, Materialien und
/// Partikel-Vorlagen. `IslandWorld` kennt nur Rendering — keine Spielregeln, keine Persistenz.
/// `IslandChoreography.swift` (Erweiterung dieser Klasse) bedient die eigentlichen `SceneCommand`s.
///
/// Fünf Knoten pro Nacht: zwei `glowing`, zwei `lukewarm`, ein `cold` (siehe poc-spec.md §1.1).
/// `glowing` und `lukewarm` sehen bis zur Setzung bewusst gleich verführerisch aus — nur Tonhöhe
/// (Audio) und ein leicht unregelmäßiger Puls unterscheiden sie. Keine Sanduhr vorab.
@MainActor
final class IslandWorld {
    /// Eine platzierte Knoten-Instanz auf der Insel. `id` ist eindeutig (z. B. "glowing1",
    /// "lukewarm2"), `family` ("glowing" | "cold" | "lukewarm") bestimmt Optik/Audio-Familie.
    struct IslandNode {
        let id: String
        let family: String
        let crystalNode: SCNNode
        let material: SCNMaterial
        let ringTicks: [SCNNode]
        let ringMaterials: [SCNMaterial]
    }

    let scene = SCNScene()

    // Kamera-Rig
    let orbitRig = SCNNode()
    let cameraNode = SCNNode()
    let camera = SCNCamera()

    // Umgebung
    let waterNode: SCNNode
    let fogDiscNode: SCNNode
    let fogDiscMaterial: SCNMaterial

    // Insel
    let islandRig = SCNNode()          // Position animiert (Reveal-Anstieg)
    let islandRockGroup = SCNNode()    // nur die Gesteinsfragmente (für Transluzenz)
    var islandRockMaterials: [SCNMaterial] = []

    // Fünf Knoten, adressiert über eindeutige IDs.
    private(set) var islandNodes: [String: IslandNode] = [:]
    let islandNodeOrder: [String] = ["glowing1", "lukewarm1", "cold1", "glowing2", "lukewarm2"]

    // Choreografie-Buchführung (nur Rendering-Zustand, keine Spielregeln).
    var lastTouchedNodeID: String?
    var chargeProgress: [String: Double] = [:]
    var settledNodeIDs: Set<String> = []
    var currentLightColor: UIColor = Palette.lightWarmDefault
    var currentFogLevel: Int = 0

    // Spieler-Licht
    let playerLightNode = SCNNode()
    let playerLight = SCNLight()
    let playerLightMaterial = SCNMaterial()
    static let playerLightStartPosition = SCNVector3(0, 3.3, 0)

    // Wurzelnetz
    let rootsNode = SCNNode()
    let rootsMaterial = SCNMaterial()
    var rootSegments: [SCNNode] = []

    // Sonne
    let sunNode = SCNNode()
    let sunLight = SCNLight()
    let sunMaterial = SCNMaterial()
    static let sunHiddenY: Float = -3.2
    static let sunRisenY: Float = 9.5

    // Durchbruch-Trieb
    let sproutNode = SCNNode()
    let sproutMaterial = SCNMaterial()

    // Lichter (max. 3 dynamische: Key, Spieler-Punktlicht, Sonne — Ambient zählt nicht mit)
    let keyLightNode = SCNNode()
    let keyLight = SCNLight()
    let ambientLightNode = SCNNode()

    // Partikel
    let ambientSparks = SCNParticleSystem()
    let impactBurstTemplate = SCNParticleSystem()
    let breakthroughBurstTemplate = SCNParticleSystem()

    // Kamera-Positionen (siehe IslandChoreography für die Animationen dazwischen)
    static let cameraClosePosition = SCNVector3(0, 1.55, 4.6)
    static let cameraOrbitPosition = SCNVector3(0, 2.5, 8.0)
    static let cameraDivePosition = SCNVector3(0, 0.3, 3.35)
    static let cameraBreakthroughPosition = SCNVector3(0, 1.85, 3.0)
    static let cameraLookTarget = SCNVector3(0, 1.05, 0)

    static let islandHiddenY: Float = 0.05
    static let islandRevealedY: Float = 1.15
    static let fogLevelHeights: [Float] = [0.55, 0.38, 0.21, 0.04]

    init() {
        setupBackgroundAndFog()
        waterNode = Self.makeWaterNode()
        (fogDiscNode, fogDiscMaterial) = Self.makeFogDisc()
        scene.rootNode.addChildNode(waterNode)
        scene.rootNode.addChildNode(fogDiscNode)

        scene.rootNode.addChildNode(islandRig)
        islandRig.addChildNode(islandRockGroup)
        islandRig.position = SCNVector3(0, Self.islandHiddenY, 0)
        buildIslandRock()
        buildIslandNodes()
        buildRoots()
        buildSprout()

        buildPlayerLight()
        buildSun()
        buildLights()
        buildCamera()
        buildAmbientParticles()
        buildBurstTemplates()
    }

    // MARK: - Hintergrund / Fog

    private func setupBackgroundAndFog() {
        scene.background.contents = Palette.waterDeep
        scene.fogColor = Palette.fogNear
        scene.fogStartDistance = 8
        scene.fogEndDistance = 30
        scene.fogDensityExponent = 1.6
    }

    private static func makeWaterNode() -> SCNNode {
        let floor = SCNFloor()
        floor.reflectivity = 0.35
        floor.reflectionFalloffEnd = 9
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = Palette.waterDeep
        material.roughness.contents = 0.15
        material.metalness.contents = 0.2
        floor.materials = [material]
        return SCNNode(geometry: floor)
    }

    private static func makeFogDisc() -> (SCNNode, SCNMaterial) {
        let plane = SCNPlane(width: 60, height: 60)
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = Palette.fogNear
        material.emission.contents = Palette.fogNear
        material.transparency = 0.32
        material.isDoubleSided = true
        material.blendMode = .add
        material.writesToDepthBuffer = false
        plane.materials = [material]
        let node = SCNNode(geometry: plane)
        node.eulerAngles.x = -.pi / 2
        node.position = SCNVector3(0, fogLevelHeights[0], 0)
        node.name = "fogDisc"
        return (node, material)
    }

    // MARK: - Insel-Gestein

    private func buildIslandRock() {
        let layout: [(SCNVector3, Float, SCNVector3)] = [
            (SCNVector3(0.0, 0.05, 0.0), 0.62, SCNVector3(-0.15, 0.3, 0.05)),
            (SCNVector3(0.55, -0.05, 0.2), 0.46, SCNVector3(0.2, -0.4, 0.1)),
            (SCNVector3(-0.5, 0.0, 0.35), 0.5, SCNVector3(0.1, 0.9, -0.2)),
            (SCNVector3(0.1, -0.1, -0.55), 0.44, SCNVector3(-0.25, -0.6, 0.15)),
            (SCNVector3(-0.35, -0.08, -0.4), 0.4, SCNVector3(0.3, 1.4, -0.1)),
            (SCNVector3(0.6, 0.12, -0.25), 0.36, SCNVector3(-0.1, 2.0, 0.2)),
            (SCNVector3(-0.15, 0.18, 0.05), 0.3, SCNVector3(0.2, -1.1, -0.25)),
        ]
        for (position, radius, tilt) in layout {
            let node = SCNNode(geometry: IslandGeometry.flatShadedIcosahedron(radius: radius))
            let material = SCNMaterial()
            material.lightingModel = .physicallyBased
            material.diffuse.contents = Palette.islandRock
            material.roughness.contents = 0.85
            material.metalness.contents = 0.05
            node.geometry?.materials = [material]
            node.position = position
            node.eulerAngles = tilt
            islandRockGroup.addChildNode(node)
            islandRockMaterials.append(material)
        }
    }

    // MARK: - Fünf Knoten

    private func buildIslandNodes() {
        // Unregelmäßiger Ring: Winkel und Radius bewusst nicht gleichmäßig verteilt.
        let slots: [(id: String, angleDeg: Float, radius: Float, height: Float)] = [
            ("glowing1", 18, 0.95, 0.62),
            ("lukewarm1", 95, 0.72, 0.58),
            ("cold1", 152, 0.88, 0.5),
            ("glowing2", 231, 0.68, 0.6),
            ("lukewarm2", 308, 0.9, 0.55),
        ]
        for slot in slots {
            let rad = slot.angleDeg * .pi / 180
            let position = SCNVector3(cos(rad) * slot.radius, slot.height, sin(rad) * slot.radius)
            let family = Self.family(ofNodeID: slot.id)
            let (node, material) = Self.makeCrystalNode(family: family)
            node.position = position
            node.name = slot.id
            islandRockGroup.addChildNode(node)
            runIdlePulse(on: node, material: material, family: family)

            let (ticks, tickMaterials) = Self.makeChargeRing(segments: 8)
            for tick in ticks { node.addChildNode(tick) }

            islandNodes[slot.id] = IslandNode(
                id: slot.id, family: family, crystalNode: node, material: material,
                ringTicks: ticks, ringMaterials: tickMaterials
            )
        }
    }

    /// Leitet die Familie ("glowing" | "cold" | "lukewarm") aus einer Knoten-ID wie "glowing2" ab.
    static func family(ofNodeID id: String) -> String {
        String(id.reversed().drop(while: { $0.isNumber }).reversed())
    }

    private static func makeCrystalNode(family: String) -> (SCNNode, SCNMaterial) {
        let node = SCNNode(geometry: IslandGeometry.flatShadedIcosahedron(radius: 0.18))
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.roughness.contents = 0.2
        material.metalness.contents = 0.35
        switch family {
        case "cold":
            material.diffuse.contents = Palette.nodeCold
            material.emission.contents = UIColor.black
            material.emission.intensity = 0
        default: // glowing & lukewarm: bewusst dieselbe warme Familie
            material.diffuse.contents = Palette.nodeWarmFamily
            material.emission.contents = Palette.nodeWarmFamily
            material.emission.intensity = 1.1
        }
        node.geometry?.materials = [material]
        return (node, material)
    }

    private func runIdlePulse(on node: SCNNode, material: SCNMaterial, family: String) {
        switch family {
        case "glowing":
            node.runAction(Self.pulseAction(period: 1.7, min: 0.9, max: 1.6) { material.emission.intensity = $0 }, forKey: "pulse")
        case "lukewarm":
            node.runAction(Self.irregularPulseAction(period: 1.4, min: 0.85, max: 1.55) { material.emission.intensity = $0 }, forKey: "pulse")
            node.runAction(Self.shimmerAction(period: 3.1, colorA: Palette.nodeWarmFamily, colorB: Palette.nodeWarmShimmer) { material.emission.contents = $0 }, forKey: "shimmer")
        default:
            break // cold: kein Puls, keine Emission
        }
    }

    /// Baut einen Ring aus kleinen "Tick"-Segmenten um den Ursprung — die Füllstands-Anzeige für
    /// `chargeNode(kind:progress:)`. Anfangs unsichtbar (Intensität 0).
    private static func makeChargeRing(segments: Int) -> ([SCNNode], [SCNMaterial]) {
        var ticks: [SCNNode] = []
        var materials: [SCNMaterial] = []
        for i in 0..<segments {
            let angle = Float(i) / Float(segments) * 2 * .pi
            let tick = SCNNode(geometry: SCNBox(width: 0.05, height: 0.14, length: 0.03, chamferRadius: 0.01))
            let material = SCNMaterial()
            material.lightingModel = .constant
            material.diffuse.contents = UIColor.white
            material.emission.contents = UIColor.white
            material.emission.intensity = 0
            material.transparency = 0
            tick.geometry?.materials = [material]
            let radius: Float = 0.34
            tick.position = SCNVector3(cos(angle) * radius, 0, sin(angle) * radius)
            tick.eulerAngles = SCNVector3(0, -angle, 0)
            ticks.append(tick)
            materials.append(material)
        }
        return (ticks, materials)
    }

    // MARK: - Spieler-Licht

    private func buildPlayerLight() {
        let sphere = SCNSphere(radius: 0.12)
        playerLightMaterial.lightingModel = .constant
        playerLightMaterial.diffuse.contents = Palette.lightWarmDefault
        playerLightMaterial.emission.contents = Palette.lightWarmDefault
        sphere.materials = [playerLightMaterial]
        playerLightNode.geometry = sphere
        playerLightNode.name = "playerLight"
        playerLightNode.position = Self.playerLightStartPosition

        playerLight.type = .omni
        playerLight.color = Palette.lightWarmDefault
        playerLight.intensity = 320
        playerLight.attenuationEndDistance = 6
        let lightHolder = SCNNode()
        lightHolder.light = playerLight
        playerLightNode.addChildNode(lightHolder)

        playerLightNode.isHidden = true
        playerLightNode.opacity = 0
        scene.rootNode.addChildNode(playerLightNode)
    }

    // MARK: - Wurzelnetz

    private func buildRoots() {
        rootsMaterial.lightingModel = .physicallyBased
        rootsMaterial.diffuse.contents = Palette.rootsGold
        rootsMaterial.emission.contents = Palette.rootsGold
        rootsMaterial.emission.intensity = 0.55
        rootsMaterial.roughness.contents = 0.35
        rootsMaterial.metalness.contents = 0.5

        islandRockGroup.addChildNode(rootsNode)
        rootsNode.position = SCNVector3(0, -0.35, 0)

        let count = 11
        for i in 0..<count {
            let angle = Float(i) * 2.399963 // Goldwinkel — wirkt organischer als gleichmäßige Teilung
            let length = 0.55 + Float((i * 37) % 5) * 0.12
            let radius: CGFloat = 0.035
            let cylinder = SCNCylinder(radius: radius, height: CGFloat(length))
            cylinder.materials = [rootsMaterial]
            let segment = SCNNode(geometry: cylinder)
            // Zylinder-Achse liegt entlang Y; nach außen/unten kippen und um den Ursprung drehen.
            segment.pivot = SCNMatrix4MakeTranslation(0, Float(length) / 2, 0)
            segment.eulerAngles = SCNVector3(-Float.pi / 2.6, angle, 0)
            segment.position = SCNVector3(0, 0, 0)
            segment.scale = SCNVector3(0.001, 0.001, 0.001)
            rootsNode.addChildNode(segment)
            rootSegments.append(segment)
        }
    }

    // MARK: - Sonne

    private func buildSun() {
        let sphere = SCNSphere(radius: 0.55)
        sunMaterial.lightingModel = .constant
        sunMaterial.diffuse.contents = Palette.sunWarm
        sunMaterial.emission.contents = Palette.sunWarm
        sphere.materials = [sunMaterial]
        sunNode.geometry = sphere
        sunNode.name = "sun"
        sunNode.position = SCNVector3(0, Self.sunHiddenY, -34)

        sunLight.type = .omni
        sunLight.color = Palette.sunWarm
        sunLight.intensity = 0
        sunLight.attenuationEndDistance = 60
        let holder = SCNNode()
        holder.light = sunLight
        sunNode.addChildNode(holder)

        sunNode.isHidden = true
        sunNode.opacity = 0
        scene.rootNode.addChildNode(sunNode)
    }

    // MARK: - Durchbruch-Trieb

    private func buildSprout() {
        let geometry = IslandGeometry.flatShadedIcosahedron(radius: 0.3)
        sproutMaterial.lightingModel = .physicallyBased
        sproutMaterial.diffuse.contents = Palette.crystalCyan
        sproutMaterial.emission.contents = Palette.crystalCyan
        sproutMaterial.emission.intensity = 2.0
        sproutMaterial.roughness.contents = 0.1
        sproutMaterial.metalness.contents = 0.6
        geometry.materials = [sproutMaterial]
        sproutNode.geometry = geometry
        sproutNode.position = SCNVector3(0, 0.35, 0)
        sproutNode.scale = Self.sproutHiddenScale // anfangs Skalierung ~0
        islandRockGroup.addChildNode(sproutNode)
    }

    /// Turm-Silhouette des Triebs: schmal und hoch. `tier2` ist deutlich größer (siehe `breakthrough(tier:)`).
    static let sproutTier1Scale = SCNVector3(0.4, 1.8, 0.4)
    static let sproutTier2Scale = SCNVector3(0.58, 2.6, 0.58)
    static let sproutHiddenScale = SCNVector3(0.0006, 0.0027, 0.0006)

    // MARK: - Licht

    private func buildLights() {
        keyLight.type = .directional
        keyLight.intensity = 480
        keyLight.color = UIColor(red: 1, green: 0.86, blue: 0.68, alpha: 1)
        keyLight.castsShadow = true
        keyLight.shadowMode = .deferred
        keyLight.shadowSampleCount = 4
        keyLight.shadowRadius = 8
        keyLight.shadowColor = UIColor.black.withAlphaComponent(0.6)
        keyLightNode.light = keyLight
        keyLightNode.eulerAngles = SCNVector3(-Float.pi / 3.4, Float.pi / 4.5, 0)
        scene.rootNode.addChildNode(keyLightNode)

        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 55
        ambient.color = UIColor(red: 0.35, green: 0.42, blue: 0.6, alpha: 1)
        ambientLightNode.light = ambient
        scene.rootNode.addChildNode(ambientLightNode)
    }

    // MARK: - Kamera

    private func buildCamera() {
        camera.fieldOfView = 52
        camera.zNear = 0.1
        camera.zFar = 120
        camera.wantsHDR = true
        camera.bloomIntensity = 1.6
        camera.bloomThreshold = 0.5
        camera.bloomBlurRadius = 28
        camera.vignettingIntensity = 0.9
        camera.vignettingPower = 1.3
        camera.screenSpaceAmbientOcclusionIntensity = 0.9
        camera.screenSpaceAmbientOcclusionRadius = 2
        camera.wantsDepthOfField = true
        camera.focusDistance = 5.5
        camera.fStop = 4.2
        camera.exposureOffset = 0.1
        cameraNode.camera = camera
        cameraNode.position = Self.cameraClosePosition
        cameraNode.look(at: Self.cameraLookTarget)
        orbitRig.addChildNode(cameraNode)
        scene.rootNode.addChildNode(orbitRig)
        orbitRig.runAction(.repeatForever(.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 70)), forKey: "drift")
    }

    // MARK: - Partikel

    private func buildAmbientParticles() {
        ambientSparks.birthRate = 40
        ambientSparks.particleLifeSpan = 7
        ambientSparks.particleLifeSpanVariation = 2.5
        ambientSparks.emitterShape = SCNSphere(radius: 4.5)
        ambientSparks.particleSize = 0.045
        ambientSparks.particleSizeVariation = 0.02
        ambientSparks.particleColor = UIColor(red: 0.75, green: 0.88, blue: 1, alpha: 0.9)
        ambientSparks.blendMode = .additive
        ambientSparks.isAffectedByGravity = false
        ambientSparks.particleVelocity = 0.12
        ambientSparks.particleVelocityVariation = 0.08
        ambientSparks.emittingDirection = SCNVector3(0, 1, 0)
        ambientSparks.spreadingAngle = 180
        ambientSparks.particleImage = IslandGeometry.softParticleImage(diameter: 64)
        ambientSparks.isLightingEnabled = false
        let node = SCNNode()
        node.position = SCNVector3(0, 1.4, 0)
        node.addParticleSystem(ambientSparks)
        scene.rootNode.addChildNode(node)
    }

    private func buildBurstTemplates() {
        impactBurstTemplate.loops = false
        impactBurstTemplate.emissionDuration = 0.12
        impactBurstTemplate.birthRate = 500
        impactBurstTemplate.particleLifeSpan = 0.9
        impactBurstTemplate.particleLifeSpanVariation = 0.3
        impactBurstTemplate.particleSize = 0.05
        impactBurstTemplate.particleSizeVariation = 0.02
        impactBurstTemplate.particleVelocity = 1.6
        impactBurstTemplate.particleVelocityVariation = 0.5
        impactBurstTemplate.emitterShape = SCNSphere(radius: 0.05)
        impactBurstTemplate.emittingDirection = SCNVector3(0, 1, 0)
        impactBurstTemplate.spreadingAngle = 80
        impactBurstTemplate.acceleration = SCNVector3(0, -0.6, 0)
        impactBurstTemplate.particleColor = Palette.rootsGold
        impactBurstTemplate.blendMode = .additive
        impactBurstTemplate.isLightingEnabled = false
        impactBurstTemplate.particleImage = IslandGeometry.softParticleImage(diameter: 64)

        breakthroughBurstTemplate.loops = false
        breakthroughBurstTemplate.emissionDuration = 0.5
        breakthroughBurstTemplate.birthRate = 600
        breakthroughBurstTemplate.particleLifeSpan = 1.4
        breakthroughBurstTemplate.particleLifeSpanVariation = 0.4
        breakthroughBurstTemplate.particleSize = 0.06
        breakthroughBurstTemplate.particleSizeVariation = 0.03
        breakthroughBurstTemplate.particleVelocity = 2.4
        breakthroughBurstTemplate.particleVelocityVariation = 0.8
        breakthroughBurstTemplate.emitterShape = SCNSphere(radius: 0.1)
        breakthroughBurstTemplate.emittingDirection = SCNVector3(0, 1, 0)
        breakthroughBurstTemplate.spreadingAngle = 130
        breakthroughBurstTemplate.acceleration = SCNVector3(0, -0.4, 0)
        breakthroughBurstTemplate.particleColor = Palette.crystalCyan
        breakthroughBurstTemplate.blendMode = .additive
        breakthroughBurstTemplate.isLightingEnabled = false
        breakthroughBurstTemplate.particleImage = IslandGeometry.softParticleImage(diameter: 72)
    }

    // MARK: - Hit-Test-Hilfen (für IslandSceneView)

    func islandNodeID(forHitNode node: SCNNode) -> String? {
        var current: SCNNode? = node
        while let n = current {
            if let name = n.name, islandNodes[name] != nil { return name }
            current = n.parent
        }
        return nil
    }

    func isPlayerLight(_ node: SCNNode) -> Bool {
        var current: SCNNode? = node
        while let n = current {
            if n === playerLightNode { return true }
            current = n.parent
        }
        return false
    }

    func isSun(_ node: SCNNode) -> Bool {
        var current: SCNNode? = node
        while let n = current {
            if n === sunNode { return true }
            current = n.parent
        }
        return false
    }

    // MARK: - Wiederverwendbare Animationshilfen

    static func pulseAction(period: TimeInterval, min: CGFloat, max: CGFloat, apply: @escaping (CGFloat) -> Void) -> SCNAction {
        let inner = SCNAction.customAction(duration: period) { _, elapsed in
            let t = (sin((elapsed / CGFloat(period)) * 2 * .pi) + 1) / 2
            apply(min + (max - min) * t)
        }
        return SCNAction.repeatForever(inner)
    }

    static func irregularPulseAction(period: TimeInterval, min: CGFloat, max: CGFloat, apply: @escaping (CGFloat) -> Void) -> SCNAction {
        let outer = period * 9
        let inner = SCNAction.customAction(duration: outer) { _, elapsed in
            let e = Double(elapsed)
            let wave = sin(e * 2 * .pi / period) * 0.65 + sin(e * 2 * .pi / (period * 1.37) + 0.6) * 0.35
            let t = Swift.max(0, Swift.min(1, (wave + 1) / 2))
            apply(min + (Swift.max(min, max) - min) * CGFloat(t))
        }
        return SCNAction.repeatForever(inner)
    }

    static func shimmerAction(period: TimeInterval, colorA: UIColor, colorB: UIColor, apply: @escaping (UIColor) -> Void) -> SCNAction {
        let inner = SCNAction.customAction(duration: period) { _, elapsed in
            let t = (sin((elapsed / CGFloat(period)) * 2 * .pi) + 1) / 2
            apply(Palette.lerp(colorA, colorB, t))
        }
        return SCNAction.repeatForever(inner)
    }
}

// MARK: - Farbpalette (poc-spec.md §2)

enum Palette {
    static let waterDeep = UIColor(levmiHex: "#04040E")
    static let fogNear = UIColor(levmiHex: "#0B0E22")
    static let fogHorizon = UIColor(levmiHex: "#1A2447")
    static let lightWarmDefault = UIColor(levmiHex: "#FFB347")
    static let rootsGold = UIColor(levmiHex: "#FFD37A")
    static let rootsWeak = UIColor(white: 0.55, alpha: 1)
    static let crystalCyan = UIColor(levmiHex: "#7FE7FF")
    static let sunWarm = UIColor(levmiHex: "#FFE3A6")
    static let islandRock = UIColor(red: 0.05, green: 0.055, blue: 0.08, alpha: 1)
    /// Gemeinsame warme Familie für `glowing` UND `lukewarm` — bis zur Setzung ununterscheidbar.
    static let nodeWarmFamily = UIColor(levmiHex: "#FFC46B")
    static let nodeWarmShimmer = UIColor(levmiHex: "#FFA9D6")
    static let nodeCold = UIColor(red: 0.4, green: 0.46, blue: 0.56, alpha: 1)
    static let spentGray = UIColor(white: 0.4, alpha: 1)

    static func lerp(_ a: UIColor, _ b: UIColor, _ t: CGFloat) -> UIColor {
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        let clamped = max(0, min(1, t))
        return UIColor(red: ar + (br - ar) * clamped, green: ag + (bg - ag) * clamped, blue: ab + (bb - ab) * clamped, alpha: aa + (ba - aa) * clamped)
    }
}

extension UIColor {
    convenience init(levmiHex hex: String, alpha: CGFloat = 1) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        var value: UInt64 = 0
        Scanner(string: s).scanHexInt64(&value)
        let r = CGFloat((value & 0xFF0000) >> 16) / 255
        let g = CGFloat((value & 0x00FF00) >> 8) / 255
        let b = CGFloat(value & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}

// MARK: - Geometrie-/Bild-Helfer (übernommen und bereinigt aus Spikes/SceneKitSpike.swift)

enum IslandGeometry {
    /// Flat-shaded Ikosaeder (jede Facette bekommt ihre eigenen Vertices/Normalen).
    static func flatShadedIcosahedron(radius: Float) -> SCNGeometry {
        let t = Float((1.0 + sqrt(5.0)) / 2.0)
        let raw: [(Float, Float, Float)] = [
            (-1, t, 0), (1, t, 0), (-1, -t, 0), (1, -t, 0),
            (0, -1, t), (0, 1, t), (0, -1, -t), (0, 1, -t),
            (t, 0, -1), (t, 0, 1), (-t, 0, -1), (-t, 0, 1),
        ]
        let base = raw.map { simd_normalize(SIMD3<Float>($0.0, $0.1, $0.2)) * radius }
        let faces: [[Int]] = [
            [0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
            [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
            [3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
            [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1],
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

    /// Weiches, radial ausgeblendetes Partikelbild (für additive Funken/Bursts).
    static func softParticleImage(diameter: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter))
        return renderer.image { ctx in
            let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor] as CFArray
            let space = CGColorSpaceCreateDeviceRGB()
            guard let grad = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1]) else { return }
            let c = CGPoint(x: diameter / 2, y: diameter / 2)
            ctx.cgContext.drawRadialGradient(grad, startCenter: c, startRadius: 0, endCenter: c, endRadius: diameter / 2, options: [])
        }
    }

    /// Kleine Sanduhr (zwei Spitze-an-Spitze-Kegel) — wird ausschließlich von `drainLight()`
    /// dynamisch erzeugt, NIE vorab am lauwarmen Knoten platziert.
    static func hourglassNode(color: UIColor) -> SCNNode {
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = color
        material.emission.contents = color
        material.emission.intensity = 0.8
        material.transparency = 0.85

        let top = SCNCone(topRadius: 0, bottomRadius: 0.05, height: 0.07)
        top.materials = [material]
        let topNode = SCNNode(geometry: top)
        topNode.position = SCNVector3(0, 0.035, 0)

        let bottom = SCNCone(topRadius: 0.05, bottomRadius: 0, height: 0.07)
        bottom.materials = [material]
        let bottomNode = SCNNode(geometry: bottom)
        bottomNode.position = SCNVector3(0, -0.035, 0)

        let group = SCNNode()
        group.addChildNode(topNode)
        group.addChildNode(bottomNode)
        return group
    }
}
