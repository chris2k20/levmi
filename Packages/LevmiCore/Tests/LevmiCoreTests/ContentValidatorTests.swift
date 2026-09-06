import Foundation
import Testing
@testable import LevmiCore

@Suite("ContentValidator")
struct ContentValidatorTests {

    // MARK: - Der gelieferte Content

    @Test("Der ausgelieferte Content ist fehlerfrei")
    func ausgelieferterContentIstSauber() throws {
        let issues = ContentValidator.validate(try TestContent.werkstatt())
        #expect(issues == [])
    }

    // MARK: - Regel 1: core

    @Test("Regel 1: ein core über 140 Zeichen wird gemeldet")
    func coreZuLang() throws {
        let world = try TestContent.brokenWorld(principle: "schnitt") { principle in
            principle["core"] = String(repeating: "a", count: 141)
        }
        let issues = ContentValidator.validate(world)
        let issue = issues.first { $0.rule == ContentRule.coreLength }
        #expect(issue != nil)
        #expect(issue?.principleID == "schnitt")
    }

    @Test("Regel 1: ein core mit Semikolon ist kein einzelner Satz")
    func coreMitSemikolon() throws {
        let world = try TestContent.brokenWorld(principle: "schnitt") { principle in
            principle["core"] = "Lauwarmes kostet Zeit; kipp es weg."
        }
        let issues = ContentValidator.validate(world)
        #expect(issues.contains { $0.rule == ContentRule.coreSingleSentence })
    }

    // MARK: - Regel 2: Erkennungsfragen

    @Test("Regel 2: eine Frage mit nur zwei Optionen wird gemeldet")
    func zweiOptionen() throws {
        let world = try TestContent.brokenWorld(principle: "schnitt") { principle in
            guard var questions = principle["recognition"] as? [[String: Any]],
                  var first = questions.first,
                  let options = first["options"] as? [[String: Any]]
            else { return }
            first["options"] = Array(options.prefix(2))
            questions[0] = first
            principle["recognition"] = questions
        }
        let issues = ContentValidator.validate(world)
        let issue = issues.first { $0.rule == ContentRule.optionCount }
        #expect(issue != nil)
        #expect(issue?.principleID == "schnitt")
    }

    @Test("Regel 2: zwei korrekte Optionen werden gemeldet")
    func zweiKorrekteOptionen() throws {
        let world = try TestContent.brokenWorld(principle: "schnitt", firstOption: { option in
            option["isCorrect"] = true
            option["fallacyID"] = nil
        })
        let issues = ContentValidator.validate(world)
        #expect(issues.contains { $0.rule == ContentRule.correctOptionCount })
    }

    @Test("Regel 2: eine falsche Option ohne fallacyID wird gemeldet")
    func falscheOptionOhneDenkfehler() throws {
        let world = try TestContent.brokenWorld(principle: "schnitt", firstOption: { option in
            option["fallacyID"] = nil
        })
        let issues = ContentValidator.validate(world)
        let issue = issues.first { $0.rule == ContentRule.fallacyIDMissing }
        #expect(issue != nil)
        #expect(issue?.principleID == "schnitt")
    }

    // MARK: - Regel 3: Drill

    @Test("Regel 3: ein Drill über 10 Minuten wird gemeldet")
    func drillZuLang() throws {
        let world = try TestContent.brokenWorld(principle: "schnitt") { principle in
            guard var drill = principle["drill"] as? [String: Any] else { return }
            drill["durationMinutes"] = 11
            principle["drill"] = drill
        }
        let issues = ContentValidator.validate(world)
        #expect(issues.contains { $0.rule == ContentRule.drillDuration })
    }

    @Test("Regel 3: genau 10 Minuten sind noch erlaubt")
    func drillGenauZehnMinutenIstOk() throws {
        let world = try TestContent.brokenWorld(principle: "schnitt") { principle in
            guard var drill = principle["drill"] as? [String: Any] else { return }
            drill["durationMinutes"] = 10
            principle["drill"] = drill
        }
        let issues = ContentValidator.validate(world)
        #expect(issues.contains { $0.rule == ContentRule.drillDuration } == false)
        #expect(issues == [])
    }

    // MARK: - Regel 4: Graph

    @Test("Regel 4: eine unbekannte Voraussetzung wird gemeldet")
    func unbekannteVoraussetzung() throws {
        let world = try TestContent.brokenWorld(principle: "engstelle") { principle in
            principle["prerequisites"] = ["gibt-es-nicht"]
        }
        let issues = ContentValidator.validate(world)
        let issue = issues.first { $0.rule == ContentRule.prerequisiteUnknown }
        #expect(issue != nil)
        #expect(issue?.principleID == "engstelle")
    }

