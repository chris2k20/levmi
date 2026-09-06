# LEVMI — PoC-Spezifikation „Erste Nacht" (verbindlich für Tests und Code)

**Stand:** 2026-09-07 01:30 · **Autor:** Architekt · **Ziel:** Morgen früh baut die App, läuft im iPhone-17-Simulator, und der Loop ist spürbar.

Diese Spezifikation ist der Vertrag zwischen den Rollen: **Opus-Chefs schreiben daraus Tests, Sonnet-Coder implementieren dagegen.** Wer etwas anders baut, ändert erst diese Datei.

---

## 0. Schnittlinie (verbindlich; keine Ergänzung ohne Streichung)

**MDP bis 03:00** — steht das nicht, wird alles darunter gestrichen und die Nacht endet mit dem MDP:
erste Minute (Licht, fünf Knoten, zwei Lichter, Wurzeln, Sonne, Durchbruch mit Haptik + Sound) · Wiederherstellung der Szene aus dem Zustand nach App-Kill · Persistenz · Absicht → Wegschicken → Sperre mit Uhrzeit → Beweis → Sonne → Durchbruch → „+1 Tag" · Demo-Modus + Reset.

**P1 (bis 05:00, in dieser Reihenfolge):** Hass-Kacheln (überspringbar) + Umkehr · „Wenn das wahr wäre…" · Kosten-Frage · Satz über dich (Befund) mit „Stimmt / Stimmt nicht" · lokale Benachrichtigung zum Ende der Sperre mit dem eigenen Absichtssatz · Rückspiel des eigenen Satzes beim nächsten Öffnen · Reduce Motion, Flacker-Rampe, sechs Accessibility-Elemente.

**P2 (nur wenn P1 steht):** „Sag es in deinen Worten" (Stufe Verstanden, `CopyCheck`) · Share-Cards (ein Screenshot ist die Share-Card) · Audio-Tiefe (heute: vier beim Start erzeugte PCM-Puffer) · Herkunftszeile · Validator-Regeln jenseits von Attribution, Sperrliste und 3-Optionen-Struktur.

**Kill-Reihenfolge, wenn hinten:** Share-Cards → Audio-Tiefe → Herkunftszeile → Validator-Rest → Befund → Kosten-Frage → Benachrichtigung.

**Bekannte Grenze:** Phase `idle` hat im PoC keinen Ausgang (kein zweiter Abend). Der Reset-Knopf im Debug-Build startet einen neuen Durchlauf.

## 1. Spielerfahrung: der eine Durchlauf

### 1.1 Erster Start (die erste Minute, reines Spiel; Texte nur als Affordance nach Zögern und als Konsequenz)

