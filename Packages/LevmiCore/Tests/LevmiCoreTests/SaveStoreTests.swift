import Foundation
import Testing
@testable import LevmiCore

@Suite("SaveStore")
struct SaveStoreTests {

    /// Ein Spielstand mit allen verschachtelten Feldern — nichts darf beim Speichern verloren gehen.
    static func zustand(days: Int = 3) -> PlayerState {
        let t0 = TestClock.epoch
        return PlayerState(
            phase: .waiting,
            createdAt: t0,
            lastOpenedAt: t0.addingTimeInterval(T.hour),
            lightsRemaining: 1,
            lightColorTile: .zuVielLauwarmes,
            pains: [.zuVielLauwarmes, .zeitWeg],
            why: "Mehr Zeit für meine Kinder",
            intention: Intention(
                id: "i1",
                principleID: "schnitt",
                text: "Sag heute zu einer lauwarmen Sache ab.",
                createdAt: t0,
                dueBy: t0.addingTimeInterval(T.day)
            ),
            closedAt: t0.addingTimeInterval(T.hour),
            readyAt: t0.addingTimeInterval(T.hour + 600),
            progress: [
                "schnitt": PrincipleProgress(
                    id: "schnitt",
                    stage: .applied,
                    stageEnteredAt: t0.addingTimeInterval(2 * T.hour),
                    explanation: "Lauwarmes kostet Platz im Kopf.",
                    proofs: [Proof.fixture(submittedAt: t0.addingTimeInterval(2 * T.hour))],
                    fallacyHits: ["lauwarm-lager": 2],
                    ownExample: "Der Beirat, den ich seit Mai vor mir herschiebe."
                )
            ],
            days: days,
            ownSentences: [
                OwnSentence.fixture(id: "s1", createdAt: t0, context: .why),
                OwnSentence.fixture(id: "s2", text: "Zwei Minuten Mut.", createdAt: t0, context: .cost)
            ],
            nodeOutcomes: [.lukewarm, .cold, .glowing],
            befund: Befund(
                sentence: "Dein Muster: Du prüfst das Lauwarme, statt es zu kippen.",
                evidence: ["lauwarm: 1", "lauwarm-lager"],
                principleID: "schnitt"
            ),
            befundAccepted: true
        )
    }

    static func withTempDirectory<R>(_ body: (URL) throws -> R) throws -> R {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("levmi-tests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: url) }
        return try body(url)
    }

    // MARK: - InMemorySaveStore

    @Test("Ein leerer Speicher liefert keinen Spielstand")
    func leererSpeicher() throws {
        let geladen = try InMemorySaveStore().load()
        #expect(geladen == nil)
    }

    @Test("Der Spielstand übersteht den Weg durch den Speicher")
    func rundreiseImSpeicher() throws {
        let store = InMemorySaveStore()
        let state = Self.zustand()
        try store.save(state)
        let geladen = try store.load()
        #expect(geladen == state)
    }

    @Test("Ein zweites Speichern überschreibt das erste")
    func zweitesSpeichernUeberschreibt() throws {
        let store = InMemorySaveStore()
        try store.save(Self.zustand(days: 3))
        try store.save(Self.zustand(days: 7))
        let geladen = try store.load()
        #expect(geladen?.days == 7)
    }

    // MARK: - FileSaveStore

    @Test("Ein leeres Verzeichnis liefert keinen Spielstand")
    func leeresVerzeichnis() throws {
        try Self.withTempDirectory { dir in
            let geladen = try FileSaveStore(directory: dir).load()
            #expect(geladen == nil)
        }
    }

    @Test("Der Spielstand übersteht den Weg über die Platte")
    func rundreiseUeberDiePlatte() throws {
        try Self.withTempDirectory { dir in
            let store = FileSaveStore(directory: dir)
            let state = Self.zustand()
            try store.save(state)
            let geladen = try store.load()
            #expect(geladen == state)
        }
    }

    @Test("Die Datei landet im übergebenen Verzeichnis")
    func dateiLiegtImVerzeichnis() throws {
        try Self.withTempDirectory { dir in
            let store = FileSaveStore(directory: dir)
            try store.save(Self.zustand())
            #expect(FileManager.default.fileExists(atPath: store.fileURL.path))
            #expect(store.fileURL.deletingLastPathComponent().path == dir.path)
        }
    }

    @Test("Ein zweiter Speicher auf demselben Verzeichnis sieht denselben Stand")
    func zweiterSpeicherSiehtDenselbenStand() throws {
        try Self.withTempDirectory { dir in
            try FileSaveStore(directory: dir).save(Self.zustand(days: 9))
            let geladen = try FileSaveStore(directory: dir).load()
            #expect(geladen?.days == 9)
        }
    }

    @Test("Ein unbekanntes Feld im JSON bricht das Laden nicht")
    func unbekanntesFeldBrichtNicht() throws {
        try Self.withTempDirectory { dir in
            let store = FileSaveStore(directory: dir)
            let state = Self.zustand()
            try store.save(state)
            #expect(FileManager.default.fileExists(atPath: store.fileURL.path))

            var dict = try JSONSerialization.jsonObject(with: Data(contentsOf: store.fileURL)) as? [String: Any] ?? [:]
            dict["feldAusEinerNeuerenVersion"] = "kommt aus Welt 2"
            try JSONSerialization.data(withJSONObject: dict).write(to: store.fileURL)

            let geladen = try store.load()
            #expect(geladen == state)
        }
    }
}
