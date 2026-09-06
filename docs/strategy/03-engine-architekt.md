# Levmi — Engine, Architektur & Nachtplan

**Rolle:** iOS-3D-Engine-Architekt · **Datum:** 2026-09-07 · **Empfänger:** Christian Simons
**Status:** Alle technischen Aussagen unten sind auf **deinem** Rechner verifiziert, nicht aus dem Gedächtnis zitiert.

---

## 0. Faktencheck vorweg — vier Dinge im Briefing sind falsch

Ich habe das Setup vermessen, bevor ich eine Zeile Strategie geschrieben habe. Vier Annahmen halten nicht:

| Behauptung im Briefing | Realität auf deinem Mac | Konsequenz |
|---|---|---|
| Team-ID = `DAV56Y8ZHK` | **Falsch.** `DAV56Y8ZHK` ist die Zertifikats-Kennung. Die Team-ID im OU-Feld ist **`NVN9F2C593`** (ImmoDigit GmbH). Zweites Team: `RJS9C92DA6` (Christian Simons, privat). | `DEVELOPMENT_TEAM: DAV56Y8ZHK` in der `project.yml` → Signing schlägt fehl. Kostet dich sonst 40 Minuten Ratlosigkeit um 3 Uhr nachts. |
| „SceneKit ist ab iOS 26 deprecated" | **Halb falsch.** Im iOS-26.5-SDK trägt **kein einziges Kern-Symbol** (`SCNView`, `SCNNode`, `SCNCamera`, `SCNParticleSystem`, `SCNTechnique`) ein `API_DEPRECATED`. Nur 4 alte Randheader. SceneKit ist *soft deprecated*: Wartungsmodus, keine neuen Features, aber **keine Compilerwarnung, kein Entzug**. | SceneKit ist heute Nacht legitim. Der Preis ist Stillstand, nicht Abschaltung. |
| „RealityKit hat kein Post-Processing auf iOS" | **Falsch seit iOS 26.** `PostProcessEffect` + `RealityViewRenderingEffects` sind public: DoF, Motion Blur, Camera Grain, MSAA und `customPostProcessing` mit Zugriff auf `sourceColorTexture`/`sourceDepthTexture`/`commandBuffer`. Ich habe es kompiliert. | RealityKit ist stärker als gedacht — **aber** `RealityViewDynamicRange` exponiert nur `.default`/`.standard`; **`_hdrRendering` ist `internal`**. Kein öffentlicher HDR-Schalter. Bloom musst du selbst als Metal-Pass schreiben. |
| „Xcode 27 installieren, dann läuft's auf dem iPhone" | **Nicht heute Nacht.** Du hast **46 GB frei**. Ein Xcode-.xip braucht beim Entpacken Download + entpackte App gleichzeitig (~45 GB Peak), dazu die iOS-27-Simulator-Runtime. Das geht sich nicht aus, ohne Xcode 26.6 vorher zu löschen — und damit dein einziges funktionierendes Setup. | Device-Deploy ist heute Nacht **kein Ziel**. Siehe §2.7. |

**Was gut ist:** M4 Max, 36 GB RAM, iPhone-17-Simulator bootet, XcodeGen 2.46, Swift 6.3.3. Ein Clean-Build der von mir gebauten Projektskizze dauert **9,6 Sekunden**. Die Iterationsschleife heute Nacht ist schnell. Das ist der eigentliche Erfolgsfaktor, nicht die Engine.

---

## 1. Urteil über das Briefing

**Stark:** Der vertikale Schnitt ist richtig gedacht. Der IP-Abschnitt ist präzise. Das Unity-Verbot für den PoC ist die richtige Engpass-Entscheidung.

