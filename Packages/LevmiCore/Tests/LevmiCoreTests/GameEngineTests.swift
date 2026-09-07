import Foundation
import Testing
@testable import LevmiCore

@Suite("GameEngine")
struct GameEngineTests {

    let world: World
    let clock = TestClock()

    init() throws {
        world = try TestContent.werkstatt()
    }

    func reduce(
        _ state: PlayerState,
        _ action: GameAction,
        rules: Rules = .standard
    ) -> (PlayerState, [Effect]) {
        GameEngine.reduce(state, action, clock: clock, world: world, rules: rules)
    }

    /// Fester Knotenteppich für konstruierte Zustände (im Spiel gemischt).
    static let layout: [NodeSpec] = [
        NodeSpec(id: 0, kind: .glowing),
        NodeSpec(id: 1, kind: .lukewarm),
        NodeSpec(id: 2, kind: .cold),
        NodeSpec(id: 3, kind: .glowing),
        NodeSpec(id: 4, kind: .lukewarm)
    ]

    /// Ein gültiger Beweis: ≥ 40 Zeichen, konkret, keine Abschrift der Anleitung.
    static let guterBeweis = "Heute um 14 Uhr habe ich Tom per Nachricht abgesagt: ein Satz, keine Diskussion."

    // MARK: - Regel 0

    @Test("Regel 0: appOpened beginnt in jeder Phase mit der Wiederherstellung", arguments: GamePhase.allCases)
    func regel0_restoreInJederPhase(phase: GamePhase) {
        var state = beweisbereit()
        state.phase = phase
        let (next, effects) = reduce(state, .appOpened)
        #expect(effects.isEmpty == false)
        #expect(effects.beginntMitRestore)
        #expect(next.lastOpenedAt == clock.now)
    }

    @Test("Regel 0: die Wiederherstellung zeigt den Zustand vor der Aktion")
    func regel0_snapshotAusDemZustand() {
        let state = beweisbereit()
        let (_, effects) = reduce(state, .appOpened)
        #expect(effects.restoredSnapshot == SceneProjection.snapshot(of: state))
    }

    // MARK: - Regel 1

    @Test("Regel 1: initial beginnt mit zwei Lichtern, ohne Knoten")
    func regel1_initial() {
        let state = GameEngine.initial(clock: clock, rules: .standard)
        #expect(state.phase == .firstLight)
        #expect(state.lightsRemaining == 2)
        #expect(state.nodes.isEmpty)
        #expect(state.days == 0)
        #expect(state.sunProgress == 0)
        #expect(state.createdAt == clock.now)
        #expect(state.lastOpenedAt == clock.now)
    }

    @Test("Regel 1: die Lichtzahl kommt aus den Regeln")
    func regel1_lichtzahlAusRegeln() {
        let eigene = Rules(
            appliedLock: 600, proofWindow: 86_400, replayMinAge: 86_400,
            lightsPerNight: 3, minProofChars: 40, minExplanationChars: 60
        )
        #expect(GameEngine.initial(clock: clock, rules: eigene).lightsRemaining == 3)
    }

    // MARK: - Regel 2

    @Test("Regel 2: lightDropped legt fünf Knoten mit stabilen IDs an")
    func regel2_knotenEntstehen() {
        let (next, _) = reduce(PlayerState(phase: .firstLight), .lightDropped)
        #expect(next.phase == .nodes)
        #expect(next.nodes.count == 5)
        #expect(Set(next.nodes.map(\.id)) == [0, 1, 2, 3, 4])
        #expect(next.nodes.filter { $0.kind == .glowing }.count == 2)
        #expect(next.nodes.filter { $0.kind == .lukewarm }.count == 2)
        #expect(next.nodes.filter { $0.kind == .cold }.count == 1)
    }

