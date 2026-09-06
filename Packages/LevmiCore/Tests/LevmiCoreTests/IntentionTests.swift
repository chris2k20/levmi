import Foundation
import Testing
@testable import LevmiCore

@Suite("Intention")
struct IntentionTests {

    /// Fester Kalender, damit „Stunde ≥ 20" unabhängig von der Maschine gilt.
    static let kalender: Calendar = {
        var kalender = Calendar(identifier: .gregorian)
        kalender.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .current
        return kalender
    }()

    static func zeit(_ stunde: Int, _ minute: Int, tag: Int = 4) -> Date {
        var teile = DateComponents()
        teile.year = 2025
        teile.month = 9
        teile.day = tag
        teile.hour = stunde
        teile.minute = minute
        return Self.kalender.date(from: teile) ?? Date(timeIntervalSince1970: 0)
    }

    static func absicht(
        um zeitpunkt: Date,
        rules: Rules = .standard,
        text: String = "Sag zu einer lauwarmen Sache ab. Ein Satz, keine Begründung."
    ) -> Intention {
        Intention.make(
            text: text,
            principleID: "schnitt",
            now: zeitpunkt,
            rules: rules,
            calendar: Self.kalender
        )
    }

    @Test("Am Nachmittag geht die Tür nach der Sperre auf")
    func nachmittags() {
        let jetzt = Self.zeit(14, 0)
        let absicht = Self.absicht(um: jetzt)
        #expect(absicht.earliestProofAt == jetzt.addingTimeInterval(600))
        #expect(absicht.createdAt == jetzt)
    }

    @Test("Das Beweisfenster beginnt an der Tür, nicht bei der Absicht")
    func dueByAusEarliestProofAt() {
        let jetzt = Self.zeit(14, 0)
        let absicht = Self.absicht(um: jetzt)
        #expect(absicht.dueBy == jetzt.addingTimeInterval(600 + 86_400))
        #expect(absicht.dueBy == absicht.earliestProofAt.addingTimeInterval(86_400))
    }

    @Test("Um 19:59 gilt noch die normale Sperre")
    func kurzVorAcht() {
        let jetzt = Self.zeit(19, 59)
        #expect(Self.absicht(um: jetzt).earliestProofAt == jetzt.addingTimeInterval(600))
    }

    @Test("Ab 20 Uhr geht die Tür erst am nächsten Morgen um 6 auf")
    func abAchtUhrAbends() {
        let absicht = Self.absicht(um: Self.zeit(20, 0))
        #expect(absicht.earliestProofAt == Self.zeit(6, 0, tag: 5))
    }

    @Test("Auch um 21:30 wird auf 6 Uhr des Folgetags verschoben")
    func halbZehnAbends() {
        let absicht = Self.absicht(um: Self.zeit(21, 30))
        #expect(absicht.earliestProofAt == Self.zeit(6, 0, tag: 5))
        #expect(absicht.dueBy == Self.zeit(6, 0, tag: 5).addingTimeInterval(86_400))
    }

    @Test("Im Demo-Modus bleibt es auch abends bei 30 Sekunden")
    func demoIgnoriertDieNachtregel() {
        let jetzt = Self.zeit(21, 30)
        let absicht = Self.absicht(um: jetzt, rules: .demo)
        #expect(absicht.earliestProofAt == jetzt.addingTimeInterval(30))
        #expect(absicht.dueBy == jetzt.addingTimeInterval(30 + 600))
    }

    @Test("Text und Prinzip werden übernommen, die ID ist gesetzt")
    func inhaltUndID() {
        let absicht = Self.absicht(um: Self.zeit(14, 0), text: "Sag Tom heute ab.")
        #expect(absicht.text == "Sag Tom heute ab.")
        #expect(absicht.principleID == "schnitt")
        #expect(absicht.id.isEmpty == false)
    }

    @Test("Zwei Absichten bekommen verschiedene IDs")
    func ideenSindEindeutig() {
        let eine = Self.absicht(um: Self.zeit(14, 0))
        let andere = Self.absicht(um: Self.zeit(14, 0))
        #expect(eine.id != andere.id)
    }
}