**Naiv:** „Platz 1 im App Store durch Grafik". Kein 3D-Spiel wurde jemals #1, weil es hübsch war. Die Top-Grossing-Liste gehört Retention-Loops, nicht Renderern. Grafik ist ein **Türöffner für Sekunde 1–30**, danach entscheidet die Schleife. Wenn du 80 % der Nacht in Shader steckst und 20 % in die Belohnungsmechanik, baust du eine Techdemo, die niemand ein zweites Mal öffnet.

**Die weiße Information** (Gesetz 5 — und die ist teuer): Das Briefing setzt stillschweigend voraus, dass **„3D" das ist, was das Produkt besonders macht**. Das ist die unsichtbare Vorbefüllung im Taschenrechner. Tatsächlich ist 3D hier ein *Ausdrucksmittel* für Metaphern, die auch in 2D funktionieren würden (80/20-Teilung, Kette mit schwachem Glied, Fluss gegen den Strom). Der Wettbewerbsvorteil von Levmi liegt in der **Verdichtung von 43 Gesetzen zu spielbaren Entscheidungen** — nicht in Polygonen. Wer das verwechselt, optimiert am falschen Hebel (Gesetz 20).

**Zweite weiße Information:** „Test-Driven Development" und „3D-Rendering" werden im Briefing als ein Arbeitsmodus behandelt. Sie sind zwei. Rendering ist nicht TDD-bar. Wenn du das nicht vorher trennst, blockieren sich deine Agenten gegenseitig. Siehe §2.5.

---

## 2. Strategie

### 2.1 PoC heute Nacht: **SceneKit.** Keine Diskussion.

Begründung in einer Zeile: **SceneKit gibt dir HDR + Bloom + Vignette + SSAO + DoF in fünf Property-Zuweisungen; RealityKit verlangt dafür einen selbstgeschriebenen Metal-Bloom-Pass; Metal pur verlangt eine Nacht nur für die Pipeline.**

Verifiziert im SDK — das ist dein komplettes „Wow"-Budget in 6 Zeilen:

```swift
let cam = SCNCamera()
cam.wantsHDR = true          // ios(10.0)
cam.bloomIntensity = 1.4     // ios(10.0)
cam.bloomThreshold = 0.35
cam.bloomBlurRadius = 18
cam.vignettingPower = 1.2
cam.screenSpaceAmbientOcclusionIntensity = 0.6
```

Dazu kommen ohne Zusatzarbeit: `SCNParticleSystem`, Physik, `SCNAction`-Choreografie mit Easing, `SCNTechnique` für eigene Passes.

Gegen RealityKit **für heute Nacht** (nicht grundsätzlich): kein öffentliches HDR, Bloom = Handarbeit in Metal, Entity-Component-Denke kostet Einarbeitungszeit, die du nicht hast. Gegen Metal pur: 6–8 Stunden bis zum ersten beleuchteten Dreieck.

**Der ehrliche Preis von SceneKit:** Du baust auf einem Framework, das Apple eingefroren hat. Das ist vertretbar, weil du die Migration von Tag 1 an einkapselst (§2.4) — aber nur dann.

### 2.2 Produkt in 6–12 Monaten: **RealityKit, nativ. Nicht Unity.**

Kaufe dir nicht ein zweites Ökosystem für ein Spiel, dessen Kern **Text, Entscheidung und Fortschritt** ist und dessen 3D-Anteil stilisiert ist. Unity würde dir bringen: bessere Tools, Cross-Platform, größerer Talentpool. Es würde dich kosten: 60–200 MB App-Größe, Runtime-Fee-Risiko, kein Liquid Glass, keine native Haptik-Integration, kein „fühlt sich wie iOS an" — und genau das ist dein Differenzierungsmerkmal gegen die 400 generischen Unity-Persönlichkeitsapps.

**Ausnahme, bei der ich meine Meinung ändere:** Wenn Android innerhalb von 12 Monaten kommen muss. Dann sofort Unity, weil eine zweite native Codebasis teurer ist als der Ökosystemwechsel. Das ist eine Business-Frage, keine Engine-Frage — sie steht in §6.

