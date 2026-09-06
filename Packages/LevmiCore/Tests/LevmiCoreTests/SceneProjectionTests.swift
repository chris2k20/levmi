import Foundation
import Testing
@testable import LevmiCore

@Suite("SceneProjection")
struct SceneProjectionTests {

    static let jetzt = TestClock.epoch

    static let layout: [NodeSpec] = [
        NodeSpec(id: 0, kind: .glowing),
        NodeSpec(id: 1, kind: .lukewarm),
        NodeSpec(id: 2, kind: .cold),
        NodeSpec(id: 3, kind: .glowing),
        NodeSpec(id: 4, kind: .lukewarm)
    ]

    @Test("firstLight: nur das Licht, keine Insel")
    func firstLight() {
        let snapshot = SceneProjection.snapshot(of: PlayerState(phase: .firstLight, lightsRemaining: 2))
        #expect(snapshot.islandRevealed == false)
        #expect(snapshot.nodes.isEmpty)
        #expect(snapshot.lightVisible == true)
        #expect(snapshot.sunVisible == false)
        #expect(snapshot.rootWindow == false)
        #expect(snapshot.fogLevel == 0)
        #expect(snapshot.sunProgress == 0)
    }

    @Test("nodes nach einer glühenden Setzung: Insel, Knoten, starke Wurzel")
    func nodesNachGluehenderSetzung() {
        let state = PlayerState(
            phase: .nodes,
            lightsRemaining: 1,
            nodes: Self.layout,
            litNodeIDs: [0],
            nodeOutcomes: [.glowing],
            placements: [.fixture(0, .glowing, at: Self.jetzt)]
        )
        let snapshot = SceneProjection.snapshot(of: state)
        #expect(snapshot.islandRevealed == true)
        #expect(snapshot.nodes == Self.layout)
        #expect(snapshot.litNodeIDs == [0])
        #expect(snapshot.roots == [.strong])
        #expect(snapshot.lightVisible == true)
        #expect(snapshot.sunVisible == false)
    }

    @Test("Lauwarme Setzungen ergeben dünne Wurzeln, kalte gar keine")
    func wurzelstaerken() {
        let state = PlayerState(
            phase: .nodes,
            lightsRemaining: 0,
            nodes: Self.layout,
            litNodeIDs: [1, 0],
            nodeOutcomes: [.lukewarm, .cold, .glowing],
            placements: [
                .fixture(1, .lukewarm, at: Self.jetzt),
                .fixture(2, .cold, at: Self.jetzt),
                .fixture(0, .glowing, at: Self.jetzt)
            ]
        )
        let snapshot = SceneProjection.snapshot(of: state)
        #expect(snapshot.roots == [.weak, .strong])
    }

    @Test("Ohne verbleibendes Licht ist kein Licht zu sehen")
    func keinLichtMehr() {
        var state = PlayerState(phase: .nodes, lightsRemaining: 0, nodes: Self.layout)
        #expect(SceneProjection.snapshot(of: state).lightVisible == false)

        // Kontrolle: mit Licht im Vorrat ist es sichtbar.
        state.lightsRemaining = 1
        #expect(SceneProjection.snapshot(of: state).lightVisible == true)
    }

    @Test("roots: die Sonne steht mit ihrem Fortschritt am Himmel")
    func roots() {
        let state = PlayerState(
            phase: .roots,
            lightsRemaining: 0,
            nodes: Self.layout,
            litNodeIDs: [0, 3],
            placements: [.fixture(0, .glowing, at: Self.jetzt), .fixture(3, .glowing, at: Self.jetzt)],
            sunProgress: 0.42
        )
        let snapshot = SceneProjection.snapshot(of: state)
        #expect(snapshot.sunVisible == true)
        #expect(snapshot.sunProgress == 0.42)
        #expect(snapshot.lightVisible == false)
        #expect(snapshot.roots == [.strong, .strong])
        #expect(snapshot.rootWindow == false)
    }

    @Test("waiting: das Wurzelfenster steht offen")
    func waiting() {
        let state = PlayerState(
            phase: .waiting,
            lightsRemaining: 0,
            nodes: Self.layout,
            litNodeIDs: [0],
            placements: [.fixture(0, .glowing, at: Self.jetzt)],
            closedAt: Self.jetzt,
            readyAt: Self.jetzt.addingTimeInterval(600)
        )
        let snapshot = SceneProjection.snapshot(of: state)
        #expect(snapshot.rootWindow == true)
        #expect(snapshot.islandRevealed == true)
        #expect(snapshot.lightVisible == false)
        #expect(snapshot.fogLevel == 0)
    }

    @Test("proof: kein Wurzelfenster mehr, Nebel noch hoch")
    func proof() {
        let state = PlayerState(
            phase: .proof,
            lightsRemaining: 0,
            nodes: Self.layout,
            litNodeIDs: [0],
            placements: [.fixture(0, .glowing, at: Self.jetzt)],
            days: 0
        )
        let snapshot = SceneProjection.snapshot(of: state)
        #expect(snapshot.rootWindow == false)
        #expect(snapshot.islandRevealed == true)
        #expect(snapshot.fogLevel == 0)
    }

    @Test("idle: der erste Tag hat den Nebel gesenkt")
    func idle() {
        let state = PlayerState(
            phase: .idle,
            lightsRemaining: 0,
            nodes: Self.layout,
            litNodeIDs: [0],
            placements: [.fixture(0, .glowing, at: Self.jetzt)],
            lightColorTile: .zuVielLauwarmes,
            days: 1
        )
        let snapshot = SceneProjection.snapshot(of: state)
        #expect(snapshot.fogLevel == 1)
        #expect(snapshot.lightTile == .zuVielLauwarmes)
        #expect(snapshot.islandRevealed == true)
        #expect(snapshot.rootWindow == false)
    }

    @Test("Die Lichtfarbe kommt aus der ersten Kachel")
    func lichtfarbe() {
        var state = PlayerState(phase: .nodes, lightsRemaining: 1, nodes: Self.layout)
        #expect(SceneProjection.snapshot(of: state).lightTile == nil)
        state.lightColorTile = .zeitWeg
        #expect(SceneProjection.snapshot(of: state).lightTile == .zeitWeg)
    }

    @Test("dawnProof: die zweite Sonne ist sichtbar")
    func dawnProof() {
        let state = PlayerState(
            phase: .dawnProof,
            lightsRemaining: 0,
            nodes: Self.layout,
            litNodeIDs: [0],
            placements: [.fixture(0, .glowing, at: Self.jetzt)],
            sunProgress: 0.3,
            days: 1
        )
        let snapshot = SceneProjection.snapshot(of: state)
        #expect(snapshot.sunVisible == true)
        #expect(snapshot.sunProgress == 0.3)
        #expect(snapshot.fogLevel == 1)
    }
}
