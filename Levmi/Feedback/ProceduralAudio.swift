import AVFoundation
import Synchronization

/// Rein prozeduraler Sound für die Insel-Szene — keine Audio-Assets, alles synthetisiert über einen
/// einzigen `AVAudioSourceNode`. Alle Cues sind auf Core Haptics abgestimmt (gleiche Timings).
///
/// Der Render-Block von `AVAudioSourceNode` läuft auf einem Echtzeit-Audio-Thread, nicht auf dem
/// MainActor. Deshalb ist der gemeinsame Zustand (die aktive Stimmenliste) bewusst NICHT
/// Actor-isoliert, sondern — analog zu "Muster B" für den SceneKit-Render-Loop
/// (docs/strategy/03-engine-architekt.md §2.8) — hinter einem `Mutex` aus `Synchronization`
/// versteckt. Trigger-Methoden (vom MainActor aufgerufen) und der Render-Block (vom Audio-Thread
/// aufgerufen) teilen sich ausschließlich Werttypen (Enums/Doubles), damit im Render-Block keine
/// Klassen/Closures angefasst werden müssen.
final class ProceduralAudio: @unchecked Sendable {
    private enum VoiceKind: Sendable {
        case sine(freq: Double)
        case detunedPair(freq1: Double, freq2: Double)
        case noise
        case glissando(fromFreq: Double, toFreq: Double)
    }

    private enum EnvelopeKind: Sendable {
        /// Exponentieller Zerfall, `tau` in Sekunden. `duration` (auf der Voice) bestimmt nur, wann
        /// aufgeräumt wird, nicht die Hüllkurvenform selbst.
        case expDecay(tau: Double)
        /// Linearer Attack, danach linearer Release bis `duration`.
        case attackDecay(attack: Double)
        /// Sofortiger Vollausschlag, linearer Abfall bis `duration`.
        case linDecay
        /// Linearer Attack, danach Sustain auf 1.0 (für Dauertöne wie die Drone).
        case sustain(attack: Double)
    }

    private struct Voice: Sendable {
        var startedAt: Double
        var duration: Double?
        var kind: VoiceKind
        var envelope: EnvelopeKind
        var amplitude: Double
        var tremoloHz: Double = 0
        var tremoloDepth: Double = 0
        var phase: Double = 0
        var noiseState: UInt64 = 0x9E3779B97F4A7C15
    }

    private struct AudioState: Sendable {
        var time: Double = 0
        var voices: [Voice] = []
    }

    private static let sampleRate: Double = 44100
    private static let masterGain: Double = pow(10, -12.0 / 20.0) // −12 dBFS

    private let state = Mutex(AudioState())
    private let engine = AVAudioEngine()
    private var noiseSeedCounter: UInt64 = 0xA5A5_A5A5_1234_5679
    private var engineStarted = false
    private var droneStarted = false

    init() {}

    // MARK: - Öffentliche Cues

    /// Zwei leicht verstimmte Sinustöne (~55 / 55,3 Hz) plus Oberton, langsames Lautstärke-LFO. Leise
    /// Dauerschleife — einmal starten, läuft weiter.
    func startDrone() {
        ensureEngineRunning()
        guard !droneStarted else { return }
        droneStarted = true
        let attack = EnvelopeKind.sustain(attack: 2.0)
        addVoice(kind: .sine(freq: 55.0), envelope: attack, amplitude: 0.16, tremoloHz: 0.045, tremoloDepth: 0.5, duration: nil)
        addVoice(kind: .sine(freq: 55.3), envelope: attack, amplitude: 0.16, tremoloHz: 0.045, tremoloDepth: 0.5, duration: nil)
        addVoice(kind: .sine(freq: 110.0), envelope: attack, amplitude: 0.05, tremoloHz: 0.045, tremoloDepth: 0.5, duration: nil)
    }

