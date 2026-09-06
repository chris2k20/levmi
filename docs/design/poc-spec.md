# LEVMI — PoC-Spezifikation „Erste Nacht" (verbindlich für Tests und Code)

**Stand:** 2026-09-07 01:30 · **Autor:** Architekt · **Ziel:** Morgen früh baut die App, läuft im iPhone-17-Simulator, und der Loop ist spürbar.

Diese Spezifikation ist der Vertrag zwischen den Rollen: **Opus-Chefs schreiben daraus Tests, Sonnet-Coder implementieren dagegen.** Wer etwas anders baut, ändert erst diese Datei.

---

## 1. Spielerfahrung: der eine Durchlauf

### 1.1 Erster Start (die erste Minute, reines Spiel, ohne Text bis auf zwei Zeilen)

| Schritt | Spieler sieht/fühlt | Domain-Ereignis |
|---|---|---|
| Schwarz, Subbass, ein Lichtpunkt, Haptik-Impuls | Ein leuchtender Punkt in der Mitte, Nebelmeer darunter | `appOpened` → Phase `firstLight` |
| Finger berührt den Punkt, zieht ihn nach unten in den Nebel, lässt los | Nebel teilt sich, ein Inselfragment hebt sich, Partikelring, schwerer Einschlag | `lightDropped` → Szene `revealIsland` |
| Kamera fährt zurück, warmes Pad setzt ein | Fragment allein im Nebelmeer | Szene `cameraPullBack` |
| Drei Knoten auf der Insel | Einer **singt** (reine Quinte, warmes Glühen), einer **brummt** (stumpf, kalt), einer **flirrt** lauwarm (Sanduhr-Puls) | Szene `presentNodes` |
| Text 1 (4 Wörter): **„Du hast ein Licht."** | Erscheint, verschwindet | — |
| Langer Druck auf einen Knoten: Ring füllt sich, Haptik rampt hoch, Vignette schließt | Loslassen = Licht gesetzt | `lightPlaced(node)` |
| **Singender Knoten:** Einschlag, Kamera taucht 1,5 s unter die Nebelkante, goldenes Wurzelnetz breitet sich aus. Oben bleibt es dunkel. | „Es passiert etwas, ich seh es nur nicht" | Szene `showRoots(strength: .strong)` |
| **Lauwarmer Knoten:** Licht wird sichtbar aufgesaugt, Sanduhr läuft, dünne graue Wurzel, das Licht ist weg. Text 2: **„Das Lauwarme hat dein Licht gefressen."** Dann erscheint ein neues Licht. | Der Lernmoment | `lightPlaced(.lukewarm)` → Szene `drainLight`, danach `presentLight` erneut |
| **Brummender Knoten:** dumpfer Schlag, nichts wächst, Licht bleibt erhalten (du darfst neu setzen) | Kalt = klares Nein, kostet nichts | Szene `thud` |
| Sonnenscheibe erscheint am Horizont, der Spieler zieht sie mit dem Finger hoch (Tutorial-Nacht: sofort erlaubt) | Zeitraffer, Licht streicht über die Insel, Nebel sinkt eine Stufe | `sunPulled(progress)` → bei ≥ 1.0 `dawnCompleted` |
| **Durchbruch:** ein Kristalltrieb bricht durch die Oberfläche, Geometrie knackt auf, Partikelburst, Akkord löst sich auf, harte Haptik, Kamera schiebt hinein | Der Belohnungsmoment | Szene `breakthrough(tier: .first)` |

Keine Zahl, kein Zähler in der ersten Minute.

### 1.2 Onboarding (nach dem Erfolg, nie davor)

1. **„Was nervt dich gerade am meisten?"** — 6 Kacheln, Mehrfachauswahl: *Zeit weg · Zu viel Lauwarmes · Kein Fortschritt · Geld reicht nicht · Immer erreichbar · Alles hängt an mir.* → `painSelected([PainTile])`
2. **Umkehr-Animation:** Jede gewählte Kachel dreht sich live um und zeigt ihr Gegenteil (*Zeit weg → Deine Zeit gehört dir* usw.). 3 Sekunden, Haptik pro Flip.
3. **„Wofür?"** — eine Zeile Freitext, Skip erlaubt. Die Antwort färbt das Licht des Spielers dauerhaft (Farbton aus der ersten gewählten Kachel, Freitext wird als eigener Satz gespeichert). → `whyEntered(String?)`
4. **Absicht für heute** — drei Vorschläge aus dem Drill der Karte „Der Schnitt", klein genug für heute (z. B. „Sag heute zu einer lauwarmen Sache ab, ein Satz, keine Begründung."), plus „eigene". → `intentionChosen(Intention)`
5. **„Für heute reicht's."** — die App schickt den Spieler weg. Ein Satz: „Die Wurzeln arbeiten. Komm zurück, wenn du es getan hast." → `closeForToday`

### 1.3 Rückkehr (der Beweis-Loop)

