# LEVMI — Red-Team-Kritik an Synthese und PoC-Spec

**Von:** Red Team (ADA-Juror + Produktchef) · **An:** Christian · **Datum:** 2026-09-07
**Geprüft gegen:** 00-brief, Memos 01–05, 06-Synthese, ADR 01–05, **poc-spec in der überarbeiteten Fassung** (fünf Knoten, zwei Lichter, `readyAt`, 10-Minuten-Sperre), Repo-Skelett.

**Schon repariert, nicht mehr Thema:** Zieh-Affordance in Sekunde 0, Balken 1/30, Sanduhr als Konsequenz statt Warnung, „Zurück ab HH:MM" statt Countdown, „Bleibt auf deinem Gerät", Reset-Knopf. Gut gemacht.

**Kurzurteil:** Die Architektur trägt, die Spec nicht. Sie definiert Bloom-Radien auf zwei Nachkommastellen und lässt den Reducer an fünf Stellen offen, an denen die App morgen früh einfriert. Sie enthält weiterhin keine Entscheidung, die etwas kostet. Und die Überarbeitung hat Umfang addiert, nicht Risiko genommen.

---

## A) Die drei größten Denkfehler

### A1. Keine Entscheidung kostet etwas — deshalb ist der PoC weder Spiel noch Diagnose

