import Foundation

// MARK: - Regeln 10–13: Hass-Kacheln, das Warum, die Absicht, das Schließen.

extension GameEngine {

    /// Regel 10: die gewählten Kacheln färben das Licht; überspringbar.
    static func reducePainSelected(_ state: PlayerState, _ tiles: [PainTile]) -> (PlayerState, [Effect]) {
        var next = state
        next.pains = tiles
        next.lightColorTile = tiles.first
        next.phase = .onboardingWhy
        return (next, [.scene(.tintLight(tiles.first)), .haptic(.flip), .persist])
    }

    /// Regel 11: das Warum wird — wenn nicht leer — als eigener Satz gespeichert.
    static func reduceWhyEntered(_ state: PlayerState, _ text: String?, clock: any Clock) -> (PlayerState, [Effect]) {
        var next = state
        if let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty {
            next.why = trimmed
            next.ownSentences.append(OwnSentence(
                id: makeSentenceID(next, context: .why, clock: clock),
                text: trimmed,
                createdAt: clock.now,
                context: .why
            ))
        }
        next.phase = .intention
        return (next, [.persist])
    }

    /// Regel 12: die Absicht setzt die Rückkehrzeit und plant die Erinnerung.
    static func reduceIntentionChosen(_ state: PlayerState, _ intention: Intention) -> (PlayerState, [Effect]) {
        var next = state
        next.intention = intention
        next.readyAt = intention.earliestProofAt
        next.phase = .closed
        return (next, [.scheduleReminder(at: intention.earliestProofAt, text: intention.text), .persist])
    }

    /// Regel 13: `closeForToday` öffnet das Wurzelfenster. Wird auch von
    /// `appOpened` in `closed` wiederverwendet (siehe GameEngine+Restore.swift).
    static func reduceCloseForToday(_ state: PlayerState, clock: any Clock) -> (PlayerState, [Effect]) {
        var next = state
        next.closedAt = clock.now
        next.phase = .waiting
        return (next, [.scene(.rootWindow(visible: true)), .persist])
    }
}
