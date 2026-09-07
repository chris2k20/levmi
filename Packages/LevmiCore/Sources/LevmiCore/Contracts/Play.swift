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
        switch self {
        case .zeitWeg: return "Zeit weg"
        case .zuVielLauwarmes: return "Zu viel Lauwarmes"
        case .keinFortschritt: return "Kein Fortschritt"
        case .geldReichtNicht: return "Geld reicht nicht"
        case .immerErreichbar: return "Immer erreichbar"
        case .allesHaengtAnMir: return "Alles hängt an mir"
        }
    }

    /// Das Gegenteil, das die Umkehr-Animation zeigt.
    public var inverted: String {
        switch self {
        case .zeitWeg: return "Deine Zeit gehört dir."
        case .zuVielLauwarmes: return "Nur noch Glühendes."
        case .keinFortschritt: return "Sichtbar weiter."
        case .geldReichtNicht: return "Mehr, als du brauchst."
        case .immerErreichbar: return "Erreichbar, wenn du willst."
        case .allesHaengtAnMir: return "Es läuft auch ohne dich."
        }
    }
}

// MARK: - Phasen und Regeln

public enum GamePhase: String, Codable, Sendable, CaseIterable {
    case firstLight, nodes, roots, breakthrough
    case onboardingPain, onboardingWhy, intention, closed
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

    public static let standard = Rules(
        appliedLock: 600, proofWindow: 86_400, replayMinAge: 86_400,
        lightsPerNight: 2, minProofChars: 40, minExplanationChars: 60
    )

    public static let demo = Rules(
        appliedLock: 30, proofWindow: 600, replayMinAge: 60,
        lightsPerNight: 2, minProofChars: 40, minExplanationChars: 60
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
        let principleID: PrincipleID = state.intention?.principleID ?? "schnitt"

        let lukewarmCount = state.placements.filter { $0.kind == .lukewarm }.count
        let coldCount = state.placements.filter { $0.kind == .cold }.count
        let glowingCount = state.placements.filter { $0.kind == .glowing }.count

        let firstLukewarmIndex = state.placements.firstIndex { $0.kind == .lukewarm }
        let firstGlowingIndex = state.placements.firstIndex { $0.kind == .glowing }
        let firstColdIndex = state.placements.firstIndex { $0.kind == .cold }

        // F2: nach der ersten lauwarmen Setzung folgt (mindestens eine) nur noch Glühendes.
        let recognizedAfterFirstLukewarm: Bool = {
            guard let idx = firstLukewarmIndex else { return false }
            let rest = state.placements[(idx + 1)...]
            return !rest.isEmpty && rest.allSatisfy { $0.kind == .glowing }
        }()

        // F3: mindestens ein Kaltes, und das erste Kalte liegt vor dem ersten Glühenden
        // (oder es gibt gar kein Glühendes).
        let coldBeforeGlowing = firstColdIndex.map { cold in
            firstGlowingIndex == nil || cold < firstGlowingIndex!
        } ?? false

        let minutesSinceIntention: Int = {
            let lastProofAt = state.progress[principleID]?.proofs.last?.submittedAt ?? now
            let start = state.intention?.createdAt ?? state.createdAt
            return max(0, Int(lastProofAt.timeIntervalSince(start) / 60))
        }()

        if state.pains.contains(.zuVielLauwarmes), lukewarmCount >= 1 {
            return Befund(
                sentence: "Du hast ‚Zu viel Lauwarmes‘ angekreuzt — und heute Nacht trotzdem \(lukewarmCount)-mal Lauwarmes gefüttert.",
                alternative: "Vielleicht ist \(lukewarmCount)-mal einfach zu wenig Übung, nicht zu viel Ausrede.",
                evidence: ["lauwarm: \(lukewarmCount)", "pain: zuVielLauwarmes"],
                principleID: principleID
            )
        }

        if recognizedAfterFirstLukewarm {
            return Befund(
                sentence: "Du hast das Lauwarme nach dem ersten Mal erkannt. Dein Beweis kam \(minutesSinceIntention) Minuten nach der Absicht.",
                alternative: "Vielleicht war es kein Erkennen — nur Zufall, dass danach nichts Lauwarmes mehr kam.",
                evidence: ["lauwarm: 1", "minuten: \(minutesSinceIntention)"],
                principleID: principleID
            )
        }

        if lukewarmCount == 0, coldBeforeGlowing {
            return Befund(
                sentence: "Du sagst Nein, bevor du das Glühende suchst. Das kostet nichts — und bringt nichts.",
                alternative: "Vielleicht war das Nein nicht Angst vor dem Glühenden, sondern eine kluge Auswahl.",
                evidence: ["cold: \(coldCount)"],
                principleID: principleID
            )
        }

        return Befund(
            sentence: "Zwei Lichter, zwei Treffer. Die Frage ist nicht, ob du erkennst, sondern ob du morgen kippst, was du erkannt hast.",
            alternative: "Vielleicht zählt nicht die Zahl der Treffer, sondern dass du beide gefunden hast.",
            evidence: ["glowing: \(glowingCount)"],
            principleID: principleID
        )
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
        // Regeln 0 und 20 gelten unabhängig von der Phase.
        switch action {
        case .appOpened:
            return reduceAppOpened(state, clock: clock, world: world, rules: rules)
        case .reset:
            return reduceReset(clock: clock, rules: rules)
        default:
            break
        }

        switch (state.phase, action) {
        case (.firstLight, .lightDropped):
            return reduceLightDropped(state, clock: clock)

        case (.nodes, .lightPlaced(let nodeID)):
            return reduceLightPlaced(state, nodeID: nodeID, clock: clock)

        case (.roots, .sunPulled(let pulled)):
            return reduceSunPulledRoots(state, pulled)

        case (.breakthrough, .breakthroughFinished):
            return reduceBreakthroughFinished(state)

        case (.onboardingPain, .painSelected(let tiles)):
            return reducePainSelected(state, tiles)

        case (.onboardingWhy, .whyEntered(let text)):
            return reduceWhyEntered(state, text, clock: clock)

        case (.intention, .intentionChosen(let intention)):
            return reduceIntentionChosen(state, intention)

        case (.closed, .closeForToday):
            return reduceCloseForToday(state, clock: clock)

        case (.proof, .proofSubmitted(let text)):
            return reduceProofSubmitted(state, text, clock: clock, world: world, rules: rules)

        case (.dawnProof, .sunPulled(let pulled)):
            return reduceSunPulledDawnProof(state, pulled)

        case (.breakthroughProof, .breakthroughFinished):
            return reduceBreakthroughFinishedProof(state)

        case (.cost, .costEntered(let text)):
            return reduceCostEntered(state, text, clock: clock)

        case (.befund, .befundAnswered(let accepted)):
            return reduceBefundAnswered(state, accepted)

        case (.idle, .dismissOwnSentence):
            return reduceDismissOwnSentence(state)

        default:
            // Regel 21: eine Aktion, die in dieser Phase nicht definiert ist.
            return (state, [])
        }
    }

    public static func initial(clock: any Clock, rules: Rules) -> PlayerState {
        PlayerState(
            phase: .firstLight,
            createdAt: clock.now,
            lastOpenedAt: clock.now,
            lightsRemaining: rules.lightsPerNight
        )
    }
}
