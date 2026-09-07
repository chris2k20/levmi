import Foundation

// MARK: - Regeln 2–7: das Licht in den Nebel, die fünf Knoten.

extension GameEngine {

    /// Regel 2: `lightDropped` in `firstLight` legt fünf Knoten mit stabilen
    /// IDs 0…4 an, gemischt mit einem deterministischen, aus `createdAt`
    /// geseedeten Shuffle.
    static func reduceLightDropped(_ state: PlayerState, clock: any Clock) -> (PlayerState, [Effect]) {
        var next = state
        let seed = UInt64(max(0, Int64(state.createdAt.timeIntervalSince1970)))
        var rng = SeededGenerator(seed: seed)
        let kinds: [NodeKind] = [.glowing, .glowing, .lukewarm, .lukewarm, .cold].shuffled(using: &rng)
        let nodes = (0..<5).map { NodeSpec(id: $0, kind: kinds[$0]) }

        next.nodes = nodes
        next.phase = .nodes

        return (next, [
            .scene(.revealIsland),
            .haptic(.impact),
            .sound(.impact),
            .scene(.cameraPullBack),
            .scene(.presentNodes(nodes)),
            .persist
        ])
    }

    /// Regeln 3–7: eine Setzung auf einen der fünf Knoten.
    static func reduceLightPlaced(_ state: PlayerState, nodeID: Int, clock: any Clock) -> (PlayerState, [Effect]) {
        guard
            let node = state.nodes.first(where: { $0.id == nodeID }),
            !state.litNodeIDs.contains(nodeID)
        else {
            // Regel 3: unbekannte oder bereits gesetzte ID → unverändert.
            return (state, [])
        }

        var next = state
        next.placements.append(Placement(nodeID: nodeID, kind: node.kind, at: clock.now))
        next.nodeOutcomes.append(node.kind)

        var effects: [Effect]
        var allowsPresentLight = false

        switch node.kind {
        case .glowing:
            // Regel 4: starke Wurzeln, ein Licht weniger, Fortschritt erkannt.
            next.lightsRemaining -= 1
            next.litNodeIDs.append(nodeID)
            advanceStage(&next, principleID: "schnitt", to: .recognized, clock: clock)
            effects = [
                .scene(.impact(nodeID: nodeID)),
                .haptic(.impact),
                .sound(.node(.glowing)),
                .scene(.showRoots(nodeID: nodeID, .strong))
            ]
            allowsPresentLight = true

        case .lukewarm:
            // Regel 5: das Licht ist weg, ersatzlos — und ein Denkfehler-Treffer.
            next.lightsRemaining -= 1
            next.litNodeIDs.append(nodeID)
            // Aus den tatsächlichen Setzungen abgeleitet (nicht hochgezählt): Testzustände
            // dürfen `placements` und `progress` unabhängig voneinander vorbelegen.
            let lukewarmCount = next.placements.filter { $0.kind == .lukewarm }.count
            var progress = next.progress["schnitt"]
                ?? PrincipleProgress(id: "schnitt", stage: .unseen, stageEnteredAt: clock.now)
            progress.fallacyHits["lauwarm-lager"] = lukewarmCount
            next.progress["schnitt"] = progress
            effects = [
                .scene(.drainLight(nodeID: nodeID)),
                .haptic(.drain),
                .sound(.node(.lukewarm)),
                .scene(.showRoots(nodeID: nodeID, .weak))
            ]
            if lukewarmCount == 2 {
                effects.append(.scene(.hintGlowing))
            }
            allowsPresentLight = true

        case .cold:
            // Regel 6: kostet nichts, hilft aber auch nichts.
            let coldCount = next.placements.filter { $0.kind == .cold }.count
            effects = [
                .scene(.thud(nodeID: nodeID)),
                .haptic(.tap),
                .sound(.node(.cold))
            ]
            if coldCount == 2 {
                effects.append(.scene(.hintGlowing))
            }
            allowsPresentLight = false
        }

        // Regel 7: weiter in `nodes`, oder hinüber zur Sonne in `roots`.
        if next.lightsRemaining > 0 && next.placements.count < 4 {
            if allowsPresentLight {
                effects.append(.scene(.presentLight))
            }
        } else {
            next.phase = .roots
            effects.append(.scene(.presentSun))
            effects.append(.persist)
        }

        return (next, effects)
    }
}