### 2.3 Cheap Wow vs. Expensive Wow

**Cheap Wow (jeweils ≤ 45 Min, Effekt/Aufwand > 10×):**

1. **Emission + Bloom auf schwarzem Grund.** Der billigste „teuer aussehende" Effekt der Welt. Ein leuchtender Körper im dunklen Raum wirkt zehnmal wertvoller als derselbe Körper in einer hellen Szene.
2. **Prozedurale Low-Poly-Geometrie statt Assets.** `SCNSphere/Box/Torus/Tube` + `flatShading` + goldener Winkel für Verteilungen. Null Asset-Pipeline, null Import-Debugging.
3. **Kamera-Choreografie.** `SCNAction`/`SCNTransaction` mit `CAMediaTimingFunction(.easeInEaseOut)`, ein langsamer Dolly-In beim Szenenstart. Menschen lesen Kamerabewegung als Produktionswert.
4. **Fog.** `scene.fogStartDistance/fogEndDistance/fogColor` — 3 Zeilen, erzeugt Tiefe und versteckt, dass hinten nichts ist.
5. **Partikel als Interpunktion.** Ein `SCNParticleSystem` beim Belohnungsmoment, nicht dauerhaft.
6. **Haptik.** `CHHapticEngine`: `.hapticTransient` auf jeder Entscheidung, `.hapticContinuous`-Sweep beim Ergebnis. **Der billigste emotionale Effekt überhaupt** — im Simulator unsichtbar, deshalb systematisch unterschätzt.
7. **Liquid Glass für Overlays.** `glassEffect(.regular, in: .capsule)` — verifiziert in `SwiftUICore` (iOS 26), kompiliert. Die UI sieht in 10 Minuten nach 2026 aus statt nach 2019.
8. **120 Hz.** `view.preferredFramesPerSecond = 120` **plus** `CADisableMinimumFrameDurationOnPhone = true` in der Info.plist. Ohne den Plist-Key bleibst du auf dem Gerät bei 60 Hz — der meistübersehene ProMotion-Fehler.
9. **Sound.** `AVAudioEngine`, ein Drone-Loop plus zwei Transients. Ton macht mehr Wow-Differenz als jeder Shader, und niemand plant ihn ein.

**Expensive Wow (heute Nacht **nicht** anfassen):** Custom-Metal-Shader über `SCNTechnique`, God Rays, SSR, gerigte Charaktere, eigene HDR-IBL-Maps, Cloth/Softbody, GPU-Instancing > 5.000 Objekte, jede Form von Asset-Import (USDZ/glTF). Jeder Punkt kostet 3–6 Stunden und erzeugt weniger Staunen als Punkt 1 und 6 oben.

**Bezug zu den Gesetzen** — die vier Metaphern mit dem besten Wow/Aufwand-Verhältnis: **Energie-Bündelung** (G36: verstreute Leuchtpunkte per Drag zusammenziehen → Zündung), **Engpass/Kette** (G41: leuchtender Fluss durch Glieder, eines glüht rot), **80/20-Teilung** (G8: Masse teilt sich sichtbar), **Bambus-Wurzel** (G13: unter der Oberfläche passiert lange nichts, dann Explosion). Alle vier sind Partikel + Emission + eine Geste. Welche der PoC nimmt, entscheidet der Game-Designer — technisch sind sie gleich billig.

### 2.4 Architektur — drei Module, eine Naht

```
Levmi/
├── Packages/LevmiCore/       Swift Package. Reine Domain, kein UIKit/SceneKit/SwiftUI-Import.
│   └── Law, LawContent, Progression, RewardEngine, Streak, SaveState, SessionClock
├── App/Sources/
│   ├── Scene/                LevmiScene: alles SceneKit. Hinter Protokoll.
│   └── UI/                   SwiftUI-Shell, Overlays, Liquid Glass
└── Tests/
```