    /// Der Ton eines Knotens: `"glowing"` (reine Quinte, warm), `"cold"` (dumpf, kurz) oder
    /// `"lukewarm"` (schwebendes Detune + Tremolo). Unbekannte Werte spielen nichts.
    func playNodeTone(_ kind: String) {
        ensureEngineRunning()
        switch kind {
        case "glowing":
            addVoice(kind: .sine(freq: 220), envelope: .attackDecay(attack: 0.02), amplitude: 0.32, duration: 0.8)
            addVoice(kind: .sine(freq: 330), envelope: .attackDecay(attack: 0.02), amplitude: 0.28, duration: 0.8)
        case "cold":
            addVoice(kind: .sine(freq: 70), envelope: .expDecay(tau: 0.06), amplitude: 0.8, duration: 0.4)
        case "lukewarm":
            addVoice(kind: .detunedPair(freq1: 194, freq2: 206), envelope: .attackDecay(attack: 0.06), amplitude: 0.34, tremoloHz: 5.5, tremoloDepth: 0.55, duration: 1.2)
        default:
            break
        }
    }

    /// Noise-Burst (80 ms) + Sub bei 45 Hz — Einschlag.
    func playImpact() {
        ensureEngineRunning()
        addVoice(kind: .noise, envelope: .linDecay, amplitude: 0.5, duration: 0.08)
        addVoice(kind: .sine(freq: 45), envelope: .expDecay(tau: 0.14), amplitude: 0.85, duration: 0.4)
    }

    /// Dur-Akkord A–C♯–E–A, der sich aus einem Sekundvorhalt (A–H–E) löst. Attack 50 ms, ~2 s Ausklang.
    func playBreakthrough() {
        ensureEngineRunning()
        let duration = 2.0
        // Gemeinsame Töne, die während des gesamten Akkords stehen bleiben.
        addVoice(kind: .sine(freq: 220.00), envelope: .attackDecay(attack: 0.05), amplitude: 0.26, duration: duration) // A3
        addVoice(kind: .sine(freq: 329.63), envelope: .attackDecay(attack: 0.05), amplitude: 0.22, duration: duration) // E4
        addVoice(kind: .sine(freq: 440.00), envelope: .attackDecay(attack: 0.05), amplitude: 0.16, duration: duration) // A4
        // Sekundvorhalt: H3 klingt kurz an …
        addVoice(kind: .sine(freq: 246.94), envelope: .linDecay, amplitude: 0.24, duration: 0.22) // H3
        // … und löst sich in die Terz C♯4 auf.
        addVoice(kind: .sine(freq: 277.18), envelope: .attackDecay(attack: 0.08), amplitude: 0.24, duration: duration - 0.18, startDelay: 0.18) // C♯4
    }

    /// Absteigendes Glissando 300 → 90 Hz über 0,6 s.
    func playDrain() {
        ensureEngineRunning()
        addVoice(kind: .glissando(fromFreq: 300, toFreq: 90), envelope: .linDecay, amplitude: 0.4, duration: 0.6)
    }

    // MARK: - Engine-Setup

