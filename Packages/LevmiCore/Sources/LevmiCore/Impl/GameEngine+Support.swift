import Foundation

// MARK: - Kleine, geteilte Bauteile des Reducers.
// Reine Hilfsfunktionen ohne eigenen Zustand — von mehreren GameEngine+*.swift
// benutzt. Kein `private`, damit sie dateiübergreifend sichtbar bleiben
// (Swifts `private` ist auf die Datei begrenzt), aber auch kein `public`:
// reine Implementierungsdetails von `LevmiCore.GameEngine`.

/// Deterministischer, seed-basierter Ersatz für `Int.random`. `GameEngine` darf
/// nie unseeded Zufall benutzen — der Seed kommt aus dem Zustand (`createdAt`),
/// damit `reduce` eine reine Funktion bleibt (gleiche Eingabe → gleiche Ausgabe).
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        self.state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        // splitmix64
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

extension GameEngine {

    /// Hebt die Mastery-Stufe eines Prinzips an, ohne sie je zurückzudrehen.
    static func advanceStage(
        _ state: inout PlayerState,
        principleID: PrincipleID,
        to stage: MasteryStage,
        clock: any Clock
    ) {
        var progress = state.progress[principleID]
            ?? PrincipleProgress(id: principleID, stage: .unseen, stageEnteredAt: clock.now)
        if progress.stage < stage {
            progress.stage = stage
            progress.stageEnteredAt = clock.now
        }
        state.progress[principleID] = progress
    }

    /// Deterministische ID für einen neu entstehenden `OwnSentence`: aus Uhrzeit
    /// und der bisherigen Anzahl eigener Sätze — nie `UUID()` (das wäre
    /// versteckter, unseeded Zufall in einer reinen Funktion).
    static func makeSentenceID(_ state: PlayerState, context: OwnSentenceContext, clock: any Clock) -> String {
        "own-\(context.rawValue)-\(Int(clock.now.timeIntervalSince1970))-\(state.ownSentences.count)"
    }
}
