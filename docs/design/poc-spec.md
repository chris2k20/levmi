# LEVMI — PoC-Spezifikation „Erste Nacht" (verbindlich für Tests und Code)

**Stand:** 2026-09-07 01:30 · **Autor:** Architekt · **Ziel:** Morgen früh baut die App, läuft im iPhone-17-Simulator, und der Loop ist spürbar.

Diese Spezifikation ist der Vertrag zwischen den Rollen: **Opus-Chefs schreiben daraus Tests, Sonnet-Coder implementieren dagegen.** Wer etwas anders baut, ändert erst diese Datei.

---

## 1. Spielerfahrung: der eine Durchlauf

### 1.1 Erster Start (die erste Minute, reines Spiel, ohne Text bis auf zwei Zeilen)

| Schritt | Spieler sieht/fühlt | Domain-Ereignis |
|---|---|---|
| Schwarz, Subbass, ein Lichtpunkt, Haptik-Impuls | Ein leuchtender Punkt in der Mitte, Nebelmeer darunter. **Affordance ohne Text:** nach 1,5 s Untätigkeit atmet der Punkt (Scale 1.0 → 1.08, Loop), nach 3 s zeichnet sich alle 3 s eine dünne Partikelspur vom Punkt nach unten in den Nebel, erst nach 7 s ein kleiner Text unten: **„Zieh das Licht in den Nebel."** | `appOpened` → Phase `firstLight` |
| Finger berührt den Punkt, zieht ihn nach unten in den Nebel, lässt los | Nebel teilt sich, ein Inselfragment hebt sich, Partikelring, schwerer Einschlag | `lightDropped` → Szene `revealIsland` |
| Kamera fährt zurück, warmes Pad setzt ein | Fragment allein im Nebelmeer | Szene `cameraPullBack` |
| Fünf Knoten auf der Insel, zwei Lichter | Zwei **singen** (reine Quinte, warmes stetiges Glühen), einer **brummt** (stumpf, kalt, matt), zwei **flirren** lauwarm. **Der lauwarme Knoten sieht bis zur Setzung genauso warm und verführerisch aus wie der singende** — Unterschied nur im Ton (schwebendes Detune) und in einem leicht unregelmäßigen Puls. Keine Sanduhr, kein Warnsymbol vorab. | Szene `presentNodes` (5 Knoten, gemischt) |
| Text 1 (4 Wörter): **„Du hast ein Licht."** | Erscheint, verschwindet | — |
| Langer Druck auf einen Knoten: Ring füllt sich, Haptik rampt hoch, Vignette schließt | Loslassen bei vollem Ring = Licht gesetzt. **Der Ring beginnt sofort bei Berührung zu füllen** und fällt bei zu frühem Loslassen sichtbar zurück (lehrt „halten" ohne Wort). Nach zwei abgebrochenen Taps ein kleiner Text: **„Halten, bis der Ring voll ist."** | `lightPlaced(node)` |
| **Singender Knoten:** Einschlag, Kamera taucht 1,5 s unter die Nebelkante, goldenes Wurzelnetz breitet sich aus. Oben bleibt es dunkel. | „Es passiert etwas, ich seh es nur nicht" | Szene `showRoots(strength: .strong)` |
| **Lauwarmer Knoten:** Licht wird sichtbar aufgesaugt, **jetzt erst** erscheint die Sanduhr (Konsequenz, nicht Warnung), dünne graue Wurzel, das Licht ist weg. Text 2: **„Das Lauwarme hat dein Licht gefressen."** Nach 3 s erscheint ein Ersatzlicht. | Der Lernmoment | `lightPlaced(.lukewarm)` → Szene `drainLight`, danach `presentLight` erneut |
| **Brummender Knoten:** dumpfer Schlag, nichts wächst, Licht bleibt erhalten (du darfst neu setzen) | Kalt = klares Nein, kostet nichts | Szene `thud` |
| Nach dem ersten gesetzten Licht erscheint ein zweites Licht (zwei Lichter pro Nacht; die verbleibenden Knoten bleiben). Sind beide Lichter gesetzt, erscheint die Sonnenscheibe am Horizont; der Spieler zieht sie mit dem Finger hoch (Tutorial-Nacht: sofort erlaubt) | Zeitraffer, Licht streicht über die Insel, Nebel sinkt eine Stufe | `sunPulled(progress)` → bei ≥ 1.0 `dawnCompleted` |
| **Durchbruch:** ein Kristalltrieb bricht durch die Oberfläche, Geometrie knackt auf, Partikelburst, Akkord löst sich auf, harte Haptik, Kamera schiebt hinein | Der Belohnungsmoment | Szene `breakthrough(tier: .first)` |

Keine Zahl, kein Zähler in der ersten Minute.

### 1.2 Onboarding (nach dem Erfolg, nie davor)

1. **„Was nervt dich gerade am meisten?"** — 6 Kacheln, Mehrfachauswahl: *Zeit weg · Zu viel Lauwarmes · Kein Fortschritt · Geld reicht nicht · Immer erreichbar · Alles hängt an mir.* → `painSelected([PainTile])`
2. **Umkehr-Animation:** Jede gewählte Kachel dreht sich live um und zeigt ihr Gegenteil (*Zeit weg → Deine Zeit gehört dir* usw.). 3 Sekunden, Haptik pro Flip. Danach ein dezenter **„Teilen"**-Knopf: Share-Card mit den umgedrehten Kacheln (positiv, keine Beichte), Inselfarbe, Wortmarke klein, `levmi.app` klein. (Reduce Motion: Cross-Dissolve statt Flip, Haptik bleibt.)
3. **„Wenn das wahr wäre — was wäre anders?"** — eine Zeile Freitext, Skip erlaubt, darunter in 12 pt: **„Bleibt auf deinem Gerät."** Die Antwort färbt das Licht des Spielers dauerhaft (Farbton aus der ersten gewählten Kachel, Freitext wird als eigener Satz gespeichert). → `whyEntered(String?)`
4. **Absicht** — drei Vorschläge aus dem Drill der Karte „Der Schnitt", klein genug (z. B. „Sag zu einer lauwarmen Sache ab. Ein Satz, keine Begründung."), plus „eigene". Vor 20 Uhr Überschrift **„Klein genug für heute."**, danach **„Klein genug für morgen früh."** → `intentionChosen(Intention)`
5. **„Für heute reicht's."** — die App schickt den Spieler weg. Zwei Zeilen: „Die Wurzeln arbeiten." / „Komm zurück, wenn du's getan hast." → `closeForToday`

