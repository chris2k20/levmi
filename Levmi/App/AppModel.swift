import Foundation
import Observation
import UserNotifications
import LevmiCore

// MARK: - AppModel
//
// Bindet Engine, Store, Renderer, Haptik und Audio zusammen (poc-spec §3, Architektur-Skizze).
// `send(_:)` ist der einzige Eingang: ruft `GameEngine.reduce`, übernimmt den neuen Zustand, führt
// jeden gelieferten `Effect` aus. Kein Spiel-Regelwissen hier — nur Verdrahtung.

@MainActor
@Observable
final class AppModel {

    private(set) var state: PlayerState
    var rules: Rules

    let world: World
    let clock: any Clock
    let renderer: any SceneRenderer

    private let store: any SaveStore
    private let haptics = HapticsPlayer()
    private let audio = ProceduralAudio()

    #if DEBUG
    /// Schalter der `DebugBar` — wechselt nur Zeitkonstanten (`Rules.demo`), keine Regel wird
    /// abgeschaltet (poc-spec 1.4).
    var isDemo = false {
        didSet {
            guard isDemo != oldValue else { return }
            rules = isDemo ? .demo : .standard
        }
    }
    #endif

    /// Ablehnung des zuletzt eingereichten Beweises (`Effect.reject`) — transient, kein
    /// `PlayerState`-Feld, da der Zustand bei Ablehnung unverändert bleibt (poc-spec 3.2 Regel 15).
    private(set) var rejectionReason: String?

    /// Der eigene Satz beim erneuten Öffnen (`Effect.showOwnSentence`) — transient, verschwindet
    /// über `dismissOwnSentenceBanner()`.
    private(set) var ownSentenceBanner: OwnSentence?

    /// Zustand des „Erinnern, wenn die Tür aufgeht?"-Schalters in `ClosedCard` — Präferenz über
    /// Nächte hinweg, deshalb in `UserDefaults` gemerkt statt nur im Zustand dieser Nacht.
    private(set) var reminderEnabled: Bool

    /// `Effect.scheduleReminder` liefert der Reducer unconditional bei `intentionChosen` (Regel
    /// 12) — das AppModel plant deshalb NICHT sofort, sondern merkt sich Zeitpunkt/Text, bis der
    /// Schalter in `ClosedCard` an ist (oder es schon war) und die Erlaubnis vorliegt.
    private var pendingReminder: (at: Date, text: String)?

    private static let reminderEnabledKey = "levmi.reminderEnabled"
    private static let reminderIdentifier = "levmi.reminder"

    init(
        rules: Rules = .standard,
        world: World? = nil,
        clock: any Clock = SystemClock(),
        store: (any SaveStore)? = nil,
        renderer: any SceneRenderer = SceneKitRenderer()
    ) {
        self.rules = rules
        self.world = world ?? (try? ContentLoader.bundledWorld("werkstatt"))
            ?? World(id: "werkstatt", title: "Werkstatt", principles: [])
        self.clock = clock
        self.store = store ?? Self.makeDefaultStore()
        self.renderer = renderer
        self.reminderEnabled = UserDefaults.standard.bool(forKey: Self.reminderEnabledKey)

        if let loaded = try? self.store.load() {
            state = loaded
        } else {
            state = GameEngine.initial(clock: clock, rules: rules)
        }

        if let sceneKitRenderer = renderer as? SceneKitRenderer {
            sceneKitRenderer.onBreakthroughFinished = { [weak self] in
                self?.send(.breakthroughFinished)
            }
        }

        audio.startDrone()
        send(.appOpened)
    }

    // MARK: - Eingang

