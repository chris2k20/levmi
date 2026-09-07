import Foundation

// MARK: - Absicht und Beweis

public struct Intention: Codable, Sendable, Equatable, Identifiable {
    public let id: String
    public let principleID: PrincipleID
    public let text: String
    public let createdAt: Date
    public var earliestProofAt: Date
    public var dueBy: Date

    public init(
        id: String,
        principleID: PrincipleID,
        text: String,
        createdAt: Date,
        earliestProofAt: Date,
        dueBy: Date
    ) {
        self.id = id
        self.principleID = principleID
        self.text = text
        self.createdAt = createdAt
        self.earliestProofAt = earliestProofAt
        self.dueBy = dueBy
    }

    /// `earliestProofAt = now + rules.appliedLock`; bei lokaler Stunde ≥ 20 und
    /// `appliedLock >= 600` stattdessen 06:00 des Folgetags.
    /// `dueBy = earliestProofAt + rules.proofWindow`.
    public static func make(
        text: String,
        principleID: PrincipleID,
        now: Date,
        rules: Rules,
        calendar: Calendar = .current
    ) -> Intention {
        let earliestProofAt = Self.earliestProofAt(now: now, rules: rules, calendar: calendar)
        let dueBy = earliestProofAt.addingTimeInterval(rules.proofWindow)
        return Intention(
            id: UUID().uuidString,
            principleID: principleID,
            text: text,
            createdAt: now,
            earliestProofAt: earliestProofAt,
            dueBy: dueBy
        )
    }

    private static func earliestProofAt(now: Date, rules: Rules, calendar: Calendar) -> Date {
        let hour = calendar.component(.hour, from: now)
        guard hour >= 20, rules.appliedLock >= 600 else {
            return now.addingTimeInterval(rules.appliedLock)
        }
        let nextDay = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        var sixAM = calendar.dateComponents([.year, .month, .day], from: nextDay)
        sixAM.hour = 6
        sixAM.minute = 0
        sixAM.second = 0
        return calendar.date(from: sixAM) ?? now.addingTimeInterval(rules.appliedLock)
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
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }
        if CopyCheck.sharesRun(trimmed, with: [drillInstruction]) {
            return .copied
        }
        guard trimmed.count >= rules.minProofChars else {
            return .tooShort(min: rules.minProofChars)
        }
        return .accepted
    }
}

/// Zählt Tage: 1 Tag pro Prinzip pro `window`.
public struct DayLedger {

    public static func days(after proofs: [Proof], window: TimeInterval) -> Int {
        let byPrinciple = Dictionary(grouping: proofs, by: \.principleID)
        var total = 0
        for times in byPrinciple.values.map({ $0.map(\.submittedAt).sorted() }) {
            var lastCounted: Date?
            for time in times {
                if let last = lastCounted, time.timeIntervalSince(last) < window {
                    continue
                }
                total += 1
                lastCounted = time
            }
        }
        return total
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
        let eligible = sentences
            .filter { now.timeIntervalSince($0.createdAt) >= minAge }
            .sorted { $0.createdAt < $1.createdAt }
        return eligible.first { $0.id != lastShownID } ?? eligible.first
    }
}