    @Test("Regel 2: lightDropped hebt die Insel und stellt die Knoten vor")
    func regel2_effekte() {
        let (next, effects) = reduce(PlayerState(phase: .firstLight), .lightDropped)
        #expect(effects == [
            .scene(.revealIsland),
            .haptic(.impact),
            .sound(.impact),
            .scene(.cameraPullBack),
            .scene(.presentNodes(next.nodes)),
            .persist
        ])
    }

    // MARK: - Regel 3

    @Test("Regel 3: eine unbekannte Knoten-ID ändert nichts")
    func regel3_unbekannteID() {
        let state = knotenZustand()
        let (next, effects) = reduce(state, .lightPlaced(nodeID: 99))
        #expect(next == state)
        #expect(effects.isEmpty)

        // Kontrolle: eine bekannte ID verändert sehr wohl etwas.
        let (gesetzt, effekte) = reduce(state, .lightPlaced(nodeID: 0))
        #expect(gesetzt != state)
        #expect(effekte.isEmpty == false)
    }

    @Test("Regel 3: ein bereits gesetzter Knoten ändert nichts")
    func regel3_bereitsGesetzt() {
        let state = knotenZustand(
            lightsRemaining: 1,
            litNodeIDs: [0],
            placements: [.fixture(0, .glowing)],
            nodeOutcomes: [.glowing]
        )
        let (next, effects) = reduce(state, .lightPlaced(nodeID: 0))
        #expect(next == state)
        #expect(effects.isEmpty)

        // Kontrolle: der zweite singende Knoten ist noch frei.
        let (gesetzt, effekte) = reduce(state, .lightPlaced(nodeID: 3))
        #expect(gesetzt != state)
        #expect(effekte.isEmpty == false)
    }

    // MARK: - Regel 4

    @Test("Regel 4: das Licht auf einem singenden Knoten treibt starke Wurzeln")
    func regel4_glowing() {
        let (next, effects) = reduce(knotenZustand(), .lightPlaced(nodeID: 0))
        #expect(next.lightsRemaining == 1)
        #expect(next.litNodeIDs == [0])
        #expect(next.nodeOutcomes == [.glowing])
        #expect(next.placements.count == 1)
        #expect(next.placements.first?.nodeID == 0)
        #expect(next.placements.first?.kind == .glowing)
        #expect(next.placements.first?.at == clock.now)
        #expect(next.progress["schnitt"]?.stage == .recognized)
        #expect(Array(effects.prefix(4)) == [
            .scene(.impact(nodeID: 0)),
            .haptic(.impact),
            .sound(.node(.glowing)),
            .scene(.showRoots(nodeID: 0, .strong))
        ])
    }

    // MARK: - Regel 5

    @Test("Regel 5: das Lauwarme frisst das Licht ersatzlos")
    func regel5_lukewarm() {
        let (next, effects) = reduce(knotenZustand(), .lightPlaced(nodeID: 1))
        #expect(next.lightsRemaining == 1)
        #expect(next.litNodeIDs == [1])
        #expect(next.nodeOutcomes == [.lukewarm])
        #expect(next.progress["schnitt"]?.fallacyHits["lauwarm-lager"] == 1)
        #expect(Array(effects.prefix(4)) == [
            .scene(.drainLight(nodeID: 1)),
            .haptic(.drain),
            .sound(.node(.lukewarm)),
            .scene(.showRoots(nodeID: 1, .weak))
        ])
        #expect(effects.contains(.scene(.hintGlowing)) == false)
    }

    @Test("Regel 5: die zweite lauwarme Setzung zeigt auf das Glühende")
    func regel5_zweitesLauwarmesHilft() {
        let state = knotenZustand(
            lightsRemaining: 1,
            litNodeIDs: [1],
            placements: [.fixture(1, .lukewarm)],
            nodeOutcomes: [.lukewarm]
        )
        let (next, effects) = reduce(state, .lightPlaced(nodeID: 4))
        #expect(next.lightsRemaining == 0)
        #expect(next.progress["schnitt"]?.fallacyHits["lauwarm-lager"] == 2)
        #expect(effects.contains(.scene(.hintGlowing)))
    }

    // MARK: - Regel 6

    @Test("Regel 6: der brummende Knoten kostet kein Licht")
    func regel6_cold() {
        let state = knotenZustand()
        let (next, effects) = reduce(state, .lightPlaced(nodeID: 2))
        #expect(next.lightsRemaining == 2)
        #expect(next.litNodeIDs.isEmpty)
        #expect(next.nodeOutcomes == [.cold])
        #expect(next.placements.count == 1)
        #expect(effects == [
            .scene(.thud(nodeID: 2)),
            .haptic(.tap),
            .sound(.node(.cold))
        ])
    }

    @Test("Regel 6: die zweite kalte Setzung zeigt auf das Glühende")
    func regel6_zweitesKaltesHilft() {
        let state = knotenZustand(placements: [.fixture(2, .cold)], nodeOutcomes: [.cold])
        let (next, effects) = reduce(state, .lightPlaced(nodeID: 2))
        #expect(next.placements.count == 2)
        #expect(next.lightsRemaining == 2)
        #expect(Array(effects.prefix(3)) == [
            .scene(.thud(nodeID: 2)),
            .haptic(.tap),
            .sound(.node(.cold))
        ])
        #expect(effects.contains(.scene(.hintGlowing)))
    }

    // MARK: - Regel 7

    @Test("Regel 7: solange ein Licht übrig ist, folgt ein neues Licht")
    func regel7_naechstesLicht() {
        let (next, effects) = reduce(knotenZustand(), .lightPlaced(nodeID: 0))
        #expect(next.phase == .nodes)
        #expect(effects.last == .scene(.presentLight))
        #expect(effects.contains(.scene(.presentSun)) == false)
    }

    @Test("Regel 7: nach dem letzten Licht kommt die Sonne")
    func regel7_letztesLicht() {
        let state = knotenZustand(
            lightsRemaining: 1,
            litNodeIDs: [0],
            placements: [.fixture(0, .glowing)],
            nodeOutcomes: [.glowing]
        )
        let (next, effects) = reduce(state, .lightPlaced(nodeID: 3))
        #expect(next.phase == .roots)
        #expect(next.lightsRemaining == 0)
        #expect(Array(effects.suffix(2)) == [.scene(.presentSun), .persist])
        #expect(effects.contains(.scene(.presentLight)) == false)
    }

    @Test("Regel 7: nach dem kalten Knoten kommt kein neues Licht")
    func regel7_keinLichtNachKalt() {
        let state = knotenZustand()
        let (_, kalt) = reduce(state, .lightPlaced(nodeID: 2))
        #expect(kalt.contains(.scene(.presentLight)) == false)

        // Kontrolle: nach einer Setzung, die ein Licht kostet, kommt sehr wohl eines nach.
        let (_, gluehend) = reduce(state, .lightPlaced(nodeID: 0))
        #expect(gluehend.contains(.scene(.presentLight)))
    }

    @Test("Regel 7: die vierte Setzung holt die Sonne, auch mit Lichtern im Rücken")
    func regel7_vierteSetzung() {
        let state = knotenZustand(
            placements: [.fixture(2, .cold), .fixture(2, .cold), .fixture(2, .cold)],
            nodeOutcomes: [.cold, .cold, .cold]
        )
        let (next, effects) = reduce(state, .lightPlaced(nodeID: 2))
        #expect(next.placements.count == 4)
        #expect(next.lightsRemaining == 2)
        #expect(next.phase == .roots)
        #expect(Array(effects.suffix(2)) == [.scene(.presentSun), .persist])
    }

    // MARK: - Regel 8

    @Test("Regel 8: die halb gezogene Sonne meldet ihren Fortschritt")
    func regel8_sonneHalb() {
        let (next, effects) = reduce(wurzelZustand(), .sunPulled(0.5))
        #expect(next.phase == .roots)
        #expect(next.sunProgress == 0.5)
        #expect(effects == [.scene(.sunProgress(0.5))])
    }

    @Test("Regel 8: die Sonne fällt nie zurück")
    func regel8_monoton() {
        var state = wurzelZustand()
        state.sunProgress = 0.7
        let (next, effects) = reduce(state, .sunPulled(0.3))
        #expect(next.sunProgress == 0.7)
        #expect(effects == [.scene(.sunProgress(0.7))])
    }

    @Test("Regel 8: über 1 wird gekappt")
    func regel8_gekappt() {
        let (next, effects) = reduce(wurzelZustand(), .sunPulled(1.5))
        #expect(next.sunProgress == 1.0)
        #expect(effects.first == .scene(.sunProgress(1.0)))
    }

    @Test("Regel 8: zwei starke Wurzeln geben den vollen Durchbruch")
    func regel8_durchbruchVoll() {
        let state = wurzelZustand(
            litNodeIDs: [0, 3],
            placements: [.fixture(0, .glowing), .fixture(3, .glowing)],
            nodeOutcomes: [.glowing, .glowing]
        )
        let (next, effects) = reduce(state, .sunPulled(1.0))
        #expect(next.phase == .breakthrough)
        #expect(effects.breakthroughTier == .full)
        let erwartet: [Effect] = [
            .scene(.dawn), .scene(.breakthrough(.full)),
            .haptic(.breakthrough), .sound(.breakthrough), .persist
        ]
        #expect(effects.filter { erwartet.contains($0) } == erwartet)
        #expect(effects.first == .scene(.sunProgress(1.0)))
    }

    @Test("Regel 8: eine starke Wurzel gibt den halben Durchbruch")
    func regel8_durchbruchHalb() {
        let state = wurzelZustand(
            litNodeIDs: [0, 1],
            placements: [.fixture(0, .glowing), .fixture(1, .lukewarm)],
            nodeOutcomes: [.glowing, .lukewarm]
        )
        let (next, effects) = reduce(state, .sunPulled(1.0))
        #expect(next.phase == .breakthrough)
        #expect(effects.breakthroughTier == .half)
    }

    @Test("Regel 8: ohne starke Wurzel bleibt der Durchbruch dünn")
    func regel8_durchbruchDuenn() {
        let state = wurzelZustand(
            litNodeIDs: [1, 4],
            placements: [.fixture(1, .lukewarm), .fixture(4, .lukewarm)],
            nodeOutcomes: [.lukewarm, .lukewarm]
        )
        let (next, effects) = reduce(state, .sunPulled(1.0))
        #expect(next.phase == .breakthrough)
        #expect(effects.breakthroughTier == .thin)
    }

    // MARK: - Regel 9

    @Test("Regel 9: erst das Ende der Durchbruch-Animation öffnet das Onboarding")
    func regel9_breakthroughFinished() {
        var state = wurzelZustand()
        state.phase = .breakthrough
        state.sunProgress = 1
        let (next, effects) = reduce(state, .breakthroughFinished)
        #expect(next.phase == .onboardingPain)
        #expect(effects == [.persist])
    }

    // MARK: - Regel 10

    @Test("Regel 10: die gewählten Kacheln färben das Licht")
    func regel10_painSelected() {
        var state = wurzelZustand()
        state.phase = .onboardingPain
        let (next, effects) = reduce(state, .painSelected([.zuVielLauwarmes, .zeitWeg]))
        #expect(next.pains == [.zuVielLauwarmes, .zeitWeg])
        #expect(next.lightColorTile == .zuVielLauwarmes)
        #expect(next.phase == .onboardingWhy)
        #expect(effects == [.scene(.tintLight(.zuVielLauwarmes)), .haptic(.flip), .persist])
    }

    @Test("Regel 10: die Kacheln sind überspringbar")
    func regel10_ueberspringbar() {
        var state = wurzelZustand()
        state.phase = .onboardingPain
        let (next, effects) = reduce(state, .painSelected([]))
        #expect(next.pains.isEmpty)
        #expect(next.lightColorTile == nil)
        #expect(next.phase == .onboardingWhy)
        #expect(effects == [.scene(.tintLight(nil)), .haptic(.flip), .persist])
        #expect(effects.rejectReason == nil)
    }

    // MARK: - Regel 11

    @Test("Regel 11: das Warum wird als eigener Satz gespeichert")
    func regel11_whyEntered() {
        var state = wurzelZustand()
        state.phase = .onboardingWhy
        let (next, effects) = reduce(state, .whyEntered("Mehr Zeit für meine Kinder"))
        #expect(next.phase == .intention)
        #expect(next.why == "Mehr Zeit für meine Kinder")
        #expect(next.ownSentences.count == 1)
        #expect(next.ownSentences.first?.context == .why)
        #expect(next.ownSentences.first?.text == "Mehr Zeit für meine Kinder")
        #expect(next.ownSentences.first?.createdAt == clock.now)
        #expect(effects.contains(.persist))
    }

    @Test("Regel 11: ohne Warum entsteht kein Satz, die Phase wechselt trotzdem")
    func regel11_whyUebersprungen() {
        var state = wurzelZustand()
        state.phase = .onboardingWhy
        let (uebersprungen, _) = reduce(state, .whyEntered(nil))
        #expect(uebersprungen.phase == .intention)
        #expect(uebersprungen.ownSentences.isEmpty)

        let (leer, _) = reduce(state, .whyEntered("   "))
        #expect(leer.phase == .intention)
        #expect(leer.ownSentences.isEmpty)
    }

    // MARK: - Regel 12

    @Test("Regel 12: die Absicht setzt die Rückkehrzeit und die Erinnerung")
    func regel12_intentionChosen() {
        var state = wurzelZustand()
        state.phase = .intention
        let absicht = Intention.fixture(earliestProofAt: clock.now.addingTimeInterval(600))
        let (next, effects) = reduce(state, .intentionChosen(absicht))
        #expect(next.phase == .closed)
        #expect(next.intention == absicht)
        #expect(next.readyAt == absicht.earliestProofAt)
        #expect(effects == [
            .scheduleReminder(at: absicht.earliestProofAt, text: absicht.text),
            .persist
        ])
    }

    // MARK: - Regel 13

    @Test("Regel 13: closeForToday öffnet das Wurzelfenster")
    func regel13_closeForToday() {
        var state = wurzelZustand()
        state.phase = .closed
        state.intention = .fixture()
        state.readyAt = clock.now.addingTimeInterval(600)
        let (next, effects) = reduce(state, .closeForToday)
        #expect(next.phase == .waiting)
        #expect(next.closedAt == clock.now)
        #expect(next.readyAt == state.readyAt)
        #expect(effects == [.scene(.rootWindow(visible: true)), .persist])
    }

    @Test("Regel 13: appOpened in closed wirkt wie closeForToday")
    func regel13_appOpenedInClosed() {
        var state = wurzelZustand()
        state.phase = .closed
        state.intention = .fixture()
        state.readyAt = clock.now.addingTimeInterval(600)
        let (next, effects) = reduce(state, .appOpened)
        #expect(next.phase == .waiting)
        #expect(next.closedAt == clock.now)
        #expect(effects.beginntMitRestore)
        #expect(effects.nachRestore == [.scene(.rootWindow(visible: true)), .persist])
    }

    // MARK: - Regel 14

    @Test("Regel 14: vor readyAt heißt zurückkommen weiter warten")
    func regel14_zuFrueh() {
        let state = wartend(readyIn: T.minute)
        let (next, effects) = reduce(state, .appOpened)
        #expect(next.phase == .waiting)
        #expect(effects.beginntMitRestore)
        #expect(effects.rootWindowVisible == true)
        #expect(next.lastOpenedAt == clock.now)
    }

    @Test("Regel 14: genau ab readyAt wird der Beweis möglich")
    func regel14_genauAbReadyAt() {
        let (next, effects) = reduce(wartend(readyIn: 0), .appOpened)
        #expect(next.phase == .proof)
        #expect(effects.rootWindowVisible == false)
    }

    @Test("Regel 14: nach readyAt wird der Beweis möglich")
    func regel14_nachAblauf() {
        let (next, effects) = reduce(wartend(readyIn: -T.minute), .appOpened)
        #expect(next.phase == .proof)
        #expect(effects.beginntMitRestore)
        #expect(effects.rootWindowVisible == false)
    }

    // MARK: - Regel 15

    @Test("Regel 15: ein gültiger Beweis bringt den Tag und die Stufe Angewendet")
    func regel15_beweisAngenommen() {
        var state = beweisbereit()
        state.sunProgress = 1
        let (next, effects) = reduce(state, .proofSubmitted(Self.guterBeweis))
        #expect(next.phase == .dawnProof)
        #expect(next.days == 1)
        #expect(next.sunProgress == 0)
        #expect(next.progress["schnitt"]?.stage == .applied)
        #expect(next.progress["schnitt"]?.proofs.count == 1)
        #expect(next.progress["schnitt"]?.proofs.first?.text == Self.guterBeweis)
        #expect(next.progress["schnitt"]?.proofs.first?.submittedAt == clock.now)
        #expect(effects == [.scene(.presentSun), .persist])
    }

    @Test("Regel 15: ein zu kurzer Beweis wird ohne Vorwurf abgelehnt")
    func regel15_beweisAbgelehnt() {
        let state = beweisbereit()
        let (next, effects) = reduce(state, .proofSubmitted("kurz"))
        #expect(next.phase == .proof)
        #expect(next.days == 0)
        #expect(next.progress["schnitt"]?.proofs.isEmpty == true)
        #expect(effects.rejectReason != nil)
    }

    @Test("Regel 15: die abgeschriebene Anleitung wird abgelehnt")
    func regel15_abschriftAbgelehnt() {
        let (next, effects) = reduce(beweisbereit(), .proofSubmitted(ProofValidatorTests.anleitung))
        #expect(next.phase == .proof)
        #expect(next.days == 0)
        #expect(effects.rejectReason != nil)
    }

    // MARK: - Regel 16

    @Test("Regel 16: die zweite Sonne bringt den größeren Durchbruch")
    func regel16_zweiterDurchbruch() {
        var state = beweisbereit()
        state.phase = .dawnProof
        state.days = 1
        let (next, effects) = reduce(state, .sunPulled(1.0))
        #expect(next.phase == .breakthroughProof)
        #expect(next.sunProgress == 1.0)
        let erwartet: [Effect] = [
            .scene(.dawn), .scene(.breakthrough(.second)), .scene(.fogLevel(1)),
            .haptic(.breakthrough), .sound(.breakthrough), .persist
        ]
        #expect(effects.filter { erwartet.contains($0) } == erwartet)
        #expect(effects.first == .scene(.sunProgress(1.0)))
    }

    @Test("Regel 16: auch die zweite Sonne läuft nur vorwärts")
    func regel16_monoton() {
        var state = beweisbereit()
        state.phase = .dawnProof
        state.sunProgress = 0.6
        let (next, effects) = reduce(state, .sunPulled(0.2))
        #expect(next.phase == .dawnProof)
        #expect(next.sunProgress == 0.6)
        #expect(effects == [.scene(.sunProgress(0.6))])
    }

    @Test("Regel 16b: erst breakthroughFinished öffnet die Kosten-Frage")
    func regel16b_breakthroughFinishedNachZweitemDurchbruch() {
        var state = beweisbereit()
        state.phase = .breakthroughProof
        state.days = 1
        let (next, effects) = reduce(state, .breakthroughFinished)
        #expect(next.phase == .cost)
        #expect(effects == [.persist])
    }

    // MARK: - Regel 17

    @Test("Regel 17: die Kosten-Antwort führt zum Satz über dich")
    func regel17_costEntered() {
        var state = beweisbereit()
        state.phase = .cost
        state.days = 1
        let (next, effects) = reduce(state, .costEntered("Zwei Minuten Mut und eine unangenehme Nachricht"))
        #expect(next.phase == .befund)
        #expect(next.ownSentences.count == state.ownSentences.count + 1)
        #expect(next.ownSentences.last?.context == .cost)
        #expect(next.ownSentences.last?.text == "Zwei Minuten Mut und eine unangenehme Nachricht")
        #expect(next.befund != nil)
        #expect(effects.count == 2)
        #expect(effects.shownBefund == next.befund)
        #expect(effects.contains(.persist))
    }

    @Test("Regel 17: ohne Kosten-Antwort entsteht kein Satz, der Befund kommt trotzdem")
    func regel17_kostenUebersprungen() {
        var state = beweisbereit()
        state.phase = .cost
        state.days = 1
        let (next, effects) = reduce(state, .costEntered(nil))
        #expect(next.phase == .befund)
        #expect(next.ownSentences.count == state.ownSentences.count)
        #expect(effects.shownBefund != nil)
    }

    // MARK: - Regel 18

    @Test("Regel 18: „Stimmt“ beendet den Abend")
    func regel18_angenommen() {
        let (next, effects) = reduce(befundZustand(), .befundAnswered(accepted: true))
        #expect(next.phase == .idle)
        #expect(next.befundAccepted == true)
        #expect(next.befundAlternativeShown == false)
        #expect(effects == [.persist])
    }

    @Test("Regel 18: „Stimmt nicht“ liefert einmal den anderen Satz")
    func regel18_abgelehntZeigtAlternative() {
        let state = befundZustand()
        let (next, effects) = reduce(state, .befundAnswered(accepted: false))
        #expect(next.phase == .befund)
        #expect(next.befundAlternativeShown == true)
        #expect(next.befundAccepted == nil)
        #expect(effects.shownBefund?.sentence == state.befund?.alternative)
    }

    @Test("Regel 18: nach der Alternative ist Schluss")
    func regel18_nachDerAlternative() {
        var state = befundZustand()
        state.befundAlternativeShown = true
        let (next, effects) = reduce(state, .befundAnswered(accepted: false))
        #expect(next.phase == .idle)
        #expect(next.befundAccepted == false)
        #expect(effects == [.persist])
    }

    // MARK: - Regel 19

    @Test("Regel 19: beim nächsten Öffnen kommt zuerst der eigene Satz")
    func regel19_eigenerSatz() {
        let alt = OwnSentence.fixture(id: "s1", createdAt: clock.now.addingTimeInterval(-3 * T.day))
        var state = befundZustand()
        state.phase = .idle
        state.days = 1
        state.ownSentences = [alt]
        let (next, effects) = reduce(state, .appOpened)
        #expect(next.phase == .idle)
        #expect(effects.beginntMitRestore)
        #expect(effects.shownOwnSentence?.id == "s1")
        #expect(next.lastShownSentenceID == "s1")
        #expect(next.lastOpenedAt == clock.now)
    }

    @Test("Regel 19: ohne passenden Satz bleibt es bei der Wiederherstellung")
    func regel19_keinSatz() {
        let frisch = OwnSentence.fixture(id: "s1", createdAt: clock.now.addingTimeInterval(-T.minute))
        var state = befundZustand()
        state.phase = .idle
        state.days = 1
        state.ownSentences = [frisch]
        let (next, effects) = reduce(state, .appOpened)
        #expect(effects.nachRestore.isEmpty)
        #expect(effects.beginntMitRestore)
        #expect(next.lastShownSentenceID == nil)
    }

    @Test("Regel 19: der zuletzt gezeigte Satz wird beim nächsten Mal übersprungen")
    func regel19_lastShownWirdBeachtet() {
        var state = befundZustand()
        state.phase = .idle
        state.days = 1
        state.ownSentences = [
            OwnSentence.fixture(id: "s1", createdAt: clock.now.addingTimeInterval(-3 * T.day)),
            OwnSentence.fixture(id: "s2", text: "Zwei Minuten Mut.", createdAt: clock.now.addingTimeInterval(-2 * T.day), context: .cost)
        ]
        state.lastShownSentenceID = "s1"
        let (next, effects) = reduce(state, .appOpened)
        #expect(effects.shownOwnSentence?.id == "s2")
        #expect(next.lastShownSentenceID == "s2")
    }

    @Test("Der weggewischte Satz kostet nur einen Speichervorgang")
    func dismissOwnSentence() {
        var state = befundZustand()
        state.phase = .idle
        state.days = 1
        state.lastShownSentenceID = "s1"
        let (next, effects) = reduce(state, .dismissOwnSentence)
        #expect(next == state)
        #expect(effects == [.persist])
    }

    // MARK: - Regel 20

    @Test("Regel 20: reset beginnt die Nacht neu")
    func regel20_reset() {
        var state = beweisbereit()
        state.phase = .idle
        state.days = 3
        let (next, effects) = reduce(state, .reset)
        #expect(next == GameEngine.initial(clock: clock, rules: .standard))
        #expect(next.phase == .firstLight)
        #expect(next.days == 0)
        #expect(next.nodes.isEmpty)
        #expect(next.sunProgress == 0)
        #expect(effects.count == 2)
        #expect(effects.beginntMitRestore)
        #expect(effects.last == .persist)
    }

    @Test("Regel 20: reset wirkt auch mitten im Spiel")
    func regel20_resetMittendrin() {
        let (next, effects) = reduce(knotenZustand(), .reset)
        #expect(next.phase == .firstLight)
        #expect(next.nodes.isEmpty)
        #expect(effects.beginntMitRestore)
    }

    // MARK: - Regel 21

    @Test("Regel 21: eine Aktion in der falschen Phase ändert nichts")
    func regel21_unbekannteAktion() {
        let state = PlayerState(phase: .firstLight)
        let (unveraendert, keineEffekte) = reduce(state, .costEntered("zu früh"))
        #expect(unveraendert == state)
        #expect(keineEffekte.isEmpty)

        // Kontrolle: in derselben Phase ist lightDropped definiert und verändert etwas.
        let (veraendert, effekte) = reduce(state, .lightDropped)
        #expect(veraendert != state)
        #expect(effekte.isEmpty == false)
    }

    @Test("Regel 21: auch der Beweis in der Wartephase prallt ab")
    func regel21_beweisWaehrendDerSperre() {
        let state = wartend(readyIn: 5 * T.minute)
        let (next, effects) = reduce(state, .proofSubmitted(Self.guterBeweis))
        #expect(next == state)
        #expect(effects.isEmpty)

        // Kontrolle: appOpened ist in dieser Phase definiert.
        // Dafür muss die Uhr weiterlaufen: `wartend()` setzt `lastOpenedAt` auf
        // `clock.now`, und `appOpened` vor `readyAt` ändert laut Regel 0/14 genau
        // dieses eine Feld. Bei stehender Uhr wäre der Zustand also identisch,
        // obwohl die Aktion sehr wohl definiert ist — die Kontrollzeile hätte den
        // Unterschied zu Regel 21 nicht gemessen, sondern die Auflösung der Uhr.
        // Eine Minute später liegt `readyAt` (+5 Min) weiter in der Zukunft, die
        // Wartephase bleibt also erhalten.
        clock.advance(by: T.minute)
        let (geoeffnet, effekte) = reduce(state, .appOpened)
        #expect(geoeffnet != state)
        #expect(geoeffnet.phase == .waiting)
        #expect(geoeffnet.lastOpenedAt == clock.now)
        #expect(effekte.isEmpty == false)
    }

    // MARK: - Regel 22

    @Test("Regel 22: ein zweiter Beweis im selben Fenster bringt keinen zweiten Tag")
    func regel22_zweiterBeweisImFenster() {
        var state = beweisbereit()
        state.progress["schnitt"] = PrincipleProgress(
            id: "schnitt",
            stage: .applied,
            stageEnteredAt: clock.now.addingTimeInterval(-2 * T.hour),
            proofs: [Proof.fixture(submittedAt: clock.now.addingTimeInterval(-2 * T.hour))]
        )
        state.days = 1

        let (next, _) = reduce(state, .proofSubmitted(Self.guterBeweis))
        #expect(next.progress["schnitt"]?.proofs.count == 2)
        #expect(next.days == 1)
        #expect(next.phase == .dawnProof)
    }

    // MARK: - Golden Path

    @Test("Golden Path: die erste Nacht bis zum eigenen Satz")
    func goldenPathStandard() throws {
        let rules = Rules.standard
        var effects: [Effect] = []

        var state = GameEngine.initial(clock: clock, rules: rules)
        #expect(state.phase == .firstLight)
        #expect(state.lightsRemaining == 2)
        #expect(state.days == 0)

        // Licht in den Nebel
        (state, effects) = reduce(state, .lightDropped, rules: rules)
        #expect(state.phase == .nodes)
        #expect(state.nodes.count == 5)

        // Das Lauwarme frisst das erste Licht — ersatzlos
        let lauwarm = try #require(state.freierKnoten(.lukewarm))
        (state, effects) = reduce(state, .lightPlaced(nodeID: lauwarm.id), rules: rules)
        #expect(state.phase == .nodes)
        #expect(state.lightsRemaining == 1)
        #expect(effects.contains(.scene(.drainLight(nodeID: lauwarm.id))))
        #expect(effects.last == .scene(.presentLight))

        // Der kalte Knoten kostet nichts
        let kalt = try #require(state.freierKnoten(.cold))
        (state, effects) = reduce(state, .lightPlaced(nodeID: kalt.id), rules: rules)
        #expect(state.lightsRemaining == 1)
        #expect(effects == [.scene(.thud(nodeID: kalt.id)), .haptic(.tap), .sound(.node(.cold))])

        // Das zweite Licht auf einen singenden Knoten: die Sonne kommt
        let gluehend = try #require(state.freierKnoten(.glowing))
        (state, effects) = reduce(state, .lightPlaced(nodeID: gluehend.id), rules: rules)
        #expect(state.phase == .roots)
        #expect(state.lightsRemaining == 0)
        #expect(state.progress["schnitt"]?.stage == .recognized)
        #expect(Array(effects.suffix(2)) == [.scene(.presentSun), .persist])

        // Sonne halb, dann ganz — ein Treffer, also halber Durchbruch
        (state, effects) = reduce(state, .sunPulled(0.5), rules: rules)
        #expect(state.sunProgress == 0.5)

        (state, effects) = reduce(state, .sunPulled(1.0), rules: rules)
        #expect(state.phase == .breakthrough)
        #expect(effects.breakthroughTier == .half)

        (state, effects) = reduce(state, .breakthroughFinished, rules: rules)
        #expect(state.phase == .onboardingPain)
        #expect(effects == [.persist])

        // Onboarding
        (state, effects) = reduce(state, .painSelected([.zuVielLauwarmes, .zeitWeg]), rules: rules)
        #expect(state.phase == .onboardingWhy)
        #expect(state.lightColorTile == .zuVielLauwarmes)

        (state, effects) = reduce(state, .whyEntered("Mehr Zeit für meine Kinder"), rules: rules)
        #expect(state.phase == .intention)
        #expect(state.ownSentences.count == 1)

        let absicht = Intention.fixture(
            createdAt: clock.now,
            earliestProofAt: clock.now.addingTimeInterval(600),
            dueBy: clock.now.addingTimeInterval(600 + T.day)
        )
        (state, effects) = reduce(state, .intentionChosen(absicht), rules: rules)
        #expect(state.phase == .closed)
        #expect(state.readyAt == absicht.earliestProofAt)
        #expect(effects.reminder?.at == absicht.earliestProofAt)
        #expect(effects.reminder?.text == absicht.text)

        (state, effects) = reduce(state, .closeForToday, rules: rules)
        #expect(state.phase == .waiting)
        #expect(state.closedAt == clock.now)
        #expect(effects == [.scene(.rootWindow(visible: true)), .persist])

        // Zu früh zurück
        clock.advance(by: 4 * T.minute)
        (state, effects) = reduce(state, .appOpened, rules: rules)
        #expect(state.phase == .waiting)
        #expect(effects.beginntMitRestore)
        #expect(effects.rootWindowVisible == true)
        #expect(state.days == 0)

        // Nach der Sperre
        clock.advance(by: 7 * T.minute)
        (state, effects) = reduce(state, .appOpened, rules: rules)
        #expect(state.phase == .proof)
        #expect(effects.rootWindowVisible == false)

        // Zu kurzer Beweis
        (state, effects) = reduce(state, .proofSubmitted("kurz"), rules: rules)
        #expect(state.phase == .proof)
        #expect(state.days == 0)
        #expect(effects.rejectReason != nil)

        // Gültiger Beweis
        (state, effects) = reduce(state, .proofSubmitted(Self.guterBeweis), rules: rules)
        #expect(state.phase == .dawnProof)
        #expect(state.days == 1)
        #expect(state.sunProgress == 0)
        #expect(state.progress["schnitt"]?.stage == .applied)
        #expect(effects == [.scene(.presentSun), .persist])

        // Zweiter Durchbruch — erst die Animation, dann breakthroughFinished, dann die Kosten-Frage
        (state, effects) = reduce(state, .sunPulled(1.0), rules: rules)
        #expect(state.phase == .breakthroughProof)
        #expect(effects.breakthroughTier == .second)
        #expect(effects.contains(.scene(.fogLevel(1))))
        (state, effects) = reduce(state, .breakthroughFinished, rules: rules)
        #expect(state.phase == .cost)

        // Kosten und der Satz über dich
        (state, effects) = reduce(state, .costEntered("Zwei Minuten Mut und eine unangenehme Nachricht"), rules: rules)
        #expect(state.phase == .befund)
        #expect(state.ownSentences.count == 2)
        #expect(effects.shownBefund != nil)
        #expect(state.befund?.principleID == "schnitt")
        // Kachel „Zu viel Lauwarmes" plus eine lauwarme Setzung → Fall F1.
        #expect(state.befund?.sentence.contains("1-mal") == true)

        (state, effects) = reduce(state, .befundAnswered(accepted: true), rules: rules)
        #expect(state.phase == .idle)
        #expect(state.befundAccepted == true)
        #expect(effects == [.persist])

        // Am nächsten Tag: der eigene Satz
        clock.advance(by: T.day)
        (state, effects) = reduce(state, .appOpened, rules: rules)
        #expect(state.phase == .idle)
        #expect(state.days == 1)
        #expect(effects.beginntMitRestore)
        #expect(effects.shownOwnSentence?.context == .why)
        #expect(effects.shownOwnSentence?.text == "Mehr Zeit für meine Kinder")
    }

    @Test("Golden Path im Demo-Modus: derselbe Loop, nur kürzere Zeiten")
    func goldenPathDemo() throws {
        let rules = Rules.demo
        var effects: [Effect] = []

        var state = GameEngine.initial(clock: clock, rules: rules)
        #expect(state.lightsRemaining == 2)

        (state, _) = reduce(state, .lightDropped, rules: rules)
        let ersterGluehender = try #require(state.freierKnoten(.glowing))
        (state, _) = reduce(state, .lightPlaced(nodeID: ersterGluehender.id), rules: rules)
        #expect(state.phase == .nodes)
        #expect(state.lightsRemaining == 1)

        let zweiterGluehender = try #require(state.freierKnoten(.glowing))
        (state, effects) = reduce(state, .lightPlaced(nodeID: zweiterGluehender.id), rules: rules)
        #expect(state.phase == .roots)
        #expect(state.lightsRemaining == 0)

        (state, effects) = reduce(state, .sunPulled(1.0), rules: rules)
        #expect(state.phase == .breakthrough)
        #expect(effects.breakthroughTier == .full)

        (state, _) = reduce(state, .breakthroughFinished, rules: rules)
        (state, _) = reduce(state, .painSelected([]), rules: rules)
        #expect(state.phase == .onboardingWhy)

        (state, _) = reduce(state, .whyEntered("Mehr Zeit für meine Kinder"), rules: rules)
        let absicht = Intention.fixture(
            createdAt: clock.now,
            earliestProofAt: clock.now.addingTimeInterval(30),
            dueBy: clock.now.addingTimeInterval(30 + 600)
        )
        (state, _) = reduce(state, .intentionChosen(absicht), rules: rules)
        #expect(state.readyAt == clock.now.addingTimeInterval(30))

        (state, _) = reduce(state, .closeForToday, rules: rules)
        #expect(state.phase == .waiting)

        // 29 Sekunden sind zu früh
        clock.advance(by: 29)
        (state, effects) = reduce(state, .appOpened, rules: rules)
        #expect(state.phase == .waiting)
        #expect(effects.rootWindowVisible == true)

        // 30 Sekunden reichen
        clock.advance(by: 1)
        (state, _) = reduce(state, .appOpened, rules: rules)
        #expect(state.phase == .proof)

        (state, _) = reduce(state, .proofSubmitted(Self.guterBeweis), rules: rules)
        #expect(state.phase == .dawnProof)
        #expect(state.days == 1)

        (state, _) = reduce(state, .sunPulled(1.0), rules: rules)
        #expect(state.phase == .breakthroughProof)
        (state, _) = reduce(state, .breakthroughFinished, rules: rules)
        #expect(state.phase == .cost)

        (state, effects) = reduce(state, .costEntered("Zwei Minuten Mut"), rules: rules)
        #expect(state.phase == .befund)
        // Keine Kachel, kein Lauwarmes, kein Kaltes → Fall F4.
        #expect(state.befund?.sentence.contains("Zwei Lichter, zwei Treffer") == true)

        (state, _) = reduce(state, .befundAnswered(accepted: true), rules: rules)
        #expect(state.phase == .idle)

        // Rückspiel bereits nach einer Minute
        clock.advance(by: T.minute)
        (state, effects) = reduce(state, .appOpened, rules: rules)
        #expect(effects.shownOwnSentence?.text == "Mehr Zeit für meine Kinder")
    }

    @Test("Lauwarm-Pfad: zwei lauwarme Setzungen kosten beide Lichter und den Durchbruch")
    func lauwarmPfad() throws {
        let rules = Rules.standard
        var effects: [Effect] = []

        var state = GameEngine.initial(clock: clock, rules: rules)
        (state, _) = reduce(state, .lightDropped, rules: rules)

        let erstes = try #require(state.freierKnoten(.lukewarm))
        (state, effects) = reduce(state, .lightPlaced(nodeID: erstes.id), rules: rules)
        #expect(state.lightsRemaining == 1)
        #expect(state.phase == .nodes)
        #expect(effects.contains(.scene(.hintGlowing)) == false)

        let zweites = try #require(state.freierKnoten(.lukewarm))
        (state, effects) = reduce(state, .lightPlaced(nodeID: zweites.id), rules: rules)
        #expect(state.lightsRemaining == 0)
        #expect(state.phase == .roots)
        #expect(effects.contains(.scene(.hintGlowing)))
        #expect(Array(effects.suffix(2)) == [.scene(.presentSun), .persist])
        #expect(state.progress["schnitt"]?.fallacyHits["lauwarm-lager"] == 2)

        (state, effects) = reduce(state, .sunPulled(1.0), rules: rules)
        #expect(state.phase == .breakthrough)
        #expect(effects.breakthroughTier == .thin)
        #expect(effects.contains(.scene(.dawn)))
    }

    // MARK: - Hilfen

    func knotenZustand(
        lightsRemaining: Int = 2,
        litNodeIDs: [Int] = [],
        placements: [Placement] = [],
        nodeOutcomes: [NodeKind] = []
    ) -> PlayerState {
        PlayerState(
            phase: .nodes,
            createdAt: clock.now,
            lastOpenedAt: clock.now,
            lightsRemaining: lightsRemaining,
            nodes: Self.layout,
            litNodeIDs: litNodeIDs,
            nodeOutcomes: nodeOutcomes,
            placements: placements
        )
    }

    func wurzelZustand(
        litNodeIDs: [Int] = [0],
        placements: [Placement] = [.fixture(0, .glowing)],
        nodeOutcomes: [NodeKind] = [.glowing]
    ) -> PlayerState {
        PlayerState(
            phase: .roots,
            createdAt: clock.now,
            lastOpenedAt: clock.now,
            lightsRemaining: 0,
            nodes: Self.layout,
            litNodeIDs: litNodeIDs,
            nodeOutcomes: nodeOutcomes,
            placements: placements,
            progress: ["schnitt": PrincipleProgress(id: "schnitt", stage: .recognized, stageEnteredAt: clock.now)]
        )
    }

    /// Wartender Zustand: `readyAt` liegt `readyIn` Sekunden in der Zukunft
    /// (negativ = die Tür ist bereits offen).
    func wartend(readyIn: TimeInterval) -> PlayerState {
        var state = beweisbereit()
        state.phase = .waiting
        state.closedAt = clock.now.addingTimeInterval(readyIn - 600)
        state.readyAt = clock.now.addingTimeInterval(readyIn)
        return state
    }

    /// Zustand kurz vor dem Beweis: Absicht gesetzt, Tür offen.
    func beweisbereit() -> PlayerState {
        PlayerState(
            phase: .proof,
            createdAt: clock.now.addingTimeInterval(-T.hour),
            lastOpenedAt: clock.now,
            lightsRemaining: 0,
            nodes: Self.layout,
            litNodeIDs: [0, 1],
            nodeOutcomes: [.lukewarm, .glowing],
            placements: [
                .fixture(1, .lukewarm, at: clock.now.addingTimeInterval(-T.hour)),
                .fixture(0, .glowing, at: clock.now.addingTimeInterval(-T.hour))
            ],
            sunProgress: 0,
            lightColorTile: .zuVielLauwarmes,
            pains: [.zuVielLauwarmes, .zeitWeg],
            why: "Mehr Zeit für meine Kinder",
            intention: .fixture(
                createdAt: clock.now.addingTimeInterval(-T.hour),
                earliestProofAt: clock.now.addingTimeInterval(-30 * T.minute),
                dueBy: clock.now.addingTimeInterval(T.day)
            ),
            closedAt: clock.now.addingTimeInterval(-T.hour),
            readyAt: clock.now.addingTimeInterval(-30 * T.minute),
            progress: [
                "schnitt": PrincipleProgress(
                    id: "schnitt",
                    stage: .recognized,
                    stageEnteredAt: clock.now.addingTimeInterval(-T.hour),
                    fallacyHits: ["lauwarm-lager": 1]
                )
            ],
            days: 0,
            ownSentences: [
                OwnSentence.fixture(id: "s1", createdAt: clock.now.addingTimeInterval(-T.hour))
            ]
        )
    }

    func befundZustand() -> PlayerState {
        var state = beweisbereit()
        state.phase = .befund
        state.days = 1
        state.befund = Befund(
            sentence: "Du hast ‚Zu viel Lauwarmes‘ angekreuzt — und heute Nacht trotzdem 1-mal Lauwarmes gefüttert.",
            alternative: "Du hast das Lauwarme nach dem ersten Mal erkannt.",
            evidence: ["lauwarm: 1", "lauwarm-lager"],
            principleID: "schnitt"
        )
        return state
    }
}

