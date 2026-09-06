import Foundation

// MARK: - Spielzustand und Reducer

public enum NodeKind: String, Codable, Sendable {
    case glowing, cold, lukewarm
}

public enum PainTile: String, Codable, CaseIterable, Sendable {
    case zeitWeg, zuVielLauwarmes, keinFortschritt, geldReichtNicht, immerErreichbar, allesHaengtAnMir

    /// Das Gegenteil der Kachel, das in der Umkehr-Animation erscheint
    /// (z. B. `zeitWeg` → „Deine Zeit gehört dir").
    public var inverted: String {
        // STUB — Implementierung durch Sonnet gegen LevmiCoreTests
        return ""
    }
}

public enum GamePhase: String, Codable, Sendable {
    case firstLight, nodes, roots, dawn, breakthrough
    case onboardingPain, onboardingFlip, onboardingWhy, intention, closed
    case waiting, proof, dawnProof, breakthroughProof, cost, befund, idle
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

/// Ein Satz über den Spieler, gebaut aus seinen eigenen Daten.
public struct Befund: Codable, Sendable, Equatable {
    public let sentence: String
    public let evidence: [String]
    public let principleID: PrincipleID

    public init(sentence: String, evidence: [String], principleID: PrincipleID) {
        self.sentence = sentence
        self.evidence = evidence
        self.principleID = principleID
    }
}

/// Regeln (poc-spec 3.1):
/// 1. `nodeOutcomes` enthält ≥ 1 `.lukewarm` → „Dein Muster: Du prüfst das Lauwarme, statt es zu kippen."
///    Evidenz: Anzahl der lauwarmen Setzungen und die Denkfehler-ID `lauwarm-lager`.
/// 2. sonst `.cold` vor `.glowing` gewählt → „Du erkennst ein Nein, bevor du das Glühende suchst."
/// 3. sonst → „Du erkennst Glühendes sofort. Dein Engpass liegt nicht im Entscheiden, sondern im Wegräumen."
///    Evidenz: die erste gewählte Kachel.
/// In allen Fällen: `principleID == "schnitt"`, `evidence` nicht leer.
public enum BefundGenerator {

    public static func generate(
        pains: [PainTile],
        nodeOutcomes: [NodeKind],
        fallacyHits: [String: Int]
    ) -> Befund {
        // STUB — Implementierung durch Sonnet gegen LevmiCoreTests
        return Befund(sentence: "", evidence: [], principleID: "")
    }
}

public struct PlayerState: Codable, Sendable, Equatable {
    public var phase: GamePhase
    public var createdAt: Date
    public var lastOpenedAt: Date
    public var lightsRemaining: Int
    public var lightColorTile: PainTile?
    public var pains: [PainTile]
    public var why: String?
    public var intention: Intention?
    public var closedAt: Date?
    public var progress: [String: PrincipleProgress]
    public var days: Int
    public var ownSentences: [OwnSentence]
    public var nodeOutcomes: [NodeKind]
    public var befund: Befund?
    public var befundAccepted: Bool?

    public init(
        phase: GamePhase = .firstLight,
        createdAt: Date = Date(timeIntervalSince1970: 0),
        lastOpenedAt: Date = Date(timeIntervalSince1970: 0),
        lightsRemaining: Int = 1,
        lightColorTile: PainTile? = nil,
        pains: [PainTile] = [],
        why: String? = nil,
        intention: Intention? = nil,
        closedAt: Date? = nil,
        progress: [String: PrincipleProgress] = [:],
        days: Int = 0,
        ownSentences: [OwnSentence] = [],
        nodeOutcomes: [NodeKind] = [],
        befund: Befund? = nil,
        befundAccepted: Bool? = nil
    ) {
        self.phase = phase
        self.createdAt = createdAt
        self.lastOpenedAt = lastOpenedAt
        self.lightsRemaining = lightsRemaining
        self.lightColorTile = lightColorTile
        self.pains = pains
        self.why = why
        self.intention = intention
        self.closedAt = closedAt
        self.progress = progress
        self.days = days
        self.ownSentences = ownSentences
        self.nodeOutcomes = nodeOutcomes
        self.befund = befund
        self.befundAccepted = befundAccepted
    }
}

public enum GameAction: Sendable {
    case appOpened
    case lightDropped
    case lightPlaced(NodeKind)
    case sunPulled(Double)
    case painSelected([PainTile])
    case whyEntered(String?)
    case intentionChosen(Intention)
    case closeForToday
    case proofSubmitted(String)
    case costEntered(String?)
    case befundAnswered(accepted: Bool)
    case dismissOwnSentence
}

public enum Effect: Equatable, Sendable {
    case scene(SceneCommand)
    case haptic(HapticCue)
    case sound(SoundCue)
    case persist
    case reject(reason: String)
    case showOwnSentence(OwnSentence)
    case showBefund(Befund)
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
