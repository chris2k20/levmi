import Foundation
import Testing
@testable import LevmiCore

@Suite("BefundGenerator")
struct BefundGeneratorTests {

    static let jetzt = TestClock.epoch
    static let absichtUm = TestClock.epoch.addingTimeInterval(-2 * T.hour)

    static func zustand(
        pains: [PainTile],
        placements: [Placement],
        proofAt: Date? = nil
    ) -> PlayerState {
        var progress = PrincipleProgress(
            id: "schnitt",
            stage: .applied,
            stageEnteredAt: absichtUm
        )
        if let proofAt {
            progress.proofs = [Proof.fixture(submittedAt: proofAt)]
        }
        return PlayerState(
            phase: .cost,
            createdAt: absichtUm,
            lastOpenedAt: jetzt,
            lightsRemaining: 0,
            nodes: [
                NodeSpec(id: 0, kind: .glowing),
                NodeSpec(id: 1, kind: .lukewarm),
                NodeSpec(id: 2, kind: .cold),
                NodeSpec(id: 3, kind: .glowing),
                NodeSpec(id: 4, kind: .lukewarm)
            ],
            litNodeIDs: placements.filter { $0.kind != .cold }.map(\.nodeID),
            nodeOutcomes: placements.map(\.kind),
            placements: placements,
            pains: pains,
            intention: .fixture(createdAt: absichtUm, earliestProofAt: absichtUm.addingTimeInterval(600)),
            progress: ["schnitt": progress],
            days: 1
        )
    }

    // MARK: - F1

    @Test("F1: gesagt „Zu viel Lauwarmes“, getan zweimal lauwarm")
    func f1_widerspruch() {
        let befund = BefundGenerator.generate(
            state: Self.zustand(
                pains: [.zuVielLauwarmes, .zeitWeg],
                placements: [.fixture(1, .lukewarm), .fixture(4, .lukewarm)]
            ),
            now: Self.jetzt
        )
        #expect(befund.sentence.contains("Zu viel Lauwarmes"))
        #expect(befund.sentence.contains("2-mal"))
        #expect(befund.principleID == "schnitt")
    }

    @Test("F1: die Zahl folgt den tatsächlichen Setzungen")
    func f1_zahlStimmt() {
        let befund = BefundGenerator.generate(
            state: Self.zustand(
                pains: [.zuVielLauwarmes],
                placements: [.fixture(1, .lukewarm), .fixture(0, .glowing)]
            ),
            now: Self.jetzt
        )
        #expect(befund.sentence.contains("1-mal"))
        #expect(befund.sentence.contains("2-mal") == false)
    }

    // MARK: - F2

    @Test("F2: nach dem ersten Lauwarmen nur noch Glühendes")
    func f2_erkanntUndUmgesteuert() {
        let befund = BefundGenerator.generate(
            state: Self.zustand(
                pains: [.zeitWeg],
                placements: [.fixture(1, .lukewarm), .fixture(0, .glowing)],
                proofAt: Self.absichtUm.addingTimeInterval(43 * T.minute)
            ),
            now: Self.jetzt
        )
        #expect(befund.sentence.contains("nach dem ersten Mal erkannt"))
        #expect(befund.sentence.contains("43"))
        #expect(befund.principleID == "schnitt")
    }

    // MARK: - F3

    @Test("F3: erst das Nein, dann die Suche nach dem Glühenden")
    func f3_kaltVorGluehend() {
        let befund = BefundGenerator.generate(
            state: Self.zustand(
                pains: [.keinFortschritt],
                placements: [.fixture(2, .cold), .fixture(0, .glowing)]
            ),
            now: Self.jetzt
        )
        #expect(befund.sentence.contains("bevor du das Glühende suchst"))
        #expect(befund.principleID == "schnitt")
    }

    // MARK: - F4

    @Test("F4: zwei Lichter, zwei Treffer")
    func f4_zweiTreffer() {
        let befund = BefundGenerator.generate(
            state: Self.zustand(
                pains: [.zeitWeg],
                placements: [.fixture(0, .glowing), .fixture(3, .glowing)]
            ),
            now: Self.jetzt
        )
        #expect(befund.sentence.contains("Zwei Lichter, zwei Treffer"))
        #expect(befund.principleID == "schnitt")
    }

    // MARK: - Gemeinsame Zusagen

    @Test("Jeder Fall liefert eine andere Alternative und Evidenz")
    func alleFaelleSindVollstaendig() {
        let faelle: [PlayerState] = [
            Self.zustand(pains: [.zuVielLauwarmes], placements: [.fixture(1, .lukewarm)]),
            Self.zustand(
                pains: [.zeitWeg],
                placements: [.fixture(1, .lukewarm), .fixture(0, .glowing)],
                proofAt: Self.absichtUm.addingTimeInterval(12 * T.minute)
            ),
            Self.zustand(pains: [.zeitWeg], placements: [.fixture(2, .cold), .fixture(0, .glowing)]),
            Self.zustand(pains: [], placements: [.fixture(0, .glowing), .fixture(3, .glowing)])
        ]
        for zustand in faelle {
            let befund = BefundGenerator.generate(state: zustand, now: Self.jetzt)
            #expect(befund.sentence.isEmpty == false)
            #expect(befund.alternative.isEmpty == false)
            #expect(befund.alternative != befund.sentence)
            #expect(befund.evidence.isEmpty == false)
            #expect(befund.principleID == "schnitt")
        }
        #expect(faelle.count == 4)
    }

    @Test("Die vier Fälle liefern vier verschiedene Sätze")
    func vierVerschiedeneSaetze() {
        let saetze = [
            BefundGenerator.generate(
                state: Self.zustand(pains: [.zuVielLauwarmes], placements: [.fixture(1, .lukewarm)]),
                now: Self.jetzt
            ).sentence,
            BefundGenerator.generate(
                state: Self.zustand(
                    pains: [.zeitWeg],
                    placements: [.fixture(1, .lukewarm), .fixture(0, .glowing)],
                    proofAt: Self.absichtUm.addingTimeInterval(12 * T.minute)
                ),
                now: Self.jetzt
            ).sentence,
            BefundGenerator.generate(
                state: Self.zustand(pains: [.zeitWeg], placements: [.fixture(2, .cold), .fixture(0, .glowing)]),
                now: Self.jetzt
            ).sentence,
            BefundGenerator.generate(
                state: Self.zustand(pains: [], placements: [.fixture(0, .glowing), .fixture(3, .glowing)]),
                now: Self.jetzt
            ).sentence
        ]
        #expect(Set(saetze).count == 4)
    }

    @Test("Ohne jede Setzung entsteht trotzdem ein vollständiger Satz")
    func leererZustand() {
        let befund = BefundGenerator.generate(
            state: Self.zustand(pains: [], placements: []),
            now: Self.jetzt
        )
        #expect(befund.sentence.isEmpty == false)
        #expect(befund.alternative.isEmpty == false)
        #expect(befund.evidence.isEmpty == false)
        #expect(befund.principleID == "schnitt")
    }
}
