# LEVMI — Red-Team-Kritik an Synthese und PoC-Spec

**Von:** Red Team (ADA-Juror + Produktchef) · **An:** Christian · **Datum:** 2026-09-07 · **Gelesen:** 00-brief, 01–05, 06-Synthese, poc-spec, ADR 01–05, Repo-Skelett.

**Kurzurteil:** Die Architektur ist gut, die Spec ist es nicht. Sie beschreibt Bloom-Radien auf zwei Nachkommastellen und lässt den Reducer an drei Stellen offen, an denen die App morgen früh einfriert. Und sie enthält kein Spiel, weil sie keine Entscheidung enthält, die etwas kostet.

---

## A) Die drei größten Denkfehler

### A1. Im ganzen PoC gibt es keine Entscheidung, die etwas kostet — deshalb ist er weder Spiel noch Diagnose

`lightsPerNight = 1`. Der **kalte** Knoten kostet nichts (Regel 5: „Licht bleibt erhalten"). Der **lauwarme** kostet nichts (Regel 4: „das gefressene Licht wird ersetzt"). Der **glühende** ist der einzige Ausgang — genau ein erreichbarer Endzustand. „Das Lauwarme hat dein Licht gefressen" ist eine Behauptung, die die Mechanik im selben Atemzug widerlegt. Knappheit, das Grundgefühl der ganzen Fantasie, existiert im PoC nicht.

