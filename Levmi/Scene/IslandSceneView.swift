@preconcurrency import SceneKit
import SwiftUI
import Synchronization

/// Callbacks der Insel-Szene — das Analogon zu `SceneEvent` aus dem Domain-Vertrag (poc-spec.md
/// §3.1), aber in Zahlen/Strings statt `LevmiCore`-Typen, damit diese Datei ohne Domain-Import
/// auskommt. `nodeID` ist die Knoten-ID `0…4`.
struct IslandSceneHandlers {
    var onLightDropped: () -> Void = {}
    var onNodeHoldBegan: (Int) -> Void = { _ in }
    var onNodeHoldEnded: (_ nodeID: Int, _ completed: Bool) -> Void = { _, _ in }
    var onSunDragged: (Double) -> Void = { _ in }
    var onSunReleased: (Double) -> Void = { _ in }
}

/// Misst Frame-Zeiten auf SceneKits Render-Thread — "Muster B" aus
/// docs/strategy/03-engine-architekt.md §2.8: kein isolierter State, Übergabe ausschließlich über
/// `Mutex`, weil `renderer(_:updateAtTime:)` nicht auf dem MainActor läuft (`MainActor.assumeIsolated`
/// wäre hier ein Crash mit Ansage). Stellt p95 über die letzten ≤120 Frames thread-sicher bereit,
/// für einen späteren Smoke-Test (Budget: p95 ≤ 8 ms im Simulator).
final class FramePacer: NSObject, SCNSceneRendererDelegate, @unchecked Sendable {
    private struct State {
        var lastTimestamp: TimeInterval?
        var samples = [Double](repeating: 0, count: 120)
        var count = 0
        var writeIndex = 0
    }

    private let state = Mutex(State())

    func renderer(_ renderer: any SCNSceneRenderer, updateAtTime time: TimeInterval) {
        state.withLock { s in
            defer { s.lastTimestamp = time }
            guard let last = s.lastTimestamp else { return }
            let deltaMS = (time - last) * 1000
            guard deltaMS.isFinite, deltaMS > 0 else { return }
            s.samples[s.writeIndex] = deltaMS
            s.writeIndex = (s.writeIndex + 1) % s.samples.count
            s.count = min(s.count + 1, s.samples.count)
        }
    }

    /// p95 Frame-Zeit in ms über die letzten ≤120 Frames, `nil` solange keine Samples vorliegen.
    var p95FrameTimeMS: Double? {
        state.withLock { s in
            guard s.count > 0 else { return nil }
            let sorted = s.samples[0..<s.count].sorted()
            let index = min(sorted.count - 1, Int(Double(sorted.count) * 0.95))
            return sorted[index]
        }
    }
}

/// `UIViewRepresentable` um `SCNView` — die Szene wird einmal in `makeUIView` gebaut, `updateUIView`
/// baut sie NIE neu (siehe §2.8 Punkt 2 in der Architektur-Doku), nur `SceneCommand`s danach.
struct IslandSceneView: UIViewRepresentable {
    let world: IslandWorld
    var handlers: IslandSceneHandlers = IslandSceneHandlers()
    var framePacer = FramePacer()

    func makeCoordinator() -> Coordinator {
        Coordinator(world: world, handlers: handlers)
    }