    private func ensureEngineRunning() {
        guard !engineStarted else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Im Simulator (oder ohne Audio-Hardwarezugriff) darf das ruhig scheitern — die Engine
            // läuft trotzdem, es respektiert nur ggf. den Stummschalter nicht.
        }
        let format = AVAudioFormat(standardFormatWithSampleRate: Self.sampleRate, channels: 2)
        // Starker `self`-Capture (statt `[state]`): `Mutex` lässt sich nicht einzeln in die Closure
        // verschieben, ohne `self.state` andernorts ungültig zu machen. Der dadurch entstehende
        // Zyklus (self → engine → sourceNode → Closure → self) ist hier gewollt: `ProceduralAudio`
        // lebt ohnehin für die App-Laufzeit, wie die Drone selbst.
        let sourceNode = AVAudioSourceNode(format: format!) { [self] _, _, frameCount, audioBufferList in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let dt = 1.0 / Self.sampleRate
            state.withLock { s in
                for frame in 0..<Int(frameCount) {
                    let t = s.time
                    var mixed = 0.0
                    for index in s.voices.indices {
                        let elapsed = t - s.voices[index].startedAt
                        guard elapsed >= 0 else { continue }
                        mixed += Self.render(voice: &s.voices[index], elapsed: elapsed, dt: dt)
                    }
                    let sample = Float(tanh(mixed) * Self.masterGain)
                    for buffer in buffers {
                        guard let raw = buffer.mData else { continue }
                        raw.assumingMemoryBound(to: Float.self)[frame] = sample
                    }
                    s.time += dt
                }
                // Einmal pro Callback aufräumen statt pro Sample.
                let now = s.time
                s.voices.removeAll { voice in
                    guard let duration = voice.duration else { return false }
                    return now - voice.startedAt > duration + 0.05
                }
            }
            return noErr
        }
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: engine.mainMixerNode, format: format)
        do {
            try engine.start()
            engineStarted = true
        } catch {
            engineStarted = false
        }
    }

    // MARK: - Stimmen verwalten

    private func addVoice(
        kind: VoiceKind,
        envelope: EnvelopeKind,
        amplitude: Double,
        tremoloHz: Double = 0,
        tremoloDepth: Double = 0,
        duration: Double?,
        startDelay: Double = 0
    ) {
        noiseSeedCounter ^= noiseSeedCounter << 7
        noiseSeedCounter ^= noiseSeedCounter >> 9
        let seed = noiseSeedCounter | 1
        state.withLock { s in
            let voice = Voice(
                startedAt: s.time + startDelay,
                duration: duration,
                kind: kind,
                envelope: envelope,
                amplitude: amplitude,
                tremoloHz: tremoloHz,
                tremoloDepth: tremoloDepth,
                phase: 0,
                noiseState: seed
            )
            s.voices.append(voice)
        }
    }

    // MARK: - Reine Synthese (läuft auf dem Audio-Thread)

    private static func render(voice: inout Voice, elapsed: Double, dt: Double) -> Double {
        let wave = waveform(voice: &voice, elapsed: elapsed, dt: dt)
        let env = envelopeValue(voice: voice, elapsed: elapsed)
        var tremolo = 1.0
        if voice.tremoloHz > 0, voice.tremoloDepth > 0 {
            let lfo = 0.5 + 0.5 * sin(2 * .pi * voice.tremoloHz * elapsed)
            tremolo = (1 - voice.tremoloDepth) + voice.tremoloDepth * lfo
        }
        return wave * env * tremolo * voice.amplitude
    }

    private static func waveform(voice: inout Voice, elapsed: Double, dt: Double) -> Double {
        switch voice.kind {
        case .sine(let freq):
            return sin(2 * .pi * freq * elapsed)
        case .detunedPair(let f1, let f2):
            return 0.5 * (sin(2 * .pi * f1 * elapsed) + sin(2 * .pi * f2 * elapsed))
        case .noise:
            voice.noiseState ^= voice.noiseState << 13
            voice.noiseState ^= voice.noiseState >> 7
            voice.noiseState ^= voice.noiseState << 17
            return Double(voice.noiseState >> 11) * (1.0 / Double(1 << 53)) * 2 - 1
        case .glissando(let from, let to):
            let duration = max(voice.duration ?? 0.6, 0.001)
            let progress = min(elapsed / duration, 1)
            let freq = from + (to - from) * progress
            voice.phase += 2 * .pi * freq * dt
            if voice.phase > 4 * .pi * 10000 { voice.phase = voice.phase.truncatingRemainder(dividingBy: 2 * .pi) }
            return sin(voice.phase)
        }
    }

    private static func envelopeValue(voice: Voice, elapsed: Double) -> Double {
        switch voice.envelope {
        case .expDecay(let tau):
            return exp(-elapsed / max(tau, 0.001))
        case .attackDecay(let attack):
            guard let duration = voice.duration else { return elapsed < attack ? elapsed / max(attack, 0.001) : 1 }
            if elapsed < attack { return elapsed / max(attack, 0.001) }
            let release = elapsed - attack
            let releaseDuration = max(duration - attack, 0.001)
            return max(0, 1 - release / releaseDuration)
        case .linDecay:
            guard let duration = voice.duration, duration > 0 else { return 1 }
            return max(0, 1 - elapsed / duration)
        case .sustain(let attack):
            return elapsed < attack ? elapsed / max(attack, 0.001) : 1
        }
    }
}
