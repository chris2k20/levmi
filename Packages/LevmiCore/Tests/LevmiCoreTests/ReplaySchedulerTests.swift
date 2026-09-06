import Foundation
import Testing
@testable import LevmiCore

@Suite("ReplayScheduler")
struct ReplaySchedulerTests {

    static let jetzt = TestClock.epoch

    static func satz(_ id: String, alter: TimeInterval, context: OwnSentenceContext = .why) -> OwnSentence {
        OwnSentence.fixture(id: id, text: "Satz \(id)", createdAt: jetzt.addingTimeInterval(-alter), context: context)
    }

    @Test("Ohne eigene Sätze gibt es nichts zu zeigen")
    func keineSaetze() {
        let satz = ReplayScheduler.sentence(from: [], now: Self.jetzt, minAge: T.day, lastShownID: nil)
        #expect(satz == nil)
    }

    @Test("Sätze unterhalb des Mindestalters werden nicht gezeigt")
    func alleZuJung() {
        let saetze = [Self.satz("a", alter: T.hour), Self.satz("b", alter: 23 * T.hour)]
        #expect(ReplayScheduler.sentence(from: saetze, now: Self.jetzt, minAge: T.day, lastShownID: nil) == nil)
        // Kontrolle: mit kleinerem Mindestalter liefert dieselbe Liste einen Satz.
        #expect(ReplayScheduler.sentence(from: saetze, now: Self.jetzt, minAge: T.minute, lastShownID: nil) != nil)
    }

    @Test("Der älteste passende Satz kommt zuerst")
    func aeltesterZuerst() {
        let saetze = [
            Self.satz("neu", alter: 2 * T.day),
            Self.satz("alt", alter: 9 * T.day),
            Self.satz("mittel", alter: 5 * T.day)
        ]
        let satz = ReplayScheduler.sentence(from: saetze, now: Self.jetzt, minAge: T.day, lastShownID: nil)
        #expect(satz?.id == "alt")
    }

    @Test("Genau am Mindestalter wird ein Satz gezeigt")
    func genauAmMindestalter() {
        let saetze = [Self.satz("a", alter: T.day)]
        let satz = ReplayScheduler.sentence(from: saetze, now: Self.jetzt, minAge: T.day, lastShownID: nil)
        #expect(satz?.id == "a")
    }

    @Test("Der zuletzt gezeigte Satz wird übersprungen, wenn es eine Alternative gibt")
    func zuletztGezeigtenUeberspringen() {
        let saetze = [Self.satz("alt", alter: 9 * T.day), Self.satz("juenger", alter: 3 * T.day)]
        let satz = ReplayScheduler.sentence(from: saetze, now: Self.jetzt, minAge: T.day, lastShownID: "alt")
        #expect(satz?.id == "juenger")
    }

    @Test("Ohne Alternative darf der zuletzt gezeigte Satz wiederkommen")
    func ohneAlternativeWiederholen() {
        let saetze = [Self.satz("alt", alter: 9 * T.day), Self.satz("frisch", alter: T.hour)]
        let satz = ReplayScheduler.sentence(from: saetze, now: Self.jetzt, minAge: T.day, lastShownID: "alt")
        #expect(satz?.id == "alt")
    }

    @Test("Kosten-Sätze werden genauso gespielt wie Warum-Sätze")
    func kontextSpieltKeineRolle() {
        let saetze = [Self.satz("kosten", alter: 4 * T.day, context: .cost)]
        let satz = ReplayScheduler.sentence(from: saetze, now: Self.jetzt, minAge: T.day, lastShownID: nil)
        #expect(satz?.id == "kosten")
        #expect(satz?.context == .cost)
    }
}
