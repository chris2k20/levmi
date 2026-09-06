import CoreHaptics

/// Core-Haptics-Wrapper für die Insel-Szene. Reine Wirkung, keine Spielregeln.
///
/// Die Engine wird lazy angelegt (erst beim ersten tatsächlichen Haptik-Aufruf) und jeder Fehler
/// wird verschluckt: im Simulator gibt es keine Taptic Engine (`supportsHaptics == false`), also
/// bleibt hier alles still — kein Crash, kein Log-Spam. Auf einem Gerät ohne Core-Haptics-Support
/// (oder wenn die Engine aus irgendeinem Grund nicht startet) gilt dasselbe.
@MainActor
final class HapticsPlayer {
    private let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private var engine: CHHapticEngine?
    private var engineIsRunning = false
    private var chargePlayer: CHHapticAdvancedPatternPlayer?

    init() {}

    // MARK: - Öffentliche Cues

    /// Kurzer, weicher Antippen-Transient (z. B. beim Tippen auf einen kalten Knoten).
    func tap() {
        playTransient(intensity: 0.55, sharpness: 0.6)
    }

    /// Weicher, kurzer Umkehr-Klick (Onboarding-Kachel dreht sich um).
    func flip() {
        playTransient(intensity: 0.4, sharpness: 0.3)
    }

    /// Schwerer Doppel-Transient — Einschlag (Insel taucht auf, Licht trifft einen Knoten).
    func impact() {
        guard let engine = ensureRunningEngine() else { return }
        let first = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25),
            ],
            relativeTime: 0
        )
        let second = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.72),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.18),
            ],
            relativeTime: 0.09
        )
        play(events: [first, second], on: engine)
    }

    /// Absteigende Continuous-Rampe über 0,6 s — das lauwarme Licht wird aufgesaugt.
    func drain() {
        guard let engine = ensureRunningEngine() else { return }
        let continuous = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.85),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.35),
            ],
            relativeTime: 0,
            duration: 0.6
        )
        let fadeOut = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.0),
                CHHapticParameterCurve.ControlPoint(relativeTime: 0.6, value: -1.0),
            ],
            relativeTime: 0
        )
        play(events: [continuous], curves: [fadeOut], on: engine)
    }

    /// Haltet den Finger einen Knoten — Intensität eines fortlaufenden Continuous-Players folgt
    /// `progress` (0…1). Erster Aufruf mit `progress > 0` startet den Player, `progress <= 0`
    /// (oder `endChargeRamp()`) beendet ihn. Sicher mehrfach pro Frame aufrufbar.
    func chargeRamp(progress: Double) {
        let clamped = max(0, min(1, progress))
        guard clamped > 0.0005 else {
            endChargeRamp()
            return
        }
        guard let engine = ensureRunningEngine() else { return }
        if let player = chargePlayer {
            try? player.sendParameters(
                [CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: Float(clamped), relativeTime: 0)],
                atTime: CHHapticTimeImmediate
            )
            return
        }
        do {
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.05),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.45),
                ],
                relativeTime: 0,
                duration: 30 // lang genug für jeden Long-Press; wird per endChargeRamp() früher gestoppt
            )
            let pattern = try CHHapticPattern(events: [event], parameterCurves: [])
            let player = try engine.makeAdvancedPlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            try player.sendParameters(
                [CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: Float(clamped), relativeTime: 0)],
                atTime: CHHapticTimeImmediate
            )
            chargePlayer = player
        } catch {
            chargePlayer = nil
        }
    }

    /// Beendet einen laufenden `chargeRamp` sofort (Loslassen vor Fertigstellung).
    func endChargeRamp() {
        guard let player = chargePlayer else { return }
        chargePlayer = nil
        try? player.stop(atTime: CHHapticTimeImmediate)
    }

    /// Sweep über 0,8 s (Intensität und Schärfe steigen) gefolgt von einem harten Schlag — Durchbruch.
    func breakthrough() {
        guard let engine = ensureRunningEngine() else { return }
        let sweep = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.15),
            ],
            relativeTime: 0,
            duration: 0.8
        )
        let intensityCurve = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.0),
                CHHapticParameterCurve.ControlPoint(relativeTime: 0.8, value: 0.9),
            ],
            relativeTime: 0
        )
        let sharpnessCurve = CHHapticParameterCurve(
            parameterID: .hapticSharpnessControl,
            controlPoints: [
                CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 0.0),
                CHHapticParameterCurve.ControlPoint(relativeTime: 0.8, value: 1.0),
            ],
            relativeTime: 0
        )
        let hit = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.85),
            ],
            relativeTime: 0.82
        )
        play(events: [sweep, hit], curves: [intensityCurve, sharpnessCurve], on: engine)
    }

    // MARK: - Intern

    private func playTransient(intensity: Float, sharpness: Float) {
        guard let engine = ensureRunningEngine() else { return }
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ],
            relativeTime: 0
        )
        play(events: [event], on: engine)
    }

    private func play(events: [CHHapticEvent], curves: [CHHapticParameterCurve] = [], on engine: CHHapticEngine) {
        do {
            let pattern = try CHHapticPattern(events: events, parameterCurves: curves)
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            // Absichtlich still: Haptik verstärkt, trägt aber nichts — ein Fehler hier darf nie auffallen.
        }
    }

    private func ensureRunningEngine() -> CHHapticEngine? {
        guard supportsHaptics else { return nil }
        if let engine, engineIsRunning { return engine }
        let engine: CHHapticEngine
        if let existing = self.engine {
            engine = existing
        } else {
            do {
                engine = try CHHapticEngine()
            } catch {
                return nil
            }
            engine.resetHandler = { [weak self] in
                DispatchQueue.main.async {
                    self?.engineIsRunning = false
                    self?.chargePlayer = nil
                }
            }
            engine.stoppedHandler = { [weak self] _ in
                DispatchQueue.main.async {
                    self?.engineIsRunning = false
                    self?.chargePlayer = nil
                }
            }
            self.engine = engine
        }
        do {
            try engine.start()
            engineIsRunning = true
            return engine
        } catch {
            engineIsRunning = false
            return nil
        }
    }
}
