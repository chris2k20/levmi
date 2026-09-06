import Foundation
import Testing
@testable import LevmiCore

@Suite("DayLedger")
struct DayLedgerTests {

    static let start = TestClock.epoch

    @Test("Ohne Beweise gibt es keinen Tag")
    func keineBeweise() {
        #expect(DayLedger.days(after: [], window: T.day) == 0)
    }

    @Test("Ein Beweis ergibt einen Tag")
    func einBeweis() {
        let proofs = [Proof.fixture(submittedAt: Self.start)]
        #expect(DayLedger.days(after: proofs, window: T.day) == 1)
    }

    @Test("Zwei Beweise desselben Prinzips im selben Fenster ergeben einen Tag")
    func zweiBeweiseImFenster() {
        let proofs = [
            Proof.fixture(submittedAt: Self.start),
            Proof.fixture(submittedAt: Self.start.addingTimeInterval(2 * T.hour))
        ]
        #expect(DayLedger.days(after: proofs, window: T.day) == 1)
    }

    @Test("Zwei Beweise desselben Prinzips außerhalb des Fensters ergeben zwei Tage")
    func zweiBeweiseAusserhalbDesFensters() {
        let proofs = [
            Proof.fixture(submittedAt: Self.start),
            Proof.fixture(submittedAt: Self.start.addingTimeInterval(T.day + T.minute))
        ]
        #expect(DayLedger.days(after: proofs, window: T.day) == 2)
    }

    @Test("Zwei Prinzipien am selben Tag ergeben zwei Tage")
    func zweiPrinzipienGleichzeitig() {
        let proofs = [
            Proof.fixture(submittedAt: Self.start, principleID: "schnitt"),
            Proof.fixture(submittedAt: Self.start, principleID: "engstelle")
        ]
        #expect(DayLedger.days(after: proofs, window: T.day) == 2)
    }

    @Test("Die Reihenfolge der Beweise ändert das Ergebnis nicht")
    func reihenfolgeEgal() {
        let früh = Proof.fixture(submittedAt: Self.start)
        let spät = Proof.fixture(submittedAt: Self.start.addingTimeInterval(3 * T.day))
        #expect(DayLedger.days(after: [spät, früh], window: T.day) == 2)
        #expect(DayLedger.days(after: [früh, spät], window: T.day) == 2)
    }

    @Test("Das Demo-Fenster von 10 Minuten zählt schneller")
    func kurzesFenster() {
        let proofs = [
            Proof.fixture(submittedAt: Self.start),
            Proof.fixture(submittedAt: Self.start.addingTimeInterval(11 * T.minute))
        ]
        #expect(DayLedger.days(after: proofs, window: 10 * T.minute) == 2)
        #expect(DayLedger.days(after: proofs, window: T.day) == 1)
    }
}
