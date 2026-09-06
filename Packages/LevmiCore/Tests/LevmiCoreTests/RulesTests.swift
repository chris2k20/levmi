import Foundation
import Testing
@testable import LevmiCore

@Suite("Rules")
struct RulesTests {

    @Test("Standard: die Sperre nach der Absicht dauert 10 Minuten")
    func standardSperre() {
        #expect(Rules.standard.appliedLock == 600)
    }

    @Test("Standard: das Beweisfenster dauert 24 Stunden, das Rückspiel-Mindestalter 1 Tag")
    func standardFenster() {
        #expect(Rules.standard.proofWindow == 86_400)
        #expect(Rules.standard.replayMinAge == 86_400)
    }

    @Test("Standard: zwei Lichter pro Nacht, 40 Beweiszeichen, 60 Erklärungszeichen")
    func standardMengen() {
        #expect(Rules.standard.lightsPerNight == 2)
        #expect(Rules.standard.minProofChars == 40)
        #expect(Rules.standard.minExplanationChars == 60)
    }

    @Test("Demo: 30 Sekunden Sperre, 10 Minuten Beweisfenster, 1 Minute Rückspiel")
    func demoZeiten() {
        #expect(Rules.demo.appliedLock == 30)
        #expect(Rules.demo.proofWindow == 600)
        #expect(Rules.demo.replayMinAge == 60)
    }

    @Test("Demo verkürzt nur Zeiten und schaltet keine Regel ab")
    func demoSchaltetNichtsAb() {
        #expect(Rules.demo.lightsPerNight == 2)
        #expect(Rules.demo.minProofChars == 40)
        #expect(Rules.demo.minExplanationChars == 60)
        #expect(Rules.demo.lightsPerNight == Rules.standard.lightsPerNight)
        #expect(Rules.demo.minProofChars == Rules.standard.minProofChars)
        #expect(Rules.demo.minExplanationChars == Rules.standard.minExplanationChars)
    }

    @Test("Demo ist in jeder Zeitgröße schneller als Standard")
    func demoIstSchneller() {
        #expect(Rules.demo.appliedLock < Rules.standard.appliedLock)
        #expect(Rules.demo.proofWindow < Rules.standard.proofWindow)
        #expect(Rules.demo.replayMinAge < Rules.standard.replayMinAge)
    }
}
