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

    /// Dekodiert eine Welt aus rohen JSON-Daten. Wirft bei ungültigem JSON.
    public static func loadWorld(from data: Data) throws -> World {
        // STUB — Implementierung durch Sonnet gegen LevmiCoreTests
        return World(id: "", title: "", principles: [])
    }

    /// Lädt `Resources/worlds/<id>.json` aus `Bundle.module`.
    public static func bundledWorld(_ id: String) throws -> World {
        // STUB — Implementierung durch Sonnet gegen LevmiCoreTests
        return World(id: "", title: "", principles: [])
    }

    /// Lädt `Resources/fallacies.json` aus `Bundle.module`.
    public static func bundledFallacies() throws -> [Fallacy] {
        // STUB — Implementierung durch Sonnet gegen LevmiCoreTests
        return []
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
        // STUB — Implementierung durch Sonnet gegen LevmiCoreTests
        return [ContentIssue(principleID: nil, rule: ContentRule.notImplemented, message: "STUB")]
    }
}
