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

    /// Ein gültiger Beweis: ≥ 40 Zeichen, konkret, keine Abschrift der Anleitung.
    static let guterBeweis = "Heute um 14 Uhr habe ich Tom per Nachricht abgesagt: ein Satz, keine Diskussion."

    // MARK: - Regel 1

    @Test("Regel 1: initial beginnt mit zwei Lichtern im ersten Licht")
    func regel1_initial() {
        let state = GameEngine.initial(clock: clock, rules: .standard)
        #expect(state.phase == .firstLight)
        #expect(state.lightsRemaining == 2)
        #expect(state.days == 0)
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

    @Test("Regel 2: lightDropped hebt die Insel und stellt fünf Knoten vor")
    func regel2_lightDropped() {
        let (next, effects) = reduce(PlayerState(phase: .firstLight), .lightDropped)
        #expect(next.phase == .nodes)
        #expect(effects.count == 5)
        #expect(Array(effects.prefix(4)) == [
            .scene(.revealIsland), .haptic(.impact), .sound(.impact), .scene(.cameraPullBack)
        ])
        let nodes = effects.presentedNodes ?? []
        #expect(nodes.count == 5)
        #expect(nodes.filter { $0 == .glowing }.count == 2)
        #expect(nodes.filter { $0 == .lukewarm }.count == 2)
        #expect(nodes.filter { $0 == .cold }.count == 1)
    }

    // MARK: - Regel 3

    @Test("Regel 3: das erste Licht auf einem singenden Knoten lässt ein zweites folgen")
    func regel3_erstesLichtGlowing() {
        let (next, effects) = reduce(PlayerState(phase: .nodes, lightsRemaining: 2), .lightPlaced(.glowing))
        #expect(next.lightsRemaining == 1)
        #expect(next.phase == .nodes)
        #expect(effects.contains(.scene(.impact(.glowing))))
        #expect(effects.contains(.scene(.showRoots(.strong))))
        #expect(effects.contains(.scene(.presentLight)))
        #expect(effects.contains(.scene(.presentSun)) == false)
        #expect(next.progress["schnitt"]?.stage == .recognized)
    }

    @Test("Regel 3: das letzte Licht auf einem singenden Knoten holt die Sonne")
    func regel3_letztesLichtGlowing() {
        let (next, effects) = reduce(PlayerState(phase: .nodes, lightsRemaining: 1), .lightPlaced(.glowing))
        #expect(next.lightsRemaining == 0)
        #expect(next.phase == .roots)
        #expect(effects.contains(.scene(.impact(.glowing))))
        #expect(effects.contains(.scene(.showRoots(.strong))))
        #expect(effects.contains(.scene(.presentSun)))
        #expect(effects.contains(.scene(.presentLight)) == false)
        #expect(next.progress["schnitt"]?.stage == .recognized)
    }

    // MARK: - Regel 4

    @Test("Regel 4: das Lauwarme frisst das Licht und bekommt ein neues")
    func regel4_lightPlacedLukewarm() {
        let (next, effects) = reduce(PlayerState(phase: .nodes, lightsRemaining: 2), .lightPlaced(.lukewarm))
        #expect(next.phase == .nodes)
        #expect(next.lightsRemaining == 2)
        #expect(effects == [.scene(.drainLight), .haptic(.drain), .sound(.lukewarm), .scene(.presentLight)])
        #expect(next.nodeOutcomes == [.lukewarm])
        #expect(next.progress["schnitt"]?.fallacyHits["lauwarm-lager"] == 1)
    }

    @Test("Regel 4: zweimal lauwarm zählt den Denkfehler zweimal")
    func regel4_zweimalLauwarm() {
        let (einmal, _) = reduce(PlayerState(phase: .nodes, lightsRemaining: 2), .lightPlaced(.lukewarm))
        let (zweimal, _) = reduce(einmal, .lightPlaced(.lukewarm))
        #expect(zweimal.nodeOutcomes == [.lukewarm, .lukewarm])
        #expect(zweimal.progress["schnitt"]?.fallacyHits["lauwarm-lager"] == 2)
        #expect(zweimal.lightsRemaining == 2)
    }

    // MARK: - Regel 5

    @Test("Regel 5: der brummende Knoten kostet nichts")
    func regel5_lightPlacedCold() {
        let (next, effects) = reduce(PlayerState(phase: .nodes, lightsRemaining: 2), .lightPlaced(.cold))
        #expect(next.phase == .nodes)
        #expect(next.lightsRemaining == 2)
        #expect(effects == [.scene(.thud), .haptic(.tap), .sound(.cold)])
    }

    // MARK: - Regel 6

    @Test("Regel 6: die halb gezogene Sonne meldet nur ihren Fortschritt")
    func regel6_sonneHalb() {
        let (next, effects) = reduce(PlayerState(phase: .roots, lightsRemaining: 0), .sunPulled(0.5))
        #expect(next.phase == .roots)
        #expect(effects.sunProgress == 0.5)
        #expect(effects.contains(.scene(.dawn)) == false)
    }

    @Test("Regel 6: die ganz gezogene Sonne bringt den Durchbruch und das Onboarding")
    func regel6_sonneGanz() {
        let (next, effects) = reduce(PlayerState(phase: .roots, lightsRemaining: 0), .sunPulled(1.0))
        #expect(next.phase == .onboardingPain)
        let erwartet: [Effect] = [
            .scene(.dawn), .scene(.breakthrough(.first)),
            .haptic(.breakthrough), .sound(.breakthrough), .persist
        ]
        // Reihenfolge und Vollständigkeit; ein zusätzliches .sunProgress(1.0) ist erlaubt.
        #expect(effects.filter { erwartet.contains($0) } == erwartet)
    }

    // MARK: - Regel 7

    @Test("Regel 7: die gewählten Kacheln färben das Licht")
    func regel7_painSelected() {
        let state = PlayerState(phase: .onboardingPain, lightsRemaining: 0)
        let (next, effects) = reduce(state, .painSelected([.zuVielLauwarmes, .zeitWeg]))
        #expect(next.pains == [.zuVielLauwarmes, .zeitWeg])
        #expect(next.lightColorTile == .zuVielLauwarmes)
        #expect(next.phase == .onboardingWhy)
        #expect(effects == [.scene(.tintLight(.zuVielLauwarmes)), .haptic(.flip)])
    }

    @Test("Regel 7: eine leere Auswahl wird abgelehnt")
    func regel7_leereAuswahl() {
        let state = PlayerState(phase: .onboardingPain, lightsRemaining: 0)
        let (next, effects) = reduce(state, .painSelected([]))
        #expect(effects.rejectReason != nil)
        #expect(next == state)
    }

    // MARK: - Regel 8

    @Test("Regel 8: das Warum wird als eigener Satz gespeichert")
    func regel8_whyEntered() {
        let state = PlayerState(phase: .onboardingWhy, lightsRemaining: 0, pains: [.zeitWeg])
        let (next, _) = reduce(state, .whyEntered("Mehr Zeit für meine Kinder"))
        #expect(next.phase == .intention)
        #expect(next.why == "Mehr Zeit für meine Kinder")
        #expect(next.ownSentences.count == 1)
        #expect(next.ownSentences.first?.context == .why)
        #expect(next.ownSentences.first?.text == "Mehr Zeit für meine Kinder")
        #expect(next.ownSentences.first?.createdAt == clock.now)
    }

    @Test("Regel 8: ohne Warum entsteht kein Satz, die Phase wechselt trotzdem")
    func regel8_whyUebersprungen() {
        let state = PlayerState(phase: .onboardingWhy, lightsRemaining: 0, pains: [.zeitWeg])
        let (uebersprungen, _) = reduce(state, .whyEntered(nil))
        #expect(uebersprungen.phase == .intention)
        #expect(uebersprungen.ownSentences.isEmpty)

        let (leer, _) = reduce(state, .whyEntered("   "))
        #expect(leer.phase == .intention)
        #expect(leer.ownSentences.isEmpty)
    }

    // MARK: - Regel 9

    @Test("Regel 9: die Absicht bekommt eine Frist aus dem Beweisfenster")
    func regel9_intentionChosen() {
        let state = PlayerState(phase: .intention, lightsRemaining: 0)
        let absicht = Intention.fixture(dueBy: Date(timeIntervalSince1970: 0))
        let (next, effects) = reduce(state, .intentionChosen(absicht))
        #expect(next.phase == .closed)
        #expect(next.intention?.id == "i1")
        #expect(next.intention?.text == absicht.text)
        #expect(next.intention?.dueBy == clock.now.addingTimeInterval(T.day))
        #expect(effects.contains(.persist))
    }

    // MARK: - Regel 10

    @Test("Regel 10: closeForToday setzt die Rückkehrzeit und öffnet das Wurzelfenster")
    func regel10_closeForToday() {
        let state = PlayerState(phase: .closed, lightsRemaining: 0, intention: .fixture())
        let (next, effects) = reduce(state, .closeForToday)
        #expect(next.phase == .waiting)
        #expect(next.closedAt == clock.now)
        #expect(next.readyAt == clock.now.addingTimeInterval(600))
        #expect(effects == [.scene(.rootWindow(visible: true)), .persist])
    }

    @Test("Regel 10: im Demo-Modus ist die Rückkehrzeit 30 Sekunden entfernt")
    func regel10_closeForTodayDemo() {
        let state = PlayerState(phase: .closed, lightsRemaining: 0, intention: .fixture())
        let (next, _) = reduce(state, .closeForToday, rules: .demo)
        #expect(next.readyAt == clock.now.addingTimeInterval(30))
    }

    // MARK: - Regel 11

    @Test("Regel 11: vor readyAt heißt zurückkommen weiter warten")
    func regel11_zuFrueh() {
        let state = wartend(readyIn: T.minute)
        let (next, effects) = reduce(state, .appOpened)
        #expect(next.phase == .waiting)
        #expect(effects.rootWindowVisible == true)
        #expect(next.lastOpenedAt == clock.now)
        #expect(next.readyAt == state.readyAt)
    }

    @Test("Regel 11: genau ab readyAt wird der Beweis möglich")
    func regel11_genauAbReadyAt() {
        let state = wartend(readyIn: 0)
        let (next, effects) = reduce(state, .appOpened)
        #expect(next.phase == .proof)
        #expect(effects.rootWindowVisible == false)
    }

    @Test("Regel 11: nach readyAt wird der Beweis möglich")
    func regel11_nachAblauf() {
        let state = wartend(readyIn: -T.minute)
        let (next, effects) = reduce(state, .appOpened)
        #expect(next.phase == .proof)
        #expect(effects.rootWindowVisible == false)
    }

    // MARK: - Regel 12

    @Test("Regel 12: ein gültiger Beweis bringt den Tag und die Stufe Angewendet")
    func regel12_beweisAngenommen() {
        let (next, effects) = reduce(beweisbereit(), .proofSubmitted(Self.guterBeweis))
        #expect(next.phase == .dawnProof)
        #expect(next.days == 1)
        #expect(next.progress["schnitt"]?.stage == .applied)
        #expect(next.progress["schnitt"]?.proofs.count == 1)
        #expect(next.progress["schnitt"]?.proofs.first?.text == Self.guterBeweis)
        #expect(next.progress["schnitt"]?.proofs.first?.submittedAt == clock.now)
        #expect(effects == [.scene(.presentSun), .persist])
    }

    @Test("Regel 12: ein zu kurzer Beweis wird ohne Vorwurf abgelehnt")
    func regel12_beweisAbgelehnt() {
        let state = beweisbereit()
        let (next, effects) = reduce(state, .proofSubmitted("kurz"))
        #expect(next.phase == .proof)
        #expect(next.days == 0)
        #expect(next.progress["schnitt"]?.proofs.isEmpty == true)
        #expect(effects.rejectReason != nil)
    }

    @Test("Regel 12: die abgeschriebene Anleitung wird abgelehnt")
    func regel12_abschriftAbgelehnt() {
        let (next, effects) = reduce(beweisbereit(), .proofSubmitted(ProofValidatorTests.anleitung))
        #expect(next.phase == .proof)
        #expect(next.days == 0)
        #expect(effects.rejectReason != nil)
    }

    // MARK: - Regel 13

    @Test("Regel 13: die zweite Sonne bringt den größeren Durchbruch")
    func regel13_zweiterDurchbruch() {
        var state = beweisbereit()
        state.phase = .dawnProof
        state.days = 1
        let (next, effects) = reduce(state, .sunPulled(1.0))
        #expect(next.phase == .cost)
        #expect(effects == [
            .scene(.dawn), .scene(.breakthrough(.second)), .scene(.fogLevel(1)),
            .haptic(.breakthrough), .sound(.breakthrough), .persist
        ])
    }

    // MARK: - Regel 14

    @Test("Regel 14: die Kosten-Antwort führt zum Befund")
    func regel14_costEntered() {
        var state = beweisbereit()
        state.phase = .cost
        state.days = 1
        state.nodeOutcomes = [.lukewarm, .glowing]
        let (next, effects) = reduce(state, .costEntered("Zwei Minuten Mut und eine unangenehme Nachricht"))
        #expect(next.phase == .befund)
        #expect(next.ownSentences.count == state.ownSentences.count + 1)
        #expect(next.ownSentences.last?.context == .cost)
        #expect(next.ownSentences.last?.text == "Zwei Minuten Mut und eine unangenehme Nachricht")
        #expect(next.befund != nil)
        #expect(effects.shownBefund == next.befund)
        #expect(effects.contains(.persist))
        #expect(effects.count == 2)
    }

    @Test("Regel 14: ohne Kosten-Antwort entsteht kein Satz, der Befund kommt trotzdem")
    func regel14_kostenUebersprungen() {
        var state = beweisbereit()
        state.phase = .cost
        state.days = 1
        let (next, effects) = reduce(state, .costEntered(nil))
        #expect(next.phase == .befund)
        #expect(next.ownSentences.count == state.ownSentences.count)
        #expect(effects.shownBefund != nil)
    }

    @Test("Regel 14b: der angenommene Befund führt in die Ruhe")
    func regel14b_befundAngenommen() {
        var state = beweisbereit()
        state.phase = .befund
        state.befund = Befund(sentence: "Dein Muster", evidence: ["lauwarm: 1"], principleID: "schnitt")
        let (next, effects) = reduce(state, .befundAnswered(accepted: true))
        #expect(next.phase == .idle)
        #expect(next.befundAccepted == true)
        #expect(effects == [.persist])
    }

    @Test("Regel 14b: ein abgelehnter Befund kostet nichts")
    func regel14b_befundAbgelehnt() {
        var state = beweisbereit()
        state.phase = .befund
        state.days = 1
        state.befund = Befund(sentence: "Dein Muster", evidence: ["lauwarm: 1"], principleID: "schnitt")
        let (next, effects) = reduce(state, .befundAnswered(accepted: false))
        #expect(next.phase == .idle)
        #expect(next.befundAccepted == false)
        #expect(next.days == 1)
        #expect(next.progress == state.progress)
        #expect(effects == [.persist])
    }

    // MARK: - Regel 15

    @Test("Regel 15: beim nächsten Öffnen kommt zuerst der eigene Satz")
    func regel15_eigenerSatz() {
        let alt = OwnSentence.fixture(id: "s1", createdAt: clock.now.addingTimeInterval(-3 * T.day))
        let state = PlayerState(phase: .idle, lightsRemaining: 0, days: 1, ownSentences: [alt])
        let (next, effects) = reduce(state, .appOpened)
        #expect(next.phase == .idle)
        #expect(effects.shownOwnSentence?.id == "s1")
        #expect(next.lastOpenedAt == clock.now)
    }

    @Test("Regel 15: ohne passenden Satz passiert beim Öffnen nichts")
    func regel15_keinSatz() {
        let frisch = OwnSentence.fixture(id: "s1", createdAt: clock.now.addingTimeInterval(-T.minute))
        let state = PlayerState(phase: .idle, lightsRemaining: 0, days: 1, ownSentences: [frisch])
        let (next, effects) = reduce(state, .appOpened)
        #expect(effects.isEmpty)
        // Kontrolle: appOpened stempelt trotzdem die Zeit.
        #expect(next.lastOpenedAt == clock.now)
        #expect(state.lastOpenedAt != clock.now)
    }

    // MARK: - Regel 16

    @Test("Regel 16: eine Aktion in der falschen Phase ändert nichts")
    func regel16_unbekannteAktion() {
        let state = PlayerState(phase: .firstLight)
        let (unveraendert, keineEffekte) = reduce(state, .costEntered("zu früh"))
        #expect(unveraendert == state)
        #expect(keineEffekte.isEmpty)

        // Kontrolle: in derselben Phase ist lightDropped definiert und verändert etwas.
        let (veraendert, effekte) = reduce(state, .lightDropped)
        #expect(veraendert != state)
        #expect(effekte.isEmpty == false)
    }

    @Test("Regel 16: auch der Beweis in der Wartephase prallt ab")
    func regel16_beweisWaehrendDerSperre() {
        let state = wartend(readyIn: 5 * T.minute)
        let (next, effects) = reduce(state, .proofSubmitted(Self.guterBeweis))
        #expect(next == state)
        #expect(effects.isEmpty)

        // Kontrolle: appOpened ist in dieser Phase definiert und verändert etwas.
        let (geoeffnet, effekte) = reduce(state, .appOpened)
        #expect(geoeffnet != state)
        #expect(effekte.isEmpty == false)
    }

    // MARK: - Regel 17

    @Test("Regel 17: ein zweiter Beweis im selben Fenster bringt keinen zweiten Tag")
    func regel17_zweiterBeweisImFenster() {
        var state = beweisbereit()
        let ersterBeweis = Proof.fixture(submittedAt: clock.now.addingTimeInterval(-2 * T.hour))
        state.progress["schnitt"] = PrincipleProgress(
            id: "schnitt",
            stage: .applied,
            stageEnteredAt: clock.now.addingTimeInterval(-2 * T.hour),
            proofs: [ersterBeweis]
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
        #expect(state.days == 0)
        #expect(state.lightsRemaining == 2)

        // Licht in den Nebel
        (state, effects) = reduce(state, .lightDropped, rules: rules)
        #expect(state.phase == .nodes)
        #expect(effects.presentedNodes?.count == 5)

        // Das Lauwarme frisst das Licht — und ersetzt es
        (state, effects) = reduce(state, .lightPlaced(.lukewarm), rules: rules)
        #expect(state.phase == .nodes)
        #expect(state.lightsRemaining == 2)
        #expect(effects.contains(.scene(.drainLight)))
        #expect(effects.contains(.scene(.presentLight)))
        #expect(state.nodeOutcomes == [.lukewarm])

        // Erstes Licht auf einen singenden Knoten: ein zweites folgt
        (state, effects) = reduce(state, .lightPlaced(.glowing), rules: rules)
        #expect(state.phase == .nodes)
        #expect(state.lightsRemaining == 1)
        #expect(effects.contains(.scene(.showRoots(.strong))))
        #expect(effects.contains(.scene(.presentLight)))
        #expect(state.progress["schnitt"]?.stage == .recognized)

        // Der kalte Knoten kostet nichts
        (state, effects) = reduce(state, .lightPlaced(.cold), rules: rules)
        #expect(state.phase == .nodes)
        #expect(state.lightsRemaining == 1)
        #expect(effects == [.scene(.thud), .haptic(.tap), .sound(.cold)])

        // Zweites Licht: jetzt kommt die Sonne
        (state, effects) = reduce(state, .lightPlaced(.glowing), rules: rules)
        #expect(state.phase == .roots)
        #expect(state.lightsRemaining == 0)
        #expect(effects.contains(.scene(.presentSun)))

        // Sonne halb, dann ganz
        (state, effects) = reduce(state, .sunPulled(0.5), rules: rules)
        #expect(state.phase == .roots)
        #expect(effects.sunProgress == 0.5)

        (state, effects) = reduce(state, .sunPulled(1.0), rules: rules)
        #expect(state.phase == .onboardingPain)
        #expect(effects.contains(.scene(.breakthrough(.first))))
        #expect(state.days == 0)

        // Onboarding
        (state, effects) = reduce(state, .painSelected([.zuVielLauwarmes, .zeitWeg]), rules: rules)
        #expect(state.phase == .onboardingWhy)
        #expect(state.lightColorTile == .zuVielLauwarmes)
        #expect(effects.contains(.scene(.tintLight(.zuVielLauwarmes))))

        (state, effects) = reduce(state, .whyEntered("Mehr Zeit für meine Kinder"), rules: rules)
        #expect(state.phase == .intention)
        #expect(state.ownSentences.count == 1)

        (state, effects) = reduce(state, .intentionChosen(.fixture()), rules: rules)
        #expect(state.phase == .closed)
        #expect(state.intention?.dueBy == clock.now.addingTimeInterval(T.day))

        let geschlossenUm = clock.now
        (state, effects) = reduce(state, .closeForToday, rules: rules)
        #expect(state.phase == .waiting)
        #expect(state.closedAt == geschlossenUm)
        #expect(state.readyAt == geschlossenUm.addingTimeInterval(600))
        #expect(effects == [.scene(.rootWindow(visible: true)), .persist])

        // Zu früh zurück
        clock.advance(by: 4 * T.minute)
        (state, effects) = reduce(state, .appOpened, rules: rules)
        #expect(state.phase == .waiting)
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
        #expect(state.progress["schnitt"]?.stage == .applied)
        #expect(effects == [.scene(.presentSun), .persist])

        // Zweiter Durchbruch
        (state, effects) = reduce(state, .sunPulled(1.0), rules: rules)
        #expect(state.phase == .cost)
        #expect(effects.contains(.scene(.breakthrough(.second))))
        #expect(effects.contains(.scene(.fogLevel(1))))

        // Kosten und Befund
        (state, effects) = reduce(state, .costEntered("Zwei Minuten Mut und eine unangenehme Nachricht"), rules: rules)
        #expect(state.phase == .befund)
        #expect(state.ownSentences.count == 2)
        #expect(effects.shownBefund != nil)
        #expect(state.befund?.principleID == "schnitt")
        #expect(state.befund?.sentence == BefundGeneratorTests.lauwarmSatz)

        (state, effects) = reduce(state, .befundAnswered(accepted: true), rules: rules)
        #expect(state.phase == .idle)
        #expect(state.befundAccepted == true)
        #expect(effects == [.persist])

        // Am nächsten Tag: der eigene Satz
        clock.advance(by: T.day)
        (state, effects) = reduce(state, .appOpened, rules: rules)
        #expect(state.phase == .idle)
        #expect(state.days == 1)
        #expect(effects.shownOwnSentence?.context == .why)
        #expect(effects.shownOwnSentence?.text == "Mehr Zeit für meine Kinder")
    }

    @Test("Golden Path im Demo-Modus: derselbe Loop, nur kürzere Zeiten")
    func goldenPathDemo() throws {
        let rules = Rules.demo
        var effects: [Effect] = []

        var state = GameEngine.initial(clock: clock, rules: rules)
        #expect(state.phase == .firstLight)
        #expect(state.lightsRemaining == 2)

        (state, _) = reduce(state, .lightDropped, rules: rules)
        (state, _) = reduce(state, .lightPlaced(.lukewarm), rules: rules)
        #expect(state.lightsRemaining == 2)

        (state, _) = reduce(state, .lightPlaced(.glowing), rules: rules)
        #expect(state.phase == .nodes)
        #expect(state.lightsRemaining == 1)

        (state, _) = reduce(state, .lightPlaced(.glowing), rules: rules)
        #expect(state.phase == .roots)
        #expect(state.lightsRemaining == 0)

        (state, _) = reduce(state, .sunPulled(1.0), rules: rules)
        #expect(state.phase == .onboardingPain)

        (state, _) = reduce(state, .painSelected([.zeitWeg]), rules: rules)
        (state, _) = reduce(state, .whyEntered("Mehr Zeit für meine Kinder"), rules: rules)
        (state, _) = reduce(state, .intentionChosen(.fixture()), rules: rules)
        #expect(state.phase == .closed)
        #expect(state.intention?.dueBy == clock.now.addingTimeInterval(600))

        let geschlossenUm = clock.now
        (state, _) = reduce(state, .closeForToday, rules: rules)
        #expect(state.phase == .waiting)
        #expect(state.readyAt == geschlossenUm.addingTimeInterval(30))

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
        #expect(state.phase == .cost)

        (state, effects) = reduce(state, .costEntered("Zwei Minuten Mut"), rules: rules)
        #expect(state.phase == .befund)
        #expect(effects.shownBefund != nil)

        (state, _) = reduce(state, .befundAnswered(accepted: true), rules: rules)
        #expect(state.phase == .idle)

        // Rückspiel bereits nach einer Minute
        clock.advance(by: T.minute)
        (state, effects) = reduce(state, .appOpened, rules: rules)
        #expect(effects.shownOwnSentence?.text == "Mehr Zeit für meine Kinder")
    }

    // MARK: - Hilfen

    /// Wartender Zustand: `readyAt` liegt `readyIn` Sekunden in der Zukunft
    /// (negativ = die Sperre ist bereits abgelaufen).
    func wartend(readyIn: TimeInterval) -> PlayerState {
        PlayerState(
            phase: .waiting,
            createdAt: clock.now.addingTimeInterval(-T.hour),
            lastOpenedAt: clock.now.addingTimeInterval(-T.hour),
            lightsRemaining: 0,
            pains: [.zuVielLauwarmes],
            why: "Mehr Zeit für meine Kinder",
            intention: .fixture(dueBy: clock.now.addingTimeInterval(T.day)),
            closedAt: clock.now.addingTimeInterval(readyIn - 600),
            readyAt: clock.now.addingTimeInterval(readyIn),
            nodeOutcomes: [.lukewarm, .glowing]
        )
    }

    /// Zustand kurz vor dem Beweis: Absicht gesetzt, Sperre abgelaufen.
    func beweisbereit() -> PlayerState {
        PlayerState(
            phase: .proof,
            createdAt: clock.now.addingTimeInterval(-T.hour),
            lastOpenedAt: clock.now,
            lightsRemaining: 0,
            lightColorTile: .zuVielLauwarmes,
            pains: [.zuVielLauwarmes, .zeitWeg],
            why: "Mehr Zeit für meine Kinder",
            intention: .fixture(dueBy: clock.now.addingTimeInterval(T.day)),
            closedAt: clock.now.addingTimeInterval(-T.hour),
            readyAt: clock.now.addingTimeInterval(-30 * T.minute),
            progress: [
                "schnitt": PrincipleProgress(
                    id: "schnitt",
                    stage: .recognized,
                    stageEnteredAt: clock.now.addingTimeInterval(-T.hour)
                )
            ],
            days: 0,
            ownSentences: [
                OwnSentence.fixture(id: "s1", createdAt: clock.now.addingTimeInterval(-T.hour))
            ],
            nodeOutcomes: [.lukewarm, .glowing]
        )
    }
}

@Suite("PainTile")
struct PainTileTests {

    @Test("„Zeit weg“ dreht sich zu „Deine Zeit gehört dir“")
    func zeitWegDrehtSich() {
        #expect(PainTile.zeitWeg.inverted == "Deine Zeit gehört dir")
    }

    @Test("Jede der sechs Kacheln hat ein Gegenteil")
    func jedeKachelHatEinGegenteil() {
        #expect(PainTile.allCases.map(\.rawValue) == [
            "zeitWeg", "zuVielLauwarmes", "keinFortschritt",
            "geldReichtNicht", "immerErreichbar", "allesHaengtAnMir"
        ])
        #expect(PainTile.allCases.allSatisfy { !$0.inverted.isEmpty })
        #expect(PainTile.allCases.allSatisfy { $0.inverted != $0.rawValue })
    }

    @Test("Die Gegenteile sind untereinander verschieden")
    func gegenteileSindEindeutig() {
        #expect(Set(PainTile.allCases.map(\.inverted)).count == 6)
    }
}
