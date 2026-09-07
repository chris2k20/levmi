@preconcurrency import SceneKit
import UIKit
import QuartzCore

/// Bedient die `SceneCommand`s aus der Domain (poc-spec.md §3.1/§3.3) — Methodennamen sind 1:1 die
/// Befehlsnamen. Reines Rendering: keine Spielregeln, keine Persistenz, kein `LevmiCore`-Import.
///
/// Adressierung: Knoten haben IDs `0…4` (`IslandWorld.islandNodeOrder`). `chargeNode` behält das
/// Argumentlabel `kind` aus dem ursprünglichen Vertrag bei, trägt jetzt aber die ID (nicht mehr die
/// Familie) — konsistent mit `impact`/`showRoots`/`drainLight`/`thud`, die alle `nodeID`/`kind`
/// als Int nehmen. `IslandWorld.nodeFamilies[id]` liefert bei Bedarf die Familie
/// ("glowing" | "cold" | "lukewarm").
///
/// Reduce Motion / Dim Flashing Lights werden zentral hier geprüft (`IslandWorld.reduceMotionEnabled`
/// / `dimFlashingLightsEnabled`), nicht in der View: Kamerafahrten (Dolly, Tauchgang, Push-In) werden
/// bei Reduce Motion zu einer kurzen Überblendung, der 70-s-Drift bleibt aus (siehe
/// `IslandWorld.buildCamera`), es gibt keinen FOV-Puls, Partikel-Bursts werden gedrittelt und bei
/// Dim Flashing Lights zusätzlich abgedunkelt. Puls-Frequenzen bleiben grundsätzlich < 2 Hz.
///
/// Timing-Budget: keine Einzelanimation länger als 2 s, außer dem 70-s-Kamera-Drift.
extension IslandWorld {
    // MARK: - Licht

    func presentLight() {
        cancelIdleAffordance()
        playerLightNode.isHidden = false
        playerLightNode.opacity = 1
        playerLightNode.position = Self.playerLightStartPosition
        playerLightNode.scale = SCNVector3(0.001, 0.001, 0.001)
        playerLightMaterial.diffuse.contents = currentLightColor
        playerLightMaterial.emission.contents = currentLightColor
        playerLight.color = currentLightColor
        playerLight.intensity = 0

        let up = SCNAction.scale(to: 1.15, duration: 0.28)
        up.timingMode = .easeOut
        let down = SCNAction.scale(to: 1.0, duration: 0.22)
        down.timingMode = .easeInEaseOut
        playerLightNode.runAction(.sequence([up, down]), forKey: "presentPop")

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        playerLight.intensity = 320
        SCNTransaction.commit()

        scheduleIdleAffordance()
    }

    /// Muss aufgerufen werden, sobald der Spieler das Licht berührt (Drag-Beginn) — beendet Atmen
    /// und Partikelspur ohne Sprung.
    func cancelIdleAffordance() {
        playerLightNode.removeAction(forKey: "idleBreatheSchedule")
        playerLightNode.removeAction(forKey: "idleBreathe")
        playerLightNode.removeAction(forKey: "idleTrailSchedule")
        if !playerLightNode.isHidden { playerLightNode.scale = SCNVector3(1, 1, 1) }
    }

    private func scheduleIdleAffordance() {
        let startBreathing = SCNAction.run { node in
            let up = SCNAction.scale(to: 1.08, duration: 0.6)
            up.timingMode = .easeInEaseOut
            let down = SCNAction.scale(to: 1.0, duration: 0.6)
            down.timingMode = .easeInEaseOut
            node.runAction(.repeatForever(.sequence([up, down])), forKey: "idleBreathe")
        }
        playerLightNode.runAction(.sequence([.wait(duration: 1.5), startBreathing]), forKey: "idleBreatheSchedule")

        // SCNAction.run-Blöcke laufen auf SceneKits Rendering-Thread, nicht auf dem MainActor
        // (siehe idleTrailTemplate-Kommentar in IslandWorld.swift). Der einmalig gebaute
        // Partikel-Vorlage-Fix allein reichte nicht: `scene.addParticleSystem(_:transform:)` selbst
        // von dort aufzurufen, während SceneKit mitten im Rendering ist, lieferte gelegentlich noch
        // ein winziges, falsch initialisiertes Quadrat (GPU-Ressource wird nebenläufig angelegt).
        // Erst der Hop zurück auf den Main-Thread vor dem eigentlichen Scene-Graph-Zugriff behebt es
        // vollständig — dasselbe Muster wie im `SCNTransaction.completionBlock` in
        // `pulseFieldOfView` weiter unten in dieser Datei.
        let emitTrail = SCNAction.run { [weak self] node in
            let position = node.presentation.position
            DispatchQueue.main.async {
                self?.spawnIdleTrail(from: position)
            }
        }
        let loop = SCNAction.repeatForever(.sequence([emitTrail, .wait(duration: 3.0)]))
        playerLightNode.runAction(.sequence([.wait(duration: 3.0), loop]), forKey: "idleTrailSchedule")
    }

