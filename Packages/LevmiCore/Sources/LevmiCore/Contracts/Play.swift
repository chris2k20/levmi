import Foundation

// MARK: - Knoten und Setzungen

public enum NodeKind: String, Codable, Sendable {
    case glowing, cold, lukewarm
}

/// Ein Knoten auf der Insel. `id` ist 0…4 und über die ganze Nacht stabil.
public struct NodeSpec: Codable, Sendable, Equatable, Identifiable {
    public let id: Int
    public let kind: NodeKind

    public init(id: Int, kind: NodeKind) {
        self.id = id
        self.kind = kind
    }
}

public struct Placement: Codable, Sendable, Equatable {
    public let nodeID: Int
    public let kind: NodeKind
    public let at: Date

    public init(nodeID: Int, kind: NodeKind, at: Date) {
        self.nodeID = nodeID
        self.kind = kind
        self.at = at
    }
}

// MARK: - Onboarding-Kacheln

public enum PainTile: String, Codable, CaseIterable, Sendable {
    case zeitWeg, zuVielLauwarmes, keinFortschritt, geldReichtNicht, immerErreichbar, allesHaengtAnMir

    /// Beschriftung der Kachel in der Auswahl.
    public var label: String {
        // STUB — Implementierung durch Sonnet gegen LevmiCoreTests
        return ""
    }

    /// Das Gegenteil, das die Umkehr-Animation zeigt.
    public var inverted: String {
        // STUB — Implementierung durch Sonnet gegen LevmiCoreTests
        return ""
    }
}

// MARK: - Phasen und Regeln

public enum GamePhase: String, Codable, Sendable, CaseIterable {
    case firstLight, nodes, roots, breakthrough
    case onboardingPain, onboardingWhy, intention, closed
    case waiting, proof, dawnProof, cost, befund, idle
}

public struct Rules: Sendable {
    public let appliedLock: TimeInterval
    public let proofWindow: TimeInterval
    public let replayMinAge: TimeInterval
    public let lightsPerNight: Int
    public let minProofChars: Int
    public let minExplanationChars: Int

    public init(
        appliedLock: TimeInterval,
        proofWindow: TimeInterval,
        replayMinAge: TimeInterval,
        lightsPerNight: Int,
        minProofChars: Int,
        minExplanationChars: Int
    ) {
        self.appliedLock = appliedLock
        self.proofWindow = proofWindow
        self.replayMinAge = replayMinAge
        self.lightsPerNight = lightsPerNight
        self.minProofChars = minProofChars
        self.minExplanationChars = minExplanationChars
    }

    // STUB — Implementierung durch Sonnet gegen LevmiCoreTests
    public static let standard = Rules(
        appliedLock: 0, proofWindow: 0, replayMinAge: 0,
        lightsPerNight: 0, minProofChars: 0, minExplanationChars: 0
    )

    // STUB — Implementierung durch Sonnet gegen LevmiCoreTests
    public static let demo = Rules(
        appliedLock: 0, proofWindow: 0, replayMinAge: 0,
        lightsPerNight: 0, minProofChars: 0, minExplanationChars: 0
    )
}

// MARK: - Der Satz über den Spieler

public struct Befund: Codable, Sendable, Equatable {
    public let sentence: String
    public let alternative: String
    public let evidence: [String]
    public let principleID: PrincipleID

    public init(sentence: String, alternative: String, evidence: [String], principleID: PrincipleID) {
        self.sentence = sentence
        self.alternative = alternative
        self.evidence = evidence
        self.principleID = principleID
    }
}

/// Baut den Satz aus dem Widerspruch zwischen Gesagtem und Getanem, mit echten Zahlen
/// aus dem Zustand (poc-spec 3.1):
/// - F1: `pains` enthält `.zuVielLauwarmes` UND `placements` enthält ≥ 1 lukewarm.
/// - F2: `placements` enthält lukewarm, danach nur noch glowing (Minuten zwischen
///   `intention.createdAt` und dem letzten Beweis).
/// - F3: kein lukewarm, aber ≥ 1 cold vor dem ersten glowing.
/// - F4: sonst.
/// `alternative` ist der jeweils nächstplausible Satz, `evidence` nie leer.
public enum BefundGenerator {

