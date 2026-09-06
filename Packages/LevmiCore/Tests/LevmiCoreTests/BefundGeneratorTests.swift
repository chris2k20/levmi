import Foundation
import Testing
@testable import LevmiCore

@Suite("BefundGenerator")
struct BefundGeneratorTests {

    static let lauwarmSatz = "Dein Muster: Du prüfst das Lauwarme, statt es zu kippen."
    static let neinZuerstSatz = "Du erkennst ein Nein, bevor du das Glühende suchst."
    static let sofortSatz = "Du erkennst Glühendes sofort. Dein Engpass liegt nicht im Entscheiden, sondern im Wegräumen."

    @Test("Fall 1: wer lauwarm gesetzt hat, bekommt den Lauwarm-Befund")
    func lauwarmerFall() {
        let befund = BefundGenerator.generate(
            pains: [.zuVielLauwarmes, .zeitWeg],
            nodeOutcomes: [.lukewarm, .cold, .glowing],
            fallacyHits: ["lauwarm-lager": 1]
        )
        #expect(befund.sentence == Self.lauwarmSatz)
        #expect(befund.principleID == "schnitt")
    }

    @Test("Fall 1: die Evidenz nennt Anzahl und Denkfehler-ID")
    func lauwarmerFallEvidenz() {
        let befund = BefundGenerator.generate(
            pains: [.zuVielLauwarmes],
            nodeOutcomes: [.lukewarm, .lukewarm, .glowing],
            fallacyHits: ["lauwarm-lager": 2]
        )
        #expect(befund.evidence.isEmpty == false)
        #expect(befund.evidence.contains { $0.contains("2") })
        #expect(befund.evidence.contains { $0.contains("lauwarm-lager") })
    }

    @Test("Fall 2: wer zuerst kalt und dann glühend setzt, erkennt das Nein früher")
    func kaltVorGluehend() {
        let befund = BefundGenerator.generate(
            pains: [.keinFortschritt],
            nodeOutcomes: [.cold, .glowing],
            fallacyHits: [:]
        )
        #expect(befund.sentence == Self.neinZuerstSatz)
        #expect(befund.principleID == "schnitt")
        #expect(befund.evidence.isEmpty == false)
    }

    @Test("Fall 3: wer direkt das Glühende trifft, hat den Engpass im Wegräumen")
    func direktGluehend() {
        let befund = BefundGenerator.generate(
            pains: [.zeitWeg, .immerErreichbar],
            nodeOutcomes: [.glowing],
            fallacyHits: [:]
        )
        #expect(befund.sentence == Self.sofortSatz)
        #expect(befund.principleID == "schnitt")
    }

    @Test("Fall 3: die erste Kachel ist die Evidenz")
    func ersteKachelAlsEvidenz() {
        let befund = BefundGenerator.generate(
            pains: [.zeitWeg, .immerErreichbar],
            nodeOutcomes: [.glowing],
            fallacyHits: [:]
        )
        #expect(befund.evidence.isEmpty == false)
        // Die Kachel darf als Roh-ID oder als Klartext auftauchen, aber sie muss auftauchen.
        #expect(befund.evidence.contains { $0.lowercased().contains("zeit") })
        #expect(befund.evidence.contains { $0.lowercased().contains("erreichbar") } == false)
    }

    @Test("Lauwarm schlägt jede andere Regel")
    func lauwarmHatVorrang() {
        let befund = BefundGenerator.generate(
            pains: [.zeitWeg],
            nodeOutcomes: [.cold, .lukewarm, .glowing],
            fallacyHits: ["lauwarm-lager": 1]
        )
        #expect(befund.sentence == Self.lauwarmSatz)
    }

    @Test("Auch ohne Kacheln und ohne Setzungen entsteht ein vollständiger Befund")
    func leereEingabe() {
        let befund = BefundGenerator.generate(pains: [], nodeOutcomes: [], fallacyHits: [:])
        #expect(befund.sentence.isEmpty == false)
        #expect(befund.evidence.isEmpty == false)
        #expect(befund.principleID == "schnitt")
    }
}