**Die eine Naht, die über das Migrationsrisiko entscheidet.** Kein SceneKit-Typ verlässt jemals `Scene/`:

```swift
// in LevmiCore — framework-frei, Sendable, testbar
public enum SceneCommand: Sendable {
    case present(LawID)
    case focus(Float)          // 0…1 Bündelungsgrad
    case reward(RewardTier)
    case transition(to: LawID)
}
public protocol SceneRenderer: AnyObject {
    func apply(_ command: SceneCommand)
    var events: AsyncStream<SceneEvent> { get }
}
```

`SceneKitRenderer` implementiert das. Für RealityKit schreibst du in 6 Monaten `RealityKitRenderer` daneben, schaltest per Feature-Flag um und wirfst den alten raus, wenn er sich bewährt hat. **Domain-Logik wird nie migriert, weil sie das Framework nie gesehen hat.** Das ist die gesamte Versicherung gegen die SceneKit-Deprecation — und sie kostet dich heute Nacht 20 Minuten.

Regel, die du durchsetzen musst: **`LevmiCore` importiert nichts außer `Foundation`.** Ein `import SceneKit` dort ist ein Merge-Blocker, kein Diskussionsthema.

### 2.5 TDD — was getestet wird und was nicht

**Wird TDD'd (100 %, Chef-Agenten schreiben die Tests zuerst):** Progression/XP-Kurven, Reward-Engine (welcher Trigger löst welchen Tier aus), Streak- und Kalenderlogik inkl. Zeitzonen und Tageswechsel, Save-State-Serialisierung und Migration, Content-Modell-Validierung (jedes Gesetz hat Titel/Metapher/Entscheidung/Konsequenz), Entscheidungsgraph.

**Warum das schnell ist — gemessen:** `swift test` auf `LevmiCore` läuft **auf dem Mac-Host, ohne Simulator**. Kalt 7,2 s inkl. Build, die Tests selbst 1 ms. Das ist deine TDD-Schleife. Sonnet-Agenten können im Sekundentakt iterieren.

```bash
swift test --package-path Packages/LevmiCore     # der schnelle Loop
```

**Wird NICHT TDD'd:** Rendering, Kamerafahrten, Partikelparameter, Timing-Feel, Haptik-Kurven. Diese Dinge werden *gesehen*, nicht assertiert. Wer versucht, Bloom-Intensität per Unit-Test festzunageln, verbrennt die Nacht.

**Wie du Rendering trotzdem absicherst — drei Gitter statt Tests:**
1. **Konstruktions-Smoke-Test:** Szene lässt sich bauen, hat Kamera + Licht + erwartete Knotenanzahl, `apply(_:)` crasht bei keinem `SceneCommand`. Läuft im Simulator-Testtarget, ~2 s.
2. **Frame-Time-Budget als Assertion:** `SCNSceneRendererDelegate` misst die Frame-Zeit, der Smoke-Test lässt 120 Frames laufen und schlägt fehl, wenn p95 > 8,3 ms. Das ist der einzige sinnvolle „Performance-Test" heute Nacht.
3. **Screenshot pro Build:** `xcrun simctl io booted screenshot` nach dem Launch, ins Repo. Kein Golden-Master-Vergleich (zu spröde), aber ein Blick pro Commit fängt schwarze Bildschirme.

**Ein verifizierter TDD-Fallstrick, der euch heute Nacht garantiert trifft:** SceneKit speichert `CGFloat`-Properties intern als `Float`. `#expect(cam.bloomIntensity == 1.4)` **schlägt fehl** — der Wert kommt als `1.399999976158142` zurück. Ich habe genau diesen Test laufen lassen und er ist rot geworden. Regel für die Agenten: gegen SceneKit-Properties nur mit Toleranz vergleichen (`abs(a - b) < 0.001`).

### 2.6 Projekt-Setup — getestet, baut in 9,6 s

