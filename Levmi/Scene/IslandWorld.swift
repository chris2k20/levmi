@preconcurrency import SceneKit
import UIKit
import MediaAccessibility
import simd

/// Baut und besitzt die komplette SceneKit-Welt der Insel: alle Knoten-Referenzen, Materialien und
/// Partikel-Vorlagen. `IslandWorld` kennt nur Rendering — keine Spielregeln, keine Persistenz.
/// `IslandChoreography.swift` (Erweiterung dieser Klasse) bedient die eigentlichen `SceneCommand`s.
///
/// Fünf Knoten pro Nacht, adressiert über IDs `0…4` (siehe `islandNodeOrder`). Welche ID welche
/// Familie (`"glowing"` | `"cold"` | `"lukewarm"`) trägt, entscheidet die Domain und teilt es über
/// `presentNodes(_:)` bzw. `restore(_:)` mit — die Insel selbst legt sich nicht vorab fest.
/// `glowing` und `lukewarm` sehen bis zur Setzung bewusst gleich verführerisch aus.
@MainActor
final class IslandWorld {
    /// Eine der fünf festen Positionen auf dem unregelmäßigen Ring. Existiert unabhängig davon,
    /// welche Familie später hineingelegt wird (das entscheidet `presentNodes`/`restore`).
    struct NodeSlot {
        let id: Int
        let crystalNode: SCNNode
        let material: SCNMaterial
        let ringTicks: [SCNNode]
        let ringMaterials: [SCNMaterial]
        let rootSegments: [SCNNode]
        let rootMaterial: SCNMaterial
    }

    /// Für `restore(_:)` — kompletter Szenenzustand, ohne Animation gesetzt (App-Kill → Wiederherstellung).
    struct Snapshot {
        struct NodeSpec { let id: Int; let kind: String }
        struct RootState { let nodeID: Int; let strong: Bool }
        var islandRevealed: Bool
        var nodes: [NodeSpec]
        var litNodeIDs: Set<Int>
        var roots: [RootState]
        var lightVisible: Bool
        var sunVisible: Bool
        var sunProgress: Double
        var fogLevel: Int
        var lightTint: String?
        var rootWindow: Bool
        var breakthroughTier: String?
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

    // Fünf Knoten-Slots (IDs 0…4), Familie wird erst über `presentNodes`/`restore` zugewiesen.
    private(set) var nodeSlots: [Int: NodeSlot] = [:]
    let islandNodeOrder: [Int] = [0, 1, 2, 3, 4]
    var nodeFamilies: [Int: String] = [:]

    // Choreografie-Buchführung (nur Rendering-Zustand, keine Spielregeln).
    var chargeProgress: [Int: Double] = [:]
    var settledNodeIDs: Set<Int> = []
    /// Merkt sich pro Knoten, ob seine Wurzel stark (gold) oder schwach (grau) ist — für den
    /// Rücksprung, wenn `rootWindow(visible: false)` den Puls beendet.
    var rootStrength: [Int: Bool] = [:]
    var currentLightColor: UIColor = Palette.lightWarmDefault
    var currentFogLevel: Int = 0
    var sunProgressHighWater: Double = 0
    /// Wird am Ende von `breakthrough(tier:)` aufgerufen — die Domain wartet darauf, bevor sie weiterschaltet.
    var onBreakthroughFinished: (() -> Void)?

    // Spieler-Licht
    let playerLightNode = SCNNode()
    let playerLight = SCNLight()
    let playerLightMaterial = SCNMaterial()
    static let playerLightStartPosition = SCNVector3(0, 2.0, 0)