    public static func generate(state: PlayerState, now: Date) -> Befund {
        // STUB — Implementierung durch Sonnet gegen LevmiCoreTests
        return Befund(sentence: "", alternative: "", evidence: [], principleID: "")
    }
}

// MARK: - Spielzustand

public struct PlayerState: Codable, Sendable, Equatable {
    public var phase: GamePhase
    public var createdAt: Date
    public var lastOpenedAt: Date
    public var lightsRemaining: Int
    public var nodes: [NodeSpec]
    public var litNodeIDs: [Int]
    public var nodeOutcomes: [NodeKind]
    public var placements: [Placement]
    public var sunProgress: Double
    public var lightColorTile: PainTile?
    public var pains: [PainTile]
    public var why: String?
    public var intention: Intention?
    public var closedAt: Date?
    public var readyAt: Date?
    public var progress: [String: PrincipleProgress]
    public var days: Int
    public var ownSentences: [OwnSentence]
    public var lastShownSentenceID: String?
    public var befund: Befund?
    public var befundAccepted: Bool?
    public var befundAlternativeShown: Bool

    public init(
        phase: GamePhase = .firstLight,
        createdAt: Date = Date(timeIntervalSince1970: 0),
        lastOpenedAt: Date = Date(timeIntervalSince1970: 0),
        lightsRemaining: Int = 2,
        nodes: [NodeSpec] = [],
        litNodeIDs: [Int] = [],
        nodeOutcomes: [NodeKind] = [],
        placements: [Placement] = [],
        sunProgress: Double = 0,
        lightColorTile: PainTile? = nil,
        pains: [PainTile] = [],
        why: String? = nil,
        intention: Intention? = nil,
        closedAt: Date? = nil,
        readyAt: Date? = nil,
        progress: [String: PrincipleProgress] = [:],
        days: Int = 0,
        ownSentences: [OwnSentence] = [],
        lastShownSentenceID: String? = nil,
        befund: Befund? = nil,
        befundAccepted: Bool? = nil,
        befundAlternativeShown: Bool = false
    ) {
        self.phase = phase
        self.createdAt = createdAt
        self.lastOpenedAt = lastOpenedAt
        self.lightsRemaining = lightsRemaining
        self.nodes = nodes
        self.litNodeIDs = litNodeIDs
        self.nodeOutcomes = nodeOutcomes
        self.placements = placements
        self.sunProgress = sunProgress
        self.lightColorTile = lightColorTile
        self.pains = pains
        self.why = why
        self.intention = intention
        self.closedAt = closedAt
        self.readyAt = readyAt
        self.progress = progress
        self.days = days
        self.ownSentences = ownSentences
        self.lastShownSentenceID = lastShownSentenceID
        self.befund = befund
        self.befundAccepted = befundAccepted
        self.befundAlternativeShown = befundAlternativeShown
    }
}

public enum GameAction: Sendable {
    case appOpened
    case lightDropped
    case lightPlaced(nodeID: Int)
    case sunPulled(Double)
    case breakthroughFinished
    case painSelected([PainTile])
    case whyEntered(String?)
    case intentionChosen(Intention)
    case closeForToday
    case proofSubmitted(String)
    case costEntered(String?)
    case befundAnswered(accepted: Bool)
    case dismissOwnSentence
    case reset
}

public enum Effect: Equatable, Sendable {
    case scene(SceneCommand)
    case haptic(HapticCue)
    case sound(SoundCue)
    case persist
    case reject(reason: String)
    case showOwnSentence(OwnSentence)
    case showBefund(Befund)
    case scheduleReminder(at: Date, text: String)
}

/// Reine Funktion. Kein Zustand außerhalb von `PlayerState`, keine Seiteneffekte.
public enum GameEngine {

    public static func reduce(
        _ state: PlayerState,
        _ action: GameAction,
        clock: any Clock,
        world: World,
        rules: Rules
    ) -> (PlayerState, [Effect]) {
        // STUB — Implementierung durch Sonnet gegen LevmiCoreTests
        return (state, [])
    }

    public static func initial(clock: any Clock, rules: Rules) -> PlayerState {
        // STUB — Implementierung durch Sonnet gegen LevmiCoreTests
        return PlayerState(
            phase: .idle,
            createdAt: Date(timeIntervalSince1970: 0),
            lastOpenedAt: Date(timeIntervalSince1970: 0),
            lightsRemaining: 0
        )
    }
}