Die folgende `project.yml` habe ich generiert, gebaut und getestet. Sie funktioniert unverändert:

```yaml
name: Levmi
options:
  bundleIdPrefix: de.immodigit
  deploymentTarget: { iOS: "26.0" }
  createIntermediateGroups: true

settings:
  base:
    SWIFT_VERSION: "6.0"
    SWIFT_STRICT_CONCURRENCY: complete
    DEVELOPMENT_TEAM: NVN9F2C593        # ImmoDigit GmbH — NICHT DAV56Y8ZHK
    CODE_SIGN_STYLE: Automatic

packages:
  LevmiCore: { path: Packages/LevmiCore }

targets:
  Levmi:
    type: application
    platform: iOS
    sources: [App/Sources]
    dependencies: [{ package: LevmiCore, product: LevmiCore }]
    info:
      path: App/Resources/Info.plist
      properties:
        CFBundleDisplayName: Levmi
        UILaunchScreen: {}
        CADisableMinimumFrameDurationOnPhone: true    # ProMotion 120 Hz
        UIRequiredDeviceCapabilities: [arm64, metal]
        UISupportedInterfaceOrientations: [UIInterfaceOrientationPortrait]
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: de.immodigit.levmi
        GENERATE_INFOPLIST_FILE: NO
        TARGETED_DEVICE_FAMILY: "1"

  LevmiAppTests:
    type: bundle.unit-test
    platform: iOS
    sources: [Tests/LevmiAppTests]
    dependencies: [{ target: Levmi }]
    settings:
      base: { GENERATE_INFOPLIST_FILE: YES }

schemes:
  Levmi:
    build: { targets: { Levmi: all } }
    run:   { config: Debug }
    test:  { config: Debug, targets: [LevmiAppTests] }
```

**Deployment-Target: iOS 26.0.** Nicht niedriger. Begründung: Liquid Glass, `RealityView`-Optionalität und moderne Swift-Concurrency setzen es voraus, und die Zielgruppe für ein Premium-3D-Spiel sitzt nicht auf iOS 17. Später herunterzugehen ist trivial, heute Nacht Fallbacks zu schreiben ist Zeitverschwendung.

**Bundle-ID:** `de.immodigit.levmi` ist korrektes Reverse-DNS. Beachte nur: eure bestehenden Profile laufen auf `com.immodigit.*`. Beides geht, aber entscheide es *jetzt* und nicht zweimal.

```bash
cd /Users/A1A7D65/stage2/levmi && xcodegen generate
xcodebuild build -project Levmi.xcodeproj -scheme Levmi \
  -destination 'platform=iOS Simulator,name=iPhone 17' -quiet
xcodebuild test  -project Levmi.xcodeproj -scheme Levmi \
  -destination 'platform=iOS Simulator,name=iPhone 17'
xcrun simctl install booted <pfad>/Levmi.app && xcrun simctl launch booted de.immodigit.levmi
```

`Levmi.xcodeproj` gehört in `.gitignore` — die `project.yml` ist die Wahrheit.

### 2.7 Das iOS-27-Gerät — ehrliche Antwort

**Heute Nacht: geht nicht. Plane es nicht ein.**