    // Sonne
    let sunNode = SCNNode()
    let sunLight = SCNLight()
    let sunMaterial = SCNMaterial()
    static let sunHiddenY: Float = -3.2
    static let sunRisenY: Float = 9.5
    static let sunZ: Float = -30
    static let keyLightNightColor = UIColor(red: 1, green: 0.86, blue: 0.68, alpha: 1)

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
    // art-direction.md: Kamera-Höhe 1,6 über dem Wasser, Blick ~8° nach unten, Insel auf
    // 8–10 Einheiten Distanz (teilweise im Nebel, klein und fern statt Modell-Viewer-Nähe).
    static let cameraClosePosition = SCNVector3(0, 1.5, 7.0)
    static let cameraOrbitPosition = SCNVector3(0, 1.6, 9.0)
    static let cameraDivePosition = SCNVector3(0, 0.1, 3.0)
    static let cameraBreakthroughPosition = SCNVector3(0, 1.4, 5.0)
    static let cameraLookTarget = SCNVector3(0, 0.6, 0)

    static let islandHiddenY: Float = 0.05
    static let islandRevealedY: Float = 1.15
    static let fogLevelHeights: [Float] = [0.55, 0.38, 0.21, 0.04]

    /// Zielgröße des Triebs je Tier (siehe `breakthrough(tier:)`); "second" > "full" > "half" > "thin".
    static let sproutHiddenScale = SCNVector3(0.0006, 0.0027, 0.0006)
    static func sproutScale(forTier tier: String) -> SCNVector3 {
        switch tier {
        case "thin": return SCNVector3(0.22, 1.5, 0.22)
        case "half": return SCNVector3(0.32, 2.0, 0.32)
        case "second": return SCNVector3(0.58, 2.6, 0.58)
        default: return SCNVector3(0.4, 1.8, 0.4) // "full"
        }
    }

    /// Reduce Motion / Dim Flashing Lights zentral abfragbar — siehe `IslandChoreography`.
    var reduceMotionEnabled: Bool { UIAccessibility.isReduceMotionEnabled }
    /// `MADimFlashingLightsEnabled()` (MediaAccessibility) — es gibt kein `UIAccessibility`-Äquivalent.
    var dimFlashingLightsEnabled: Bool { MADimFlashingLightsEnabled() }

    init() {
        waterNode = Self.makeWaterNode()
        (fogDiscNode, fogDiscMaterial) = Self.makeFogDisc()
        setupBackgroundAndFog()
        scene.rootNode.addChildNode(waterNode)
        scene.rootNode.addChildNode(fogDiscNode)

        scene.rootNode.addChildNode(islandRig)
        islandRig.addChildNode(islandRockGroup)
        islandRig.position = SCNVector3(0, Self.islandHiddenY, 0)
        islandRig.isHidden = true // zusätzlich zur Position verdeckt, bis revealIsland() sie zeigt
        buildIslandRock()
        buildNodeSlots()
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
        // Verlauf statt Flächenfarbe (art-direction.md §1): unten am dunkelsten, zum Horizont ein
        // Hauch heller, oben wieder dunkler — kein harter Bruch zwischen Himmel und Nebel.
        scene.background.contents = IslandGeometry.verticalGradient(
            top: Palette.skyTop, middle: Palette.skyHorizon, bottom: Palette.skyBottom, size: CGSize(width: 4, height: 512)
        )
        scene.fogColor = Palette.fogColor
        scene.fogStartDistance = 6
        scene.fogEndDistance = 22
        scene.fogDensityExponent = 1.8
    }

    private static func makeWaterNode() -> SCNNode {
        let floor = SCNFloor()
        // art-direction.md nennt 0.5/8 — bei der flachen Kamera (Höhe 1.6) streckt das die
        // Spiegelung des Lichts zu einer langen, ausgebrannten Lichtgasse statt eines kompakten
        // zweiten Punkts. Gedämpft, bis „Kern + Spiegelung“ statt „Lichtsäule“ zu sehen ist.
        floor.reflectivity = 0.26
        floor.reflectionFalloffEnd = 4
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = Palette.waterSurface
        // Ursache der "Lichtgasse" war nicht `reflectivity` (die Spiegel-Kopie der Szene), sondern
        // die direkte PBR-Spekularantwort auf das 900-lm-Punktlicht bei niedriger Rauheit — bei
        // flachem Kamerawinkel zieht sich ein glänziger Specular-Highlight bis zum Betrachter.
        // Höhere Rauheit verteilt ihn zu einem weichen Schimmer statt einer harten Säule.
        material.roughness.contents = 0.3
        material.metalness.contents = 0.1
        floor.materials = [material]
        return SCNNode(geometry: floor)
    }

