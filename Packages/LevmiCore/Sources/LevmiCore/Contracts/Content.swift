import Foundation

// MARK: - Canonical Content (unveränderlich, aus JSON dekodiert)
// Schema aus Memo 05, Abschnitt 2.1 — Felder 1:1.
// Content ist Daten, nie Swift-Literale. Einzige Quelle: Resources/worlds/*.json.

public typealias PrincipleID = String
public typealias WorldID = String

public enum LifeDomain: String, Codable, Hashable, Sendable {
    case zeit, geld, menschen, energie, klarheit
}

public struct Metaphor: Codable, Hashable, Sendable {
    public let imageLine: String
    public let sceneID: String
    public let primaryObject: String
    public let interaction: Interaction
    public let successState: String

    public enum Interaction: String, Codable, Hashable, Sendable {
        case kippen, drehen, schneiden, stapeln, oeffnen, ziehen
    }
}

public struct RecognitionQuestion: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let situation: String
    public let prompt: String
    public let options: [Option]

    public struct Option: Codable, Identifiable, Hashable, Sendable {
        public let id: String
        public let text: String
        public let isCorrect: Bool
        public let fallacyID: String?
        public let feedback: String
    }
}

public struct Drill: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let instruction: String
    public let durationMinutes: Int
    public let inputKind: InputKind
    public let minEvidenceChars: Int
    public let windowHours: Int

    /// Synthetisiertes Codable-Format: `{ "liste": { "min": 5 } }` bzw. `{ "text": {} }`.
    public enum InputKind: Codable, Hashable, Sendable {
        case text, zahl, foto, stimme
        case liste(min: Int)
    }
}

public struct SelfCheck: Codable, Hashable, Sendable {
    public let question: String
    public let passCriteria: [String]
}

public struct AntiPattern: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let tellTale: String
    public let counterMove: String
}

public struct TeachTask: Codable, Hashable, Sendable {
    public let prompt: String
    public let maxSeconds: Int
    public let requiredElements: [String]
}

public struct Synergy: Codable, Hashable, Sendable {
    public let partner: PrincipleID
    public let chordName: String
    public let effect: String
    public let bonus: Double
}

public struct Attribution: Codable, Hashable, Sendable {
    public let originName: String
    public let originKind: Kind
    public let originYear: Int?
    public let note: String
    public let furtherReading: String?

    public enum Kind: String, Codable, Hashable, Sendable { case person, tradition, gemeingut, haus }
}

public struct Principle: Codable, Identifiable, Hashable, Sendable {
    public let id: PrincipleID
    public let schemaVersion: Int
    public let world: WorldID
    public let orderInWorld: Int

    public let title: String
    public let subtitle: String
    public let core: String
    public let expandedCore: String

    public let metaphor: Metaphor

    public let recognition: [RecognitionQuestion]
    public let explainPrompt: String
    public let drill: Drill
    public let selfCheck: SelfCheck
    public let antiPattern: AntiPattern
    public let teachTask: TeachTask

    public let prerequisites: [PrincipleID]
    public let synergies: [Synergy]
    public let tensions: [PrincipleID]

    public let difficulty: Int
    public let estimatedMinutes: Int
    public let lifeDomains: [LifeDomain]
    public let attribution: Attribution
    public let tags: [String]
}

public struct World: Codable, Sendable {
    public let id: String
    public let title: String
    public let principles: [Principle]

    public init(id: String, title: String, principles: [Principle]) {
        self.id = id
        self.title = title
        self.principles = principles
    }
}

/// Globale Denkfehler-Registry (Cross-Welt), Quelle: Resources/fallacies.json.
public struct Fallacy: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let note: String

    public init(id: String, name: String, note: String) {
        self.id = id
        self.name = name
        self.note = note
    }
}

// MARK: - Laden

public enum ContentLoader {

    enum LoadError: Error, CustomStringConvertible {
        case resourceNotFound(String)

        var description: String {
            switch self {
            case .resourceNotFound(let path):
                return "Ressource nicht im Bundle gefunden: \(path)"
            }
        }
    }

    /// Dekodiert eine Welt aus rohen JSON-Daten. Wirft bei ungültigem JSON.
    public static func loadWorld(from data: Data) throws -> World {
        try JSONDecoder().decode(World.self, from: data)
    }

    /// Lädt `Resources/worlds/<id>.json` aus `Bundle.module`.
    /// Im gebauten Bundle liegt die Datei unter
    /// `Bundle.module.url(forResource: id, withExtension: "json", subdirectory: "Resources/worlds")`.
    public static func bundledWorld(_ id: String) throws -> World {
        guard let url = Bundle.module.url(forResource: id, withExtension: "json", subdirectory: "Resources/worlds") else {
            throw LoadError.resourceNotFound("Resources/worlds/\(id).json")
        }
        return try loadWorld(from: Data(contentsOf: url))
    }