    func makeUIView(context: Context) -> IslandAccessibilitySCNView {
        let view = IslandAccessibilitySCNView(frame: .zero)
        view.world = world
        view.handlers = handlers
        view.scene = world.scene
        view.backgroundColor = .black
        view.antialiasingMode = .multisampling4X
        view.preferredFramesPerSecond = 120
        view.rendersContinuously = true
        view.isPlaying = true
        view.allowsCameraControl = false
        view.pointOfView = world.cameraNode
        view.delegate = framePacer

        let touch = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTouch(_:)))
        touch.minimumPressDuration = 0 // Ring/Drag müssen sofort bei Berührung reagieren
        touch.delegate = context.coordinator
        touch.cancelsTouchesInView = false // SwiftUI-Buttons über der Szene (DebugBar, Demo-Karte) dürfen Touches noch bekommen
        view.addGestureRecognizer(touch)
        context.coordinator.sceneView = view
        return view
    }

    func updateUIView(_ uiView: IslandAccessibilitySCNView, context: Context) {
        uiView.handlers = handlers
        context.coordinator.handlers = handlers
    }

    // MARK: - Coordinator (Gesten)

    @MainActor
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let world: IslandWorld
        var handlers: IslandSceneHandlers
        weak var sceneView: SCNView?

        private enum DragMode: Equatable {
            case none, orbit, light, sun
            case node(Int)
        }

        private var mode: DragMode = .none
        private var lastLocation: CGPoint = .zero
        private var chargeStartedAt: Date?
        /// Nutzertest Ben/Nadine: Ein ruhig aufliegender Finger erzeugt keine `.changed`-Events —
        /// der Ladefortschritt muss von einem Timer getrieben werden, nicht von Bewegung.
        private var chargeTimer: Timer?
        private var sunDragProgress: Double = 0
        /// Für die Tap-vs-Drag-Unterscheidung auf der Sonne (siehe `ended()`): jede Geste setzt
        /// diese in `began()`, unabhängig vom erkannten `mode`.
        private var gestureStartedAt = Date()
        private var gestureStartLocation: CGPoint = .zero
        /// Großzügiger Trefferradius um die projizierte Sonnenposition (siehe `began()`) — die Sonne
        /// selbst ist auf dem Bildschirm klein, und die Nebelscheibe/das Wasser (riesige flache
        /// Ebenen auf ihrem Höhenniveau) gewannen bislang jeden `hitTest` gegen sie (siehe
        /// `IslandWorld.nonInteractiveCategory`). Ein Treffer hier gilt unabhängig vom Hit-Test.
        private static let sunHitRadius: CGFloat = 44
        /// Fortschritts-Schritt pro Tap auf die Sonne — identisch zum VoiceOver-Custom-Action-Wert
        /// in `IslandAccessibilitySCNView.buildAccessibilityElements`, damit Tippen (Zeigefinger)
        /// und Antippen (VoiceOver) sich gleich anfühlen: drei Tipps bringen sie auf voll.
        private static let sunTapStep: Double = 0.34

        init(world: IslandWorld, handlers: IslandSceneHandlers) {
            self.world = world
            self.handlers = handlers
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }

        /// SwiftUI-Overlays (DebugBar, Demo-Karte) liegen NICHT als Subviews der SCNView, sondern
        /// als eigener ZStack-Layer darüber — ohne diese Prüfung nimmt die Long-Press-Erkennung
        /// (minimumPressDuration 0) jeden Touch für sich, bevor er die Buttons erreicht.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            touch.view === sceneView
        }

        @objc func handleTouch(_ gesture: UILongPressGestureRecognizer) {
            guard let view = sceneView else { return }
            let location = gesture.location(in: view)
            switch gesture.state {
            case .began: began(at: location, in: view)
            case .changed: changed(at: location, in: view)
            case .ended, .cancelled, .failed: ended(at: location, in: view)
            default: break
            }
        }

        private func began(at location: CGPoint, in view: SCNView) {
            lastLocation = location
            gestureStartedAt = Date()
            gestureStartLocation = location
            // `.categoryBitMask` schließt die Nebelscheibe und das Wasser aus (siehe
            // `IslandWorld.nonInteractiveCategory`) — beide sind riesige flache Ebenen, deren
            // Hit-Test-Box sonst jeden Kamerastrahl zu einem entfernteren Ziel (z. B. der Sonne)
            // zuerst abfängt (`SCNHitTestOption.searchMode` ist standardmäßig `.closest`).
            let options: [SCNHitTestOption: Any] = [
                .boundingBoxOnly: true,
                .categoryBitMask: 1,
            ]
            let hits = view.hitTest(location, options: options)

            // Großzügiger, hit-test-unabhängiger Fallback für die Sonne: sie ist auf dem Bildschirm
            // klein (ferne Kugel), und selbst ohne die Nebelscheibe/das Wasser im Weg bleibt ein
            // reiner 3D-Hit-Test unnötig streng. Ein Treffer hier zählt zusätzlich zum Hit-Test.
            let sunProjected = view.projectPoint(world.sunNode.presentation.position)
            let sunOnScreen = !world.sunNode.isHidden && sunProjected.z > 0 && sunProjected.z < 1
            let sunScreenPoint = CGPoint(x: CGFloat(sunProjected.x), y: CGFloat(sunProjected.y))
            let nearSun = sunOnScreen && hypot(location.x - sunScreenPoint.x, location.y - sunScreenPoint.y) <= Self.sunHitRadius

            if hits.contains(where: { world.isPlayerLight($0.node) }) {
                mode = .light
                world.cancelIdleAffordance()
            } else if nearSun || hits.contains(where: { world.isSun($0.node) }) {
                mode = .sun
                sunDragProgress = world.sunProgressHighWater
            } else if let id = hits.compactMap({ world.islandNodeID(forHitNode: $0.node) }).first {
                mode = .node(id)
                chargeStartedAt = Date()
                handlers.onNodeHoldBegan(id)
                world.chargeNode(kind: id, progress: 0.02) // sofort sichtbar bei Berührung
                chargeTimer?.invalidate()
                chargeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                    guard let self, case .node(let activeID) = self.mode, let start = self.chargeStartedAt else { return }
                    let progress = min(1, Date().timeIntervalSince(start) / 1.1)
                    self.world.chargeNode(kind: activeID, progress: progress)
                }
            } else {
                mode = .orbit
                world.orbitRig.isPaused = true
            }
        }

        private func changed(at location: CGPoint, in view: SCNView) {
            switch mode {
            case .orbit:
                let dx = location.x - lastLocation.x
                world.orbitRig.eulerAngles.y += Float(dx) * 0.006
                lastLocation = location
            case .light:
                let dy = location.y - lastLocation.y
                lastLocation = location
                var position = world.playerLightNode.position
                position.y -= Float(dy) * 0.012
                position.y = max(-0.6, min(4.0, position.y))
                world.playerLightNode.position = position
            case .sun:
                let dy = lastLocation.y - location.y // nach oben ziehen = Fortschritt steigt
                lastLocation = location
                sunDragProgress = max(0, min(1, sunDragProgress + Double(dy) / 260.0))
                handlers.onSunDragged(sunDragProgress)
                world.sunProgress(sunDragProgress)
            case .node(let id):
                guard let start = chargeStartedAt else { return }
                let progress = min(1, Date().timeIntervalSince(start) / 1.1)
                world.chargeNode(kind: id, progress: progress)
            case .none:
                break
            }
        }

        private func ended(at location: CGPoint, in view: SCNView) {
            defer {
                mode = .none
                chargeStartedAt = nil
                chargeTimer?.invalidate()
                chargeTimer = nil
            }
            switch mode {
            case .orbit:
                world.orbitRig.isPaused = false
            case .light:
                let fogHeight = IslandWorld.fogLevelHeights[world.currentFogLevel]
                if world.playerLightNode.position.y <= fogHeight + 0.15 {
                    handlers.onLightDropped()
                } else {
                    world.presentLight() // nicht tief genug gezogen: zurück zur Startposition
                }
            case .sun:
                // Kurzes Antippen (kein Drag) durchläuft `changed()` nie, `sunDragProgress` bliebe
                // beim alten Wert stehen — genau das Verhalten aus dem Bug-Report ("dreimaliges
                // Tippen registriert keinen Fortschritt"). Tap-Erkennung wie bei den Knoten-Holds:
                // kurze Dauer, kaum Bewegung. Schrittgröße identisch zur VoiceOver-Custom-Action.
                let elapsed = Date().timeIntervalSince(gestureStartedAt)
                let moved = hypot(location.x - gestureStartLocation.x, location.y - gestureStartLocation.y)
                if elapsed < 0.25, moved < 10 {
                    sunDragProgress = min(1, world.sunProgressHighWater + Self.sunTapStep)
                    world.sunProgress(sunDragProgress)
                }
                handlers.onSunReleased(sunDragProgress)
            case .node(let id):
                guard let start = chargeStartedAt else { return }
                let progress = min(1, Date().timeIntervalSince(start) / 1.1)
                let completed = progress >= 0.999
                world.chargeNode(kind: id, progress: completed ? 1.0 : 0.0)
                handlers.onNodeHoldEnded(id, completed)
            case .none:
                break
            }
        }
    }
}