    /// Kopiert `idleTrailTemplate` statt bei jedem Aufruf ein neues `SCNParticleSystem` (inkl.
    /// `particleImage`) zu bauen. Dieser Aufruf kommt aus einem `SCNAction.run`-Block, der auf
    /// SceneKits Rendering-Thread läuft, nicht auf dem MainActor — `IslandGeometry.softParticleImage`
    /// (UIGraphicsImageRenderer) dort frisch zu rendern lieferte ein Bild, aus dem SceneKit keine
    /// Textur laden konnte, und fiel auf ein opakes schwarzes Quadrat zurück (Ursache des Bugs
    /// „schwarzes Quadrat unter dem Spieler-Licht"). Die Vorlage entsteht jetzt einmalig auf dem
    /// MainActor in `buildBurstTemplates()`; hier wird nur noch kopiert und die Lichtfarbe gesetzt.
    private func spawnIdleTrail(from position: SCNVector3) {
        guard let ps = idleTrailTemplate.copy() as? SCNParticleSystem else { return }
        ps.particleColor = currentLightColor
        scene.addParticleSystem(ps, transform: SCNMatrix4MakeTranslation(position.x, position.y, position.z))
    }

    func tintLight(hex: String?) {
        let color = hex.map { UIColor(levmiHex: $0) } ?? Palette.lightWarmDefault
        currentLightColor = color
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        playerLightMaterial.diffuse.contents = color
        playerLightMaterial.emission.contents = color
        playerLight.color = color
        SCNTransaction.commit()
    }

    // MARK: - Insel-Reveal & Kamera

    func revealIsland() {
        cancelIdleAffordance()
        playerLightNode.isHidden = true
        playerLightNode.opacity = 0
        islandRig.isHidden = false

        let dipDown = SCNAction.fadeOpacity(to: 0.15, duration: 0.22)
        let dipUp = SCNAction.fadeOpacity(to: 1.0, duration: 0.45)
        fogDiscNode.runAction(.sequence([dipDown, dipUp]), forKey: "fogParts")

        let overshootY: Float = Self.islandRevealedY + 0.18
        let rise = SCNAction.move(to: SCNVector3(0, overshootY, 0), duration: 0.55)
        rise.timingMode = .easeOut
        let ring = SCNAction.run { [weak self] _ in self?.spawnBurst(self!.impactBurstTemplate, atWorldPosition: SCNVector3(0, 0.35, 0)) }
        let settle = SCNAction.move(to: SCNVector3(0, Self.islandRevealedY, 0), duration: 0.35)
        settle.timingMode = .easeInEaseOut
        islandRig.runAction(.sequence([rise, ring, settle]), forKey: "reveal")

        pulseFieldOfView(delta: 3, upDuration: 0.15, downDuration: 0.22)
    }

    func cameraPullBack() {
        moveCamera(to: Self.cameraOrbitPosition, lookAt: Self.cameraLookTarget, duration: 1.2, key: "cameraMove")
    }

    /// Kamerafahrt zwischen zwei festen Positionen. Bei Reduce Motion: kurze Überblendung
    /// (Root-Node kurz abgedunkelt) statt einer Fahrt durch den Raum.
    private func moveCamera(to target: SCNVector3, lookAt: SCNVector3, duration: TimeInterval, key: String) {
        if reduceMotionEnabled {
            let dip = SCNAction.fadeOpacity(to: 0, duration: 0.12)
            let cut = SCNAction.run { [weak self] _ in
                guard let self else { return }
                self.cameraNode.position = target
                self.cameraNode.look(at: lookAt)
            }
            let rise = SCNAction.fadeOpacity(to: 1, duration: 0.18)
            scene.rootNode.runAction(.sequence([dip, cut, rise]), forKey: key + "Crossfade")
            return
        }
        let move = SCNAction.move(to: target, duration: duration)
        move.timingMode = .easeInEaseOut
        let look = SCNAction.customAction(duration: duration) { node, _ in node.look(at: lookAt) }
        cameraNode.runAction(.group([move, look]), forKey: key)
    }