| Schritt | Spieler sieht/fühlt | Domain-Ereignis |
|---|---|---|
| Schwarz, Subbass, ein Lichtpunkt, Haptik-Impuls | Ein leuchtender Punkt in der Mitte, Nebelmeer darunter. **Affordance ohne Text:** nach 1,5 s Untätigkeit atmet der Punkt (Scale 1.0 → 1.08, Loop), nach 3 s zeichnet sich alle 3 s eine dünne Partikelspur vom Punkt nach unten in den Nebel, erst nach 7 s ein kleiner Text unten: **„Zieh das Licht in den Nebel."** | `appOpened` → Phase `firstLight` |
| Finger berührt den Punkt, zieht ihn nach unten in den Nebel, lässt los | Nebel teilt sich, ein Inselfragment hebt sich, Partikelring, schwerer Einschlag | `lightDropped` → Szene `revealIsland` |
| Kamera fährt zurück, warmes Pad setzt ein | Fragment allein im Nebelmeer | Szene `cameraPullBack` |
| Fünf Knoten auf der Insel, zwei Lichter | Zwei **singen** (reine Quinte, warmes stetiges Glühen), einer **brummt** (stumpf, kalt, matt), zwei **flirren** lauwarm. **Der lauwarme Knoten sieht bis zur Setzung genauso warm und verführerisch aus wie der singende** — Unterschied nur im Ton (schwebendes Detune) und in einem leicht unregelmäßigen Puls. Keine Sanduhr, kein Warnsymbol vorab. | Szene `presentNodes` (5 Knoten, gemischt) |
| Text 1 (4 Wörter): **„Du hast ein Licht."** | Erscheint, verschwindet | — |
| Langer Druck auf einen Knoten: Ring füllt sich, Haptik rampt hoch, Vignette schließt | Loslassen bei vollem Ring = Licht gesetzt. **Der Ring beginnt sofort bei Berührung zu füllen** und fällt bei zu frühem Loslassen sichtbar zurück (lehrt „halten" ohne Wort). Nach zwei abgebrochenen Taps ein kleiner Text: **„Halten, bis der Ring voll ist."** | `lightPlaced(node)` |
| **Singender Knoten:** Einschlag, Kamera taucht 1,5 s unter die Nebelkante, goldenes Wurzelnetz breitet sich aus. Oben bleibt es dunkel. | „Es passiert etwas, ich seh es nur nicht" | Szene `showRoots(strength: .strong)` |
| **Lauwarmer Knoten:** Licht wird sichtbar aufgesaugt, **jetzt erst** erscheint die Sanduhr (Konsequenz, nicht Warnung), dünne graue Wurzel. **Das Licht ist wirklich weg** (kein Ersatz): Die Nacht hat ein Licht weniger, die Wurzeln bleiben dünner, der Durchbruch fällt kleiner aus. Text 2: **„Das Lauwarme hat dein Licht gefressen."** Ab dem zweiten Fehlgriff pulsieren die verbleibenden glühenden Knoten ruhig und stetig (das Spiel lehrt das Erkennungsmerkmal, statt die Strafe zu wiederholen). | Der Lernmoment mit echtem Preis | `lightPlaced(nodeID:)` → Szene `drainLight(nodeID)`; ist noch ein Licht übrig: `presentLight`, sonst `presentSun` |
| **Brummender Knoten:** dumpfer Schlag, nichts wächst, Licht bleibt erhalten (du darfst neu setzen) | Kalt = klares Nein, kostet nichts | Szene `thud` |
| Nach dem ersten verbrauchten Licht erscheint ein zweites (zwei Lichter pro Nacht; die verbleibenden Knoten bleiben). Sind beide Lichter verbraucht (glühend oder lauwarm) **oder** vier Setzungen erfolgt, erscheint die Sonnenscheibe am Horizont; der Spieler zieht sie mit dem Finger hoch. Die Sonne bleibt beim Loslassen auf dem bisher höchsten Stand (monoton), nach 6 s ohne Zug pulsiert sie leicht. | Zeitraffer, Licht streicht über die Insel, Nebel sinkt eine Stufe | `sunPulled(progress)` monoton; bei ≥ 1.0 Durchbruch |
| **Durchbruch:** ein Kristalltrieb bricht durch die Oberfläche, Geometrie knackt auf, Partikelburst (Rampe ≥ 400 ms, kein Blitz), Akkord löst sich auf, harte Haptik, Kamera schiebt hinein. **Die Größe hängt an den Wurzeln:** zwei starke Wurzeln → `.full`, eine → `.half`, keine → `.thin` (die Sonne geht trotzdem auf: gleiche Mühe, weniger Welt). Erst wenn der Renderer `breakthroughFinished` meldet, geht es weiter. | Der Belohnungsmoment | Szene `breakthrough(.full/.half/.thin)` → `breakthroughFinished` |

Keine Zahl, kein Zähler in der ersten Minute.

### 1.2 Onboarding (nach dem Erfolg, nie davor)

1. **„Was hat dich diese Woche am meisten aufgehalten?"** — 6 Kacheln, Mehrfachauswahl, **überspringbar** (leere Auswahl ist erlaubt): *Zeit weg · Zu viel Lauwarmes · Kein Fortschritt · Geld reicht nicht · Immer erreichbar · Alles hängt an mir.* → `painSelected([PainTile])`
2. **Umkehr-Animation:** Jede gewählte Kachel dreht sich live um und zeigt ihr Gegenteil (*Zeit weg → Deine Zeit gehört dir* usw.). 3 Sekunden, Haptik pro Flip. Danach ein dezenter **„Teilen"**-Knopf: Share-Card mit den umgedrehten Kacheln (positiv, keine Beichte), Inselfarbe, Wortmarke klein, `levmi.app` klein. (Reduce Motion: Cross-Dissolve statt Flip, Haptik bleibt.)
3. **„Wenn das wahr wäre — was wäre anders?"** — eine Zeile Freitext, Skip erlaubt, darunter in 12 pt: **„Bleibt auf deinem Gerät."** Die Antwort färbt das Licht des Spielers dauerhaft (Farbton aus der ersten gewählten Kachel, Freitext wird als eigener Satz gespeichert). → `whyEntered(String?)`
4. **Absicht** — drei Vorschläge aus dem Drill der Karte „Der Schnitt", klein genug (z. B. „Sag zu einer lauwarmen Sache ab. Ein Satz, keine Begründung."), plus „eigene". Vor 20 Uhr Überschrift **„Klein genug für heute."**, danach **„Klein genug für morgen früh."** → `intentionChosen(Intention)`
5. **„Für heute reicht's."** — die App schickt den Spieler weg. Zwei Zeilen: „Die Wurzeln arbeiten." / „Komm zurück, wenn du's getan hast." Darunter dezent: „Erinnern, wenn die Tür aufgeht?" → fragt die Benachrichtigungs-Erlaubnis ab und plant eine lokale Benachrichtigung zum Zeitpunkt `readyAt` **mit dem eigenen Absichtssatz** als Text. → `closeForToday`

### 1.3 Rückkehr (der Beweis-Loop)