/// `SCNView`-Unterklasse mit sieben VoiceOver-Elementen (fünf Knoten, Licht, Sonne) statt eines
/// einzigen undurchsichtigen Container-Elements. Frames kommen live aus `projectPoint`, weil sich
/// Kamera und Knoten laufend bewegen (Orbit-Drift, Licht-Atmen, Sonnenaufgang).
final class IslandAccessibilitySCNView: SCNView {
    weak var world: IslandWorld?
    var handlers = IslandSceneHandlers()

    override var isAccessibilityElement: Bool {
        get { false }
        set {}
    }

    override var accessibilityElements: [Any]? {
        get { buildAccessibilityElements() }
        set {}
    }

    private func makeElement(label: String, worldPosition: SCNVector3, actionName: String, action: @escaping () -> Bool) -> UIAccessibilityElement? {
        let projected = projectPoint(worldPosition)
        guard projected.z > 0, projected.z < 1 else { return nil } // hinter der Kamera / außerhalb des Frustums
        let element = UIAccessibilityElement(accessibilityContainer: self)
        element.accessibilityLabel = label
        element.accessibilityFrameInContainerSpace = CGRect(x: CGFloat(projected.x) - 26, y: CGFloat(projected.y) - 26, width: 52, height: 52)
        element.accessibilityTraits = .button
        element.accessibilityCustomActions = [UIAccessibilityCustomAction(name: actionName) { _ in action() }]
        return element
    }