    private static func makeFogDisc() -> (SCNNode, SCNMaterial) {
        let plane = SCNPlane(width: 60, height: 60)
        let material = SCNMaterial()
        material.lightingModel = .constant
        material.diffuse.contents = Palette.fogColor
        material.emission.contents = UIColor.black // rein diffus: darf nie selbst bloomen
        material.transparency = 0.22
        material.isDoubleSided = true
        material.blendMode = .alpha
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
        // "Insel nimmt ~35 % der Breite ein" (art-direction.md) — bei der Distanz aus
        // cameraOrbitPosition (9 Einheiten) muss der Cluster kleiner sein als die reinen
        // Rohradien; 0.7 bringt ihn in die Nähe der Zielgröße, ohne jede Zahl neu zu erfinden.
        let clusterScale: Float = 0.7
        for (rawPosition, rawRadius, tilt) in layout {
            let position = SCNVector3(rawPosition.x * clusterScale, rawPosition.y * clusterScale, rawPosition.z * clusterScale)
            let radius = rawRadius * clusterScale
            let node = SCNNode(geometry: IslandGeometry.flatShadedIcosahedron(radius: radius))
            let material = SCNMaterial()
            material.lightingModel = .physicallyBased
            material.diffuse.contents = Palette.islandRock
            material.roughness.contents = 0.85
            material.metalness.contents = 0.0
            node.geometry?.materials = [material]
            node.position = position
            node.eulerAngles = tilt
            islandRockGroup.addChildNode(node)
            islandRockMaterials.append(material)
        }
    }

    // MARK: - Fünf Knoten-Slots

    private func buildNodeSlots() {
        // Unregelmäßiger Ring: Winkel und Radius bewusst nicht gleichmäßig verteilt.
        // Höhe bewusst ÜBER dem höchsten Gesteinspunkt (~0.47 nach dem 0.7-Schrumpfen) und Radius
        // näher am Zentrum: die Knoten sollen wie eine kleine Krone auf dem Cluster sitzen, nicht
        // an einzelnen Gesteinsstücken hängen, die je nach Winkel gar nicht darunterliegen.
        let slots: [(id: Int, angleDeg: Float, radius: Float, height: Float)] = [
            (0, 18, 0.42, 0.56),
            (1, 95, 0.32, 0.52),
            (2, 152, 0.4, 0.58),
            (3, 231, 0.3, 0.5),
            (4, 308, 0.38, 0.54),
        ]
        for slot in slots {
            let rad = slot.angleDeg * .pi / 180
            let position = SCNVector3(cos(rad) * slot.radius, slot.height, sin(rad) * slot.radius)

            // r 0.11 statt der 0.16 aus art-direction.md: im selben 0.7-Maßstab wie der geschrumpfte
            // Gesteins-Cluster (siehe buildIslandRock), sonst wirken die Knoten überdimensioniert.
            let crystalNode = SCNNode(geometry: IslandGeometry.flatShadedIcosahedron(radius: 0.11))
            let material = SCNMaterial()
            material.lightingModel = .physicallyBased
            material.roughness.contents = 0.2
            material.metalness.contents = 0.35
            crystalNode.geometry?.materials = [material]
            crystalNode.position = position
            crystalNode.name = "node\(slot.id)"
            crystalNode.isHidden = true
            crystalNode.opacity = 0
            islandRockGroup.addChildNode(crystalNode)

            let (ticks, tickMaterials) = Self.makeChargeRing(segments: 8)
            for tick in ticks { crystalNode.addChildNode(tick) }

            let (rootSegments, rootMaterial) = Self.buildRootCluster(around: position, seed: slot.id)
            for segment in rootSegments { islandRockGroup.addChildNode(segment) }

            nodeSlots[slot.id] = NodeSlot(
                id: slot.id, crystalNode: crystalNode, material: material,
                ringTicks: ticks, ringMaterials: tickMaterials,
                rootSegments: rootSegments, rootMaterial: rootMaterial
            )
        }
    }

