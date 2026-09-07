import Foundation

// MARK: - Regeln 0, 14, 19, 20: Wiederherstellung, Warten, Rückspiel, Reset.

extension GameEngine {

    /// Regel 0: `appOpened` ist in jeder Phase gültig und beginnt immer mit
    /// `.restore` des Zustands **vor** der Aktion. Danach je nach Phase:
    /// Regel 13 (`closed`), Regel 14 (`waiting`), Regel 19 (`idle`) — sonst nichts.
    static func reduceAppOpened(_ state: PlayerState, clock: any Clock, world: World, rules: Rules) -> (PlayerState, [Effect]) {
        let restore = Effect.scene(.restore(SceneProjection.snapshot(of: state)))
        var next = state
        next.lastOpenedAt = clock.now

        switch state.phase {
        case .closed:
            // appOpened in closed wirkt wie closeForToday.
            let (afterClose, closeEffects) = reduceCloseForToday(next, clock: clock)
            return (afterClose, [restore] + closeEffects)

        case .waiting:
            if clock.now >= (state.readyAt ?? .distantFuture) {
                next.phase = .proof
                return (next, [restore, .scene(.rootWindow(visible: false))])
            }
            return (next, [restore, .scene(.rootWindow(visible: true))])

        case .idle:
            if let sentence = ReplayScheduler.sentence(
                from: state.ownSentences,
                now: clock.now,
                minAge: rules.replayMinAge,
                lastShownID: state.lastShownSentenceID
            ) {
                next.lastShownSentenceID = sentence.id
                return (next, [restore, .showOwnSentence(sentence)])
            }
            return (next, [restore])

        default:
            return (next, [restore])
        }
    }

    /// Regel 20: `reset` beginnt die Nacht in jeder Phase neu.
    static func reduceReset(clock: any Clock, rules: Rules) -> (PlayerState, [Effect]) {
        let fresh = initial(clock: clock, rules: rules)
        return (fresh, [.scene(.restore(SceneProjection.snapshot(of: fresh))), .persist])
    }

    /// Der weggewischte eigene Satz kostet nur einen Speichervorgang.
    static func reduceDismissOwnSentence(_ state: PlayerState) -> (PlayerState, [Effect]) {
        (state, [.persist])
    }
}
