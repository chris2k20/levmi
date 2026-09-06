import Foundation
import Testing
@testable import LevmiCore

// MARK: - Steuerbare Uhr

/// Die einzige Test-Doppelgängerin neben `InMemorySaveStore`.
final class TestClock: LevmiCore.Clock, @unchecked Sendable {

    /// 2025-09-04 12:13:20 UTC — fester Startpunkt, damit Zeitrechnungen lesbar bleiben.
    static let epoch = Date(timeIntervalSince1970: 1_757_000_000)

    var now: Date

    init(_ now: Date = TestClock.epoch) {
        self.now = now
    }

    @discardableResult
    func advance(by interval: TimeInterval) -> Date {
        now = now.addingTimeInterval(interval)
        return now
    }
}

// MARK: - Zeitkonstanten als Literale (nicht aus Rules ableiten!)

enum T {
    static let minute: TimeInterval = 60
    static let hour: TimeInterval = 60 * 60
    static let day: TimeInterval = 24 * 60 * 60
}

// MARK: - Content-Fixtures

enum FixtureError: Error, CustomStringConvertible {
    case noPrinciples
    case principleNotFound(String)

    var description: String {
        switch self {
        case .noPrinciples:
            return "Fixture: die geladene Welt enthält keine Prinzipien (ContentLoader liefert nichts)."
        case .principleNotFound(let id):
            return "Fixture: Prinzip \(id) nicht in der geladenen Welt gefunden."
        }
    }
}

enum TestContent {

    /// Die ausgelieferte Welt aus `Bundle.module`.
    static func werkstatt() throws -> World {
        try ContentLoader.bundledWorld("werkstatt")
    }

    /// Nimmt die ausgelieferte Welt, macht über das JSON gezielt etwas kaputt und
    /// dekodiert sie wieder. So braucht kein Test einen Content-Typ von Hand nachzubauen.
    static func brokenWorld(_ patch: (inout [[String: Any]]) throws -> Void) throws -> World {
        let world = try werkstatt()
        let data = try JSONEncoder().encode(world)
        guard
            var dict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            var principles = dict["principles"] as? [[String: Any]],
            !principles.isEmpty
        else {
            throw FixtureError.noPrinciples
        }
        try patch(&principles)
        dict["principles"] = principles
        let patched = try JSONSerialization.data(withJSONObject: dict)
        return try JSONDecoder().decode(World.self, from: patched)
    }

    /// Wie oben, aber nur für ein einzelnes Prinzip.
    static func brokenWorld(
        principle id: String,
        _ patch: (inout [String: Any]) -> Void
    ) throws -> World {
        try brokenWorld { principles in
            guard let index = principles.firstIndex(where: { $0["id"] as? String == id }) else {
                throw FixtureError.principleNotFound(id)
            }
            var principle = principles[index]
            patch(&principle)
            principles[index] = principle
        }
    }

    /// Ersetzt in einem Prinzip die erste Option der ersten Erkennungsfrage.
    static func brokenOption(
        principle id: String,
        _ patch: @escaping (inout [String: Any]) -> Void
    ) throws -> World {
        try brokenWorld(principle: id) { (principle: inout [String: Any]) in
            guard var questions = principle["recognition"] as? [[String: Any]],
                  var first = questions.first,
                  var options = first["options"] as? [[String: Any]],
                  var option = options.first
            else { return }
            patch(&option)
            options[0] = option
            first["options"] = options
            questions[0] = first
            principle["recognition"] = questions
        }
    }
}

// MARK: - Effekt-Zugriffe ohne force unwrap

extension Array where Element == Effect {

    var rejectReason: String? {
        for effect in self {
            if case .reject(let reason) = effect { return reason }
        }
        return nil
    }

    var presentedNodes: [NodeKind]? {
        for effect in self {
            if case .scene(.presentNodes(let nodes)) = effect { return nodes }
        }
        return nil
    }

    var sunProgress: Double? {
        for effect in self {
            if case .scene(.sunProgress(let progress)) = effect { return progress }
        }
        return nil
    }

    var shownOwnSentence: OwnSentence? {
        for effect in self {
            if case .showOwnSentence(let sentence) = effect { return sentence }
        }
        return nil
    }

    var shownBefund: Befund? {
        for effect in self {
            if case .showBefund(let befund) = effect { return befund }
        }
        return nil
    }

    var rootWindowVisible: Bool? {
        for effect in self {
            if case .scene(.rootWindow(let visible)) = effect { return visible }
        }
        return nil
    }

    func position(of effect: Effect) -> Int? {
        firstIndex(of: effect)
    }
}

// MARK: - Kleine Bauhelfer

extension Intention {
    static func fixture(
        id: String = "i1",
        principleID: String = "schnitt",
        text: String = "Sag heute zu einer lauwarmen Sache ab, ein Satz, keine Begründung.",
        createdAt: Date = TestClock.epoch,
        dueBy: Date = Date(timeIntervalSince1970: 0)
    ) -> Intention {
        Intention(id: id, principleID: principleID, text: text, createdAt: createdAt, dueBy: dueBy)
    }
}

extension OwnSentence {
    static func fixture(
        id: String,
        text: String = "Mehr Zeit für meine Kinder",
        createdAt: Date,
        context: OwnSentenceContext = .why
    ) -> OwnSentence {
        OwnSentence(id: id, text: text, createdAt: createdAt, context: context)
    }
}

extension Proof {
    static func fixture(
        text: String = "Ich habe Tom um 14 Uhr per Nachricht abgesagt, ein Satz, ohne Begründung.",
        submittedAt: Date,
        principleID: String = "schnitt"
    ) -> Proof {
        Proof(text: text, submittedAt: submittedAt, principleID: principleID)
    }
}