@Suite("PainTile")
struct PainTileTests {

    @Test("Jede der sechs Kacheln hat eine Beschriftung")
    func beschriftungen() {
        #expect(PainTile.allCases.map(\.rawValue) == [
            "zeitWeg", "zuVielLauwarmes", "keinFortschritt",
            "geldReichtNicht", "immerErreichbar", "allesHaengtAnMir"
        ])
        #expect(PainTile.allCases.map(\.label) == [
            "Zeit weg", "Zu viel Lauwarmes", "Kein Fortschritt",
            "Geld reicht nicht", "Immer erreichbar", "Alles hängt an mir"
        ])
    }

    @Test("Jede Kachel dreht sich in ihr Gegenteil")
    func gegenteile() {
        #expect(PainTile.allCases.map(\.inverted) == [
            "Deine Zeit gehört dir.",
            "Nur noch Glühendes.",
            "Sichtbar weiter.",
            "Mehr, als du brauchst.",
            "Erreichbar, wenn du willst.",
            "Es läuft auch ohne dich."
        ])
    }

    @Test("Die Gegenteile sind untereinander verschieden")
    func gegenteileSindEindeutig() {
        #expect(Set(PainTile.allCases.map(\.inverted)).count == 6)
        #expect(PainTile.allCases.allSatisfy { $0.inverted != $0.label })
    }
}
