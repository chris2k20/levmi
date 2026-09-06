import Foundation
import Testing
@testable import LevmiCore

@Suite("ProofValidator")
struct ProofValidatorTests {

    /// Wortgleich mit `schnitt.drill.instruction` aus werkstatt.json.
    static let anleitung = """
        Schreib die fünf offenen Dinge auf, die seit über zwei Wochen in deinem Kopf hängen. \
        Markiere jedes mit GLÜHEND oder GRAU. Sag heute zu genau einem GRAUEN ab — eine Nachricht, \
        ein Satz, keine Begründung.
        """

    static func verdict(_ text: String) -> ProofVerdict {
        ProofValidator.validate(text, rules: .standard, drillInstruction: anleitung)
    }

    @Test("Ein leerer Beweis ist leer")
    func leererBeweis() {
        #expect(Self.verdict("") == .empty)
    }

    @Test("Ein Beweis aus Leerzeichen ist leer")
    func nurLeerzeichen() {
        #expect(Self.verdict("   \n\t  ") == .empty)
    }

    @Test("39 Zeichen sind zu kurz")
    func neununddreissigZeichen() {
        let text = "Ich habe Tom heute Mittag abgesagt, ok."
        #expect(text.count == 39)
        #expect(Self.verdict(text) == .tooShort(min: 40))
    }

    @Test("40 Zeichen reichen")
    func vierzigZeichen() {
        let text = "Ich habe Tom heute Mittag kurz abgesagt."
        #expect(text.count == 40)
        #expect(Self.verdict(text) == .accepted)
    }

    @Test("Führende und folgende Leerzeichen zählen nicht mit")
    func leerzeichenZaehlenNicht() {
        let text = "   Ich habe Tom heute Mittag abgesagt, ok.   "
        #expect(text.trimmingCharacters(in: .whitespacesAndNewlines).count == 39)
        #expect(Self.verdict(text) == .tooShort(min: 40))
    }

    @Test("Die abgeschriebene Drill-Anleitung ist kein Beweis")
    func abschriftDerAnleitung() {
        #expect(Self.verdict(Self.anleitung) == .copied)
    }

    @Test("Auch eine umgeschriebene Abschrift wird erkannt")
    func abschriftInAnderemSatzbau() {
        let text = "Also: schreib die fünf offenen Dinge auf, die seit über zwei Wochen im Kopf hängen."
        #expect(Self.verdict(text) == .copied)
    }

    @Test("Ein konkreter eigener Beweis wird angenommen")
    func konkreterBeweisWirdAngenommen() {
        let text = "Heute um 14 Uhr habe ich Tom per Nachricht abgesagt: ein Satz, keine Diskussion."
        #expect(text.count >= 40)
        #expect(Self.verdict(text) == .accepted)
    }
}
