import Foundation

// MARK: - Regeln 8, 9, 16: die Sonne, zweimal, und die Durchbruch-Animation.

extension GameEngine {

    /// Zieht die Sonne monoton auf `pulled` (gekappt bei 1) und meldet den
    /// Fortschritt. Gemeinsamer erster Schritt der Regeln 8 und 16.
    private static func advanceSun(_ state: PlayerState, _ pulled: Double) -> (PlayerState, [Effect]) {
        var next = state
        next.sunProgress = max(state.sunProgress, min(pulled, 1))
        return (next, [.scene(.sunProgress(next.sunProgress))])
    }

    /// Regel 8: `sunPulled` in `roots`. Bei Erreichen von 1 kommt der erste
    /// Durchbruch, dessen Stärke aus der Zahl starker Wurzeln (glühende
    /// Setzungen) folgt.
    static func reduceSunPulledRoots(_ state: PlayerState, _ pulled: Double) -> (PlayerState, [Effect]) {
        var (next, effects) = advanceSun(state, pulled)

        if next.sunProgress >= 1 {
            let strongRoots = state.placements.filter { $0.kind == .glowing }.count
            let tier: BreakthroughTier = strongRoots >= 2 ? .full : (strongRoots == 1 ? .half : .thin)
            next.phase = .breakthrough
            effects += [
                .scene(.dawn),
                .scene(.breakthrough(tier)),
                .haptic(.breakthrough),
                .sound(.breakthrough),
                .persist
            ]
        }

        return (next, effects)
    }

    /// Regel 9: das Ende der Durchbruch-Animation öffnet das Onboarding.
    static func reduceBreakthroughFinished(_ state: PlayerState) -> (PlayerState, [Effect]) {
        var next = state
        next.phase = .onboardingPain
        return (next, [.persist])
    }

    /// Regel 16: `sunPulled` in `dawnProof` — der zweite, größere Durchbruch.
    /// Die Stufe ist immer `.second`, unabhängig von den Wurzeln der ersten Nacht.
    static func reduceSunPulledDawnProof(_ state: PlayerState, _ pulled: Double) -> (PlayerState, [Effect]) {
        var (next, effects) = advanceSun(state, pulled)

        if next.sunProgress >= 1 {
            next.phase = .cost
            effects += [
                .scene(.dawn),
                .scene(.breakthrough(.second)),
                .scene(.fogLevel(1)),
                .haptic(.breakthrough),
                .sound(.breakthrough),
                .persist
            ]
        }

        return (next, effects)
    }
}