    /// Konfiguriert Optik + Leerlauf-Puls eines Slots für seine Familie. Wird von `presentNodes`
    /// und `restore` aufgerufen — niemals vorab am lauwarmen Knoten mit einer Warnfarbe/Sanduhr.
    func configureCrystal(slot: NodeSlot, family: String) {
        slot.crystalNode.removeAction(forKey: "pulse")
        slot.crystalNode.removeAction(forKey: "shimmer")
        switch family {
        case "cold":
            slot.material.diffuse.contents = Palette.nodeCold
            slot.material.emission.contents = UIColor.black
            slot.material.emission.intensity = 0
        case "glowing":
            slot.material.diffuse.contents = Palette.nodeGlowing
            slot.material.emission.contents = Palette.nodeGlowing
            slot.material.emission.intensity = 1.4
            // 0,5 Hz — ruhig und stetig (Erkennungsmerkmal, siehe hintGlowing()).
            slot.crystalNode.runAction(Self.pulseAction(period: 2.0, min: 1.0, max: 1.4) { [material = slot.material] in material.emission.intensity = $0 }, forKey: "pulse")
        default: // "lukewarm": bewusst dieselbe warme Familie wie glowing, nur Ton + Puls verraten sie
            slot.material.diffuse.contents = Palette.nodeLukewarm
            slot.material.emission.contents = Palette.nodeLukewarm
            slot.material.emission.intensity = 1.2
            slot.crystalNode.runAction(Self.irregularPulseAction(period: 1.4, min: 0.75, max: 1.2) { [material = slot.material] in material.emission.intensity = $0 }, forKey: "pulse")
            slot.crystalNode.runAction(Self.shimmerAction(period: 3.1, colorA: Palette.nodeLukewarm, colorB: Palette.nodeWarmShimmer) { [material = slot.material] in material.emission.contents = $0 }, forKey: "shimmer")
        }
    }

    /// Baut einen Ring aus kleinen "Tick"-Segmenten um den Ursprung — die Füllstands-Anzeige für
    /// `chargeNode(kind:progress:)`. Anfangs unsichtbar (Intensität 0).
    private static func makeChargeRing(segments: Int) -> ([SCNNode], [SCNMaterial]) {
        var ticks: [SCNNode] = []
        var materials: [SCNMaterial] = []
        for i in 0..<segments {
            let angle = Float(i) / Float(segments) * 2 * .pi
            let tick = SCNNode(geometry: SCNBox(width: 0.035, height: 0.1, length: 0.02, chamferRadius: 0.008))
            let material = SCNMaterial()
            material.lightingModel = .constant
            material.diffuse.contents = UIColor.white
            material.emission.contents = UIColor.white
            material.emission.intensity = 0
            material.transparency = 0
            tick.geometry?.materials = [material]
            let radius: Float = 0.24
            tick.position = SCNVector3(cos(angle) * radius, 0, sin(angle) * radius)
            tick.eulerAngles = SCNVector3(0, -angle, 0)
            ticks.append(tick)
            materials.append(material)
        }
        return (ticks, materials)
    }

