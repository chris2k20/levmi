import Foundation
import Testing
@testable import LevmiCore

@Suite("ContentLoader")
struct ContentLoaderTests {

    @Test("Die Welt werkstatt wird aus Bundle.module geladen")
    func ladeWeltAusBundle() throws {
        let world = try TestContent.werkstatt()
        #expect(world.id == "werkstatt")
        #expect(world.title == "Die Werkstatt")
    }

    @Test("Die Werkstatt enthält genau drei Prinzipien")
    func dreiPrinzipien() throws {
        let world = try TestContent.werkstatt()
        #expect(world.principles.count == 3)
    }

    @Test("Die Prinzipien tragen die vereinbarten IDs in Spielreihenfolge")
    func idsInSpielreihenfolge() throws {
        let world = try TestContent.werkstatt()
        #expect(world.principles.map(\.id) == ["schnitt", "ein-prozent-spur", "engstelle"])
        #expect(world.principles.map(\.orderInWorld) == [1, 2, 3])
    }

    @Test("Der Drill von „Der Schnitt“ dekodiert inputKind als .liste(min: 5)")
    func inputKindDekodiert() throws {
        let world = try TestContent.werkstatt()
        let schnitt = try #require(world.principles.first { $0.id == "schnitt" })
        #expect(schnitt.drill.inputKind == .liste(min: 5))
        #expect(schnitt.drill.durationMinutes == 7)
        #expect(schnitt.drill.minEvidenceChars == 80)
    }

    @Test("Jeder Drill verlangt eine Liste mit eigenem Minimum")
    func alleDrillsVerlangenListen() throws {
        let world = try TestContent.werkstatt()
        #expect(world.principles.map(\.drill.inputKind) == [
            .liste(min: 5), .liste(min: 6), .liste(min: 4)
        ])
    }

    @Test("Jedes Prinzip nennt eine Herkunft")
    func attributionVorhanden() throws {
        let world = try TestContent.werkstatt()
        #expect(world.principles.count == 3)
        #expect(world.principles.allSatisfy { !$0.attribution.originName.isEmpty })
        let schnitt = try #require(world.principles.first { $0.id == "schnitt" })
        #expect(schnitt.attribution.originName == "Derek Sivers")
        #expect(schnitt.attribution.originKind == .person)
        #expect(schnitt.attribution.originYear == 2009)
    }

    @Test("Die Metapher von „Der Schnitt“ zeigt auf die Werkbank-Szene")
    func metapherDekodiert() throws {
        let world = try TestContent.werkstatt()
        let schnitt = try #require(world.principles.first { $0.id == "schnitt" })
        #expect(schnitt.metaphor.sceneID == "scene.werkbank")
        #expect(schnitt.metaphor.interaction == .kippen)
        #expect(schnitt.metaphor.primaryObject == "Die graue Ablage")
    }

    @Test("Jedes Prinzip hat drei Erkennungsfragen mit je drei Optionen")
    func erkennungsfragenVollstaendig() throws {
        let world = try TestContent.werkstatt()
        #expect(world.principles.count == 3)
        #expect(world.principles.allSatisfy { $0.recognition.count == 3 })
        #expect(world.principles.allSatisfy { principle in
            principle.recognition.allSatisfy { $0.options.count == 3 }
        })
    }

    @Test("Jede falsche Option nennt einen Denkfehler, jede richtige keinen")
    func falscheOptionenNennenDenkfehler() throws {
        let world = try TestContent.werkstatt()
        let options = world.principles.flatMap { $0.recognition.flatMap(\.options) }
        #expect(options.count == 27)
        #expect(options.filter { !$0.isCorrect }.allSatisfy { ($0.fallacyID ?? "").isEmpty == false })
        #expect(options.filter(\.isCorrect).allSatisfy { $0.fallacyID == nil })
    }

    @Test("loadWorld dekodiert eine Welt aus rohen Daten")
    func loadWorldAusDaten() throws {
        let data = try JSONEncoder().encode(TestContent.werkstatt())
        let world = try ContentLoader.loadWorld(from: data)
        #expect(world.principles.count == 3)
        #expect(world.id == "werkstatt")
    }

    @Test("loadWorld wirft bei kaputtem JSON")
    func loadWorldWirftBeiKaputtemJSON() {
        #expect(throws: (any Error).self) {
            _ = try ContentLoader.loadWorld(from: Data("{ das ist kein JSON".utf8))
        }
    }

    @Test("Die Denkfehler-Registry ist vollständig und eindeutig")
    func denkfehlerRegistrie() throws {
        let fallacies = try ContentLoader.bundledFallacies()
        #expect(fallacies.count == 15)
        #expect(Set(fallacies.map(\.id)).count == fallacies.count)
        #expect(fallacies.allSatisfy { !$0.name.isEmpty && !$0.note.isEmpty })
    }

    @Test("Jede im Content benutzte fallacyID steht in der Registry")
    func alleBenutztenDenkfehlerSindRegistriert() throws {
        let world = try TestContent.werkstatt()
        let known = Set(try ContentLoader.bundledFallacies().map(\.id))
        var used: Set<String> = []
        for principle in world.principles {
            used.insert(principle.antiPattern.id)
            for question in principle.recognition {
                for option in question.options {
                    if let id = option.fallacyID { used.insert(id) }
                }
            }
        }
        #expect(used.count == 15)
        #expect(used.subtracting(known) == [])
        #expect(used.contains("lauwarm-lager"))
    }
}