    func send(_ action: GameAction) {
        let (newState, effects) = GameEngine.reduce(state, action, clock: clock, world: world, rules: rules)
        let changed = newState != state
        state = newState
        for effect in effects {
            perform(effect)
        }
        // Review-Befund: Regeln 4–6 liefern kein `.persist`; nach App-Kill mitten in `nodes`
        // gingen Setzungen verloren. Deshalb wird jeder Zustandswechsel sofort gesichert.
        if changed, !effects.contains(.persist) {
            try? store.save(state)
        }
        // Review-Befund 3: Wiederherstellung mitten in einer Durchbruch-Animation (App-Kill).
        // Der Renderer zeigt den Trieb statisch (Snapshot-Tier); das Tor öffnet sich nach kurzer Pause.
        if case .appOpened = action, state.phase == .breakthrough || state.phase == .breakthroughProof {
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.8))
                send(.breakthroughFinished)
            }
        }
    }

    func clearRejection() {
        rejectionReason = nil
    }

    func dismissOwnSentenceBanner() {
        ownSentenceBanner = nil
        send(.dismissOwnSentence)
    }

    /// Direkte UI-Haptik für die Umkehr-Animation der Pain-Kacheln (`PainTilesView`) — läuft pro
    /// Flip, unabhängig vom einmaligen `.haptic(.flip)`-Effekt, den der Reducer bei `painSelected`
    /// liefert (poc-spec 3.2 Regel 10). Kein Domain-Umweg, weil der Reducer von der Animation
    /// selbst nichts weiß.
    func playTileFlipHaptic() {
        haptics.flip()
    }

    /// Beweisfeld ab 40 Zeichen: „die Sonne beginnt zu glimmen" (poc-spec 1.3).
    ///
    /// Geplante Schnittstelle: `IslandChoreography.sunGlimmer(_ on: Bool)` auf `IslandWorld`
    /// (Erweiterung in `Levmi/Scene/IslandChoreography.swift`). Existiert die Methode noch nicht
    /// (geprüft zuletzt: weder in `IslandChoreography.swift` noch in `IslandWorld.swift` vorhanden),
    /// bleibt der Aufruf ein No-Op — sobald sie landet, hier die auskommentierte Zeile aktivieren;
    /// `TextEntryCard`/`GameView` bleiben unverändert.
    func setSunGlimmer(_ isReady: Bool) {
        // (renderer as? SceneKitRenderer)?.world.sunGlimmer(isReady)
    }

    /// Wird von `ClosedCard`s Schalter „Erinnern, wenn die Tür aufgeht?" aufgerufen. Persistiert
    /// die Präferenz, fragt beim Einschalten die Benachrichtigungs-Erlaubnis ab und plant dann
    /// `pendingReminder` (falls schon einer da ist). Aus/Erlaubnis verweigert → nichts geplant;
    /// ein zuvor geplanter Reminder wird beim Ausschalten storniert.
    func setReminderEnabled(_ enabled: Bool) {
        reminderEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: Self.reminderEnabledKey)

        guard enabled else {
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: [Self.reminderIdentifier])
            return
        }
        requestPermissionAndScheduleReminder()
    }

    // MARK: - Effekte

    private func perform(_ effect: Effect) {
        switch effect {
        case .scene(let command):
            renderer.apply(command)

        case .haptic(let cue):
            play(cue)

        case .sound(let cue):
            play(cue)

        case .persist:
            try? store.save(state)

        case .reject(let reason):
            rejectionReason = reason

        case .showOwnSentence(let sentence):
            ownSentenceBanner = sentence

        case .showBefund:
            break // `state.befund` trägt den Satz; `GameView` liest ihn direkt aus dem Zustand.

        case .scheduleReminder(let at, let text):
            pendingReminder = (at, text)
            // Regel 12 liefert diesen Effekt unconditional. Ist der Schalter aus einer früheren
            // Nacht schon an (Präferenz persistiert), sofort planen — sonst wartet's auf
            // `setReminderEnabled(true)`.
            if reminderEnabled {
                requestPermissionAndScheduleReminder()
            }
        }
    }

    private func play(_ cue: HapticCue) {
        switch cue {
        case .tap: haptics.tap()
        case .flip: haptics.flip()
        case .impact: haptics.impact()
        case .drain: haptics.drain()
        case .breakthrough: haptics.breakthrough()
        }
    }

    private func play(_ cue: SoundCue) {
        switch cue {
        case .impact: audio.playImpact()
        case .node(let kind): audio.playNodeTone(kind.rawValue)
        case .drain: audio.playDrain()
        case .breakthrough: audio.playBreakthrough()
        }
    }

    private func requestPermissionAndScheduleReminder() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            guard granted else { return }
            Task { @MainActor [weak self] in
                self?.scheduleReminderIfNeeded()
            }
        }
    }

    /// Titel/Body laut Vorgabe: Titel immer „Die Tür ist auf.", Body ist der Absichtssatz —
    /// derselbe Satz, den der Spieler in `IntentionCard` gewählt/geschrieben hat.
    private func scheduleReminderIfNeeded() {
        guard let reminder = pendingReminder else { return }
        let content = UNMutableNotificationContent()
        content.title = "Die Tür ist auf."
        content.body = reminder.text
        content.sound = .default

        let interval = max(1, reminder.at.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: Self.reminderIdentifier,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Store

    /// `FileSaveStore` in Application Support, Dateischutz `.completeUntilFirstUserAuthentication`
    /// (poc-spec-Vertrag). Fällt auf `InMemorySaveStore` zurück, falls das Verzeichnis nicht
    /// ermittelbar ist (z. B. in bestimmten Testumgebungen).
    private static func makeDefaultStore() -> any SaveStore {
        let fileManager = FileManager.default
        guard let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return InMemorySaveStore()
        }
        let directory = base.appendingPathComponent("Levmi", isDirectory: true)
        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            try fileManager.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: directory.path
            )
        } catch {
            return InMemorySaveStore()
        }
        return FileSaveStore(directory: directory)
    }
}
