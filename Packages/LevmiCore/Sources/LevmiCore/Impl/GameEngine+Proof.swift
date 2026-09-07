import Foundation

// MARK: - Regeln 15, 17, 18: der Beweis, die Kosten-Frage, der Befund.

extension GameEngine {

    /// Regel 15: ein Beweis in `proof`. Angenommen → Tag +1, Stufe `applied`,
    /// weiter zur zweiten Sonne. Abgelehnt → `.reject`, Phase bleibt.
    static func reduceProofSubmitted(
        _ state: PlayerState,
        _ text: String,
        clock: any Clock,
        world: World,
        rules: Rules
    ) -> (PlayerState, [Effect]) {
        let principleID: PrincipleID = "schnitt"
        let drillInstruction = world.principles.first { $0.id == principleID }?.drill.instruction ?? ""
        let verdict = ProofValidator.validate(text, rules: rules, drillInstruction: drillInstruction)

        switch verdict {
        case .tooShort(let min):
            return (state, [.reject(reason: "Zu kurz — mindestens \(min) Zeichen.")])
        case .copied:
            return (state, [.reject(reason: "Das ist die Anleitung, nicht dein eigener Beweis.")])
        case .empty:
            return (state, [.reject(reason: "Das ist leer.")])
        case .accepted:
            var next = state
            var progress = next.progress[principleID]
                ?? PrincipleProgress(id: principleID, stage: .unseen, stageEnteredAt: clock.now)
            progress.proofs.append(Proof(text: text, submittedAt: clock.now, principleID: principleID))
            progress.stage = .applied
            progress.stageEnteredAt = clock.now
            next.progress[principleID] = progress
            next.days = DayLedger.days(after: progress.proofs, window: rules.proofWindow)
            next.sunProgress = 0
            next.phase = .dawnProof
            return (next, [.scene(.presentSun), .persist])
        }
    }

    /// Regel 17: die Kosten-Antwort — wenn vorhanden, ein weiterer eigener Satz —
    /// führt direkt zum generierten Befund.
    static func reduceCostEntered(_ state: PlayerState, _ text: String?, clock: any Clock) -> (PlayerState, [Effect]) {
        var next = state
        if let trimmed = text?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty {
            next.ownSentences.append(OwnSentence(
                id: makeSentenceID(next, context: .cost, clock: clock),
                text: trimmed,
                createdAt: clock.now,
                context: .cost
            ))
        }
        let befund = BefundGenerator.generate(state: next, now: clock.now)
        next.befund = befund
        next.phase = .befund
        return (next, [.showBefund(befund), .persist])
    }

    /// Regel 18: „Stimmt“ (oder eine bereits gezeigte Alternative) beendet den
    /// Abend. „Stimmt nicht“ zeigt einmalig die Alternative.
    static func reduceBefundAnswered(_ state: PlayerState, _ accepted: Bool) -> (PlayerState, [Effect]) {
        var next = state

        if accepted || state.befundAlternativeShown {
            next.befundAccepted = accepted
            next.phase = .idle
            return (next, [.persist])
        }

        next.befundAlternativeShown = true
        guard let befund = state.befund else {
            return (next, [])
        }
        let alternative = Befund(
            sentence: befund.alternative,
            alternative: befund.sentence,
            evidence: befund.evidence,
            principleID: befund.principleID
        )
        return (next, [.showBefund(alternative)])
    }
}