Erste Folge: Der Dreimal-Test des Directors („setzt du das Licht beim zweiten Mal *anders*?") ist unbeantwortbar — anders geht nicht. Zweite, schwerere: Der **Befund** ist eine Horoskop-Maschine. `BefundGenerator` liest drei Fälle aus `nodeOutcomes`, aber das Tutorial ist so gebaut, dass fast jeder den lauwarmen Knoten anfasst — er *ist* der designierte Lernmoment. Also bekommt fast jeder Satz 1. Fall 3 nimmt „erste Kachel als Evidenz", also das, was der Spieler zwei Bildschirme vorher selbst angekreuzt hat. Growth hat P0 an „ein Befund, dem er zustimmt **und der unangenehm ist**" gehängt. Du wirst zustimmen, und unangenehm wird es nicht, weil du den Trick gebaut hast. Falsches Grün.

**Gegenvorschlag (~45 Min):** (a) Lauwarm kostet das Licht wirklich. Die Sonne wird trotzdem greifbar, aber die Wurzeln bleiben dünn und der Durchbruch ist ein `.tier0` — dieselbe Mühe, weniger Welt. Das ist die Lektion, wortlos. (b) Der Befund entsteht aus dem **Widerspruch zwischen Gesagtem und Getanem**, mit Zeitstempeln, die du über die `Clock` ohnehin hast: „Du hast *Zu viel Lauwarmes* angekreuzt — und dann neun Sekunden gebraucht, um es trotzdem anzufassen." Aus eigenen Daten, unangenehm, widerlegbar. (c) „Stimmt nicht" muss zu einem zweiten Befund führen, sonst ist der Knopf Dekoration.

### A2. Der Scope hat sich seit Memo 03 verdreifacht, und es gibt keine Schnittlinie

Der Engine-Architekt hat **6,25 h** für sieben Pakete kalkuliert — ohne Persistenz, Onboarding, Content-Pipeline, UI-Tests. Die Spec addiert: neun Overlays, Disk-Persistenz, Validator mit acht Regeln, ≥ 40 test-first-Tests (seriell: Opus schreibt, Sonnet implementiert, Opus reviewt), Befund, Share-Card, prozedurales Audio, Demo-Modus, Screenshots, Recording. Realistisch 14–18 Stunden. Die Spec sagt, was *nicht* gebaut wird — nirgends, **was um 03:00 stirbt, wenn ihr hinten liegt.** Ohne diese Zeile priorisiert um vier Uhr die Müdigkeit, und die wählt das Fast-Fertige, nicht das Wichtige.

**Gegenvorschlag (10 Min Schreibarbeit):** Schnittlinie in die Spec. **MDP bis 03:00:** erste Minute + Durchbruch + Persistenz + Sperre + Beweis + „in eigenen Worten". **Danach killbar, in dieser Reihenfolge:** Share-Card → Validator-Regeln 1–4/7/8 → Audio-Tiefe → Befund → Kosten-Frage. Und: die neun Overlays sind **eine** Komponente (Titel/Text/Eingabe/CTA) in sieben Konfigurationen. Das allein sind 60–90 Minuten.

### A3. Der Demo-Modus testet genau die Variable weg, die bewiesen werden soll

Die These lautet: „Ich habe draußen etwas getan, und drinnen ist etwas gewachsen." Der Demo-Modus verkürzt die Sperre auf 30 Sekunden — kein Vorfreude-Fenster, ein Ladebalken. Der Beweis, den du morgen früh eintippst, wird über etwas sein, das du nicht getan hast. Go/No-Go-Test 2 ist im Demo-Modus **strukturell nicht durchführbar.** „Keine Regel wird ausgeschaltet" ist im Code wahr und im Erleben falsch.

**Gegenvorschlag (0 Min Entwicklung, ändert die Reihenfolge):** Du spielst heute Nacht einmal den **Echt-Modus**: Licht setzen, eine Absicht wählen, die du morgen früh wirklich tun kannst, App zu, schlafen. Morgen früh tust du es und gibst den echten Beweis. Der einzige Lauf, der die These prüft; der Demo-Modus ist ein Vorführwerkzeug für andere. Konsequenz: Der Echt-Pfad muss **zuerst** stehen und persistent sein — ein Kaltstart nach sechs Stunden muss halten, bevor jemand am Befund arbeitet.

---

## B) Konsistenz-Check und Reducer-Lücken

**Widersprüche:**

1. **„Erleben vor Benennen" vs. Text 2.** „Das Lauwarme hat dein Licht gefressen" benennt Konsequenz *und* Deutung, zwei Sekunden nach dem Erleben, in den Worten der App. Gleichzeitig verlangt Go/No-Go-Test 3 einen Text-Aus-Test, den die Spec per Konstruktion nicht bestehen kann, weil die Lektion im Text steckt. **Text 2 streichen** — Aufsaugen, Sanduhr und dunkler Himmel sagen es bereits.
2. **„Verstanden" fehlt komplett.** `CopyCheck`, `minExplanationChars: 60` und `PrincipleProgress.explanation` werden gebaut und getestet — und von keinem Code-Pfad benutzt. Die Leiter springt `recognized` → `applied`. Verletzt Memo 05 Punkt 3 und Memo 02 Stufe 2, und ist das billigste fehlende Stück (siehe E).
3. **„Keine Zahl" vs. „+1 Tag" und „Balken 1/30".** Ein Beweis = ein Tag = ein Zähler: XP mit besserem Etikett. Der Nenner ist schlimmer — „1/30" behauptet eine Ziellinie und widerspricht ADR 02 („es gibt kein 100 %"). **Nenner weg.** Ebenso der **Zeichenzähler** im Beweisfeld: Er macht aus dem Beweis eine Hausaufgabe („40 erreicht"), genau Risiko Nr. 1 des Psychologen. Rückmeldung ist die greifbar werdende Sonne.
4. **„Nach fünf Minuten wegschicken" vs. Demo-Modus.** Siehe A3.
5. **`dueBy` wird geschrieben und nie gelesen.** Regel 11 prüft nur die Untergrenze; ein Beweis nach 48 h zählt wie einer nach zwei Stunden. Feld streichen oder festlegen: läuft nie ab, wird mit Alter gezeigt. Nie bestrafen.

**Lücken im Reducer-Ablauf 3.2 — jede davon ist morgen früh sichtbar:**

- **App-Kill in der ersten Minute → Softlock.** Die Szene wird von *Effekten* aufgebaut (`revealIsland`, `presentNodes`), nicht aus dem Zustand projiziert. Wird nach dem ersten Speichern in Phase `nodes`/`roots`/`proof`/`cost` neu gestartet, greift Regel 16 („Aktion in fremder Phase → nichts"): `appOpened` liefert **keine** Kommandos. Nebelmeer ohne Insel, ohne Knoten, ohne Ausweg — und das passiert morgen früh beim ersten Wegwischen. **Fix (30 Min):** `appOpened` ist in *jeder* Phase gültig und liefert die vollständige Wiederherstellungsliste; Test: „für jede Phase eine nicht-leere Kommandoliste".
- **Kill in Phase `closed`.** `closedAt` wird erst bei `closeForToday` gesetzt (Regel 10); wer vorher killt, hat `closedAt == nil`, und Regel 11 rechnet mit nil. **Fix:** `appOpened` in `closed` wirkt wie `closeForToday`.
- **Der Spieler zieht die Sonne nie hoch.** `SceneEvent.sunReleased` existiert, eine Aktion dafür nicht. Bei 0,4 loslassen — zurückschnappen, stehenbleiben, Schwellwert? Undefiniert heißt: der Renderer erfindet die Regel, die Domäne besitzt sie nicht mehr. **Fix (15 Min):** `sunPulled` monoton (Maximum), unter 1,0 sanft auf den letzten Höchststand, nach 6 s ohne Zug pulsiert sie.
- **Dreimal lauwarm:** unendlich oft, folgenlos, identischer Ton und Haptik. Mit A1 gelöst; sonst mindestens ab dem zweiten Mal keinen Text wiederholen und den Sanduhr-Ton dumpfer werden lassen.
- **Regel 6 setzt `phase = .onboardingPain`, während der Durchbruch noch läuft.** Ist die View phasengetrieben, liegen die Hass-Kacheln über dem einen Moment, in den 60 % der Nacht geflossen sind. **Fix:** Aktion `breakthroughFinished` vom Renderer (Event-Kanal existiert), kein Timer in der View.
- **`idle` hat keinen Ausgang** — kein zweiter Abend, keine zweite Absicht. Für eine Nacht in Ordnung, steht aber nirgends. Als bekannte Grenze hinschreiben.

---

## C) Der Apple-Blick

Was heute Nacht rein muss (zusammen ~90 Min):

- **Reduce Motion.** Dolly, 1,5-s-Tauchgang, FOV-Puls, Push-In, 70-s-Drift, 600-Partikel-Burst — eine Liste vestibulärer Auslöser. `accessibilityReduceMotion`: Überblendung statt Kamerafahrt, kein FOV-Puls, Partikel gedrittelt. Zentral in `Choreography` sind das 20 Minuten, verstreut zwei Stunden. Genau deshalb heute.
- **Blendung/Flackern.** Emission > 1,5 auf #04040E plus Vollbild-Burst. Regel: keine Helligkeitsänderung über > 10 % der Fläche schneller als 3 Hz, Durchbruchs-Burst rampt über ≥ 400 ms statt zu blitzen. `accessibilityDimFlashingLights` respektieren. 10 Minuten.
- **Vier Accessibility-Elemente über der `SCNView`** (drei Knoten + Sonne) mit Labels („Knoten, singt" / „brummt" / „flirrt, lauwarm") und Custom Action „Licht setzen". Für VoiceOver ist ein `SCNView` sonst eine stumme Fläche — nicht *reduziert*, sondern *nichts*. Damit ist der Kern-Loop mit VoiceOver abschließbar, und genau das prüft ein ADA-Juror. Passt es nicht rein: in die README, **nicht** in die Accessibility-Angaben der Produktseite — falsche Angaben dort sind schlimmer als eine Lücke.
- **Hass-Kacheln überspringbar machen.** Regel 7 lehnt leere Auswahl ab — erzwungene Selbstoffenbarung in Minute 2. Autonomie ist eine der drei SDT-Säulen, auf denen das Retentionsmodell steht. 5 Minuten.
- **Freitext-Datenschutz.** On-Device ist richtig; das Leck ist die Share-Card. Sie darf **nur** den Befundsatz rendern, nie „Wofür" oder „Kosten". Dazu `FileSaveStore` mit `.completeUntilFirstUserAuthentication` und null Netzwerkaufrufe — „diese App telefoniert nicht" ist ein belegbares Featuring-Argument.

Darf warten: VoiceOver-Rotor-Navigation der Insel, Dynamic Type über alle künftigen Screens (heute nur: keine festen Höhen, Kachelraster bricht bei AX5 auf eine Spalte), Voice Control, Lokalisierung.

---

## D) Der Spieler-Blick — drei Abbruchpunkte

**1. Sekunde 0–15: „Ich weiß nicht, was ich tun soll."** Verlangt wird ein Ziehen nach unten. Nichts zeigt „ziehen", nichts zeigt „unten". Der 40-Jährige tippt — und nichts passiert, weil es für Tippen keine Aktion gibt. Zwei Sekunden Stille lesen beide Personas als „kaputt". *Fix (< 20 Min):* Nach 2 s ohne Eingabe driftet das Licht ein Stück nach unten und federt zurück; ein Tap löst denselben Fall aus wie der Zug. Falsche Eingaben nie bestrafen.

**2. Minute 1: die Hass-Kacheln.** Direkt nach dem Belohnungsmoment ein Pflicht-Fragebogen mit „Geld reicht nicht". Für den 40-jährigen Unternehmer passt keine Kachel — es wirkt wie eine Umfrage für jemand anderen. Für den 28-Jährigen mit Nebenprojekt passt sie zu gut für Minute 2 gegenüber einer App, die er 90 Sekunden kennt. Beide denken: „Ach so, ein Quiz." *Fix (< 20 Min):* überspringbar machen und situativ statt charakterlich fragen — „Was hat dich diese Woche am meisten aufgehalten?" Niedrigere Offenbarungskosten, und der Befund braucht ohnehin genau das.

**3. Der zweite Besuch während der Sperre.** Er kommt nach zehn Minuten neugierig zurück und bekommt eine verschlossene Tür plus „Noch nicht." Genau hier wird D1 entschieden. *Fix (< 30 Min):* Wartezeit **physisch** zeigen (Sonnenstand unter dem Horizont, „Die Sonne steht in 47 Minuten") und das Wurzelfenster während der Sperre anfassbar lassen — etwas tun, das nichts kostet. Dazu die lokale Benachrichtigung am Ende der Sperre **mit seinem eigenen Absichtssatz**.

---

## E) Fehlt komplett / muss trotzdem rein

1. **Zustand → Szene-Wiederherstellung** (B). Ohne sie ist die Demo nach dem ersten Wegwischen tot.
2. **Lokale Benachrichtigung am Ende der Sperre, mit den eigenen Worten des Spielers** (~20 Min inkl. Kontext-Vorabfrage bei „Für heute reicht's"). Die Rückkehr ist derzeit eine Hoffnung, kein Mechanismus — und die Rückkehr *ist* das Produkt.
3. **„Sag es in deinen Worten" nach dem Durchbruch** (~15 Min). Nutzt `CopyCheck` und `minExplanationChars`, die ohnehin gebaut werden, schließt Stufe „Verstanden" und erzeugt den einen Satz, der das Zurückspielen später trägt.

## Was fliegen sollte

1. **Share-Card** (`ImageRenderer` + `ShareLink`, 45–60 Min). Testet heute Nacht nichts: kein Publikum, keine Landingpage, n = 1 im Simulator. Ein Screenshot des Befunds ist die Share-Card; nächste Woche in 20 Minuten nachbaubar.
2. **Validator-Regeln 1–4, 7, 8 samt Testsuite** (60–90 Min, seriell durch Opus *und* Sonnet). Sie schützen gegen ein Risiko, das heute Nacht nicht eintreten kann: drei handgeschriebene Karten, dieselben Autoren, kein CI, `werkstatt.json` liegt fertig im Repo. Heute nur Regel 5 + 6 (Attribution + Sperrliste/n-Gramm) — das IP-Gate ist das Einzige, was sich nicht nachrüsten lässt, ohne allen Content anzufassen.
3. **Audio-Tiefe.** Verstimmte Sinus mit LFO-Filter, schwebendes Detune mit Tremolo, ein sich auflösender Dur-Akkord, „timing-genau zu Haptik und Partikeln" — ein 2–3-Stunden-Loch für jeden, der `AVAudioEngine` nicht täglich benutzt. Heute: vier beim Start prozedural erzeugte PCM-Puffer (Drone + drei Transienten) per `scheduleBuffer`. Achtzig Prozent der Wirkung, weiterhin kein Lizenzmaterial.

---

## F) Go / No-Go

**Go — mit vier Bedingungen.** Der Kern ist tragfähig: eine Welt, ein Gesetz, eine Geste, ein Moment, Fortschritt nur gegen Beweis, Content als Daten, ein reiner Reducer als Vertrag. Die ADRs sind sauber, das Skelett baut.

1. **Schnittlinie mit Uhrzeiten in die Spec, bevor die erste Zeile Code fällt** (A2).
2. **Die drei Reducer-Löcher in der Spec schließen, bevor Opus den ersten Test schreibt** (Wiederherstellung, Sonnen-Release, Lauwarm kostet wirklich). Tests gegen einen lückenhaften Vertrag sind teurer als gar keine.
3. **Reduce Motion, Flackerrampe und die drei Accessibility-Elemente im Build** — nicht als Ticket. Nachrüsten kostet das Zehnfache, und es ist dein bestes Featuring-Argument.
4. **Du spielst heute Nacht den Echt-Modus** und gibst morgen früh einen echten Beweis (A3). Sonst prüfst du die Bedienung, nicht die These.

**No-Go-Auslöser um 03:00:** Steht der Durchbruchs-Moment dann nicht, wird alles unterhalb der Schnittlinie gestrichen und die Nacht endet mit dem MDP. Ein fertiges Onboarding auf einem toten Kern ist der teuerste mögliche Ausgang dieser Nacht.
