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
        let textWords = words(in: text)
        guard !textWords.isEmpty else { return false }
        for source in sources {
            let sourceWords = words(in: source)
            if longestCommonRun(textWords, sourceWords) >= minWords {
                return true
            }
        }
        return false
    }

    /// Kleingeschrieben, Satzzeichen entfernt — Umlaute und Ziffern bleiben Wortbestandteil.
    private static func words(in text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }

    /// Länge der längsten zusammenhängenden Wortfolge, die `a` und `b` teilen.
    private static func longestCommonRun(_ a: [String], _ b: [String]) -> Int {
        guard !a.isEmpty, !b.isEmpty else { return 0 }
        var previous = [Int](repeating: 0, count: b.count + 1)
        var longest = 0
        for i in 1...a.count {
            var current = [Int](repeating: 0, count: b.count + 1)
            for j in 1...b.count where a[i - 1] == b[j - 1] {
                current[j] = previous[j - 1] + 1
                longest = max(longest, current[j])
            }
            previous = current
        }
        return longest
    }
}