### 1.3 Rückkehr (der Beweis-Loop)

| Bedingung | Was passiert |
|---|---|
| Zurück **vor** Ablauf der Sperre (Standard 10 Min, Demo 30 s) | Welt zeigt das Wurzelfenster (Insel durchscheinend, goldene Wurzeln pulsieren), Sonne ist nicht greifbar. Zwei Zeilen: „Die Wurzeln arbeiten." / **„Zurück ab 14:20."** (Uhrzeit aus `readyAt`, kein rückwärts laufender Timer). Kein Beweis möglich. |
| Zurück **nach** Ablauf | Die Absicht des Spielers in seinen eigenen Worten. Frage: **„Hast du es getan?"** → Feld für den Beweis (≥ 40 Zeichen), Platzhalter **„Wer? Wann? Was ist passiert?"**, darunter „Bleibt auf deinem Gerät.", Zähler zeigt Zeichen. |
| Beweis ungültig (zu kurz, Abschrift der Anleitung) | Kein Vorwurf. Feld bleibt, Hinweis: „Konkreter: Wer, wann, was ist passiert?" |
| Beweis gültig | Sonne wird greifbar → Spieler zieht sie hoch → Durchbruch (Tier 2, größer als Tier 1) → **„+1 Tag"** erscheint zum ersten Mal, groß, darunter die gesunkene Nebelkante (kein Balken 1/30) → Karte „Der Schnitt" auf Stufe **Angewendet** |
| Danach eine Frage: **„Was war unangenehm daran?"** (eine Zeile, Skip erlaubt, „Bleibt auf deinem Gerät.") | Wird als eigener Satz gespeichert |
| **Der Satz über dich** (intern „Befund", das Wort erscheint nie in der UI). Ein Satz aus den eigenen Daten (Kacheln, Knoten-Entscheidungen, Denkfehler-Treffer): z. B. *„Dein Muster: Du prüfst das Lauwarme, statt es zu kippen."* Zwei Buttons: **„Stimmt"** / **„Stimmt nicht"** (Ablehnen ist kostenlos). Darunter dezent **„Teilen"** → Share-Card (Satz groß, Insel-Farbe, Wortmarke klein, `levmi.app`). Eine Geste tiefer die Herkunft der Karte: **„Nach Derek Sivers."** | `befundAnswered(accepted:)`; Share-Card mit `ImageRenderer` + `ShareLink` |
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
- **Haptik (CoreHaptics):** Transient bei jedem Tap, Continuous-Ramp beim Halten (Intensität folgt dem Ring), schwerer Doppel-Transient beim Einschlag, langer Sweep + harter Schlag beim Durchbruch. Läuft im Simulator ins Leere, darf nicht crashen.
- **Sound (AVAudioEngine, prozedural, kein Asset):** Drone (zwei verstimmte Sinus + langsames LFO-Filter), Knoten-Töne (singt = reine Quinte, brummt = tiefer dumpfer Ton, flirrt = schwebendes Detune mit Tremolo), Einschlag (Noise-Burst + Sub), Durchbruch (Dur-Akkord, der sich aus einer Spannung löst). Alle Töne timing-genau zu Haptik und Partikeln.

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
public enum PainTile: String, Codable, CaseIterable, Sendable { case zeitWeg, zuVielLauwarmes, keinFortschritt, geldReichtNicht, immerErreichbar, allesHaengtAnMir; public var inverted: String { get } }
public enum GamePhase: String, Codable, Sendable { case firstLight, nodes, roots, dawn, breakthrough, onboardingPain, onboardingFlip, onboardingWhy, intention, closed, waiting, proof, dawnProof, breakthroughProof, cost, befund, idle }
public struct Rules: Sendable { appliedLock: TimeInterval; proofWindow: TimeInterval; replayMinAge: TimeInterval; lightsPerNight: Int; minProofChars: Int; minExplanationChars: Int; static let standard: Rules; static let demo: Rules }
// standard: appliedLock 600 s (10 Min), proofWindow 86_400 s, replayMinAge 86_400 s, lightsPerNight 2, minProofChars 40, minExplanationChars 60
// demo:     appliedLock 30 s, proofWindow 600 s, replayMinAge 60 s, lightsPerNight 2, minProofChars 40, minExplanationChars 60
public struct PlayerState: Codable, Sendable, Equatable { phase, createdAt, lastOpenedAt, lightsRemaining, lightColorTile: PainTile?, pains: [PainTile], why: String?, intention: Intention?, closedAt: Date?, readyAt: Date?, progress: [String: PrincipleProgress], days: Int, ownSentences: [OwnSentence], nodeOutcomes: [NodeKind], befund: Befund?, befundAccepted: Bool? }
public enum GameAction: Sendable { case appOpened; case lightDropped; case lightPlaced(NodeKind); case sunPulled(Double); case painSelected([PainTile]); case whyEntered(String?); case intentionChosen(Intention); case closeForToday; case proofSubmitted(String); case costEntered(String?); case befundAnswered(accepted: Bool); case dismissOwnSentence }
public enum Effect: Equatable, Sendable { case scene(SceneCommand); case haptic(HapticCue); case sound(SoundCue); case persist; case reject(reason: String); case showOwnSentence(OwnSentence); case showBefund(Befund) }
public struct Befund: Codable, Sendable, Equatable { let sentence: String; let evidence: [String]; let principleID: String }
public enum BefundGenerator { public static func generate(pains: [PainTile], nodeOutcomes: [NodeKind], fallacyHits: [String: Int]) -> Befund }
// Regeln: nodeOutcomes enthält ≥ 1 .lukewarm → „Dein Muster: Du prüfst das Lauwarme, statt es zu kippen." (evidence: Anzahl lauwarmer Setzungen, Denkfehler-ID lauwarm-lager)
//         sonst, .cold gewählt vor .glowing → „Du erkennst ein Nein, bevor du das Glühende suchst." · sonst → „Du erkennst Glühendes sofort. Dein Engpass liegt nicht im Entscheiden, sondern im Wegräumen." + erste Kachel als Evidenz.
public enum GameEngine { public static func reduce(_ state: PlayerState, _ action: GameAction, clock: any Clock, world: World, rules: Rules) -> (PlayerState, [Effect]); public static func initial(clock: any Clock, rules: Rules) -> PlayerState }

// Proof
public struct Intention: Codable, Sendable, Equatable, Identifiable { id, principleID, text, createdAt, dueBy }
public struct Proof: Codable, Sendable, Equatable { text, submittedAt, principleID }
public enum ProofValidator { public static func validate(_ text: String, rules: Rules, drillInstruction: String) -> ProofVerdict }  // .accepted / .tooShort(min:) / .copied / .empty
public struct DayLedger { public static func days(after proofs: [Proof], window: TimeInterval) -> Int }  // 1 Tag pro Prinzip pro Fenster
public enum ReplayScheduler { public static func sentence(from: [OwnSentence], now: Date, minAge: TimeInterval, lastShownID: String?) -> OwnSentence? }
public struct OwnSentence: Codable, Sendable, Equatable, Identifiable { id, text, createdAt, context: OwnSentenceContext }  // .why, .cost, .explanation

// Scene contract (Datentypen)
public enum SceneCommand: Equatable, Sendable { case presentLight; case revealIsland; case cameraPullBack; case presentNodes([NodeKind]); case chargeNode(NodeKind, progress: Double); case impact(NodeKind); case showRoots(RootStrength); case drainLight; case thud; case presentSun; case sunProgress(Double); case dawn; case breakthrough(BreakthroughTier); case tintLight(PainTile?); case rootWindow(visible: Bool); case fogLevel(Int) }
public enum SceneEvent: Sendable { case lightDropped; case nodeHoldBegan(NodeKind); case nodeHoldEnded(NodeKind, completed: Bool); case sunDragged(Double); case sunReleased(Double) }
public protocol Clock: Sendable { var now: Date { get } }
public protocol SaveStore { func load() throws -> PlayerState?; func save(_ state: PlayerState) throws }
```

### 3.2 Ablaufregeln des Reducers (Testgrundlage)

1. `initial` → Phase `firstLight`, `lightsRemaining = rules.lightsPerNight`, `days = 0`.
2. `lightDropped` in `firstLight` → Phase `nodes`, Effekte `[.scene(.revealIsland), .haptic(.impact), .sound(.impact), .scene(.cameraPullBack), .scene(.presentNodes(kinds))]` mit `kinds` = fünf Knoten `[.glowing, .glowing, .lukewarm, .lukewarm, .cold]` in gemischter Reihenfolge (alle fünf enthalten).
3. `lightPlaced(.glowing)` in `nodes` → `lightsRemaining -= 1`, Effekte enthalten `.scene(.impact(.glowing))`, `.scene(.showRoots(.strong))`, Progress `schnitt` → `recognized`. Ist danach `lightsRemaining > 0`: Phase bleibt `nodes`, Effekt `.scene(.presentLight)` (zweites Licht). Ist `lightsRemaining == 0`: Phase `roots`, Effekt `.scene(.presentSun)`.
4. `lightPlaced(.lukewarm)` in `nodes` → `lightsRemaining` unverändert (das gefressene Licht wird ersetzt), Phase bleibt `nodes`, Effekte `[.scene(.drainLight), .haptic(.drain), .sound(.lukewarm), .scene(.presentLight)]`, `nodeOutcomes` merkt sich `.lukewarm`, `fallacyHits["lauwarm-lager"] += 1`.
5. `lightPlaced(.cold)` in `nodes` → nichts verbraucht, Effekte `[.scene(.thud), .haptic(.tap), .sound(.cold)]`, Phase bleibt `nodes`.
6. `sunPulled(p)` in `roots` → Effekt `.scene(.sunProgress(p))`; bei `p >= 1` Phase `breakthrough`, Effekte `[.scene(.dawn), .scene(.breakthrough(.first)), .haptic(.breakthrough), .sound(.breakthrough), .persist]`, danach automatisch Phase `onboardingPain` (Reducer setzt `phase = .onboardingPain`).
7. `painSelected(tiles)` (≥ 1) → `pains = tiles`, `lightColorTile = tiles.first`, Phase `onboardingWhy`, Effekte `[.scene(.tintLight(tiles.first)), .haptic(.flip)]`. Leere Auswahl → `.reject`.
8. `whyEntered(text)` → wenn Text nicht leer: `ownSentences += [.why]`; Phase `intention`.
9. `intentionChosen(i)` → `intention = i` (dueBy = now + proofWindow), Phase `closed`, Effekt `.persist`.
10. `closeForToday` in `closed` → `closedAt = now`, `readyAt = now + rules.appliedLock`, Phase `waiting`, Effekte `[.scene(.rootWindow(visible: true)), .persist]`.
11. `appOpened` in `waiting` mit `now < readyAt` → bleibt `waiting`, Effekt `.scene(.rootWindow(visible: true))` (die UI zeigt „Zurück ab HH:MM" aus `readyAt`). Mit `now >= readyAt` → Phase `proof`, Effekte enthalten `.scene(.rootWindow(visible: false))`.
12. `proofSubmitted(text)` in `proof` → `ProofValidator`; bei `.accepted`: `progress["schnitt"].proofs += [proof]`, Stufe `applied`, `days = DayLedger.days(...)`, Phase `dawnProof`, Effekte `[.scene(.presentSun), .persist]`. Sonst `.reject(reason:)`, Phase bleibt.
13. `sunPulled(p >= 1)` in `dawnProof` → Phase `cost`, Effekte `[.scene(.dawn), .scene(.breakthrough(.second)), .scene(.fogLevel(1)), .haptic(.breakthrough), .sound(.breakthrough), .persist]`.
14. `costEntered(text)` → wenn Text: `ownSentences += [.cost]`; `befund = BefundGenerator.generate(...)`; Phase `befund`, Effekte `[.showBefund(befund), .persist]`.
14b. `befundAnswered(accepted)` in `befund` → `befundAccepted = accepted`; Phase `idle`, Effekt `.persist`. Ablehnen hat keine weiteren Folgen.
15. `appOpened` in `idle` → wenn `ReplayScheduler` einen Satz liefert: Effekt `.showOwnSentence(s)`; sonst nichts. `lastOpenedAt = now` bei jedem `appOpened`.
16. Jede Aktion in einer Phase, für die sie nicht definiert ist → Zustand unverändert, Effekte `[]`.
17. `days` zählt pro Prinzip höchstens einen Beweis pro `proofWindow`.

---

## 4. Testplan (Opus schreibt zuerst, Sonnet implementiert)

**LevmiCoreTests** (Swift Testing, `swift test`):
- `ContentLoaderTests`: lädt `werkstatt.json` aus `Bundle.module`, 3 Prinzipien, IDs `schnitt`, `ein-prozent-spur`, `engstelle`, Reihenfolge 1–3, `inputKind` `.liste(min:)` dekodiert, Attribution vorhanden.
- `ContentValidatorTests`: jede Regel 1–8 aus Memo 05 als eigener Test mit einem absichtlich kaputten Prinzip (zu langer `core`, 2 Optionen, 2 korrekte, fehlende `fallacyID`, Drill 11 Min, unbekannte Voraussetzung, Zyklus, fehlende Attribution, Sperrbegriff „Geissens"/Buchtitel/Autorname, < 3 Fragen). Der gelieferte Content ist fehlerfrei.
- `CopyCheckTests`: 7-Wort-Überschneidung erkannt, 6 Wörter nicht, Groß-/Kleinschreibung und Satzzeichen egal.
- `ProofValidatorTests`: leer, nur Leerzeichen, 39 Zeichen, 40 Zeichen, Abschrift der Drill-Anleitung.
- `DayLedgerTests`: 0 ohne Beweise, 1 mit einem, 1 mit zwei innerhalb des Fensters, 2 mit zwei außerhalb.
- `ReplaySchedulerTests`: nil ohne Sätze, nil wenn alle jünger als minAge, ältester zuerst, `lastShownID` wird übersprungen wenn ein anderer verfügbar ist.
- `RulesTests`: `standard` (10 Min / 24 h / 1 Tag / 2 Lichter / 40 / 60), `demo` (30 s / 10 Min / 1 Min / 2 / 40 / 60).
- `GameEngineTests`: Regeln 1–17 oben, jede als Test, plus ein „Golden Path" durch den ganzen Loop mit `TestClock`, plus „Golden Path im Demo-Modus".
- `BefundGeneratorTests`: die drei Fälle aus 3.1, Evidenz nicht leer, `principleID == "schnitt"`.
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