    /// Eine kleine Wurzel-Gruppe, die von `position` aus fächerförmig nach außen/unten wächst.
    /// Anfangs Skalierung ~0. Farbe/Emission wird erst von `showRoots`/`restore` gesetzt.
    private static func buildRootCluster(around position: SCNVector3, seed: Int, segmentCount: Int = 5) -> ([SCNNode], SCNMaterial) {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased
        material.diffuse.contents = Palette.rootsGold
        material.roughness.contents = 0.35
        material.metalness.contents = 0.5
        var segments: [SCNNode] = []
        for i in 0..<segmentCount {
            let angle = Float(i) * 2.399963 + Float(seed) * 1.1
            // Kurz und nahezu senkrecht nach unten (Knoten sitzen jetzt hoch über dem Cluster, siehe
            // buildNodeSlots) — die Wurzeln sollen im Gestein verschwinden, nicht seitlich abstehen.
            let length: Float = 0.16 + Float((i * 23 + seed * 7) % 4) * 0.035
            let cylinder = SCNCylinder(radius: 0.014, height: CGFloat(length))
            cylinder.materials = [material]
            let segment = SCNNode(geometry: cylinder)
            segment.pivot = SCNMatrix4MakeTranslation(0, length / 2, 0)
            segment.eulerAngles = SCNVector3(-Float.pi / 2 + Float(i) * 0.05, angle, 0)
            segment.position = position
            segment.scale = SCNVector3(0.001, 0.001, 0.001)
            segments.append(segment)
        }
        return (segments, material)
    }

    // MARK: - Spieler-Licht

    private func buildPlayerLight() {
        let sphere = SCNSphere(radius: 0.12)
        playerLightMaterial.lightingModel = .constant
        playerLightMaterial.diffuse.contents = Palette.lightWarmDefault
        playerLightMaterial.emission.contents = Palette.lightWarmDefault
        playerLightMaterial.emission.intensity = 2.0
        sphere.materials = [playerLightMaterial]
        playerLightNode.geometry = sphere
        playerLightNode.name = "playerLight"
        playerLightNode.position = Self.playerLightStartPosition

        // art-direction.md: kleiner warmer Kern, aber ein "echtes" Punktlicht (900 lm) — das trägt
        // erst zusammen mit der GEDRÜCKTEN Exposure (-0.4) und dem hohen Bloom-Threshold (0.65):
        // dunkle Welt + helle Quelle, nicht mittelhelle Welt + Übersteuerung.
        playerLight.type = .omni
        playerLight.color = Palette.lightWarmDefault
        // 900 lm (Briefwert) sättigt bei niedriger Kamera das unendliche Wasser zu einer riesigen
        // Specular-Wolke, weil das Licht selbst über seine eigene Emission leuchtet, nicht über
        // diese Punktlicht-Intensität — die muss nur die NAHE Umgebung sichtbar anfärben.
        playerLight.intensity = 90
        playerLight.attenuationEndDistance = 4
        let lightHolder = SCNNode()
        lightHolder.light = playerLight
        playerLightNode.addChildNode(lightHolder)

        playerLightNode.isHidden = true
        playerLightNode.opacity = 0
        scene.rootNode.addChildNode(playerLightNode)
    }

    // MARK: - Sonne

    private func buildSun() {
        let sphere = SCNSphere(radius: 0.9)
        sunMaterial.lightingModel = .constant
        sunMaterial.diffuse.contents = Palette.sunRising
        sunMaterial.emission.contents = Palette.sunRising
        sphere.materials = [sunMaterial]
        sunNode.geometry = sphere
        sunNode.name = "sun"
        sunNode.position = SCNVector3(0, Self.sunHiddenY, Self.sunZ)

        sunLight.type = .omni
        sunLight.color = Palette.sunRising
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
        sproutNode.scale = Self.sproutHiddenScale
        sproutNode.isHidden = true
        islandRockGroup.addChildNode(sproutNode)
    }

    // MARK: - Licht

