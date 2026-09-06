# LEVMI — Synthese & Entscheidungen des Architekten

**Von:** Claude Fable 5.1 (Architekt) · **An:** Christian · **Datum:** 2026-09-07, 01:20
**Grundlage:** Memos 01–05 (Game Director, Psychologe, Engine-Architekt, Growth-Lead, Learning-Designer). Wo Memo 04 (Growth) fehlt, ist es nachgetragen (siehe Abschnitt 8).

---

## 1. Wo alle fünf Köpfe unabhängig voneinander dasselbe sagen

Das ist die belastbarste Erkenntnis der Runde, weil niemand die Memos der anderen kannte:

1. **Grafik ist der Türöffner, nicht der Graben.** „GTA-Niveau" ist der falsche und ein gefährlicher Maßstab. Der richtige: Monument Valley, Journey, Alto's, Sky, Tetris Effect. Stilisieren statt simulieren.
2. **Ein Gesetz wird nie zuerst erzählt.** Reihenfolge: Erleben → Konsequenz → Benennen → Übertragen. Sonst ist es ein Quiz in 3D-Haut (die 95 % toten Serious Games).
3. **Fortschritt entsteht ausschließlich durch verifizierte Handlung im echten Leben.** Session-Länge ist eine *invertierte* Metrik. Levmi schickt den Spieler aktiv weg.
4. **Content ist Daten, nicht Code.** Prinzipien als versionierte JSON-Pakete („Welten"), Validator mit IP-Gate, Attribution pro Karte. Neue Quellen (Naval, Hormozi, Stoa, Haus-Content) sind Daten-Packs.
5. **Der Spieler schreibt eigene Sätze, die App spielt sie ihm später zurück.** Identität statt Punkte. Kein Leaderboard, kein XP.
6. **Haptik und Sound sind Kern-Feature**, nicht Polish. Sie liefern mehr Wow pro Minute als jeder Shader.
7. **SceneKit für den PoC, RealityKit in 6–12 Monaten, Domain framework-frei hinter einer Naht.**
8. **Das erste Gesetz ist „Der Schnitt" (Hell-Yeah-or-No).** Drei Köpfe (Director, Psychologe, Learning-Designer) haben es unabhängig gewählt: höchster Sofort-Nutzen, heute Abend ausführbar, IP-frei (Sivers).
9. **Gerät heute Nacht: nein.** iOS 27 vs. Xcode 26.6, 45 GB frei, kein Distribution-Zertifikat. Demo im iPhone-17-Simulator.

## 2. Die weißen Informationen im ursprünglichen Briefing (deine verdeckten Annahmen)

| Annahme | Warum sie kippt | Konsequenz |
|---|---|---|
| „Inhalt vermitteln + Spielspaß sind additiv" | Sie sind gegenläufig; jeder Lehrtext zieht Game Feel ab | Gesetze sind die Physik der Welt, nie Text zuerst |
| „Lange gespielt = Erfolg" | Für Persönlichkeitsentwicklung ist Bildschirmzeit der Gegner | Nordstern: Proof Rate, nicht Minuten |
| „Buchstruktur = Spielstruktur" | Buch optimiert Argumentation, Spiel optimiert Minute 1 und Tag 2. 24 Kapitel Mindset als Einstieg ist tödlich | Eigene Reihenfolge: Werkstatt (Sehen & Schneiden) zuerst, Kompass (Warum) als Charaktererstellung |
| „43 Gesetze = 43 Inhalte" | Es sind ~12 Mechanik-Archetypen mit 43 Skins | Lösbares System-Problem statt unlösbares Content-Problem |
| „3D ist das Differenzierungsmerkmal" | 3D ist Ausdrucksmittel; der Graben ist Transfer-Verifikation | 3D bleibt, aber weil Raum und Kamera Wachstum körperlich machen |
| „Einmal visuell durchgehen" | Durchgehen ist Konsum, und der Autor der Quelle sagt selbst: Konsum verbrennt 90 % | Wiederholung mit sichtbarem Verfall statt Abhaken |
| „43" als Produktversprechen | Rekonstruierte Zahl, IP-Nähe, friert die Roadmap ein | Wir verkaufen Welten, keine Zahl |

## 3. Konflikte zwischen den Köpfen und meine Entscheidung

### 3a. Währung: „Tage" (Director) vs. „Einsicht/Beweis" (Psychologe) vs. Mastery-Stufen (Learning-Designer)
**Entscheidung: Eine sichtbare Währung, „Tage". Sie entsteht ausschließlich aus Beweisen.**
- Im Spiel gibt es **Licht** (knappe Session-Ressource: du hast wenige Lichter, viele Knoten, das ist Pareto ohne ein Wort). Licht setzen erzeugt *Wurzeln* unter dem Nebel, keine Tage.
- **Tage** entstehen nur, wenn ein Beweis aus dem echten Leben angenommen wurde. Ein Beweis = die Sonne geht auf = die Insel wächst sichtbar = +1 Tag.
- Keine Punkte, keine Sterne, kein XP, keine Zahl außer „Tage" (und die erst ab dem ersten Beweis).
- Der Belohnungsmoment der ersten Minute ist **körperlich und visuell** (Durchbruch der Wurzel durch den Nebel), nicht numerisch. Das erfüllt Director (Moment), Psychologe (keine Zahl vor Handlung) und Learning-Designer (Angewendet nur außerhalb der Session).

### 3b. Welt: eine Insel im Nebelmeer (Director) vs. Szene pro Gesetz (Learning-Designer)
**Entscheidung: Eine persistente Welt, die Insel im Nebelmeer. Jedes Gesetz ist eine Station auf der Insel mit eigener Mikro-Mechanik.**
Die Stationen nutzen die Archetypen des Directors (Knappheit, Filter, Drossel, Kompass, Schloss, Verzögerung, Schwelle, Zähler, Wurzel, Spiegel, Kette, Leere). Die Learning-Designer-Metaphern (Werkbank, Hangar, Glasrohr) werden Stationen, keine getrennten Level. Für den PoC gibt es genau eine Station: **Der Schnitt** als Stimmgabel-Filter (drei Knoten: einer singt, einer brummt, einer flirrt lauwarm und frisst Licht).

### 3c. Rhythmus: „Nacht → Morgengrauen" (Director) vs. „Morgens Absicht, abends Beweis" (Psychologe)
**Entscheidung: Beides ist dasselbe, wenn man es richtig verdrahtet.**
- **Licht setzen = Absicht.** Du entscheidest im Spiel, welche graue Sache du heute kippst. Die Welt zeigt Wurzeln, aber nichts wächst über den Nebel.
- **Sonne hochziehen = Beweis.** Du kommst zurück, tippst in ≥ 40 Zeichen, was du getan hast, und ziehst die Sonne hoch. Erst dann bricht das Wachstum durch. Anticipation braucht die Lücke (Psychologe), der Director bekommt sein Morgengrauen.
- Beim ersten Durchlauf ist die Wurzel-Phase auf Sekunden verkürzt (Tutorial-Nacht), ab dann gilt der Kalender.

### 3d. Onboarding: „Wofür?" bei 0:58 (Director) vs. Hass-Kacheln + Umkehr (Psychologe) vs. 2 Fragen vorher, 3 nachher (Learning-Designer)
**Entscheidung: Erst spielen, dann fragen. Fragen werden nach dem ersten Erfolg gestellt, nie vor einem Fremden.**
Reihenfolge im PoC: Minute 1 reines Spiel → Durchbruch → „Was nervt dich gerade am meisten?" (6 Kacheln, Mehrfachauswahl) → Umkehr-Animation (die Kacheln drehen sich live ins Positive) → „Wofür?" (eine Zeile, Skip erlaubt; die Antwort färbt dein Licht dauerhaft) → erste Absicht (aus 3 kleinen Vorschlägen, heute machbar) → „Für heute reicht's."

### 3e. Swift-6-Strictness: `complete` im App-Target (Engine-Architekt) vs. Reibung mit SceneKit-Delegates
**Entscheidung: `complete` im Core-Package, `minimal` im App-Target.** Der Architekt nennt das selbst als Notfallventil; ich ziehe es vor, weil heute Nacht jede Stunde zählt. Render-Loop nach Muster B (Mutex, kein isolierter State).

### 3f. Zielgruppe (alle fragen danach)
**Annahme, bis du widersprichst: Beachhead = deine Community (Unternehmer, Investoren, 25–50), Deutsch zuerst, iOS zuerst.** Ton: erwachsen, direkt, kein Cartoon-Maskottchen. Wochen-Kadenz für Streaks (nicht Tage). Der Grund: Distribution, Zahlungsbereitschaft, Kontextwissen. 16–30 wäre ein anderes Produkt.

## 4. Levmi in einem Absatz

Levmi ist eine Insel im Nebelmeer, die nur aus dem wächst, was du im echten Leben getan hast. Du bist der Lichtsetzer: Du hast wenig Licht und viele Möglichkeiten. Alles, worauf du Licht legst, schlägt Wurzeln, unsichtbar unter dem Nebel. Wenn du zurückkommst und beweist, was du draußen getan hast, ziehst du die Sonne hoch, und die Insel bricht durch die Nebelkante. Jede Station der Insel ist ein Gesetz, das du nicht liest, sondern am eigenen Leib erlebst, danach in eigenen Worten benennst und dann in deinem Leben anwendest. Deine eigenen Sätze kommen Wochen später zu dir zurück. Was du nicht pflegst, verliert Licht. Was du lehrst, leuchtet am längsten. Kein Konto, keine Punkte, kein Ranking, und die App schickt dich nach fünf Minuten weg, weil das Spiel draußen stattfindet.

## 5. Annahmen, wo du noch nicht geantwortet hast (bitte morgen früh bestätigen oder kippen)

| Frage der Experten | Meine Annahme für heute Nacht |
|---|---|
| Zielgruppe | Deine Community, 25–50, Unternehmer/Investoren |
| Darf Levmi den Spieler wegschicken? Werbemodell? | Ja. Kein Werbemodell, keine Time-Spent-Ökonomie |
| Persönliche Daten (eigene Sätze) lokal oder Cloud? | PoC: nur lokal. Cloud später opt-in, DSGVO-Kapitel nötig |
| „Lehren" im Produkt? | v1: außerhalb (Share-Card später). Kein soziales Datenmodell heute |
| Erfolgskriterium nach 30 Tagen | „Der Spieler hat ≥ 12 verifizierte Handlungen ausgeführt und kann seine drei Akkord-Gesetze in eigenen Worten erklären" |
| Android in 12 Monaten? | Nein → nativ, RealityKit als Zielplattform |
| Team-ID / Bundle-ID | NVN9F2C593 (ImmoDigit GmbH) / `de.immodigit.levmi` |
| Sound | Prozedural erzeugt (kein Lizenzmaterial), ein Drone, drei Transienten |
| Eigene Beispiele: Text oder Sprache? | Text im PoC, Sprache später |
| Tages-Zeitbudget des Spielers | 5 Minuten |
| 100 GB freiräumen für Xcode 27? | Deine Entscheidung; ohne das kein Gerätetest, dauerhaft |

## 6. Der vertikale Schnitt für heute Nacht (verbindlich)

Vollständige Spezifikation in `docs/design/poc-spec.md`. Kurzform:

- **Eine Welt:** Inselfragment im Nebelmeer, Orbit-Kamera, HDR-Bloom, Fog, Spiegelwasser, Partikel.
- **Eine Station, drei Mechaniken:** Licht setzen unter Knappheit (Pareto, gefühlt) · Stimmgabel-Filter (Der Schnitt: singt/brummt/flirrt) · Wurzel → Sonne hochziehen → Durchbruch (verzögerte Auszahlung).
- **Der Beweis-Loop komplett für ein Gesetz:** Absicht → App zu → zurück → Beweis (≥ 40 Zeichen, kein Abschreiben) → Sonne → Durchbruch → +1 Tag → eigener Satz wird gespeichert und später zurückgespielt.
- **Onboarding nach dem Erfolg:** 6 Hass-Kacheln → Umkehr → „Wofür?" → Absicht → „Für heute reicht's".
- **Content als Daten:** `Content/worlds/werkstatt/*.json` mit drei Karten (Schnitt, Ein-Prozent-Spur, Engstelle), Validator mit Tests. Karten 2 und 3 laufen im PoC als Karten ohne eigene 3D-Station.
- **Haptik + prozeduraler Sound** im Build (Haptik wirkt nur auf dem Gerät).
- **Demo-Modus** als separates Flag, damit du morgen früh die 60-Minuten-Sperre und den Zeitversatz in 30 Sekunden erleben kannst, ohne dass die Regel aufgeweicht wird.

**Fliegt raus:** 40 Gesetze, Menüs, Accounts, Cloud, Shop, Sharing, Lehren, Streaks, Wochenrückblick, Spaced Repetition (Stufen 4–5), Lokalisierung, App-Store-Assets, Device-Deploy, importierte 3D-Assets, Custom-Shader.

## 7. Go/No-Go morgen früh (nicht „gefällt es dir")

1. **Dreimal-Test (Director):** Spielst du den 30-Sekunden-Loop dreimal hintereinander, ohne dass jemand dich bittet, und setzt du das Licht beim zweiten Mal anders?
2. **Beweis-Test (Psychologe):** Fühlst du nach dem Beweis „ich habe draußen etwas getan, und drinnen ist etwas gewachsen"?
3. **Text-Aus-Test (Director):** Versteht ein Fremder ohne jede Beschriftung in 60 Sekunden, was er tun soll?
4. **Hausaufgaben-Test:** Dauert der Beweis unter 45 Sekunden?

Zwei von vier bestanden = Kern lebt, wir bauen aus. Weniger = Loop tauschen, nicht polieren.

## 8. Growth-Realität (Memo 04) und was sie an den Entscheidungen ändert

Das Growth-Memo ist das unbequemste der fünf, und es ist belegt (aus deinem eigenen Repo):

- **Distribution existiert nicht.** 195 Instagram-Follower, kein dokumentierter YouTube-Kanal, keine belegte Newsletter-Größe. Deine Nutzerbasis ist eine B2B-Vertriebsbasis, keine Consumer-Launch-Rampe. Platz 1 „Overall Free DE" braucht 25.000–40.000 Downloads pro Tag [Erfahrungswert] und ist unerreichbar; Platz 1 in einer Paid-Unterkategorie (200–600/Tag) ist an einem Tag machbar, aber ein Screenshot, kein Geschäft, und darf nie als „Platz 1 App Store" kommuniziert werden (§ 5 UWG).
- **Gamescom: klares Abraten** (8.000–15.000 € plus 4–6 Personenwochen für ein Publikum, das Eskapismus sucht). Stattdessen OMR und deine eigenen Immo-/Finanzbühnen; Gamescom höchstens als Content-Dreh unter 1.500 €.
- **Apple-Featuring ist der realistische Kanal** (10.000–40.000 Downloads über eine Feature-Woche, 20–35 % Wahrscheinlichkeit bei sauberer Ausführung). Hebel: native Frameworks, Accessibility ab Tag 1, On-Device-Privacy, eine Zwei-Satz-Story, keine manipulative Monetarisierung. Genau das bauen wir ohnehin.
- **Der Engpass des ganzen Vorhabens ist ein Lizenz-/Reichweitenpartner mit ≥ 100.000 echter Reichweite.** Die naheliegendste und unangenehmste Option ist Alex Fischer selbst: Eine Lizenz löst Distribution und IP in einem Zug. Zweitbeste: ein deutscher Finanz-/Personal-Development-Creator, der eine App will, aber keine bauen kann.
- **Consumer-Subscription allein trägt nicht** (Install→Paid 2–4 %, erlaubter CAC ~1 €, realer CPI 1,50–4 €). Der eigentliche Umsatz sind **B2B-Welten für Coaches und Firmen** (249 €/Monat pro Welt), weil dort der Lizenznehmer den CAC bezahlt. Strom 1 ist immoJUMP-Aktivierung (Churn!), Strom 2 Levmi Plus (6,99 €/Monat, 49 €/Jahr, kauft Breite und Werkzeug, nie Tiefe oder Tempo).
- **„43" ist die größte unterschätzte IP-Gefahr.** Die Zahl führt direkt zur Quelle zurück. Levmi hat Welten, keine Zahl. Dazu Markenrecherche „Levmi" diese Woche (DPMA/EUIPO/TMview, Klassen 9/41/42, Klangnähe zu Levi's prüfen), keine Heil- und Finanzerfolgsversprechen (MDR, HWG, § 5 UWG, § 34f GewO), On-Device-Daten (DSGVO Art. 9).
- **Kill-Kriterien, heute aufgeschrieben:** D7 < 15 % nach Alpha → Stopp. D30 < 6 % nach Beta → Levmi wird immoJUMP-Feature statt eigenständige App.

**Konsequenzen für die Entscheidungen oben:**
1. Der PoC bekommt zusätzlich den **Befund-Moment** (ein persönlicher Engpass-Satz aus den eigenen Daten, mit „Stimmt / Stimmt nicht") und eine **Share-Card**. Ohne die testen wir morgen keine einzige Wachstumsannahme. Eingearbeitet in `docs/design/poc-spec.md`.
2. Name und Claim: **Levmi („lever me" — heb mich). Claim: „Finde deinen Hebel." App-Store-Subtitle: „Finde deinen Engpass."** Schmerz-Hook: „Du strengst dich seit Jahren an und stehst ungefähr da, wo du vor drei Jahren standest. Das ist kein Motivationsproblem. Das ist ein Engpass."
3. Zielgruppen-Entscheidung aus 3f bleibt, wird aber präzisiert: die Immo-Community ist **Labor** (50 Tester), nicht Markt. Markt sind deutschsprachige „Umsetzer" 28–48. Reichweite muss geliehen werden.
4. Levmi wird ab Alpha als **Aktivierungswerkzeug für immoJUMP** gerahmt, nicht als Zweitgeschäft. Jede Levmi-Woche muss eine Aktivierungs- oder Churn-Zahl im Kerngeschäft bewegen, sonst Pause. Das ist Gesetz 41 auf dein Unternehmen angewandt.
5. Die Frage, die alles bestimmt und die nur du beantworten kannst: **Sprichst du mit Alex Fischer über eine Lizenz?**

## 9. Was ich heute Nacht trotzdem baue, obwohl Growth „Werkzeug statt Spiel" sagt

Die Empfehlungen „Diagnose-Instrument mit außergewöhnlicher Oberfläche" (Growth) und „Insel im Nebelmeer" (Director) widersprechen sich nicht: Die Insel **ist** das Diagnose-Instrument. Der Befund entsteht aus dem, was du auf der Insel tust. Ich baue den vertikalen Schnitt wie in Abschnitt 6, plus Befund und Share-Card, und nehme Gamescom und „Platz 1 Overall" als Ambition aus dem Vokabular. Das Ziel heißt ab jetzt: **Apple-Featuring DE, ein Lizenzpartner, D7 ≥ 25 % in der Alpha.**