| Bedingung | Was passiert |
|---|---|
| Zurück **vor** `readyAt` (Standard: frühestens 10 Min nach der Absicht, bei Absichten nach 20 Uhr frühestens 06:00 am Folgetag; Demo 30 s) | Welt zeigt das Wurzelfenster (Insel durchscheinend, goldene Wurzeln pulsieren, anfassbar), die Sonne steht sichtbar unter dem Horizont (Wartezeit physisch). Zwei Zeilen: „Die Wurzeln arbeiten." / **„Zurück ab 14:20."** (Uhrzeit aus `readyAt`, kein rückwärts laufender Timer). Kein Beweis möglich. |
| Zurück **ab** `readyAt` | Die Absicht des Spielers in seinen eigenen Worten. Frage: **„Hast du es getan?"** → Feld für den Beweis (≥ 40 Zeichen), Platzhalter **„Wer? Wann? Was ist passiert?"**, darunter „Bleibt auf deinem Gerät.". **Kein Zeichenzähler**: Rückmeldung ist die greifbar werdende Sonne (ab 40 Zeichen beginnt sie zu glimmen). |
| Beweis ungültig (zu kurz, Abschrift der Anleitung) | Kein Vorwurf. Feld bleibt, Hinweis: „Konkreter: Wer, wann, was ist passiert?" |
| Beweis gültig | Sonne wird greifbar → Spieler zieht sie hoch → Durchbruch (Tier 2, größer als Tier 1) → **„+1 Tag"** erscheint zum ersten Mal, groß, darunter die gesunkene Nebelkante (kein Balken 1/30) → Karte „Der Schnitt" auf Stufe **Angewendet** |
| Danach eine Frage: **„Was war unangenehm daran?"** (eine Zeile, Skip erlaubt, „Bleibt auf deinem Gerät.") | Wird als eigener Satz gespeichert |
| **Der Satz über dich** (intern „Befund", das Wort erscheint nie in der UI). Ein Satz aus dem **Widerspruch zwischen Gesagtem und Getanem**, mit echten Zahlen aus dem Zustand: z. B. *„Du hast ‚Zu viel Lauwarmes' angekreuzt — und heute Nacht trotzdem zweimal Lauwarmes gefüttert."* oder *„Du hast das Lauwarme nach dem ersten Mal erkannt. Dein Beweis kam 43 Minuten nach der Absicht."* Zwei Buttons: **„Stimmt"** / **„Stimmt nicht"**. **„Stimmt nicht" liefert einen zweiten, anderen Satz** (Alternative aus dem Generator), danach ist Schluss. (P2: dezent „Teilen"; Herkunftszeile „Nach Derek Sivers.") | `befundAnswered(accepted:)` |
| Beim nächsten Öffnen (≥ 1 Tag später, Demo ≥ 1 Min) | Zuerst ein eigener Satz des Spielers von früher: „Du hast geschrieben: …" | 

### 1.4 Demo-Modus

Ein Flag (`Rules.demo`), das **nur Zeitkonstanten** verkürzt (Sperre 10 Min → 30 s, Beweisfenster 24 h → 10 Min, Rückspiel-Mindestalter 1 Tag → 1 Min). Keine Regel wird ausgeschaltet. Im DEBUG-Build über einen kleinen Schalter oben rechts erreichbar, im Release nicht sichtbar. Daneben im DEBUG-Build ein **„Neu"**-Knopf (Reset des Spielstands), ohne den der Dreimal-Test morgen früh nicht durchführbar ist.

---

## 2. Die Welt (Szene) — Look & Feel

- **Palette:** Nebelmeer tiefes Blauschwarz (#04040E), Nebel kühl (#0B0E22 → #1A2447 am Horizont), Licht des Spielers warm (Standard #FFB347, färbt sich durch „Wofür?"), Wurzeln Gold (#FFD37A), Kristall-Durchbruch hell-cyan (#7FE7FF) mit Emission > 1.5 für Bloom.
- **Geometrie:** ausschließlich prozedural (SCNSphere/Box/Cylinder/Torus/Tube, flat-shaded Ikosaeder aus dem Spike). Inselfragment = Cluster aus 5–9 flachen, gekippten Ikosaeder-/Box-Segmenten. Knoten = kleine Kristalle (Ikosaeder r 0.18). Kein Asset-Import.
- **Kamera:** `SCNCamera` mit `wantsHDR`, Bloom (Intensität 1.4–1.8, Threshold 0.5), Vignette, SSAO leicht, DoF (Fokus auf Insel). Orbit-Rig, langsame Drift (70 s/Umlauf), Drag rotiert das Rig (Parallaxe). Dolly-In beim Start, Tauchgang unter die Nebelkante bei `showRoots`, Push-In beim Durchbruch. FOV-Puls ±3° beim Einschlag.
- **Nebel:** `SCNScene.fog*` plus eine halbtransparente, additive Nebelscheibe knapp über dem Wasser, deren Höhe „sinkt" (Stufe pro Durchbruch).
- **Wasser:** `SCNFloor` mit Reflexion 0.35, dunkles PBR-Material.
- **Licht:** ein gerichtetes Key-Light (warm), ein Punktlicht im Spieler-Licht (Farbe = Spielerfarbe), Ambient minimal. Maximal 3 dynamische Lichter, Schatten nur vom Key-Light, deferred, sampleCount 4.
- **Partikel:** Umgebungsfunken (dauerhaft, ≤ 60/s), Einschlagring (Burst), Durchbruch-Burst (≤ 600 Partikel). Keine Partikel ohne Anlass.
- **Performance-Budget:** ≤ 2.000 sichtbare Partikel, ≤ 300 Draw Calls, p95 Frame-Zeit ≤ 8 ms im Simulator (120 Hz Ziel, `preferredFramesPerSecond = 120`).
- **Reduce Motion (zentral in der Choreografie, nicht verstreut):** bei `UIAccessibility.isReduceMotionEnabled` Überblendung statt Kamerafahrt (Dolly, Tauchgang, Push-In, Drift), kein FOV-Puls, Partikel gedrittelt, Kachel-Flip als Cross-Dissolve. Haptik und Sound bleiben.
- **Blendung/Flackern:** keine Helligkeitsänderung über > 10 % der Fläche schneller als 3 Hz; der lauwarme Puls ist unregelmäßig, aber langsam (< 2 Hz); Durchbruchs-Burst rampt über ≥ 400 ms; `UIAccessibility.isDimFlashingLightsEnabled` → Burst-Helligkeit halbiert.
- **VoiceOver:** sieben Accessibility-Elemente über der `SCNView` (fünf Knoten mit Label „Knoten, singt/brummt/flirrt"… nein: Labels verraten nichts — „Knoten 1"…„Knoten 5", Custom Action „Licht setzen"; Licht „Dein Licht, in den Nebel ziehen", Action „Licht in den Nebel setzen"; Sonne „Sonne, hochziehen", Action „Morgengrauen"). Damit ist der Kern-Loop mit VoiceOver abschließbar.
- **Haptik (CoreHaptics):** Transient bei jedem Tap, Continuous-Ramp beim Halten (Intensität folgt dem Ring), schwerer Doppel-Transient beim Einschlag, langer Sweep + harter Schlag beim Durchbruch. Läuft im Simulator ins Leere, darf nicht crashen.
- **Sound (AVAudioEngine, prozedural, kein Asset):** heute Nacht **vier beim Start erzeugte PCM-Puffer** per `scheduleBuffer`: Drone-Loop (zwei verstimmte Sinus), Knoten-Ton (Quinte; Varianten für brummt/flirrt durch Pitch/Detune desselben Puffers), Einschlag (Noise + Sub), Durchbruch (Dur-Akkord mit Ausklang). Audio-Tiefe ist P2.

---

## 3. Architektur und Modulschnitt

```
Packages/LevmiCore/            reine Domain, importiert nur Foundation, Swift 6 strict
  Sources/LevmiCore/
    Content/    Principle, World, ContentLoader, ContentValidator, Fallacy
    Mastery/    MasteryStage, PrincipleProgress, MasteryRules, CopyCheck
    Play/       PlayerState, GameAction, GameEngine (Reducer), Effect, Rules, NodeKind, PainTile
    Proof/      Intention, Proof, ProofValidator, DayLedger, ReplayScheduler
    Scene/      SceneCommand, SceneEvent (nur Datentypen, kein SceneKit)
    Persistence/ SaveStore, InMemorySaveStore, FileSaveStore, Clock
  Tests/LevmiCoreTests/        Swift Testing, ≥ 40 Tests, laufen mit `swift test` auf macOS
Levmi/                         App
  App/         LevmiApp, AppModel (@Observable, bindet Engine, Store, Renderer, Haptik, Audio)
  Scene/       SceneKitRenderer (SceneRenderer), IslandSceneBuilder, Choreography, Procedural
  UI/          GameView, Overlays (PainTiles, Why, Intention, Closed, Proof, DayBar, OwnSentence), Theme
  Feedback/    HapticsPlayer, ProceduralAudio
  Content/     worlds/werkstatt/*.json (Bundle-Ressourcen, Kopie aus Packages? → Single Source: Packages/LevmiCore/Resources)
LevmiUITests/                  ein Smoke-Test (App startet, Szene sichtbar)
```

**Harte Regeln:** `LevmiCore` importiert nur `Foundation`. Kein `SCNNode` außerhalb von `Levmi/Scene/`. Content kommt aus JSON (`Bundle.module`), nie aus Swift-Literalen. `GameEngine.reduce` ist eine reine Funktion `(PlayerState, GameAction, Clock, World, Rules) -> (PlayerState, [Effect])`.

### 3.1 Domain-API (Vertrag; Namen sind verbindlich)

```swift
// Content (Schema aus Memo 05, Felder 1:1)
public struct Principle: Codable, Identifiable, Hashable, Sendable { id, world, orderInWorld, title, subtitle, core, expandedCore, metaphor, recognition, explainPrompt, drill, selfCheck, antiPattern, teachTask, prerequisites, synergies, tensions, difficulty, estimatedMinutes, lifeDomains, attribution, tags }
public struct World: Codable, Sendable { let id: String; let title: String; let principles: [Principle] }
public enum ContentLoader { public static func loadWorld(from data: Data) throws -> World; public static func bundledWorld(_ id: String) throws -> World }
public struct ContentIssue: Equatable, Sendable { let principleID: String?; let rule: String; let message: String }
public enum ContentValidator { public static func validate(_ world: World, blocklist: [String] = Blocklist.default) -> [ContentIssue] }

// Mastery
public enum MasteryStage: Int, Codable, Comparable, Sendable { case unseen=0, recognized, understood, applied, retained, taught }
public struct PrincipleProgress: Codable, Sendable { id, stage, stageEnteredAt, explanation: String?, proofs: [Proof], fallacyHits: [String:Int], ownExample: String? }
public enum CopyCheck { public static func sharesRun(_ text: String, with sources: [String], minWords: Int = 7) -> Bool }

// Play
public enum NodeKind: String, Codable, Sendable { case glowing, cold, lukewarm }
public struct NodeSpec: Codable, Sendable, Equatable, Identifiable { let id: Int; let kind: NodeKind }   // id 0…4
public enum RootStrength: String, Codable, Sendable { case strong, weak }
public enum BreakthroughTier: String, Codable, Sendable { case full, half, thin, second }
public struct SceneSnapshot: Codable, Sendable, Equatable { islandRevealed: Bool; nodes: [NodeSpec]; litNodeIDs: [Int]; roots: [RootStrength]; lightVisible: Bool; sunProgress: Double; sunVisible: Bool; fogLevel: Int; lightTile: PainTile?; rootWindow: Bool; breakthroughTier: BreakthroughTier? }
public enum SceneProjection { public static func snapshot(of state: PlayerState) -> SceneSnapshot }   // reine Funktion Zustand → Szene
public enum PainTile: String, Codable, CaseIterable, Sendable { case zeitWeg, zuVielLauwarmes, keinFortschritt, geldReichtNicht, immerErreichbar, allesHaengtAnMir; public var inverted: String { get } }
public enum GamePhase: String, Codable, Sendable { case firstLight, nodes, roots, dawn, breakthrough, onboardingPain, onboardingFlip, onboardingWhy, intention, closed, waiting, proof, dawnProof, breakthroughProof, cost, befund, idle }
public struct Rules: Sendable { appliedLock: TimeInterval; proofWindow: TimeInterval; replayMinAge: TimeInterval; lightsPerNight: Int; minProofChars: Int; minExplanationChars: Int; static let standard: Rules; static let demo: Rules }
// standard: appliedLock 600 s (10 Min), proofWindow 86_400 s, replayMinAge 86_400 s, lightsPerNight 2, minProofChars 40, minExplanationChars 60
// demo:     appliedLock 30 s, proofWindow 600 s, replayMinAge 60 s, lightsPerNight 2, minProofChars 40, minExplanationChars 60
public struct PlayerState: Codable, Sendable, Equatable { phase, createdAt, lastOpenedAt, lightsRemaining, nodes: [NodeSpec], litNodeIDs: [Int], nodeOutcomes: [NodeKind], placements: [Placement], sunProgress: Double, lightColorTile: PainTile?, pains: [PainTile], why: String?, intention: Intention?, closedAt: Date?, readyAt: Date?, progress: [String: PrincipleProgress], days: Int, ownSentences: [OwnSentence], befund: Befund?, befundAccepted: Bool?, befundAlternativeShown: Bool }
public struct Placement: Codable, Sendable, Equatable { nodeID: Int; kind: NodeKind; at: Date }
public enum GameAction: Sendable { case appOpened; case lightDropped; case lightPlaced(nodeID: Int); case sunPulled(Double); case breakthroughFinished; case painSelected([PainTile]); case whyEntered(String?); case intentionChosen(Intention); case closeForToday; case proofSubmitted(String); case costEntered(String?); case befundAnswered(accepted: Bool); case dismissOwnSentence; case reset }
public enum Effect: Equatable, Sendable { case scene(SceneCommand); case haptic(HapticCue); case sound(SoundCue); case persist; case reject(reason: String); case showOwnSentence(OwnSentence); case showBefund(Befund); case scheduleReminder(at: Date, text: String) }
public struct Befund: Codable, Sendable, Equatable { let sentence: String; let alternative: String; let evidence: [String]; let principleID: String }
public enum BefundGenerator { public static func generate(state: PlayerState, now: Date) -> Befund }
// Aus dem Widerspruch Gesagtes/Getanes, mit Zahlen aus dem Zustand:
//  F1: pains enthält .zuVielLauwarmes UND placements enthält ≥ 1 lukewarm → „Du hast ‚Zu viel Lauwarmes' angekreuzt — und heute Nacht trotzdem N-mal Lauwarmes gefüttert." (N = Anzahl)
//  F2: placements enthält lukewarm, danach nur noch glowing → „Du hast das Lauwarme nach dem ersten Mal erkannt. Dein Beweis kam M Minuten nach der Absicht." (M aus intention.createdAt und letztem Proof)
//  F3: kein lukewarm, aber ≥ 1 cold vor dem ersten glowing → „Du sagst Nein, bevor du das Glühende suchst. Das kostet nichts — und bringt nichts."
//  F4: sonst → „Zwei Lichter, zwei Treffer. Die Frage ist nicht, ob du erkennst, sondern ob du morgen kippst, was du erkannt hast."
//  alternative = der jeweils nächstplausible Satz; evidence = die verwendeten Zahlen/Fakten als Strings, nie leer.
public enum GameEngine { public static func reduce(_ state: PlayerState, _ action: GameAction, clock: any Clock, world: World, rules: Rules) -> (PlayerState, [Effect]); public static func initial(clock: any Clock, rules: Rules) -> PlayerState }

// Proof
public struct Intention: Codable, Sendable, Equatable, Identifiable { id, principleID, text, createdAt, earliestProofAt, dueBy; static func make(text:principleID:now:rules:calendar:) -> Intention }
public struct Proof: Codable, Sendable, Equatable { text, submittedAt, principleID }
public enum ProofValidator { public static func validate(_ text: String, rules: Rules, drillInstruction: String) -> ProofVerdict }  // .accepted / .tooShort(min:) / .copied / .empty
public struct DayLedger { public static func days(after proofs: [Proof], window: TimeInterval) -> Int }  // 1 Tag pro Prinzip pro Fenster
public enum ReplayScheduler { public static func sentence(from: [OwnSentence], now: Date, minAge: TimeInterval, lastShownID: String?) -> OwnSentence? }
public struct OwnSentence: Codable, Sendable, Equatable, Identifiable { id, text, createdAt, context: OwnSentenceContext }  // .why, .cost, .explanation

// Scene contract (Datentypen)
public enum SceneCommand: Equatable, Sendable { case restore(SceneSnapshot); case presentLight; case revealIsland; case cameraPullBack; case presentNodes([NodeSpec]); case impact(nodeID: Int); case showRoots(nodeID: Int, RootStrength); case drainLight(nodeID: Int); case thud(nodeID: Int); case hintGlowing; case presentSun; case sunProgress(Double); case dawn; case breakthrough(BreakthroughTier); case tintLight(PainTile?); case rootWindow(visible: Bool); case fogLevel(Int) }
public enum SceneEvent: Sendable { case lightDropped; case nodeHoldBegan(nodeID: Int); case nodeHoldEnded(nodeID: Int, completed: Bool); case sunDragged(Double); case sunReleased(Double); case breakthroughFinished }
public enum HapticCue: Equatable, Sendable { case tap, flip, impact, drain, breakthrough }
public enum SoundCue: Equatable, Sendable { case impact, node(NodeKind), drain, breakthrough }
public protocol Clock: Sendable { var now: Date { get } }
public protocol SaveStore { func load() throws -> PlayerState?; func save(_ state: PlayerState) throws }
```

### 3.2 Ablaufregeln des Reducers (Testgrundlage, v3)

0. **`appOpened` ist in jeder Phase gültig.** Es setzt `lastOpenedAt = now` und liefert **immer** als erstes Effekt `.scene(.restore(SceneProjection.snapshot(of: state)))`, danach die phasenspezifischen Effekte. Test: für jede Phase eine nicht-leere Kommandoliste, die mit `.restore` beginnt.
1. `initial` → Phase `firstLight`, `lightsRemaining = rules.lightsPerNight`, `nodes = []`, `days = 0`, `sunProgress = 0`.
2. `lightDropped` in `firstLight` → `nodes` = fünf `NodeSpec` mit ids 0…4 und Kinds `[.glowing, .glowing, .lukewarm, .lukewarm, .cold]` in gemischter Reihenfolge; Phase `nodes`; Effekte `[.scene(.revealIsland), .haptic(.impact), .sound(.impact), .scene(.cameraPullBack), .scene(.presentNodes(nodes)), .persist]`.
3. `lightPlaced(nodeID)` in `nodes` mit unbekannter oder bereits gesetzter ID → unverändert, `[]`.
4. `lightPlaced(nodeID)` auf **glowing** → `lightsRemaining -= 1`, `litNodeIDs += [id]`, `placements += [Placement]`, `nodeOutcomes += [.glowing]`, Progress `schnitt` → `recognized`; Effekte beginnen mit `.scene(.impact(id))`, `.haptic(.impact)`, `.sound(.node(.glowing))`, `.scene(.showRoots(nodeID: id, .strong))`.
5. `lightPlaced(nodeID)` auf **lukewarm** → `lightsRemaining -= 1` (**kein Ersatz**), `litNodeIDs += [id]`, `placements`/`nodeOutcomes` ergänzt, `progress["schnitt"].fallacyHits["lauwarm-lager"] += 1`; Effekte beginnen mit `.scene(.drainLight(nodeID: id))`, `.haptic(.drain)`, `.sound(.node(.lukewarm))`, `.scene(.showRoots(nodeID: id, .weak))`. Ist das die zweite lauwarme Setzung insgesamt: zusätzlich `.scene(.hintGlowing)`.
6. `lightPlaced(nodeID)` auf **cold** → kein Licht verbraucht, `litNodeIDs` unverändert, `placements`/`nodeOutcomes` ergänzt; Effekte `[.scene(.thud(nodeID: id)), .haptic(.tap), .sound(.node(.cold))]`. Zweite kalte Setzung insgesamt: zusätzlich `.scene(.hintGlowing)`.
7. Nach jeder Setzung (4–6): ist `lightsRemaining > 0` **und** `placements.count < 4` → Phase bleibt `nodes`, letzter Effekt `.scene(.presentLight)` (nur nach 4/5, nicht nach 6). Sonst → Phase `roots`, letzter Effekt `.scene(.presentSun)`, plus `.persist`.
8. `sunPulled(p)` in `roots` → `sunProgress = max(sunProgress, min(p, 1))`, Effekt `.scene(.sunProgress(sunProgress))`. Bei `sunProgress >= 1`: Phase `breakthrough`, Effekte `[.scene(.dawn), .scene(.breakthrough(tier)), .haptic(.breakthrough), .sound(.breakthrough), .persist]` mit `tier` = `.full` (zwei starke Wurzeln), `.half` (eine), `.thin` (keine).
9. `breakthroughFinished` in `breakthrough` → Phase `onboardingPain`, Effekt `.persist`. (Der Renderer meldet das Ende der Animation; kein Timer in der View.)
10. `painSelected(tiles)` in `onboardingPain` → `pains = tiles` (leer erlaubt), `lightColorTile = tiles.first` (nil bei leer), Phase `onboardingWhy`, Effekte `[.scene(.tintLight(tiles.first)), .haptic(.flip), .persist]`.
11. `whyEntered(text)` in `onboardingWhy` → wenn Text nicht leer: `ownSentences += [.why]`; Phase `intention`, `.persist`.
12. `intentionChosen(i)` in `intention` → `intention = i`, `readyAt = i.earliestProofAt`, Phase `closed`, Effekte `[.scheduleReminder(at: readyAt, text: i.text), .persist]`. `Intention.make(text:principleID:now:rules:)` setzt `earliestProofAt = now + rules.appliedLock`, bei Stunde ≥ 20 (lokale Zeit) und `rules.appliedLock >= 600` stattdessen 06:00 des Folgetags; `dueBy = earliestProofAt + rules.proofWindow`.
13. `closeForToday` in `closed` → `closedAt = now`, Phase `waiting`, Effekte `[.scene(.rootWindow(visible: true)), .persist]`. **`appOpened` in `closed` wirkt wie `closeForToday`** (zusätzlich zu Regel 0).
14. `appOpened` in `waiting`: `now < readyAt` → bleibt `waiting`, Effekte enthalten `.scene(.rootWindow(visible: true))`; `now >= readyAt` → Phase `proof`, Effekte enthalten `.scene(.rootWindow(visible: false))`.
15. `proofSubmitted(text)` in `proof` → `ProofValidator.validate(text, rules:, drillInstruction:)`; bei `.accepted`: `progress["schnitt"].proofs += [Proof]`, Stufe `applied`, `days = DayLedger.days(after:window:)`, `sunProgress = 0`, Phase `dawnProof`, Effekte `[.scene(.presentSun), .persist]`. Sonst `.reject(reason:)`, Phase bleibt.
16. `sunPulled(p)` in `dawnProof` → wie 8; bei `>= 1`: Phase `cost`, Effekte `[.scene(.dawn), .scene(.breakthrough(.second)), .scene(.fogLevel(1)), .haptic(.breakthrough), .sound(.breakthrough), .persist]`.
17. `costEntered(text)` in `cost` → wenn Text: `ownSentences += [.cost]`; `befund = BefundGenerator.generate(state:now:)`; Phase `befund`, Effekte `[.showBefund(befund), .persist]`.
18. `befundAnswered(accepted)` in `befund` → bei `true` oder wenn `befundAlternativeShown` bereits `true`: `befundAccepted = accepted`, Phase `idle`, `.persist`. Bei `false` und noch keine Alternative gezeigt: `befundAlternativeShown = true`, Effekt `.showBefund(Befund(sentence: befund.alternative, …))`, Phase bleibt `befund`.
19. `appOpened` in `idle` → wenn `ReplayScheduler` einen Satz liefert: Effekt `.showOwnSentence(s)`; sonst keine weiteren Effekte.
20. `reset` in jeder Phase → `GameEngine.initial(...)`, Effekte `[.scene(.restore(snapshot)), .persist]`.
21. Jede andere Aktion in einer Phase, für die sie nicht definiert ist → Zustand unverändert, Effekte `[]`.
22. `days` zählt pro Prinzip höchstens einen Beweis pro `proofWindow`.

### 3.3 Wiederherstellung (Zustand → Szene)

`SceneProjection.snapshot(of:)` ist eine reine Funktion. Der Renderer setzt bei `.restore` die komplette Szene ohne Animation: Insel sichtbar ab Phase ≥ `nodes`; Knoten aus `nodes`, gesetzte aus `litNodeIDs` mit Wurzelstärke aus `placements`; Licht sichtbar in `firstLight`/`nodes` (wenn `lightsRemaining > 0`); Sonne sichtbar in `roots`/`dawnProof` mit `sunProgress`, in `waiting` unter dem Horizont; Wurzelfenster in `waiting`; Nebelstufe = `days > 0 ? 1 : 0`; Lichtfarbe aus `lightColorTile`. Tests: Snapshot pro Phase entlang des Golden Path.

## 4. Testplan (Opus schreibt zuerst, Sonnet implementiert)

**LevmiCoreTests** (Swift Testing, `swift test`):
- `ContentLoaderTests`: lädt `werkstatt.json` aus `Bundle.module`, 3 Prinzipien, IDs `schnitt`, `ein-prozent-spur`, `engstelle`, Reihenfolge 1–3, `inputKind` `.liste(min:)` dekodiert, Attribution vorhanden.
- `ContentValidatorTests`: jede Regel 1–8 aus Memo 05 als eigener Test mit einem absichtlich kaputten Prinzip (zu langer `core`, 2 Optionen, 2 korrekte, fehlende `fallacyID`, Drill 11 Min, unbekannte Voraussetzung, Zyklus, fehlende Attribution, Sperrbegriff „Geissens"/Buchtitel/Autorname, < 3 Fragen). Der gelieferte Content ist fehlerfrei.
- `CopyCheckTests`: 7-Wort-Überschneidung erkannt, 6 Wörter nicht, Groß-/Kleinschreibung und Satzzeichen egal.
- `ProofValidatorTests`: leer, nur Leerzeichen, 39 Zeichen, 40 Zeichen, Abschrift der Drill-Anleitung.
- `DayLedgerTests`: 0 ohne Beweise, 1 mit einem, 1 mit zwei innerhalb des Fensters, 2 mit zwei außerhalb.
- `ReplaySchedulerTests`: nil ohne Sätze, nil wenn alle jünger als minAge, ältester zuerst, `lastShownID` wird übersprungen wenn ein anderer verfügbar ist.
- `RulesTests`: `standard` (10 Min / 24 h / 1 Tag / 2 Lichter / 40 / 60), `demo` (30 s / 10 Min / 1 Min / 2 / 40 / 60).
- `GameEngineTests`: Regeln 0–22 oben, jede als Test (Regel 0: für jede Phase beginnt `appOpened` mit `.restore`), plus ein „Golden Path" durch den ganzen Loop mit `TestClock`, plus „Golden Path im Demo-Modus", plus „Lauwarm-Pfad" (zwei lauwarme Setzungen → Sonne → `.thin`).
- `SceneProjectionTests`: Snapshot in `firstLight`, `nodes` (nach einer Setzung), `roots`, `waiting`, `proof`, `idle` — Felder wie in 3.3.
- `IntentionTests`: `make` vor 20 Uhr → `earliestProofAt = now + appliedLock`; um 21:30 mit `Rules.standard` → 06:00 Folgetag; im Demo immer `now + 30 s`; `dueBy = earliestProofAt + proofWindow`.
- `BefundGeneratorTests`: die vier Fälle F1–F4 aus 3.1 mit konkreten Zahlen im Satz, `alternative != sentence`, Evidenz nicht leer, `principleID == "schnitt"`.
- `SaveStoreTests`: Round-Trip `PlayerState` über `InMemorySaveStore` und `FileSaveStore` (temp dir), unbekanntes Feld im JSON bricht das Laden nicht.

**LevmiUITests**: App startet, `root` existiert. Mehr nicht.

**Nicht getestet (bewusst):** Bloom-Werte, Kamera-Timing, Partikel. Absicherung: Smoke-Konstruktion der Szene (Kamera, Licht, Knotenzahl vorhanden) + Screenshot pro grünem Build.

---

## 5. Definition of Done (heute Nacht)

1. `scripts/gen.sh && scripts/build.sh` grün, keine Warnungen aus eigenem Code.
2. `scripts/test-core.sh` grün, ≥ 40 Tests.
3. App startet im iPhone-17-Simulator und zeigt in ≤ 2 s die Welt.
4. Der komplette Loop aus Abschnitt 1 ist im Demo-Modus in unter 4 Minuten durchspielbar (erste Minute → Onboarding → Absicht → Schließen → 30 s warten → Beweis → Sonne → Durchbruch → +1 Tag → Kosten-Frage → Befund mit Share-Card → beim nächsten Öffnen eigener Satz).
5. Screenshots der Schlüsselmomente in `docs/screens/` und ein Screen-Recording (20 s).
6. README mit „So testest du morgen früh" (Simulator + was für das iPhone fehlt).