    private func buildLights() {
        // art-direction.md nennt 60 (Nacht) → 450 (voller Aufstieg); 60 ließ die dunkle Insel
        // (#14162A) komplett ohne lesbare Kante verschwinden, daher angehoben auf 130 (siehe
        // sunProgress/dawn/restore — dieselbe Zahl an allen drei Stellen).
        keyLight.type = .directional
        keyLight.intensity = 130
        keyLight.color = Self.keyLightNightColor
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
        ambient.intensity = 22
        ambient.color = UIColor(red: 0.3, green: 0.36, blue: 0.52, alpha: 1)
        ambientLightNode.light = ambient
        scene.rootNode.addChildNode(ambientLightNode)
    }

    // MARK: - Kamera

    private func buildCamera() {
        // Werte 1:1 aus docs/design/art-direction.md.
        camera.fieldOfView = 48
        camera.zNear = 0.1
        camera.zFar = 120
        camera.wantsHDR = true
        camera.bloomIntensity = 1.2
        camera.bloomThreshold = 0.65
        camera.bloomBlurRadius = 22
        camera.vignettingIntensity = 1.0
        camera.vignettingPower = 1.4
        camera.screenSpaceAmbientOcclusionIntensity = 0.6
        camera.screenSpaceAmbientOcclusionRadius = 2
        camera.wantsDepthOfField = true
        camera.focusDistance = 8.5 // auf die Insel, siehe cameraOrbitPosition
        camera.fStop = 5.6
        camera.exposureOffset = -0.4
        camera.averageGray = 0.12
        camera.whitePoint = 1.0
        camera.wantsExposureAdaptation = false // fester Look statt automatischer Anpassung
        cameraNode.camera = camera
        cameraNode.position = Self.cameraClosePosition
        cameraNode.look(at: Self.cameraLookTarget)
        orbitRig.addChildNode(cameraNode)
        scene.rootNode.addChildNode(orbitRig)
        if !reduceMotionEnabled {
            orbitRig.runAction(.repeatForever(.rotateBy(x: 0, y: .pi * 2, z: 0, duration: 70)), forKey: "drift")
        }
    }

    // MARK: - Partikel