    /// FOV-Puls (±delta Grad). Zwei verkettete Transaktionen: die zweite wird erst im
    /// Completion-Block der ersten gestartet, sonst überschreiben sich beide Animationen, da sie
    /// sonst im selben Sekundenbruchteil committen. Entfällt komplett bei Reduce Motion.
    private func pulseFieldOfView(delta: CGFloat, upDuration: TimeInterval, downDuration: TimeInterval) {
        guard !reduceMotionEnabled else { return }
        let base = camera.fieldOfView
        SCNTransaction.begin()
        SCNTransaction.animationDuration = upDuration
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        SCNTransaction.completionBlock = { [weak self] in
            DispatchQueue.main.async {
                guard let self else { return }
                SCNTransaction.begin()
                SCNTransaction.animationDuration = downDuration
                SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeIn)
                self.camera.fieldOfView = base
                SCNTransaction.commit()
            }
        }
        camera.fieldOfView = base + delta
        SCNTransaction.commit()
    }

    /// Feuert eine Kopie von `template` an `worldPosition`. Bei Reduce Motion gedrittelt, bei
    /// Dim Flashing Lights zusätzlich abgedunkelt (keine Vorgabe verlangt Partikel > 1/3 Budget).
    func spawnBurst(_ template: SCNParticleSystem, atWorldPosition worldPosition: SCNVector3, birthRateOverride: CGFloat? = nil) {
        guard let burst = template.copy() as? SCNParticleSystem else { return }
        if let birthRateOverride { burst.birthRate = birthRateOverride }
        if reduceMotionEnabled { burst.birthRate = burst.birthRate / 3 }
        if dimFlashingLightsEnabled { burst.particleColor = dimmedColor(burst.particleColor) }
        scene.addParticleSystem(burst, transform: SCNMatrix4MakeTranslation(worldPosition.x, worldPosition.y, worldPosition.z))
    }

    private func dimmedColor(_ color: UIColor) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: r * 0.5, green: g * 0.5, blue: b * 0.5, alpha: a)
    }

    // MARK: - Knoten

    /// `specs` weist jeder ID ihre Familie zu — das entscheidet die Domain, nicht die Insel.
    func presentNodes(_ specs: [(id: Int, kind: String)]) {
        // Dolly-In (Bug-Fix Knotenabstand): vergrößert den Bildschirmabstand der fünf Knoten, ohne
        // ihren Insel-Radius allein bis ins Absurde zu treiben (siehe cameraNodesPosition/
        // buildNodeSlots). presentSun() fährt beim Sonnenaufgang wieder auf cameraOrbitPosition
        // zurück. `performCameraDive()` (showRoots) kehrt während der Knoten-Phase ebenfalls hierher
        // zurück, nicht zur weiten Orbit-Position.
        moveCamera(to: Self.cameraNodesPosition, lookAt: Self.cameraLookTarget, duration: 0.7, key: "cameraMove")
        for (index, spec) in specs.enumerated() {
            guard let slot = nodeSlots[spec.id] else { continue }
            nodeFamilies[spec.id] = spec.kind
            configureCrystal(slot: slot, family: spec.kind)

            let node = slot.crystalNode
            node.opacity = 0
            node.scale = SCNVector3(0.001, 0.001, 0.001)
            node.isHidden = false

            let fadeIn = SCNAction.fadeIn(duration: 0.18)
            let scaleUp = SCNAction.scale(to: 1.2, duration: 0.22)
            scaleUp.timingMode = .easeOut
            let settle = SCNAction.scale(to: 1.0, duration: 0.16)
            settle.timingMode = .easeInEaseOut

            let sequence = SCNAction.sequence([
                .wait(duration: Double(index) * 0.26),
                .group([fadeIn, scaleUp]),
                settle,
            ])
            node.runAction(sequence, forKey: "present")
        }
    }

    /// Argumentlabel `kind` aus dem ursprünglichen Vertrag beibehalten, trägt jetzt die Knoten-ID.
    func chargeNode(kind nodeID: Int, progress: Double) {
        guard let slot = nodeSlots[nodeID] else { return }
        let clamped = max(0, min(1, progress))
        let previous = chargeProgress[nodeID] ?? 0
        chargeProgress[nodeID] = clamped
        let isFallingBack = clamped < previous - 0.001

        SCNTransaction.begin()
        SCNTransaction.animationDuration = isFallingBack ? 0.4 : 0.05
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: isFallingBack ? .easeOut : .linear)
        let segments = slot.ringMaterials.count
        for (index, material) in slot.ringMaterials.enumerated() {
            let threshold = Double(index) / Double(segments)
            let lit = clamped > threshold
            material.emission.intensity = lit ? 2.2 : 0
            material.transparency = lit ? 1.0 : 0.0
        }
        SCNTransaction.commit()

        // Kalte Knoten bleiben matt, auch während des Ladens.
        if nodeFamilies[nodeID] != "cold" {
            slot.material.emission.intensity = 1.1 + CGFloat(clamped) * 1.3
        }
        camera.vignettingIntensity = 1.0 + clamped * 0.5
    }

    func impact(nodeID: Int) {
        guard let slot = nodeSlots[nodeID] else { return }
        settledNodeIDs.insert(nodeID)
        chargeProgress[nodeID] = 0
        for material in slot.ringMaterials {
            material.emission.intensity = 0
            material.transparency = 0
        }
        camera.vignettingIntensity = 1.0

        let squash = SCNAction.scale(to: 1.3, duration: 0.08)
        squash.timingMode = .easeOut
        let settle = SCNAction.scale(to: 1.0, duration: 0.35)
        settle.timingMode = .easeOut
        slot.crystalNode.runAction(.sequence([squash, settle]), forKey: "impactBounce")

        // `configureCrystal` lässt für "glowing" eine `repeatForever`-Puls-Action auf
        // `slot.crystalNode` laufen, die `material.emission.intensity` bei JEDEM Frame überschreibt
        // (Custom-Action-Handler laufen auf SceneKits Rendering-Thread, nicht dem MainActor). Ohne
        // `removeAction` hier konkurriert dieser Dauer-Schreiber mit dem direkten Schreiben unten von
        // zwei verschiedenen Threads auf dieselbe Material-Property — ein Data Race auf dem
        // GPU-Uniform-Buffer der Emission, der als Ursache für das opake schwarze Quadrat auf dem
        // gerade getroffenen Knoten in Frage kommt. Erst stoppen, dann exklusiv setzen.
        slot.crystalNode.removeAction(forKey: "pulse")

        // Verschmilzt sichtbar mit dem Licht — bleibt als Wurzel-Anker dauerhaft heller.
        slot.material.emission.intensity = 2.0

        let worldPosition = slot.crystalNode.convertPosition(SCNVector3(0, 0, 0), to: nil)
        spawnBurst(impactBurstTemplate, atWorldPosition: worldPosition)
        pulseFieldOfView(delta: 1.4, upDuration: 0.07, downDuration: 0.18)
    }

    /// Nichts wächst, nichts wird verbraucht: Ring fällt zurück, der Knoten bleibt unverändert nutzbar.
    func thud(nodeID: Int) {
        if let slot = nodeSlots[nodeID] {
            chargeProgress[nodeID] = 0
            for material in slot.ringMaterials {
                material.emission.intensity = 0
                material.transparency = 0
            }
            camera.vignettingIntensity = 1.0
        }
        let nodDown = SCNAction.rotateBy(x: CGFloat(-2 * Double.pi / 180), y: 0, z: 0, duration: 0.09)
        nodDown.timingMode = .easeOut
        let nodUp = SCNAction.rotateBy(x: CGFloat(2 * Double.pi / 180), y: 0, z: 0, duration: 0.16)
        nodUp.timingMode = .easeInEaseOut
        cameraNode.runAction(.sequence([nodDown, nodUp]), forKey: "thud")
    }

    /// Die verbleibenden glühenden (noch nicht gesetzten) Knoten pulsieren kurz betont ruhig und
    /// stetig — ein Erkennungsmerkmal, keine neue Optik.
    func hintGlowing() {
        for (id, family) in nodeFamilies where family == "glowing" && !settledNodeIDs.contains(id) {
            guard let slot = nodeSlots[id] else { continue }
            let material = slot.material
            let hint = SCNAction.customAction(duration: 1.6) { _, elapsed in
                let t = Double(elapsed) / 1.6
                let wave = (sin(t * 4 * .pi) + 1) / 2
                material.emission.intensity = 1.3 + CGFloat(wave) * 1.1
            }
            slot.crystalNode.runAction(hint, forKey: "hint")
        }
    }

    // MARK: - Wurzeln

    /// Wurzeln wachsen vom gesetzten Knoten `nodeID` aus (glühend = stark/gold, lauwarm = dünn/grau).
    /// Kamera taucht dafür 1,5 s unter die Nebelkante (Reduce Motion: Überblendung).
    func showRoots(nodeID: Int, strong: Bool) {
        guard let slot = nodeSlots[nodeID] else { return }
        performCameraDive()
        growRoots(slot: slot, strong: strong)
    }

    private func performCameraDive() {
        let translucent: CGFloat = 0.4
        if reduceMotionEnabled {
            cameraNode.position = Self.cameraDivePosition
            cameraNode.look(at: SCNVector3(0, 0.6, 0))
            for material in islandRockMaterials { material.transparency = translucent }
            let restore = SCNAction.run { [weak self] _ in
                guard let self else { return }
                // showRoots läuft nur während der Knoten-Phase — zurück zur gedollyten Knoten-
                // Position (siehe presentNodes), nicht zur weiten Orbit-Position.
                self.cameraNode.position = Self.cameraNodesPosition
                self.cameraNode.look(at: Self.cameraLookTarget)
                for material in self.islandRockMaterials { material.transparency = 1.0 }
            }
            cameraNode.runAction(.sequence([.wait(duration: 0.5), restore]), forKey: "cameraMove")
            return
        }

        let diveDown = SCNAction.move(to: Self.cameraDivePosition, duration: 0.55)
        diveDown.timingMode = .easeIn
        let lookDown = SCNAction.customAction(duration: 0.55) { node, _ in node.look(at: SCNVector3(0, 0.6, 0)) }
        let fadeRockOut = SCNAction.run { [weak self] _ in
            guard let self else { return }
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            for material in self.islandRockMaterials { material.transparency = translucent }
            SCNTransaction.commit()
        }
        let hold = SCNAction.wait(duration: 0.4)
        // showRoots läuft nur während der Knoten-Phase — zurück zur gedollyten Knoten-Position
        // (siehe presentNodes), nicht zur weiten Orbit-Position.
        let diveUp = SCNAction.move(to: Self.cameraNodesPosition, duration: 0.55)
        diveUp.timingMode = .easeOut
        let lookUp = SCNAction.customAction(duration: 0.55) { node, _ in node.look(at: Self.cameraLookTarget) }
        let fadeRockIn = SCNAction.run { [weak self] _ in
            guard let self else { return }
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.3
            for material in self.islandRockMaterials { material.transparency = 1.0 }
            SCNTransaction.commit()
        }
        cameraNode.runAction(.sequence([
            .group([diveDown, lookDown, fadeRockOut]),
            hold,
            .group([diveUp, lookUp, fadeRockIn]),
        ]), forKey: "cameraMove")
    }

    private func growRoots(slot: NodeSlot, strong: Bool) {
        setRootColor(slot: slot, strong: strong)
        let finalScale: (Float, Float, Float) = strong ? (1, 1, 1) : (0.5, 0.75, 0.5)
        let overshootTarget = SCNVector3(finalScale.0 * 1.12, finalScale.1 * 1.1, finalScale.2 * 1.12)
        let settleTarget = SCNVector3(finalScale.0, finalScale.1, finalScale.2)
        for (index, segment) in slot.rootSegments.enumerated() {
            let delay = Double(index) * 0.04
            let overshoot = Self.nonUniformScaleAction(to: overshootTarget, duration: 0.7, ease: .easeOut)
            let settle = Self.nonUniformScaleAction(to: settleTarget, duration: 0.35, ease: .easeInEaseOut)
            segment.runAction(.sequence([.wait(duration: delay), overshoot, settle]), forKey: "grow")
        }
    }

    private func setRootColor(slot: NodeSlot, strong: Bool) {
        rootStrength[slot.id] = strong
        slot.rootMaterial.diffuse.contents = strong ? Palette.rootsGold : Palette.rootsWeak
        slot.rootMaterial.emission.contents = strong ? Palette.rootsGold : Palette.rootsWeak
        slot.rootMaterial.emission.intensity = strong ? 1.6 : 0.2
    }

    /// Persistentes "Wurzelfenster" (Zwei-Finger-Geste, außerhalb dieser Datei): Insel wird
    /// durchscheinend, alle bereits gewachsenen Wurzeln pulsieren gemeinsam.
    func rootWindow(visible: Bool) {
        let opacity: CGFloat = visible ? 0.35 : 1.0
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.6
        for material in islandRockMaterials { material.transparency = opacity }
        SCNTransaction.commit()

        islandRig.removeAction(forKey: "rootWindowPulse")
        if visible {
            let rootMaterials = nodeSlots.values.map(\.rootMaterial)
            let pulse = Self.pulseAction(period: 1.8, min: 0.8, max: 1.9) { value in
                for material in rootMaterials { material.emission.intensity = value }
            }
            islandRig.runAction(pulse, forKey: "rootWindowPulse")
        } else {
            for (id, slot) in nodeSlots {
                guard let strong = rootStrength[id] else { continue }
                slot.rootMaterial.emission.intensity = strong ? 1.6 : 0.2
            }
        }
    }

    /// Saugt das Licht sichtbar in den gesetzten lauwarmen Knoten `nodeID`. Das Licht ist danach
    /// weg (kein automatischer Ersatz hier — das entscheidet die Domain über `presentLight()`).
    /// Wächst dieselbe dünne graue Wurzel wie `showRoots(nodeID:strong:false)`, aber ohne
    /// Kamera-Tauchgang (die Wurzel bleibt unsichtbar unter der Oberfläche).
    func drainLight(nodeID: Int) {
        guard let slot = nodeSlots[nodeID] else {
            playerLightNode.isHidden = true
            playerLightNode.opacity = 0
            return
        }
        settledNodeIDs.insert(nodeID)
        chargeProgress[nodeID] = 0
        for material in slot.ringMaterials {
            material.emission.intensity = 0
            material.transparency = 0
        }
        camera.vignettingIntensity = 1.0
        let targetWorld = slot.crystalNode.convertPosition(SCNVector3(0, 0, 0), to: nil)

        playerLightNode.isHidden = false
        let travel = SCNAction.move(to: targetWorld, duration: 0.55)
        travel.timingMode = .easeIn
        let shrink = SCNAction.scale(to: 0.05, duration: 0.55)
        shrink.timingMode = .easeIn
        let fade = SCNAction.fadeOut(duration: 0.55)
        let cleanup = SCNAction.run { [weak self] node in
            node.isHidden = true
            node.scale = SCNVector3(1, 1, 1)
            node.opacity = 1
            self?.playerLight.intensity = 320 // zurückgesetzt für den nächsten presentLight()-Aufruf
        }
        playerLightNode.runAction(.sequence([.group([travel, shrink, fade]), cleanup]), forKey: "drain")

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.55
        playerLight.intensity = 0
        SCNTransaction.commit()

        let material = slot.material
        let boost = SCNAction.customAction(duration: 0.55) { _, elapsed in
            let t = elapsed / 0.55
            material.emission.intensity = 1.1 + t * 1.6
        }
        let cooldown = SCNAction.customAction(duration: 0.3) { _, elapsed in
            let t = elapsed / 0.3
            material.emission.intensity = 2.7 - t * 1.7
        }
        slot.crystalNode.runAction(.sequence([boost, cooldown]), forKey: "drainPulse")

        growRoots(slot: slot, strong: false)

        // Erst jetzt erscheint die Sanduhr — Konsequenz, keine Vorwarnung.
        let hourglass = IslandGeometry.hourglassNode(color: Palette.rootsWeak)
        hourglass.opacity = 0
        hourglass.scale = SCNVector3(0.01, 0.01, 0.01)
        hourglass.position = SCNVector3(0, 0.3, 0)
        slot.crystalNode.addChildNode(hourglass)
        let popIn = SCNAction.group([.fadeIn(duration: 0.3), .scale(to: 1.0, duration: 0.4)])
        hourglass.runAction(.sequence([.wait(duration: 0.15), popIn]), forKey: "hourglassIn")
    }

    // MARK: - Sonne / Morgengrauen

    func presentSun() {
        // Dolly zurück von der Knoten-Position (siehe presentNodes) auf die weite Orbit-Position —
        // die Knoten-Phase ist vorbei, die Sonne soll fern und die Insel wieder klein wirken.
        moveCamera(to: Self.cameraOrbitPosition, lookAt: Self.cameraLookTarget, duration: 1.0, key: "cameraMove")
        sunNode.isHidden = false
        sunNode.opacity = 0
        sunNode.scale = SCNVector3(1, 1, 1)
        sunNode.position = SCNVector3(0, Self.sunHiddenY, Self.sunZ)
        sunMaterial.diffuse.contents = Palette.sunRising
        sunMaterial.emission.contents = Palette.sunRising
        sunNode.runAction(.fadeIn(duration: 0.6), forKey: "presentSun")
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.6
        sunLight.color = Palette.sunRising
        sunLight.intensity = 60
        keyLight.intensity = 130
        keyLight.color = Self.keyLightNightColor
        SCNTransaction.commit()
        sunProgressHighWater = 0
    }

    /// Die Sonne beginnt sanft zu glimmern (Emission- und Licht-Puls, < 2 Hz), während sie noch
    /// unter/am Horizont steht — z. B. sobald ein Beweistext lang genug ist. Kein Teil des
    /// Aufstiegs selbst: `sunProgress`/`dawn` überschreiben die Werte, sobald tatsächlich gezogen wird.
    func sunGlimmer(_ on: Bool) {
        sunNode.removeAction(forKey: "glimmerEmission")
        sunNode.removeAction(forKey: "glimmerLight")
        guard on else {
            let baseline = Palette.lerp(Palette.sunRising, Palette.sunRisen, CGFloat(sunProgressHighWater))
            sunMaterial.emission.contents = baseline
            sunMaterial.emission.intensity = 1.0
            sunLight.intensity = CGFloat(60 + sunProgressHighWater * 740)
            return
        }
        sunNode.isHidden = false
        if sunNode.opacity < 0.05 { sunNode.opacity = 1 }
        let material = sunMaterial
        let baseColor = Palette.lerp(Palette.sunRising, Palette.sunRisen, CGFloat(sunProgressHighWater))
        let emissionPulse = Self.pulseAction(period: 1.7, min: 0.5, max: 1.5) { value in
            material.emission.contents = Palette.lerp(baseColor, UIColor.white, (value - 0.5) * 0.18)
            material.emission.intensity = value
        }
        sunNode.runAction(emissionPulse, forKey: "glimmerEmission")
        let light = sunLight
        let baseIntensity = 60 + sunProgressHighWater * 740
        let lightPulse = Self.pulseAction(period: 1.7, min: CGFloat(baseIntensity * 0.5), max: CGFloat(baseIntensity * 1.4 + 40)) { value in
            light.intensity = value
        }
        sunNode.runAction(lightPulse, forKey: "glimmerLight")
    }

    /// Monoton: fällt nie unter den bisher höchsten gemeldeten Wert zurück (auch wenn `p` sinkt,
    /// z. B. weil der Finger zurückrutscht). Läuft während des Ziehens oft pro Sekunde — daher kurze,
    /// weiche Angleichung statt einer langen Animation. Setzt/verlängert den 6-s-Ruhepuls-Timer.
    func sunProgress(_ p: Double) {
        let requested = max(0, min(1, p))
        let clamped = max(requested, sunProgressHighWater)
        sunProgressHighWater = clamped
        scheduleSunIdlePulse()

        let t = CGFloat(clamped)
        let y = Self.sunHiddenY + (Self.sunRisenY - Self.sunHiddenY) * Float(clamped)
        let fogColor = Palette.lerp(Palette.fogColor, Palette.fogDawn, t)
        let sunColor = Palette.lerp(Palette.sunRising, Palette.sunRisen, t)

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.05
        sunNode.position = SCNVector3(0, y, Self.sunZ)
        sunMaterial.diffuse.contents = sunColor
        sunMaterial.emission.contents = sunColor
        sunLight.color = sunColor
        sunLight.intensity = CGFloat(60 + clamped * 740)
        keyLight.intensity = CGFloat(130 + clamped * 320) // 130 (Nacht) → 450 (voller Aufstieg)
        keyLight.color = Palette.lerp(Self.keyLightNightColor, sunColor, t)
        scene.fogColor = fogColor
        fogDiscMaterial.diffuse.contents = fogColor
        fogDiscNode.position.y = Self.fogLevelHeights[currentFogLevel] - Float(clamped) * 0.12
        SCNTransaction.commit()
    }

    /// Nach 6 s ohne weiteren `sunProgress`-Aufruf pulsiert die Sonne leicht (< 1 Hz, flacker-sicher).
    private func scheduleSunIdlePulse() {
        sunNode.removeAction(forKey: "sunIdleSchedule")
        sunNode.removeAction(forKey: "sunIdlePulse")
        sunNode.scale = SCNVector3(1, 1, 1)
        let start = SCNAction.run { node in
            node.runAction(Self.pulseAction(period: 2.2, min: 0.94, max: 1.06) { scale in
                node.scale = SCNVector3(Float(scale), Float(scale), Float(scale))
            }, forKey: "sunIdlePulse")
        }
        sunNode.runAction(.sequence([.wait(duration: 6.0), start]), forKey: "sunIdleSchedule")
    }

    func dawn() {
        sunProgressHighWater = 1
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.8
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        sunNode.position = SCNVector3(0, Self.sunRisenY, Self.sunZ)
        sunMaterial.diffuse.contents = Palette.sunRisen
        sunMaterial.emission.contents = Palette.sunRisen
        sunLight.color = Palette.sunRisen
        sunLight.intensity = 800
        keyLight.intensity = 450 // art-direction.md: voller Aufstieg
        keyLight.color = Palette.sunRisen
        scene.fogColor = Palette.fogDawn
        fogDiscMaterial.diffuse.contents = Palette.fogDawn
        SCNTransaction.commit()
    }

    func fogLevel(_ level: Int) {
        currentFogLevel = max(0, min(Self.fogLevelHeights.count - 1, level))
        let targetY = Self.fogLevelHeights[currentFogLevel]
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        fogDiscNode.position = SCNVector3(0, targetY, 0)
        scene.fogEndDistance = 22 + CGFloat(currentFogLevel) * 6
        SCNTransaction.commit()
    }

    // MARK: - Durchbruch

    /// `tier`: `"full"` (zwei starke Wurzeln, großer Trieb) | `"half"` (mittel) | `"thin"` (dünn,
    /// die Sonne geht trotzdem auf) | `"second"` (größer als "full", mit Nebelabsenkung — der
    /// Aufrufer sollte hier zusätzlich `fogLevel(_:)` erhöhen). Ruft am Ende `onBreakthroughFinished`
    /// auf — die Domain wartet darauf. Bloom-Rampe ≥ 400 ms, kein Blitz.
    func breakthrough(tier: String) {
        let target = Self.sproutScale(forTier: tier)
        let overshoot = SCNVector3(target.x * 1.22, target.y * 1.15, target.z * 1.22)

        let burstCount: CGFloat
        let cameraDuration: TimeInterval
        let bloomBoost: CGFloat
        switch tier {
        case "second": burstCount = 600; cameraDuration = 1.15; bloomBoost = 1.15
        case "full": burstCount = 480; cameraDuration = 1.0; bloomBoost = 1.0
        case "half": burstCount = 320; cameraDuration = 0.85; bloomBoost = 0.7
        default: burstCount = 180; cameraDuration = 0.75; bloomBoost = 0.5 // "thin"
        }

        sproutNode.isHidden = false
        sproutNode.opacity = 1

        let grow = Self.nonUniformScaleAction(to: overshoot, duration: 0.5, ease: .easeOut)
        let settle = Self.nonUniformScaleAction(to: target, duration: 0.35, ease: .easeInEaseOut)
        let burstNow = SCNAction.run { [weak self] node in
            guard let self else { return }
            let world = node.convertPosition(SCNVector3(0, 0, 0), to: nil)
            self.spawnBurst(self.breakthroughBurstTemplate, atWorldPosition: world, birthRateOverride: burstCount)
        }
        let finished = SCNAction.run { [weak self] _ in self?.onBreakthroughFinished?() }
        sproutNode.runAction(.sequence([grow, burstNow, settle, finished]), forKey: "breakthrough")

        guard !reduceMotionEnabled else { return }

        let effectiveBoost = dimFlashingLightsEnabled ? bloomBoost * 0.5 : bloomBoost
        let baseBloom = camera.bloomIntensity
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.45 // ≥ 400 ms Rampe, kein Blitz
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        camera.bloomIntensity = baseBloom + effectiveBoost
        SCNTransaction.commit()
        let bloomFadeBack = SCNAction.run { [weak self] _ in
            guard let self else { return }
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.6
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeIn)
            self.camera.bloomIntensity = baseBloom
            SCNTransaction.commit()
        }
        cameraNode.runAction(.sequence([.wait(duration: 0.45), bloomFadeBack]), forKey: "bloomPulse")

        moveCamera(to: Self.cameraBreakthroughPosition, lookAt: SCNVector3(0, 1.2, 0), duration: cameraDuration, key: "cameraMove")
    }

    // MARK: - Wiederherstellung (App-Kill)

    /// Setzt die komplette Szene OHNE Animation auf `snapshot`. Pflicht für die Rückkehr nach
    /// App-Kill — kein Golden-Path-Replay der Choreografie.
    func restore(_ snapshot: Snapshot) {
        stopAllChoreographyActions()

        SCNTransaction.begin()
        SCNTransaction.disableActions = true
        SCNTransaction.animationDuration = 0
        defer { SCNTransaction.commit() }

        currentLightColor = snapshot.lightTint.map { UIColor(levmiHex: $0) } ?? Palette.lightWarmDefault
        playerLightMaterial.diffuse.contents = currentLightColor
        playerLightMaterial.emission.contents = currentLightColor
        playerLight.color = currentLightColor
        playerLightNode.position = Self.playerLightStartPosition
        playerLightNode.scale = SCNVector3(1, 1, 1)
        playerLightNode.isHidden = !snapshot.lightVisible
        playerLightNode.opacity = snapshot.lightVisible ? 1 : 0
        playerLight.intensity = snapshot.lightVisible ? 320 : 0

        islandRig.position = SCNVector3(0, snapshot.islandRevealed ? Self.islandRevealedY : Self.islandHiddenY, 0)
        islandRig.isHidden = !snapshot.islandRevealed
        for material in islandRockMaterials { material.transparency = snapshot.rootWindow ? 0.35 : 1.0 }

        nodeFamilies.removeAll()
        settledNodeIDs = snapshot.litNodeIDs
        let specifiedIDs = Set(snapshot.nodes.map(\.id))
        for (id, slot) in nodeSlots where !specifiedIDs.contains(id) {
            slot.crystalNode.isHidden = true
            slot.crystalNode.opacity = 0
        }
        for spec in snapshot.nodes {
            guard let slot = nodeSlots[spec.id] else { continue }
            nodeFamilies[spec.id] = spec.kind
            configureCrystal(slot: slot, family: spec.kind)
            slot.crystalNode.isHidden = false
            slot.crystalNode.opacity = 1
            slot.crystalNode.scale = SCNVector3(1, 1, 1)
            slot.crystalNode.childNode(withName: "hourglass", recursively: false)?.removeFromParentNode()
            for material in slot.ringMaterials { material.emission.intensity = 0; material.transparency = 0 }
            chargeProgress[spec.id] = 0

            guard snapshot.litNodeIDs.contains(spec.id) else { continue }
            if spec.kind == "glowing" {
                slot.material.emission.intensity = 2.0
            } else if spec.kind == "lukewarm" {
                slot.material.emission.intensity = 1.0
                let hourglass = IslandGeometry.hourglassNode(color: Palette.rootsWeak)
                hourglass.position = SCNVector3(0, 0.3, 0)
                slot.crystalNode.addChildNode(hourglass)
            }
        }

        let rootedIDs = Set(snapshot.roots.map(\.nodeID))
        for rootState in snapshot.roots {
            guard let slot = nodeSlots[rootState.nodeID] else { continue }
            setRootColor(slot: slot, strong: rootState.strong)
            let s: (Float, Float, Float) = rootState.strong ? (1, 1, 1) : (0.5, 0.75, 0.5)
            for segment in slot.rootSegments { segment.scale = SCNVector3(s.0, s.1, s.2) }
        }
        for (id, slot) in nodeSlots where !rootedIDs.contains(id) {
            for segment in slot.rootSegments { segment.scale = SCNVector3(0.001, 0.001, 0.001) }
        }

        sunProgressHighWater = snapshot.sunProgress
        sunNode.isHidden = !snapshot.sunVisible
        sunNode.opacity = snapshot.sunVisible ? 1 : 0
        sunNode.scale = SCNVector3(1, 1, 1)
        let sunT = CGFloat(snapshot.sunProgress)
        let sunY = Self.sunHiddenY + (Self.sunRisenY - Self.sunHiddenY) * Float(snapshot.sunProgress)
        sunNode.position = SCNVector3(0, sunY, Self.sunZ)
        let sunColor = Palette.lerp(Palette.sunRising, Palette.sunRisen, sunT)
        sunMaterial.diffuse.contents = sunColor
        sunMaterial.emission.contents = sunColor
        sunLight.color = sunColor
        sunLight.intensity = CGFloat(60 + snapshot.sunProgress * 740)
        keyLight.intensity = CGFloat(130 + snapshot.sunProgress * 320)
        keyLight.color = Palette.lerp(Self.keyLightNightColor, sunColor, sunT)
        let fogColor = Palette.lerp(Palette.fogColor, Palette.fogDawn, sunT)
        scene.fogColor = fogColor
        fogDiscMaterial.diffuse.contents = fogColor

        currentFogLevel = max(0, min(Self.fogLevelHeights.count - 1, snapshot.fogLevel))
        fogDiscNode.position = SCNVector3(0, Self.fogLevelHeights[currentFogLevel] - Float(snapshot.sunProgress) * 0.12, 0)
        scene.fogEndDistance = 22 + CGFloat(currentFogLevel) * 6

        if let tier = snapshot.breakthroughTier {
            sproutNode.isHidden = false
            sproutNode.opacity = 1
            sproutNode.scale = Self.sproutScale(forTier: tier)
        } else {
            sproutNode.isHidden = true
            sproutNode.opacity = 0
            sproutNode.scale = Self.sproutHiddenScale
        }
    }

    private func stopAllChoreographyActions() {
        playerLightNode.removeAllActions()
        cameraNode.removeAllActions()
        orbitRig.removeAllActions()
        fogDiscNode.removeAllActions()
        islandRig.removeAllActions()
        sunNode.removeAllActions()
        sproutNode.removeAllActions()
        for slot in nodeSlots.values {
            slot.crystalNode.removeAllActions()
            for segment in slot.rootSegments { segment.removeAllActions() }
        }
    }
}
