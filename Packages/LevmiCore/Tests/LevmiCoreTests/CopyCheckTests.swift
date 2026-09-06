import Foundation
import Testing
@testable import LevmiCore

@Suite("CopyCheck")
struct CopyCheckTests {

    /// Elf Wörter. Alle Testtexte überlappen bewusst kontrolliert mit dieser Quelle.
    static let quelle = "Lauwarmes fuehlt sich nach Sorgfalt an aber es ist reine Lagerhaltung"

    /// Sieben gemeinsame Wörter: „fuehlt sich nach Sorgfalt an aber es"
    static let siebenWoerter = "Bei mir gilt: fuehlt sich nach Sorgfalt an aber es klingt hohl."

    /// Sechs gemeinsame Wörter: „fuehlt sich nach Sorgfalt an aber"
    static let sechsWoerter = "Bei mir gilt: fuehlt sich nach Sorgfalt an aber klingt hohl."

    @Test("Sieben gemeinsame Wörter gelten als Abschrift")
    func siebenWoerterSindAbschrift() {
        #expect(CopyCheck.sharesRun(Self.siebenWoerter, with: [Self.quelle]) == true)
    }

    @Test("Sechs gemeinsame Wörter reichen nicht")
    func sechsWoerterSindKeineAbschrift() {
        #expect(CopyCheck.sharesRun(Self.sechsWoerter, with: [Self.quelle]) == false)
        // Kontrolle: dieselbe Quelle, ein Wort mehr — sonst prüft der Test nichts.
        #expect(CopyCheck.sharesRun(Self.siebenWoerter, with: [Self.quelle]) == true)
    }

    @Test("Groß- und Kleinschreibung ist egal")
    func grossKleinschreibungEgal() {
        #expect(CopyCheck.sharesRun(Self.siebenWoerter.uppercased(), with: [Self.quelle]) == true)
        #expect(CopyCheck.sharesRun(Self.siebenWoerter, with: [Self.quelle.uppercased()]) == true)
    }

    @Test("Satzzeichen sind egal")
    func satzzeichenEgal() {
        let mitZeichen = "Bei mir gilt: fuehlt, sich — nach Sorgfalt; an! aber? es ... klingt hohl."
        #expect(CopyCheck.sharesRun(mitZeichen, with: [Self.quelle]) == true)
    }

    @Test("Es genügt eine einzige passende Quelle")
    func eineVonMehrerenQuellenGenuegt() {
        let andere = "Ein Glasrohr voller Kugeln, eine einzige Stelle ist verengt"
        #expect(CopyCheck.sharesRun(Self.siebenWoerter, with: [andere, Self.quelle]) == true)
        #expect(CopyCheck.sharesRun(Self.siebenWoerter, with: [andere]) == false)
    }

    @Test("minWords ist einstellbar")
    func minWordsEinstellbar() {
        #expect(CopyCheck.sharesRun(Self.sechsWoerter, with: [Self.quelle], minWords: 6) == true)
        #expect(CopyCheck.sharesRun(Self.sechsWoerter, with: [Self.quelle], minWords: 7) == false)
    }

    @Test("Leerer Text und leere Quellen sind keine Abschrift")
    func leereEingabenSindHarmlos() {
        #expect(CopyCheck.sharesRun("", with: [Self.quelle]) == false)
        #expect(CopyCheck.sharesRun(Self.siebenWoerter, with: []) == false)
        // Kontrolle
        #expect(CopyCheck.sharesRun(Self.siebenWoerter, with: [Self.quelle]) == true)
    }
}