    /// Lädt `Resources/fallacies.json` aus `Bundle.module`
    /// (`subdirectory: "Resources"`, Wurzelelement ist ein JSON-Array).
    public static func bundledFallacies() throws -> [Fallacy] {
        guard let url = Bundle.module.url(forResource: "fallacies", withExtension: "json", subdirectory: "Resources") else {
            throw LoadError.resourceNotFound("Resources/fallacies.json")
        }
        return try JSONDecoder().decode([Fallacy].self, from: Data(contentsOf: url))
    }
}

// MARK: - Validierung

public struct ContentIssue: Equatable, Sendable {
    public let principleID: String?
    public let rule: String
    public let message: String

    public init(principleID: String?, rule: String, message: String) {
        self.principleID = principleID
        self.rule = rule
        self.message = message
    }
}

/// Stabile Regel-IDs für `ContentIssue.rule` (Memo 05, Abschnitt 2.5, Regeln 1–8).
public enum ContentRule {
    /// 1 — `core` länger als 140 Zeichen.
    public static let coreLength = "core-length"
    /// 1 — `core` ist kein einzelner Satz (Semikolon).
    public static let coreSingleSentence = "core-single-sentence"
    /// 2 — Erkennungsfrage hat nicht genau 3 Optionen.
    public static let optionCount = "option-count"
    /// 2 — Erkennungsfrage hat nicht genau 1 korrekte Option.
    public static let correctOptionCount = "correct-option-count"
    /// 2 — falsche Option ohne `fallacyID`.
    public static let fallacyIDMissing = "fallacy-id-missing"
    /// 3 — `drill.durationMinutes` größer als 10.
    public static let drillDuration = "drill-duration"
    /// 4 — `prerequisites` verweist auf ein unbekanntes Prinzip.
    public static let prerequisiteUnknown = "prerequisite-unknown"
    /// 4 — Voraussetzungs-Graph enthält einen Zyklus.
    public static let prerequisiteCycle = "prerequisite-cycle"
    /// 5 — `attribution.originName` fehlt.
    public static let attributionMissing = "attribution-missing"
    /// 5 — `originKind == .gemeingut` ohne `note`.
    public static let attributionNote = "attribution-note"
    /// 6 — Sperrbegriff im Text (IP-Gate).
    public static let blocklist = "blocklist"
    /// 7 — Welt hat auf Position 1–2 kein Prinzip mit `difficulty == 1`.
    public static let worldEasyStart = "world-easy-start"
    /// 8 — weniger als 3 Erkennungsfragen.
    public static let recognitionCount = "recognition-count"

    /// Nur vom Stub benutzt — nach der Implementierung darf diese Regel nie mehr auftauchen.
    public static let notImplemented = "not-implemented"
}

/// IP-Gate: Begriffe, die im ausgelieferten Content nicht vorkommen dürfen.
public enum Blocklist {
    public static let `default`: [String] = [
        "Geissens",
        "Reicher als die",
        "Alex Fischer",
        "Düsseldorf Fischer"
    ]
}

public enum ContentValidator {

    /// Prüft eine Welt gegen die Regeln 1–8. Leeres Ergebnis = sauber.
    public static func validate(_ world: World, blocklist: [String] = Blocklist.default) -> [ContentIssue] {
        var issues: [ContentIssue] = []
        let knownIDs = Set(world.principles.map(\.id))

        for principle in world.principles {
            issues.append(contentsOf: validate(principle, knownIDs: knownIDs, blocklist: blocklist))
        }
        if hasPrerequisiteCycle(world.principles) {
            issues.append(ContentIssue(
                principleID: nil,
                rule: ContentRule.prerequisiteCycle,
                message: "Der Voraussetzungs-Graph enthält einen Zyklus."
            ))
        }
        if !easyStart(world.principles) {
            issues.append(ContentIssue(
                principleID: nil,
                rule: ContentRule.worldEasyStart,
                message: "Welt „\(world.id)“ hat auf Position 1–2 kein Prinzip mit difficulty == 1."
            ))
        }
        return issues
    }

    // MARK: - Regeln 1, 2, 3, 5, 6, 8 (pro Prinzip)