Fünf Knoten, zwei Lichter, und trotzdem genau ein möglicher Ausgang: Der **kalte** Knoten kostet nichts (Regel 5), der **lauwarme** kostet nichts (Regel 4: „das gefressene Licht wird ersetzt"), also endet jeder Spieler mit zwei Setzungen auf den beiden glühenden Knoten. „Das Lauwarme hat dein Licht gefressen" ist ein Satz, den die Mechanik im selben Atemzug widerlegt. Knappheit — Grundgefühl der Fantasie und der ganze Pareto-Gedanke — existiert im PoC nicht, und der Dreimal-Test des Directors („setzt du das Licht beim zweiten Mal *anders*?") ist unbeantwortbar.

Die Überarbeitung verschärft das. Der lauwarme Knoten sieht bis zur Setzung aus wie der singende, also trifft ihn fast jeder — und `BefundGenerator` liefert bei „≥ 1 lauwarm" immer Satz 1. Der Befund ist eine **Horoskop-Maschine**: Das Tutorial erzeugt die Evidenz, die der Befund als Diagnose zurückgibt; Fall 3 nimmt sogar „erste Kachel als Evidenz", also das, was der Spieler selbst angekreuzt hat. Growth hat P0 an „ein Befund, dem er zustimmt **und der unangenehm ist**" gehängt. Du wirst zustimmen, unangenehm wird es nicht, weil du den Trick gebaut hast. Falsches Grün.

**Gegenvorschlag (~45 Min):** (a) Lauwarm kostet das Licht wirklich; die Sonne kommt trotzdem, aber die Wurzeln bleiben dünn und der Durchbruch ist `.tier0` — dieselbe Mühe, weniger Welt. Die Lektion, wortlos, und Text 2 wird überflüssig. (b) Der Befund entsteht aus dem **Widerspruch zwischen Gesagtem und Getanem**, mit Zeitstempeln, die die `Clock` liefert: „Du hast *Zu viel Lauwarmes* angekreuzt — und dann neun Sekunden gebraucht, um es trotzdem anzufassen." Aus eigenen Daten, unangenehm, widerlegbar. (c) „Stimmt nicht" muss zu einem zweiten Satz führen, sonst ist der Knopf Dekoration.

### A2. Der Umfang ist seit Memo 03 dreimal gewachsen, und es gibt keine Schnittlinie

Der Engine-Architekt kalkulierte **6,25 h** für sieben Pakete — ohne Persistenz, Onboarding, Content-Pipeline, UI-Tests. In der Spec stehen heute: neun Overlays, Disk-Persistenz, Validator mit acht Regeln, ≥ 40 test-first-Tests (seriell: Opus schreibt, Sonnet implementiert, Opus reviewt), Befund, **zwei** Share-Cards, prozedurales Audio, Demo-Modus, Reset, tageszeitabhängige Überschriften, Herkunftsanzeige. Realistisch 14–18 Stunden, und die Überarbeitung hat ausschließlich hinzugefügt.

Die Spec sagt, was *nicht* gebaut wird — nirgends, **was um 03:00 stirbt, wenn ihr hinten liegt.** Ohne diese Zeile priorisiert um vier Uhr die Müdigkeit, und die wählt das Fast-Fertige.

**Gegenvorschlag (10 Min):** **MDP bis 03:00:** erste Minute + Durchbruch + Persistenz + Sperre + Beweis + „in eigenen Worten". **Danach killbar, in dieser Reihenfolge:** beide Share-Cards → Validator-Regeln 1–4/7/8 → Audio-Tiefe → Befund → Kosten-Frage. Und: die neun Overlays sind **eine** Komponente (Titel/Text/Eingabe/CTA) in sieben Konfigurationen — allein 60–90 Minuten.

### A3. Der Demo-Modus testet die Variable weg, die bewiesen werden soll

Die These lautet: „Ich habe draußen etwas getan, und drinnen ist etwas gewachsen." Der Demo-Modus verkürzt die Sperre auf 30 Sekunden — kein Vorfreude-Fenster, ein Ladebalken. Der Beweis, den du morgen früh eintippst, wird über etwas sein, das du nicht getan hast. Go/No-Go-Test 2 ist im Demo-Modus **strukturell nicht durchführbar.** „Keine Regel wird ausgeschaltet" ist im Code wahr und im Erleben falsch.

**Gegenvorschlag (0 Min Entwicklung, ändert die Reihenfolge):** Du spielst heute Nacht einmal den **Echt-Modus**: Licht setzen, eine Absicht wählen, die du morgen früh wirklich tun kannst, App zu, schlafen. Morgen früh tust du es und gibst den echten Beweis. Der einzige Lauf, der die These prüft; der Demo-Modus ist ein Vorführwerkzeug für andere. Konsequenz: Der Echt-Pfad muss **zuerst** stehen und einen Kaltstart nach sechs Stunden überleben, bevor jemand am Befund arbeitet.

---

## B) Konsistenz-Check und Reducer-Lücken

**Widersprüche:**

1. **Drei Dokumente, drei Zahlen.** Die Spec setzt `appliedLock = 600 s`. ADR 02 sagt weiter wörtlich „≥ 60 Minuten", Synthese §6 spricht von der „60-Minuten-Sperre", Memo 05 fordert 60 Minuten als Mastery-Bedingung. Dasselbe bei der Knotenzahl: Spec fünf, Synthese §3b drei. Die Spec ist als „Vertrag" deklariert, die vorgelagerten Dokumente wurden nicht mitgezogen — ein Reviewer, der gegen das ADR prüft, kippt heute Nacht einen korrekten Test. Nachziehen oder 60 Minuten zurückholen.
2. **10-Minuten-Sperre vs. „Klein genug für morgen früh".** Nach 20 Uhr schlägt die App eine Absicht für den nächsten Morgen vor — und fragt zehn Minuten später „Hast du es getan?". **Fix:** Die Sperre endet frühestens bei `intention.dueBy`. Damit wird `dueBy` erstmals gelesen; heute wird es nur geschrieben.
3. **„Erleben vor Benennen" vs. inzwischen vier Texte.** Die Überschrift von 1.1 sagt weiter „ohne Text bis auf zwei Zeilen", der Ablauf enthält vier. Go/No-Go-Test 3 (Text-Aus-Test) ist per Konstruktion nicht bestehbar. Mit A1 fällt Text 2 weg, die Affordance-Texte sind gerechtfertigt — schreib die Überschrift ehrlich um.
4. **„Verstanden" fehlt komplett.** `CopyCheck`, `minExplanationChars: 60` und `PrincipleProgress.explanation` werden gebaut und getestet, aber von keinem Code-Pfad benutzt. Die Leiter springt `recognized` → `applied`. Verletzt Memo 05 Punkt 3 und Memo 02 Stufe 2 (siehe E).
5. **Zeichenzähler im Beweisfeld.** Macht aus dem Beweis eine Hausaufgabe („40 erreicht") — Risiko Nr. 1 des Psychologen. Rückmeldung ist die greifbar werdende Sonne, keine Zahl.

**Lücken im Reducer-Ablauf 3.2:**

- **Knoten haben keine Identität.** `presentNodes([NodeKind])` und `lightPlaced(NodeKind)` transportieren nur die Art. Bei drei Knoten grenzwertig, bei fünf kaputt: Der Reducer weiß nicht, welcher glühende Knoten gesetzt wurde, kann Doppelsetzung nicht verhindern und kennt die freien Knoten nicht. **Fix (15 Min):** `lightPlaced(nodeID:kind:)`, `presentNodes([(id, kind)])`. Nach dem ersten Test nicht mehr billig.
- **App-Kill → Softlock.** Die Szene wird aus *Effekten* aufgebaut (`revealIsland`, `presentNodes`), nicht aus dem Zustand projiziert. Nach einem `.persist` und Neustart in `nodes`/`roots`/`proof`/`cost` greift Regel 16 („Aktion in fremder Phase → nichts"): `appOpened` liefert **keine** Kommandos. Nebelmeer ohne Insel, ohne Knoten, ohne Ausweg — und das passiert beim ersten Wegwischen morgen früh. **Fix (30 Min):** `appOpened` ist in *jeder* Phase gültig und liefert die vollständige Wiederherstellungsliste. Test: „für jede Phase eine nicht-leere Kommandoliste".
- **Kill in Phase `closed`.** `readyAt` entsteht erst bei `closeForToday` (Regel 10); wer vorher killt, hat nil, und Regel 11 vergleicht gegen nil. **Fix:** `appOpened` in `closed` wirkt wie `closeForToday`.
- **Die Sonne wird nie hochgezogen.** `SceneEvent.sunReleased` existiert, eine Aktion dafür nicht. Bei 0,4 loslassen — zurückschnappen, stehenbleiben, Schwellwert? Undefiniert heißt: der Renderer erfindet die Regel, die Domäne besitzt sie nicht mehr. **Fix (15 Min):** `sunPulled` monoton, unter 1,0 sanft auf den letzten Höchststand, nach 6 s ohne Zug pulsiert sie.
- **Regel 6 setzt `phase = .onboardingPain`, während der Durchbruch läuft.** Ist die View phasengetrieben, liegen die Hass-Kacheln über dem einen Moment, in den 60 % der Nacht geflossen sind. **Fix:** Aktion `breakthroughFinished` vom Renderer, kein Timer in der View.
- **`idle` hat keinen Ausgang** — kein zweiter Abend, keine zweite Absicht. Für eine Nacht vertretbar, steht aber nirgends. Als bekannte Grenze hinschreiben.

---

## C) Der Apple-Blick

Heute Nacht (zusammen ~90 Min):

- **Reduce Motion.** Bisher nur für den Kachel-Flip vorgesehen. Es fehlt der Rest: Dolly, 1,5-s-Tauchgang, FOV-Puls ±3°, Push-In, 70-s-Drift, 600-Partikel-Burst — die vollständige Liste vestibulärer Auslöser. `accessibilityReduceMotion`: Überblendung statt Kamerafahrt, kein FOV-Puls, Partikel gedrittelt. Zentral in `Choreography` 20 Minuten, verstreut zwei Stunden. Genau deshalb heute.
- **Blendung/Flackern.** Emission > 1,5 auf #04040E plus Vollbild-Burst. Regel: keine Helligkeitsänderung über > 10 % der Fläche schneller als 3 Hz, Durchbruchs-Burst rampt über ≥ 400 ms statt zu blitzen. `accessibilityDimFlashingLights` respektieren. 10 Minuten.
- **Sechs Accessibility-Elemente über der `SCNView`** (fünf Knoten + Sonne) mit Labels und Custom Action „Licht setzen". Für VoiceOver ist ein `SCNView` sonst eine stumme Fläche — nicht *reduziert*, sondern *nichts*. Damit ist der Kern-Loop mit VoiceOver abschließbar, und genau das prüft ein ADA-Juror. Passt es nicht rein: in die README, **nicht** in die Accessibility-Angaben der Produktseite.
- **Hass-Kacheln überspringbar machen.** Regel 7 lehnt leere Auswahl weiter ab — erzwungene Selbstoffenbarung in Minute 2. Autonomie ist eine der drei SDT-Säulen des Retentionsmodells. 5 Minuten.
- **Die neue Kachel-Share-Card ist das Datenschutzleck.** Der Befund-Satz ist generiert, unkritisch. Die Umkehr-Karte zeigt die **gewählten Kacheln**, also die Problemauswahl in positiver Verkleidung — wer sie teilt, teilt eine Selbstauskunft. Positive Rahmung reicht nicht: keine ungewählte Kachel darf erscheinen, und der Teilen-Knopf gehört hinter eine bewusste Geste. Dazu `FileSaveStore` mit `.completeUntilFirstUserAuthentication` und null Netzwerkaufrufe — „diese App telefoniert nicht" ist ein belegbares Featuring-Argument.

Darf warten: VoiceOver-Rotor-Navigation der Insel, Dynamic Type über alle künftigen Screens (heute nur: keine festen Höhen, Kachelraster bricht bei AX5 auf eine Spalte), Voice Control, Lokalisierung.

---

## D) Der Spieler-Blick — drei Abbruchpunkte

**1. Minute 2–4: die Schleife in Phase `nodes`.** Zwei lauwarme Knoten, die aussehen wie die glühenden, plus Erstattung: Wer zweimal danebengreift, bekommt zweimal dieselbe Animation, denselben Ton, denselben Satz — ohne Sonne, ohne Fortschritt, ohne Ausweg. Der 40-jährige Unternehmer liest das als „die App lässt mich nicht weiter", der 28-Jährige als „ich werde fürs Raten bestraft". Teuerster Nebeneffekt der Überarbeitung. *Fix (< 30 Min):* Ab dem zweiten Fehlgriff pulsieren die verbleibenden glühenden Knoten ruhig und stetig — das Spiel bringt das Erkennungsmerkmal bei, statt die Strafe zu wiederholen — und nach vier Setzungen erscheint die Sonne in jedem Fall.

**2. Minute 1: die Hass-Kacheln.** Direkt nach dem Belohnungsmoment ein Pflicht-Fragebogen mit „Geld reicht nicht". Für den 40-Jährigen passt keine Kachel — es wirkt wie eine Umfrage für jemand anderen. Für den 28-Jährigen mit Nebenprojekt passt sie zu gut für Minute 2 gegenüber einer App, die er 90 Sekunden kennt. Beide denken: „Ach so, ein Quiz." *Fix (< 20 Min):* überspringbar machen, situativ statt charakterlich fragen — „Was hat dich diese Woche am meisten aufgehalten?"

**3. Der zweite Besuch während der Sperre.** „Zurück ab 14:20" ist gut; es fehlt ein Grund wiederzukommen und etwas zu tun, während die Tür zu ist. *Fix (< 30 Min):* Wartezeit **physisch** zeigen (Sonnenstand unter dem Horizont), das Wurzelfenster während der Sperre anfassbar lassen — und die lokale Benachrichtigung zum Ablauf, formuliert **mit seinem eigenen Absichtssatz**.

---

## E) Fehlt komplett / muss trotzdem rein

1. **Zustand → Szene-Wiederherstellung** (B). Ohne sie ist die Demo nach dem ersten Wegwischen tot.
2. **Lokale Benachrichtigung am Ende der Sperre, mit den eigenen Worten des Spielers** (~20 Min inkl. Vorabfrage bei „Für heute reicht's"). Die Rückkehr ist derzeit eine Hoffnung, kein Mechanismus — und die Rückkehr *ist* das Produkt.
3. **„Sag es in deinen Worten" nach dem Durchbruch** (~15 Min). Nutzt `CopyCheck` und `minExplanationChars`, schließt Stufe „Verstanden" und erzeugt den Satz, der das Zurückspielen später trägt.

## Was fliegen sollte

1. **Beide Share-Cards** (60–75 Min). Sie testen heute Nacht nichts: kein Publikum, keine Landingpage, n = 1 im Simulator. Ein Screenshot ist die Share-Card; nächste Woche in 20 Minuten nachbaubar.
2. **Validator-Regeln 1–4, 7, 8 samt Testsuite** (60–90 Min, seriell durch Opus *und* Sonnet). Sie schützen gegen ein Risiko, das heute Nacht nicht eintreten kann: drei handgeschriebene Karten, dieselben Autoren, kein CI, `werkstatt.json` liegt fertig im Repo. Heute nur Regel 5 + 6 (Attribution + Sperrliste/n-Gramm) — das IP-Gate ist das Einzige, was sich nicht nachrüsten lässt, ohne allen Content anzufassen.
3. **Audio-Tiefe.** LFO-Filter, schwebendes Detune mit Tremolo, ein sich auflösender Dur-Akkord, „timing-genau zu Haptik und Partikeln" — ein 2–3-Stunden-Loch für jeden, der `AVAudioEngine` nicht täglich benutzt. Heute: vier beim Start erzeugte PCM-Puffer (Drone + drei Transienten) per `scheduleBuffer`. Achtzig Prozent der Wirkung, weiterhin kein Lizenzmaterial.

---

## F) Go / No-Go

**Go — mit vier Bedingungen.** Der Kern trägt: eine Welt, ein Gesetz, eine Geste, ein Moment, Fortschritt nur gegen Beweis, Content als Daten, ein reiner Reducer als Vertrag.

1. **Schnittlinie mit Uhrzeiten in die Spec, bevor die erste Zeile Code fällt** (A2). Ab jetzt gilt: keine Ergänzung ohne Streichung.
2. **Die Reducer-Löcher schließen, bevor Opus den ersten Test schreibt** — Knoten-Identität, Wiederherstellung, Sonnen-Release, Lauwarm kostet wirklich. Tests gegen einen lückenhaften Vertrag sind teurer als gar keine.
3. **Sperre, ADR 02 und Synthese in Übereinstimmung bringen** (10 vs. 60 Minuten, gekoppelt an `dueBy`), und Reduce Motion, Flackerrampe und die sechs Accessibility-Elemente in den Build — nicht als Ticket.
4. **Du spielst heute Nacht den Echt-Modus** und gibst morgen früh einen echten Beweis (A3). Sonst prüfst du die Bedienung, nicht die These.

**No-Go-Auslöser um 03:00:** Steht der Durchbruchs-Moment dann nicht, wird alles unterhalb der Schnittlinie gestrichen und die Nacht endet mit dem MDP. Ein fertiges Onboarding auf einem toten Kern ist der teuerste mögliche Ausgang dieser Nacht.