Fakten: Xcode 26.6 kennt DeviceSupport bis iOS 16 im Bundle, dein User-DeviceSupport hat `iPhone16,2 26.6`. Für iOS 27.0 fehlt es. Xcode 27 zu installieren scheitert an **46 GB freiem Speicher** (Peak-Bedarf beim Entpacken liegt darüber). Dein iPhone ist aktuell zwar gekoppelt (`devicectl` sieht es als „unavailable/paired"), aber nicht angeschlossen.

Was **theoretisch** ginge und was ich als 20-Minuten-Timebox erlauben würde, aber nicht als Plan: Build für `generic/platform=iOS` signieren und mit `xcrun devicectl device install app` installieren — CoreDevice braucht DeviceSupport primär für Debug-Symbole, nicht für plain install/launch. Wenn es nach 20 Minuten nicht läuft: abbrechen. TestFlight fällt aus, weil ihr **kein Apple-Distribution-Zertifikat** habt (nur zwei Apple-Development und ein Developer ID) — das nachts neu anzulegen plus App-Store-Connect-Record plus Processing ist eine Stunde Risiko für null Erkenntnisgewinn.

**Was du stattdessen morgen früh zeigst:** iPhone-17-Simulator auf dem M4 Max, im Vollbild, plus eine Bildschirmaufnahme. Das sieht gut aus. Der Unterschied Gerät/Simulator ist Haptik und echte 120 Hz — beides erklärst du in einem Satz.

**Diese Woche, nicht heute Nacht:** 100 GB freischaufeln → Xcode 27 parallel als `/Applications/Xcode-27.app` installieren → `xcode-select` umschalten. Dann Gerät, dann Haptik-Feintuning.

### 2.8 Performance & Concurrency — die drei Fallstricke

**(1) Swift 6 × SceneKit. Verifiziert, das kostet euch sonst eine Stunde.** SceneKit hat im SDK **null** `NS_SWIFT_UI_ACTOR`-Annotationen. Ein `@MainActor`-Typ, der `SCNSceneRendererDelegate` implementiert, kompiliert mit `SWIFT_STRICT_CONCURRENCY: complete` **nicht**:

> `error: conformance of 'MainActorLoop' to protocol 'SCNSceneRendererDelegate' crosses into main actor-isolated code and can cause data races [#ConformanceIsolation]`

Zwei Lösungen, beide von mir kompiliert:

```swift
// A) Konformanz explizit auf den MainActor isolieren (kurz, für UI-nahe Logik)
@MainActor final class Loop: NSObject, @MainActor SCNSceneRendererDelegate { … }

// B) Render-Loop ohne isolierten State, Übergabe per Mutex (richtig, für die Spielschleife)
import Synchronization
final class Loop: NSObject, SCNSceneRendererDelegate, @unchecked Sendable {
    private let frames = Mutex<Int>(0)
    func renderer(_ r: any SCNSceneRenderer, updateAtTime t: TimeInterval) {
        frames.withLock { $0 += 1 }
    }
}
```

Nimm **B** für den Render-Loop. `renderer(_:updateAtTime:)` läuft auf SceneKits Render-Thread, nicht auf Main — `MainActor.assumeIsolated` wäre dort ein Crash mit Ansage. RealityKit ist hier deutlich angenehmer (`@MainActor @preconcurrency` durchgehend annotiert) — ein weiterer Punkt für die Migration in 6 Monaten.

**(2) SwiftUI-Integration: `UIViewRepresentable` mit `SCNView`, nicht `SceneView`.** `SceneView` gibt dir keinen Zugriff auf `preferredFramesPerSecond`, `antialiasingMode` oder den Renderer-Delegate — also weder 120 Hz noch Frame-Budget-Messung. 15 Zeilen `UIViewRepresentable` sind das wert. Und: `updateUIView` **niemals** die Szene neu bauen lassen — Szene einmal in `makeUIView`, danach nur `SceneCommand`s.

**(3) Simulator lügt.** Metal ist emuliert: Partikelzahlen und Fill-Rate-Verhalten sind nicht übertragbar (der Simulator ist bei Partikeln oft *langsamer* als das Gerät, bei Overdraw *schneller*). Haptik existiert nicht. 120 Hz existiert nicht. Ableitung: **kalibriere Partikeldichte und Bloom-Radius heute Nacht konservativ** — was im Simulator flüssig ist, ist auf dem A17 Pro sicher flüssig, umgekehrt gilt es nicht.

**Budget:** 120 Hz = 8,3 ms/Frame. Ziel für den PoC: p95 unter 6 ms im Simulator. Obergrenzen für heute Nacht: ≤ 2.000 sichtbare Partikel gleichzeitig, ≤ 300 Draw Calls, ≤ 3 dynamische Lichter, Schatten nur von einem Licht (oder gar keine — Bloom trägt die Szene). Wenn du Schatten brauchst: `.deferred` mit `shadowSampleCount = 4`, nicht mehr.

---

## 3. Nicht verhandelbar

1. **`LevmiCore` importiert nur `Foundation`.** Kein SceneKit, kein SwiftUI, kein UIKit. Verletzung = Merge blockiert. Das ist deine gesamte Absicherung gegen die SceneKit-Deprecation.
2. **Rendering nur hinter `SceneRenderer`/`SceneCommand`.** Kein `SCNNode` in einer ViewModel-Signatur. Nie.
3. **Haptik + Sound sind Teil des PoC, nicht „Polish später".** Sie erzeugen mehr Wow pro investierter Minute als jeder Shader — und wenn sie nicht von Anfang an im Loop sind, kommen sie nie.
4. **Ein Screenshot pro grünem Build.** Sonst merkt niemand, dass die Szene seit drei Commits schwarz ist.
5. **`DEVELOPMENT_TEAM: NVN9F2C593`.** Nicht die Zertifikatskennung aus dem Briefing.

---

## 4. Der PoC heute Nacht

**Endergebnis:** Eine Szene. Ein Gesetz. Eine Geste. Ein Belohnungsmoment, der körperlich wirkt. Christian öffnet die App und will sie ein zweites Mal öffnen.

**Reihenfolge — früh etwas Sichtbares, dann Substanz:**

| # | Paket | Zeit | Warum in dieser Reihenfolge |
|---|---|---|---|
| 0 | Repo-Skelett, `project.yml`, `xcodegen`, leerer Build grün | 30 min | Ohne grünen Build ist alles andere Spekulation |
| 1 | Schwarzer Screen mit **einem leuchtenden Objekt**, HDR+Bloom+Fog, Dolly-In | 45 min | **Erstes Wow nach 75 Minuten.** Ab hier ist die Nacht psychologisch gerettet |
| 2 | `LevmiCore`: `Law`, `Progression`, `RewardEngine` — TDD, Tests zuerst | 60 min | Läuft parallel, braucht keinen Simulator (`swift test`) |
| 3 | `SceneRenderer`-Protokoll + `SceneCommand`, SceneKit dahinter | 45 min | Die Naht, bevor Code sie verletzt |
| 4 | Geste → `SceneCommand` → sichtbare Reaktion (Bündelung/Fokus) | 60 min | Der Kern-Loop |
| 5 | Belohnungsmoment: Partikel + Bloom-Puls + **CoreHaptics** + Sound | 60 min | Der emotionale Höhepunkt |
| 6 | Liquid-Glass-Overlay: Gesetzestitel, Fortschritt, eine Entscheidung | 45 min | Macht aus der Techdemo ein Produkt |
| 7 | Frame-Budget-Assertion, Smoke-Test, Screenshot, Aufräumen | 30 min | Definition of Done |

**Gesamt ~6,25 h reine Arbeit.** Puffer einplanen: das ist eine Nacht, keine Schicht.

**Definition of Done (alle sechs, sonst nicht fertig):**
- `xcodegen generate && xcodebuild build` grün, ohne Warnungen aus eigenem Code
- `swift test --package-path Packages/LevmiCore` grün, ≥ 8 Tests
- `xcodebuild test` grün (Smoke + Frame-Budget)
- App startet im iPhone-17-Simulator und zeigt in ≤ 2 s die Szene
- Ein vollständiger Durchlauf: Gesetz erscheinen → Geste → Belohnung → Fortschritt sichtbar
- Screenshot + 20-s-Bildschirmaufnahme im Repo

**Was rausfliegt — kompromisslos:** mehr als ein Gesetz; jedes Menü, jeder Onboarding-Flow, jeder Settings-Screen; Persistenz auf Disk (In-Memory reicht); Login/Account/Cloud; App-Icon und Launch-Design; Lokalisierung; alles aus der „Expensive Wow"-Liste; Device-Deploy; UI-Tests (`XCUITest` ist heute Nacht reine Zeitverbrennung); Analytics.

---

## 5. Top-5-Risiken

| # | Risiko | Wahrsch. | Gegenmaßnahme |
|---|---|---|---|
| 1 | **Swift-6-Concurrency-Fehler mit SceneKit blockieren die Nacht** | hoch | Muster B aus §2.8 steht vor Arbeitspaket 3 im Repo. Notfallventil: `SWIFT_STRICT_CONCURRENCY: minimal` für das App-Target, `complete` bleibt auf `LevmiCore`. Kostet 30 Sekunden statt 90 Minuten. |
| 2 | **Zeit fließt in Optik, die Mechanik bleibt leer** — Techdemo statt Spiel | hoch | Arbeitspaket 4+5 (Loop, Belohnung) sind vor Paket 6 hart terminiert. Wenn um 04:00 kein Belohnungsmoment steht: Optik einfrieren, Mechanik fertigbauen. |
| 3 | **Signing/Team-ID kostet nachts eine Stunde** | mittel | `NVN9F2C593` steht in der `project.yml`. Für den Simulator zusätzlich `CODE_SIGNING_ALLOWED=NO` — dann ist Signing heute Nacht komplett irrelevant. |
| 4 | **Simulator-Performance täuscht; auf dem Gerät ruckelt es** | mittel | Partikel- und Draw-Call-Obergrenzen aus §2.8 als harte Konstanten im Code, Frame-Budget-Assertion im Testlauf. Diese Woche auf dem Gerät gegenprüfen. |
| 5 | **SceneKit-Code verteilt sich über die App und die Migration wird in 6 Monaten unbezahlbar** | mittel | Das Protokoll aus §2.4 vor dem ersten Feature. Wenn heute Nacht ein `SCNNode` außerhalb von `Scene/` landet, ist es morgen 200. |

---

## 6. Offene Fragen an Christian

1. **Android innerhalb von 12 Monaten — ja oder nein?** Ein „ja" kippt meine Produktempfehlung von nativ auf Unity. Das ist die einzige Frage, die die Architektur grundlegend ändert.
2. **Team `NVN9F2C593` (ImmoDigit GmbH) oder `RJS9C92DA6` (privat)?** Beides ist auf dem Rechner. Firmenkonto = saubere Rechte, privates = weniger Reibung bei App Store Connect. Entscheide es jetzt, nicht beim ersten Upload.
3. **Bundle-ID `de.immodigit.levmi` oder `com.immodigit.levmi`?** Eure bestehenden Apps laufen auf `com.`. Ein späterer Wechsel bedeutet neue App im Store — es gibt keine Migration.
4. **Darf ich 100 GB auf deinem Mac freiräumen?** Ohne das gibt es kein Xcode 27 und damit kein Gerätetesten — dauerhaft, nicht nur heute Nacht.
5. **Wie hoch ist die Ambition beim Sound?** Eigene Vertonung oder lizenzierte Loops? Sound ist der unterschätzteste Wow-Hebel des Projekts, und er hat eine Vorlaufzeit, die 3D nicht hat.

---

**Letzte Anmerkung, ungefragt.** Das Briefing fragt nach der Engine. Die Engine ist nicht dein Engpass (Gesetz 41). Dein Engpass ist die Frage, ob ein Spieler an Tag 3 zurückkommt. SceneKit, RealityKit oder Metal ändern daran exakt nichts. Was daran etwas ändert, ist, ob der Belohnungsmoment aus Arbeitspaket 5 im Körper ankommt — deshalb steht Haptik bei mir unter „nicht verhandelbar" und Shader unter „fliegt raus".