    private static func validate(_ principle: Principle, knownIDs: Set<PrincipleID>, blocklist: [String]) -> [ContentIssue] {
        var issues: [ContentIssue] = []
        func issue(_ rule: String, _ message: String) {
            issues.append(ContentIssue(principleID: principle.id, rule: rule, message: message))
        }

        // Regel 1
        if principle.core.count > 140 {
            issue(ContentRule.coreLength, "core hat \(principle.core.count) Zeichen, mehr als 140.")
        }
        if principle.core.contains(";") {
            issue(ContentRule.coreSingleSentence, "core enthält ein Semikolon und ist kein einzelner Satz.")
        }

        // Regel 8 (Anzahl) und Regel 2 (pro Frage)
        if principle.recognition.count < 3 {
            issue(ContentRule.recognitionCount, "Nur \(principle.recognition.count) Erkennungsfragen, mindestens 3 nötig.")
        }
        for question in principle.recognition {
            if question.options.count != 3 {
                issue(ContentRule.optionCount, "Frage „\(question.id)“ hat \(question.options.count) statt 3 Optionen.")
            }
            let correct = question.options.filter(\.isCorrect).count
            if correct != 1 {
                issue(ContentRule.correctOptionCount, "Frage „\(question.id)“ hat \(correct) korrekte Optionen statt 1.")
            }
            for option in question.options where !option.isCorrect && (option.fallacyID ?? "").isEmpty {
                issue(ContentRule.fallacyIDMissing, "Falsche Option „\(option.id)“ in „\(question.id)“ nennt keine fallacyID.")
            }
        }

        // Regel 3
        if principle.drill.durationMinutes > 10 {
            issue(ContentRule.drillDuration, "Drill dauert \(principle.drill.durationMinutes) Minuten, mehr als 10.")
        }

        // Regel 4a (unbekannte Voraussetzung; der Zyklus wird global geprüft)
        for prerequisite in principle.prerequisites where !knownIDs.contains(prerequisite) {
            issue(ContentRule.prerequisiteUnknown, "Voraussetzung „\(prerequisite)“ ist kein bekanntes Prinzip.")
        }

        // Regel 5
        if principle.attribution.originName.isEmpty {
            issue(ContentRule.attributionMissing, "attribution.originName fehlt.")
        }
        if principle.attribution.originKind == .gemeingut && principle.attribution.note.isEmpty {
            issue(ContentRule.attributionNote, "originKind == .gemeingut verlangt eine Notiz.")
        }

        // Regel 6 (IP-Gate)
        let texts = blocklistTexts(of: principle)
        for term in blocklist where !term.isEmpty {
            if texts.contains(where: { $0.range(of: term, options: .caseInsensitive) != nil }) {
                issue(ContentRule.blocklist, "Sperrbegriff „\(term)“ im Content gefunden.")
            }
        }

        return issues
    }

    // MARK: - Regel 4b (Zyklus im Voraussetzungs-Graph)

    private static func hasPrerequisiteCycle(_ principles: [Principle]) -> Bool {
        enum Mark { case visiting, done }
        var marks: [PrincipleID: Mark] = [:]
        let byID = Dictionary(uniqueKeysWithValues: principles.map { ($0.id, $0) })

        func visit(_ id: PrincipleID) -> Bool {
            switch marks[id] {
            case .visiting: return true
            case .done: return false
            case nil: break
            }
            marks[id] = .visiting
            for prerequisite in byID[id]?.prerequisites ?? [] where byID[prerequisite] != nil {
                if visit(prerequisite) { return true }
            }
            marks[id] = .done
            return false
        }

        return principles.contains { visit($0.id) }
    }

    // MARK: - Regel 7 (leichter Einstieg)

    private static func easyStart(_ principles: [Principle]) -> Bool {
        principles
            .sorted { $0.orderInWorld < $1.orderInWorld }
            .prefix(2)
            .contains { $0.difficulty == 1 }
    }

    // MARK: - Freitext eines Prinzips, für Regel 6

    private static func blocklistTexts(of principle: Principle) -> [String] {
        var texts = [
            principle.title, principle.subtitle, principle.core, principle.expandedCore,
            principle.metaphor.imageLine, principle.metaphor.primaryObject, principle.metaphor.successState,
            principle.explainPrompt,
            principle.drill.title, principle.drill.instruction,
            principle.selfCheck.question,
            principle.antiPattern.name, principle.antiPattern.tellTale, principle.antiPattern.counterMove,
            principle.teachTask.prompt,
            principle.attribution.originName, principle.attribution.note
        ]
        texts.append(contentsOf: principle.selfCheck.passCriteria)
        texts.append(contentsOf: principle.teachTask.requiredElements)
        texts.append(contentsOf: principle.tags)
        texts.append(contentsOf: principle.synergies.map(\.chordName))
        texts.append(contentsOf: principle.synergies.map(\.effect))
        if let furtherReading = principle.attribution.furtherReading {
            texts.append(furtherReading)
        }
        for question in principle.recognition {
            texts.append(question.situation)
            texts.append(question.prompt)
            for option in question.options {
                texts.append(option.text)
                texts.append(option.feedback)
            }
        }
        return texts
    }
}