    @Test("Regel 4: ein Zyklus im Voraussetzungs-Graph wird gemeldet")
    func zyklusImGraph() throws {
        let world = try TestContent.brokenWorld { principles in
            for index in principles.indices {
                switch principles[index]["id"] as? String {
                case "schnitt": principles[index]["prerequisites"] = ["engstelle"]
                case "engstelle": principles[index]["prerequisites"] = ["schnitt"]
                default: break
                }
            }
        }
        let issues = ContentValidator.validate(world)
        #expect(issues.contains { $0.rule == ContentRule.prerequisiteCycle })
    }

    // MARK: - Regel 5: Herkunft

    @Test("Regel 5: eine fehlende Herkunft wird gemeldet")
    func fehlendeHerkunft() throws {
        let world = try TestContent.brokenWorld(principle: "schnitt") { principle in
            guard var attribution = principle["attribution"] as? [String: Any] else { return }
            attribution["originName"] = ""
            principle["attribution"] = attribution
        }
        let issues = ContentValidator.validate(world)
        let issue = issues.first { $0.rule == ContentRule.attributionMissing }
        #expect(issue != nil)
        #expect(issue?.principleID == "schnitt")
    }

    @Test("Regel 5: Gemeingut ohne Notiz wird gemeldet")
    func gemeingutOhneNotiz() throws {
        let world = try TestContent.brokenWorld(principle: "schnitt") { principle in
            guard var attribution = principle["attribution"] as? [String: Any] else { return }
            attribution["originKind"] = "gemeingut"
            attribution["note"] = ""
            principle["attribution"] = attribution
        }
        let issues = ContentValidator.validate(world)
        #expect(issues.contains { $0.rule == ContentRule.attributionNote })
    }

    // MARK: - Regel 6: IP-Gate

    @Test("Regel 6: ein Sperrbegriff im Fließtext wird gemeldet")
    func sperrbegriffImText() throws {
        let world = try TestContent.brokenWorld(principle: "schnitt") { principle in
            principle["expandedCore"] = "Wer das Graue wegkippt, wird schneller reicher als die Geissens."
        }
        let issues = ContentValidator.validate(world)
        let issue = issues.first { $0.rule == ContentRule.blocklist }
        #expect(issue != nil)
        #expect(issue?.principleID == "schnitt")
    }

    @Test("Regel 6: ein Sperrbegriff im Feedback einer Option wird gemeldet")
    func sperrbegriffImFeedback() throws {
        let world = try TestContent.brokenWorld(principle: "schnitt", firstOption: { option in
            option["feedback"] = "Das sagt Alex Fischer auch immer."
        })
        let issues = ContentValidator.validate(world)
        #expect(issues.contains { $0.rule == ContentRule.blocklist })
    }

    @Test("Regel 6: die Sperrliste ist frei wählbar")
    func eigeneSperrliste() throws {
        let world = try TestContent.werkstatt()
        #expect(ContentValidator.validate(world, blocklist: []) == [])
        #expect(ContentValidator.validate(world, blocklist: ["Lauwarmes"])
            .contains { $0.rule == ContentRule.blocklist })
    }

    // MARK: - Regel 7 und 8

    @Test("Regel 7: eine Welt ohne leichten Einstieg wird gemeldet")
    func weltOhneLeichtenEinstieg() throws {
        let world = try TestContent.brokenWorld { principles in
            for index in principles.indices where (principles[index]["orderInWorld"] as? Int ?? 0) <= 2 {
                principles[index]["difficulty"] = 3
            }
        }
        let issues = ContentValidator.validate(world)
        #expect(issues.contains { $0.rule == ContentRule.worldEasyStart })
    }

    @Test("Regel 8: weniger als drei Erkennungsfragen werden gemeldet")
    func zuWenigeErkennungsfragen() throws {
        let world = try TestContent.brokenWorld(principle: "engstelle") { principle in
            guard let questions = principle["recognition"] as? [[String: Any]] else { return }
            principle["recognition"] = Array(questions.prefix(2))
        }
        let issues = ContentValidator.validate(world)
        let issue = issues.first { $0.rule == ContentRule.recognitionCount }
        #expect(issue != nil)
        #expect(issue?.principleID == "engstelle")
    }

    // MARK: - Meta

    @Test("Jeder Befund nennt eine gefüllte Regel und eine Meldung")
    func befundeSindBeschriftet() throws {
        let world = try TestContent.brokenWorld(principle: "schnitt") { principle in
            principle["core"] = String(repeating: "a", count: 200)
        }
        let issues = ContentValidator.validate(world)
        #expect(issues.isEmpty == false)
        #expect(issues.allSatisfy { !$0.rule.isEmpty && !$0.message.isEmpty })
        #expect(issues.contains { $0.rule == ContentRule.notImplemented } == false)
    }
}