    private func buildAmbientParticles() {
        ambientSparks.birthRate = 40
        ambientSparks.particleLifeSpan = 7
        ambientSparks.particleLifeSpanVariation = 2.5
        ambientSparks.emitterShape = SCNSphere(radius: 4.5)
        ambientSparks.particleSize = 0.032
        ambientSparks.particleSizeVariation = 0.015
        ambientSparks.particleColor = UIColor(red: 0.55, green: 0.65, blue: 0.78, alpha: 0.35)
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

    func islandNodeID(forHitNode node: SCNNode) -> Int? {
        var current: SCNNode? = node
        while let n = current {
            if let name = n.name, name.hasPrefix("node"), let id = Int(name.dropFirst(4)), nodeSlots[id] != nil {
                return id
            }
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

    /// Puls aus zwei inkommensurablen Frequenzen — wirkt über eine PoC-Sitzung hinweg unregelmäßig,
    /// bleibt aber < 2 Hz (Flacker-Sicherheit, siehe `IslandChoreography`).
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

    enum ScaleEase { case linear, easeOut, easeInEaseOut }

    /// SceneKit hat keine eingebaute "scale(to: x:y:z:)"-Aktion für nicht-uniforme Zielskalierung —
    /// diese Hilfsfunktion interpoliert `node.scale` manuell (eigene Ease-Kurve statt `timingMode`,
    /// das bei `customAction` nicht greift) über `duration`. Startwert wird beim ersten Tick erfasst.
    static func nonUniformScaleAction(to target: SCNVector3, duration: TimeInterval, ease: ScaleEase = .linear) -> SCNAction {
        final class StartBox { var value: SCNVector3? }
        let box = StartBox()
        return SCNAction.customAction(duration: duration) { node, elapsed in
            if box.value == nil { box.value = node.scale }
            guard let start = box.value else { return }
            let rawT = duration > 0 ? min(max(Double(elapsed) / duration, 0), 1) : 1
            let t: Double
            switch ease {
            case .linear: t = rawT
            case .easeOut: t = 1 - pow(1 - rawT, 3)
            case .easeInEaseOut: t = rawT < 0.5 ? 4 * rawT * rawT * rawT : 1 - pow(-2 * rawT + 2, 3) / 2
            }
            node.scale = SCNVector3(
                start.x + (target.x - start.x) * Float(t),
                start.y + (target.y - start.y) * Float(t),
                start.z + (target.z - start.z) * Float(t)
            )
        }
    }
}

// MARK: - Farbpalette (poc-spec.md §2)

/// Werte 1:1 aus docs/design/art-direction.md — "ein kleines warmes Licht in einer großen,
/// dunklen, kalten Welt". Nicht nach Gefühl ändern, sondern gegen die Prüfliste am Ende der Datei.
enum Palette {
    // Himmel/Hintergrund-Verlauf (kein Blau über ~0.15 Luminanz)
    static let skyBottom = UIColor(levmiHex: "#04040E")
    static let skyHorizon = UIColor(levmiHex: "#0B0E22")
    static let skyTop = UIColor(levmiHex: "#050510")
    static let waterDeep = skyBottom // Rückwärtskompatibel; Hintergrund selbst ist jetzt ein Verlauf.

    static let fogColor = UIColor(levmiHex: "#0A0D1F")
    static let fogDawn = UIColor(levmiHex: "#2B2340")

    static let lightWarmDefault = UIColor(levmiHex: "#FFB347")
    static let rootsGold = UIColor(levmiHex: "#FFD37A")
    static let rootsWeak = UIColor(white: 0.4, alpha: 1)
    static let crystalCyan = UIColor(levmiHex: "#7FE7FF")
    static let sunRising = UIColor(levmiHex: "#FF9A5C")
    static let sunRisen = UIColor(levmiHex: "#FFE0B0")
    static let islandRock = UIColor(levmiHex: "#14162A")
    static let waterSurface = UIColor(levmiHex: "#05060F")

    /// Gemeinsame warme Familie für `glowing` UND `lukewarm` — bis zur Setzung ununterscheidbar
    /// (die Hex-Werte unterscheiden sich nur in der zweiten Nachkommastelle der Sättigung).
    static let nodeGlowing = UIColor(levmiHex: "#FFB347")
    static let nodeLukewarm = UIColor(levmiHex: "#FFC27A")
    static let nodeWarmShimmer = UIColor(levmiHex: "#FFD08A")
    static let nodeCold = UIColor(levmiHex: "#2A2F45")
    static let spentGray = UIColor(white: 0.35, alpha: 1)

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

    /// Vertikaler 3-Stopp-Verlauf für den Szenenhintergrund (art-direction.md: kein harter Bruch
    /// zwischen Himmel und Nebel). `top` erscheint oben im Bild, `bottom` unten.
    static func verticalGradient(top: UIColor, middle: UIColor, bottom: UIColor, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let colors = [top.cgColor, middle.cgColor, bottom.cgColor] as CFArray
            let space = CGColorSpaceCreateDeviceRGB()
            guard let grad = CGGradient(colorsSpace: space, colors: colors, locations: [0, 0.62, 1]) else { return }
            ctx.cgContext.drawLinearGradient(grad, start: CGPoint(x: size.width / 2, y: 0), end: CGPoint(x: size.width / 2, y: size.height), options: [])
        }
    }

    /// Kleine Sanduhr (zwei Spitze-an-Spitze-Kegel) — wird ausschließlich von `drainLight(nodeID:)`
    /// dynamisch erzeugt (oder von `restore` für einen bereits gedrainten Knoten), NIE vorab am
    /// lauwarmen Knoten platziert.
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
        group.name = "hourglass"
        group.addChildNode(topNode)
        group.addChildNode(bottomNode)
        return group
    }
}