    private func buildAccessibilityElements() -> [Any] {
        guard let world else { return [] }
        var elements: [UIAccessibilityElement] = []

        for (index, id) in world.islandNodeOrder.enumerated() {
            guard let slot = world.nodeSlots[id], !slot.crystalNode.isHidden else { continue }
            let position = slot.crystalNode.presentation.convertPosition(SCNVector3(0, 0, 0), to: nil)
            if let element = makeElement(label: "Knoten \(index + 1)", worldPosition: position, actionName: "Licht setzen", action: { [weak self] in
                guard let self, let world = self.world else { return false }
                self.handlers.onNodeHoldBegan(id)
                world.chargeNode(kind: id, progress: 1.0)
                self.handlers.onNodeHoldEnded(id, true)
                return true
            }) {
                elements.append(element)
            }
        }

        if !world.playerLightNode.isHidden {
            let position = world.playerLightNode.presentation.position
            if let element = makeElement(label: "Dein Licht", worldPosition: position, actionName: "In den Nebel setzen", action: { [weak self] in
                self?.handlers.onLightDropped()
                return true
            }) {
                elements.append(element)
            }
        }

        if !world.sunNode.isHidden {
            let position = world.sunNode.presentation.position
            if let element = makeElement(label: "Sonne", worldPosition: position, actionName: "Morgengrauen", action: { [weak self] in
                guard let self, let world = self.world else { return false }
                let next = min(1.0, world.sunProgressHighWater + 0.34)
                self.handlers.onSunDragged(next)
                world.sunProgress(next)
                self.handlers.onSunReleased(next)
                return true
            }) {
                elements.append(element)
            }
        }

        return elements
    }
}
