import Foundation

// MARK: - Absicht und Beweis

public struct Intention: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let principleID: PrincipleID
    public let text: String
    public let createdAt: Date
    public var dueBy: Date

    public init(id: String, principleID: PrincipleID, text: String, createdAt: Date, dueBy: Date) {
        self.id = id
        self.principleID = principleID
        self.text = text
        self.createdAt = createdAt
        self.dueBy = dueBy
    }
}

public struct Proof: Codable, Sendable, Equatable {
    public let text: String
    public let submittedAt: Date
    public let principleID: PrincipleID

    public init(text: String, submittedAt: Date, principleID: PrincipleID) {
        self.text = text
        self.submittedAt = submittedAt
        self.principleID = principleID
    }
}

public enum ProofVerdict: Equatable, Sendable {
    case accepted
    case tooShort(min: Int)
    case copied
    case empty
}

/// Prüft einen Beweis-Text. Leerzeichen zählen nicht: `text` wird vor der
/// Längenprüfung getrimmt. Abschrift der Drill-Anleitung → `.copied` (CopyCheck).
public enum ProofValidator {

    public static func validate(_ text: String, rules: Rules, drillInstruction: String) -> ProofVerdict {
        // STUB — Implementierung durch Sonnet gegen LevmiCoreTests
        return .tooShort(min: 0)
    }
}

/// Zählt Tage: 1 Tag pro Prinzip pro `window`.
public struct DayLedger {

    public static func days(after proofs: [Proof], window: TimeInterval) -> Int {
        // STUB — Implementierung durch Sonnet gegen LevmiCoreTests
        return -1
    }
}

public enum OwnSentenceContext: String, Codable, Sendable, Equatable {
    case why, cost, explanation
}

public struct OwnSentence: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let text: String
    public let createdAt: Date
    public let context: OwnSentenceContext

    public init(id: String, text: String, createdAt: Date, context: OwnSentenceContext) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.context = context
    }
}

/// Wählt den eigenen Satz, der beim nächsten Öffnen gezeigt wird:
/// ältester zuerst, mindestens `minAge` alt, `lastShownID` nur, wenn es keine Alternative gibt.
public enum ReplayScheduler {

    public static func sentence(
        from sentences: [OwnSentence],
        now: Date,
        minAge: TimeInterval,
        lastShownID: String?
    ) -> OwnSentence? {
        // STUB — Implementierung durch Sonnet gegen LevmiCoreTests
        return OwnSentence(id: "", text: "", createdAt: Date(timeIntervalSince1970: 0), context: .why)
    }
}