| Bedingung | Was passiert |
|---|---|
| Zurück **vor** Ablauf der Sperre (Standard 60 Min, Demo 30 s) | Welt zeigt das Wurzelfenster (Insel durchscheinend, goldene Wurzeln pulsieren), Sonne ist nicht greifbar. Ein Satz: „Noch nicht. Die Wurzeln arbeiten." Kein Beweis möglich. |
| Zurück **nach** Ablauf | Die Absicht des Spielers in seinen eigenen Worten. Frage: **„Hast du es getan?"** → Feld für den Beweis (≥ 40 Zeichen, konkret: Wer? Wann? Was passierte?). Zähler zeigt Zeichen. |
| Beweis ungültig (zu kurz, Abschrift der Anleitung) | Kein Vorwurf. Feld bleibt, Hinweis: „Konkreter: Wer, wann, was ist passiert?" |
| Beweis gültig | Sonne wird greifbar → Spieler zieht sie hoch → Durchbruch (Tier 2, größer als Tier 1) → **„+1 Tag"** erscheint zum ersten Mal, Balken 1/30 → Karte „Der Schnitt" auf Stufe **Angewendet** |
| Danach eine Frage: **„Was hat es dich gekostet?"** (eine Zeile, Skip erlaubt) | Wird als eigener Satz gespeichert |
| **Der Befund.** Ein Satz über den Spieler, aus seinen eigenen Daten (Kacheln, Knoten-Entscheidungen, Denkfehler-Treffer): z. B. *„Dein Muster: Du prüfst das Lauwarme, statt es zu kippen."* Zwei Buttons: **„Stimmt"** / **„Stimmt nicht"** (Ablehnen ist kostenlos). Darunter **„Teilen"** → Share-Card (Bild: Befund groß, Insel-Farbe, Wortmarke klein, kein Account). | `befundAnswered(accepted:)`; die Share-Card entsteht mit `ImageRenderer` + `ShareLink` |
| Beim nächsten Öffnen (≥ 1 Tag später, Demo ≥ 1 Min) | Zuerst ein eigener Satz des Spielers von früher: „Du hast geschrieben: …" | 

### 1.4 Demo-Modus

Ein Flag (`Rules.demo`), das **nur Zeitkonstanten** verkürzt (Sperre 60 Min → 30 s, Beweisfenster 24 h → 10 Min, Rückspiel-Mindestalter 1 Tag → 1 Min). Keine Regel wird ausgeschaltet. Im DEBUG-Build über einen kleinen Schalter oben rechts erreichbar, im Release nicht sichtbar.

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
public struct PlayerState: Codable, Sendable, Equatable { phase, createdAt, lastOpenedAt, lightsRemaining, lightColorTile: PainTile?, pains: [PainTile], why: String?, intention: Intention?, closedAt: Date?, progress: [String: PrincipleProgress], days: Int, ownSentences: [OwnSentence], nodeOutcomes: [NodeKind], befund: Befund?, befundAccepted: Bool? }
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
2. `lightDropped` in `firstLight` → Phase `nodes`, Effekte `[.scene(.revealIsland), .haptic(.impact), .sound(.impact), .scene(.cameraPullBack), .scene(.presentNodes([.glowing,.cold,.lukewarm]))]` (Reihenfolge der Knoten wird gemischt, alle drei sind enthalten).
3. `lightPlaced(.glowing)` in `nodes` → `lightsRemaining -= 1`, Phase `roots`, Effekte enthalten `.scene(.showRoots(.strong))`, Progress `schnitt` → `recognized`; `.scene(.presentSun)` folgt.
4. `lightPlaced(.lukewarm)` in `nodes` → `lightsRemaining` unverändert (das gefressene Licht wird ersetzt), Phase bleibt `nodes`, Effekte `[.scene(.drainLight), .haptic(.drain), .sound(.lukewarm), .scene(.presentLight)]`, `nodeOutcomes` merkt sich `.lukewarm`, `fallacyHits["lauwarm-lager"] += 1`.
5. `lightPlaced(.cold)` in `nodes` → nichts verbraucht, Effekte `[.scene(.thud), .haptic(.tap), .sound(.cold)]`, Phase bleibt `nodes`.
6. `sunPulled(p)` in `roots` → Effekt `.scene(.sunProgress(p))`; bei `p >= 1` Phase `breakthrough`, Effekte `[.scene(.dawn), .scene(.breakthrough(.first)), .haptic(.breakthrough), .sound(.breakthrough), .persist]`, danach automatisch Phase `onboardingPain` (Reducer setzt `phase = .onboardingPain`).
7. `painSelected(tiles)` (≥ 1) → `pains = tiles`, `lightColorTile = tiles.first`, Phase `onboardingWhy`, Effekte `[.scene(.tintLight(tiles.first)), .haptic(.flip)]`. Leere Auswahl → `.reject`.
8. `whyEntered(text)` → wenn Text nicht leer: `ownSentences += [.why]`; Phase `intention`.
9. `intentionChosen(i)` → `intention = i` (dueBy = now + proofWindow), Phase `closed`, Effekt `.persist`.
10. `closeForToday` in `closed` → `closedAt = now`, Phase `waiting`, Effekte `[.scene(.rootWindow(visible: true)), .persist]`.
11. `appOpened` in `waiting` mit `now - closedAt < appliedLock` → bleibt `waiting`, Effekt `.scene(.rootWindow(visible: true))`. Mit `now - closedAt >= appliedLock` → Phase `proof`, Effekte enthalten `.scene(.rootWindow(visible: false))`.
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
- `RulesTests`: `standard` (60 Min / 24 h / 1 Tag / 1 Licht / 40 / 60), `demo` (30 s / 10 Min / 1 Min / 1 / 40 / 60).
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
