import Foundation

// MARK: - Mastery

public enum MasteryStage: Int, Codable, Comparable, Sendable {
    case unseen = 0
    case recognized
    case understood
    case applied
    case retained
    case taught

    public static func < (lhs: MasteryStage, rhs: MasteryStage) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public struct PrincipleProgress: Codable, Sendable, Equatable {
    public let id: PrincipleID
    public var stage: MasteryStage
    public var stageEnteredAt: Date
    public var explanation: String?
    public var proofs: [Proof]
    public var fallacyHits: [String: Int]
    public var ownExample: String?

    public init(
        id: PrincipleID,
        stage: MasteryStage = .unseen,
        stageEnteredAt: Date = Date(timeIntervalSince1970: 0),
        explanation: String? = nil,
        proofs: [Proof] = [],
        fallacyHits: [String: Int] = [:],
        ownExample: String? = nil
    ) {
        self.id = id
        self.stage = stage
        self.stageEnteredAt = stageEnteredAt
        self.explanation = explanation
        self.proofs = proofs
        self.fallacyHits = fallacyHits
        self.ownExample = ownExample
    }
}

/// Abschreibe-Prüfung: teilt `text` eine zusammenhängende Wortfolge von `minWords`
/// Wörtern mit einer der Quellen? Groß-/Kleinschreibung und Satzzeichen sind egal.
public enum CopyCheck {

    public static func sharesRun(_ text: String, with sources: [String], minWords: Int = 7) -> Bool {
        // STUB — Implementierung durch Sonnet gegen LevmiCoreTests
        return false
    }
}
