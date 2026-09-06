# LEVMI — Learning Designer & Content-Architekt

**Rolle:** Curriculum, Content-Modell, Progression, Mastery-System, IP-Sicherheit
**Datum:** 2026-09-07 · **Adressat:** Christian Simons · **Sprache:** Deutsch, du-Form
**Hinweis:** Die Code-/JSON-Blöcke sind Liefergegenstand, nicht Prosa. Der Fließtext ist bewusst kurz gehalten.

---

## 1. Urteil über das Briefing

**Stark:** Du hast erkannt, dass Wiederholung und Lehren die eigentlichen Lernhebel sind — das steht schon in den Lesehinweisen deiner Quelle drin und ist faktisch eine Spezifikation für Spaced Repetition plus Feynman-Technik. Du hast den Akkord-Gedanken (mehrere Prinzipien gleichzeitig) bewahrt statt ihn zu Einzel-Hacks zu zerlegen. Und du hast IP von Anfang an als Konstruktionsbedingung gesetzt, nicht als Rechtsabteilungs-Nachgedanke. Das sind drei Entscheidungen, an denen 90 % vergleichbarer Projekte scheitern.

**Naiv — drei Punkte, direkt:**

1. **„Platz 1 durch 3D-Grafik".** Die Charts oben werden über Retention und Zahlungsbereitschaft entschieden, nicht über Polygone. Ein Lern-Spiel gewinnt über sein Content-Modell und seine Review-Schleife. 3D, das das Prinzip nicht *verkörpert*, ist Deko — und Deko kostet dich exakt die Nacht, die du hast.
2. **„Das Buch hat eine Struktur, also hat das Spiel diese Struktur."** Das ist die weiße Information im Briefing. Eine Buchreihenfolge optimiert auf Argumentationslogik. Eine Spielreihenfolge optimiert auf die ersten zehn Minuten und die Rückkehr an Tag 2. Deine Quelle beginnt mit 24 Kapiteln Mindset — als Spielstart ist das tödlich. Wer bei „Macht Geld glücklich?" einsteigt, ist nach vier Minuten weg. **Buchtreue ist hier der Hauptdenkfehler.** Nebeneffekt: Eine eigene Reihenfolge ist zusätzlich IP-Abstand.
3. **„Komplett verstehen und visuell einmal durchgehen".** Durchgehen ist Konsum. Genau das, was deine Quelle selbst als Wertvernichtung bezeichnet. Ein Spiel, in dem man 43 Karten abhakt, produziert exakt das Verhalten, das das Buch verhindern will. Die Einheit des Fortschritts darf nicht „gesehen" sein, sondern muss „im echten Leben belegt" sein.

**Der Zielkonflikt, den du benennen musst:** „Suchtfaktor" und „im echten Leben wachsen" ziehen gegeneinander. Wenn du Session-Länge optimierst, baust du einen Spielautomaten mit Ratgeber-Skin. Die richtige Nordstern-Metrik ist **verifizierte Real-Life-Handlungen pro Woche** und **Tag-7-Rückkehr** — nicht Minuten in der App. Levmi muss den Spieler aktiv rauswerfen: die Übung passiert offline, die App ist nur Auslöser und Zeuge.

---

## 2. Strategie

### 2.1 Das Content-Modell

Zwei strikt getrennte Welten: **Canonical Content** (unveränderlich, wird als JSON ausgeliefert, versioniert) und **Player State** (veränderlich, pro Spieler, persistiert). Wer die vermischt, kann später keine Welt nachliefern, ohne Spielstände zu zerschießen. Das ist die wichtigste Architekturentscheidung in diesem Dokument.

```swift
// ══════ CANONICAL CONTENT — immutable, aus JSON dekodiert, versioniert ══════

typealias PrincipleID = String   // stabiler Slug, wird NIE umbenannt: "schnitt"
typealias WorldID     = String   // "werkstatt"

struct Principle: Codable, Identifiable, Hashable, Sendable {
    let id: PrincipleID
    let schemaVersion: Int            // 1
    let world: WorldID
    let orderInWorld: Int

    // Identität
    let title: String                 // Spielname, unser Wording
    let subtitle: String              // 2–4 Wörter für die Karte
    let core: String                  // Ein-Satz-Kern, ≤ 140 Zeichen, eigene Worte
    let expandedCore: String          // 3–5 Sätze: warum das stimmt

    // Sinnlich / 3D
    let metaphor: Metaphor

    // Lernpfad — je ein Feld pro Mastery-Stufe
    let recognition: [RecognitionQuestion]   // ≥ 3  → Stufe „Erkannt"
    let explainPrompt: String                // Feynman → Stufe „Verstanden"
    let drill: Drill                         // ≤ 10 Min → Stufe „Angewendet"
    let selfCheck: SelfCheck                 // binäres Kriterium für den Drill
    let antiPattern: AntiPattern             // typischer Denkfehler / Gegenteil
    let teachTask: TeachTask                 // → Stufe „Gelehrt"

    // Graph
    let prerequisites: [PrincipleID]         // hart: dort mindestens „Angewendet"
    let synergies: [Synergy]                 // der Akkord
    let tensions: [PrincipleID]              // scheinbare Widersprüche, bewusst gezeigt

    // Meta
    let difficulty: Int                      // 1…5
    let estimatedMinutes: Int
    let lifeDomains: [LifeDomain]            // .zeit .geld .menschen .energie .klarheit
    let attribution: Attribution
    let tags: [String]
}

struct Metaphor: Codable, Hashable, Sendable {
    let imageLine: String        // ein Satz, der das Bild setzt (< 20 Wörter)
    let sceneID: String          // "scene.werkbank" — Key in die 3D-Registry
    let primaryObject: String    // was der Spieler tatsächlich anfasst
    let interaction: Interaction // .kippen .drehen .schneiden .stapeln .oeffnen .ziehen
    let successState: String     // wie die Szene aussieht, wenn es klickt
    enum Interaction: String, Codable, Sendable {
        case kippen, drehen, schneiden, stapeln, oeffnen, ziehen
    }
}

struct RecognitionQuestion: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let situation: String        // Mini-Szene aus dem echten Leben, 1–2 Sätze
    let prompt: String
    let options: [Option]        // GENAU 3, GENAU 1 korrekt
    struct Option: Codable, Hashable, Sendable {
        let id: String
        let text: String
        let isCorrect: Bool
        let fallacyID: String?   // Pflicht bei falschen: benannter Denkfehler
        let feedback: String     // ≤ 200 Zeichen
    }
}

struct Drill: Codable, Hashable, Sendable {
    let id: String
    let title: String
    let instruction: String      // imperativ, konkret, ≤ 3 Sätze
    let durationMinutes: Int     // ≤ 10, hart validiert
    let inputKind: InputKind     // .text .liste(min:) .zahl .foto .stimme
    let minEvidenceChars: Int
    let windowHours: Int         // Zeitfenster, in dem der Log zählt
    enum InputKind: Codable, Hashable, Sendable {
        case text, zahl, foto, stimme
        case liste(min: Int)
    }
}

struct SelfCheck: Codable, Hashable, Sendable {
    let question: String         // binär beantwortbar
    let passCriteria: [String]   // maschinell prüfbar, wo möglich
}

struct AntiPattern: Codable, Hashable, Sendable {
    let id: String               // "fleiss-illusion" — global eindeutig, kreuzt Gesetze
    let name: String
    let tellTale: String         // der Satz, den man sich selbst sagen hört
    let counterMove: String
}

struct TeachTask: Codable, Hashable, Sendable {
    let prompt: String
    let maxSeconds: Int          // 60
    let requiredElements: [String]  // ["eigenes Beispiel", "eine Zahl", "keine Fachwörter"]
}

struct Synergy: Codable, Hashable, Sendable {
    let partner: PrincipleID
    let chordName: String        // "Klarer Tag"
    let effect: String
    let bonus: Double            // 1.25 — Spielökonomie
}

struct Attribution: Codable, Hashable, Sendable {
    let originName: String       // "Vilfredo Pareto", "Derek Sivers", "Gemeingut"
    let originKind: Kind         // .person .tradition .gemeingut .haus
    let originYear: Int?
    let note: String             // ein Satz, eigene Worte, KEIN Zitat
    let furtherReading: String?  // frei zugängliche Quelle
    enum Kind: String, Codable, Sendable { case person, tradition, gemeingut, haus }
}

// ══════ PLAYER STATE — mutabel, persistiert, migrierbar ══════

enum MasteryStage: Int, Codable, CaseIterable, Comparable, Sendable {
    case unseen = 0, recognized = 1, understood = 2, applied = 3, retained = 4, taught = 5
    static func < (a: Self, b: Self) -> Bool { a.rawValue < b.rawValue }
}

struct PrincipleProgress: Codable, Identifiable, Sendable {
    let id: PrincipleID
    var stage: MasteryStage
    var stageEnteredAt: Date

    // Belege
    var attempts: [RecognitionAttempt]
    var explanation: Explanation?     // eigene Worte
    var drillLogs: [DrillLog]         // ≥ 1 für „Angewendet"
    var teachArtifact: TeachArtifact?

    // Wiederholung (SM-2-lite, Upgrade-Pfad FSRS)
    var stability: Double             // Tage
    var ease: Double                  // 1.3 … 2.8, Start 2.5
    var dueAt: Date?
    var reviewCount: Int
    var lapses: Int

    // Verfall & Personalisierung
    var lastReviewedAt: Date?
    var demotedFrom: MasteryStage?
    var fallacyHits: [String: Int]    // Denkfehler-ID → Häufigkeit (Spielerprofil!)
    var ownExample: String?           // wird in künftige Drills eingespeist
}
```

**Drei Felder, die den Unterschied machen und die du nicht wegkürzen darfst:**

- **`fallacyID` an jeder falschen Antwort.** Falsche Optionen sind kein Zufallsrauschen, sondern benannte Denkfehler mit globaler ID. Damit weiß das System nach zwei Wochen: „Du fällst systematisch auf die Fleiß-Illusion rein" — quer über alle Gesetze. Das ist der Punkt, an dem aus einer Quiz-App ein Spiegel wird. Kostet in der Datenstruktur nichts und ist später nicht nachrüstbar, ohne allen Content anzufassen.
- **`ownExample`.** Das eigene Beispiel des Spielers wird gespeichert und in spätere Reviews eingesetzt. Generation Effect plus emotionale Bindung, ein Feld.
- **`attribution`.** Ohne dieses Feld ist die Pipeline für fremde Welten (Naval, Hormozi, Coaches) tot, und dein IP-Schutz ist Behauptung statt Struktur.

### 2.2 Die Kurskarte

Ich ordne die 43 Prinzipien nach zwei Achsen: **Sofort-Nutzen (Hell-Yeah)** und **kognitive Voraussetzung**. Wahrnehmungs-Werkzeuge zuerst, Identitätsarbeit später. Begründung: Filter und Diagnose liefern innerhalb von Minuten ein spürbares Ergebnis und brauchen kein Vertrauen; Glaubenssatz- und Purpose-Arbeit liefert langsam und braucht viel Vertrauen. Wer mit Purpose startet, verliert den Spieler, bevor der Purpose sitzt.

**Das Warum wird nicht gelehrt, es wird gespielt** — als Charaktererstellung im Onboarding (siehe 4.2). Damit ist „Ziel hinter dem Ziel" ab Sekunde 20 präsent, ohne den Tag-1-Lernpfad zu beschweren.

**Fünf Welten, 44 Karten** (die Engpass-Logik zerfällt spielmechanisch in zwei verschiedene Züge — Engstelle finden vs. Quelle finden — deshalb 44 Karten aus 43 Prinzipien):

| Welt | Thema | Karten | Prinzipien (Nr. aus `_43-gesetze.md`) |
|---|---|---|---|
| 1 **Die Werkstatt** | Sehen & Schneiden | 10 | 14, 8, 41a, 22, 20, 41b, 5, 30, 40, 11 |
| 2 **Der Kompass** | Richtung & Warum | 9 | 1, 35, 10, 12, 2, 17, 18, 36, 43 |
| 3 **Der Motor** | Kraft & Ausdauer | 8 | 21, 16, 23, 13, 38, 4, 6, 24 |
| 4 **Die Werkbank** | Handwerk & Wirkung | 8 | 26, 25, 3, 9, 7, 19, 34, 15 |
| 5 **Die Resonanz** | Andere Menschen | 9 | 27, 28, 29, 31, 32, 33, 37, 39, 42 |

**Welt 1 in Spielreihenfolge** (Schwierigkeit in Klammern, ein Wow-Ausschlag bei #7 gegen den Mitte-Durchhänger):

| # | Spielname | Prinzip | Diff | Warum hier |
|---|---|---|---|---|
| 1 | Der Schnitt | Hell-Yeah-or-No | 1 | Höchster Sofort-Nutzen, null Vorwissen, heute messbar |
| 2 | Die Ein-Prozent-Spur | Pareto rekursiv | 1 | 80/20 kennen alle — 1/51 überrascht. Überraschung = teilbar |
| 3 | Die Engstelle | Engpass | 2 | Macht aus Chaos eine einzige Frage |
| 4 | Der Dehnungs-Effekt | Parkinson | 1 | Jeder erkennt sich sofort wieder, leichte Runde nach der ersten Anstrengung |
| 5 | Die Strömung | Anstrengungs-Diagnose | 2 | Erlaubt Aufhören ohne Scham — hoher emotionaler Payoff |
| 6 | Die Dreckschleuder | Ursachen-Suche | 3 | Baut auf Engstelle auf |
| 7 | Der weiße Wert | Verborgene Annahmen | 3 | Der Wow-Moment der Welt |
| 8 | Die falsche Frage | Frage-Reframe | 2 | Nutzt die Einsicht aus #7 operativ |
| 9 | Der nächste Stein | Umsetzungs-Lücke | 1 | Leichte Runde, erzeugt Handlung |
| 10 | Der Gutschein | Wert = Geld | 3 | Finale, öffnet Welt 2 (Richtung/Warum) |

**Tag 1 = die ersten drei.** Nicht willkürlich: Schnitt (*was fliegt raus?*), Spur (*was rein?*), Engstelle (*was zuerst?*) bilden nach ca. 12 Minuten ein geschlossenes, funktionierendes Betriebssystem für den eigenen Tag. Das ist gleichzeitig der Beweis für den Akkord-Gedanken — drei Gesetze klingen zusammen und heißen im Spiel **„Klarer Tag"**. Und: alle drei haben eine saubere, buchunabhängige Herkunft (Sivers, Pareto/Juran, Goldratt) — genau dort, wo später Screenshots und App-Store-Previews entstehen, ist das IP-Risiko damit praktisch null.

**Abhängigkeiten:** hart nur dort, wo es logisch zwingt (Dreckschleuder setzt Engstelle voraus; Gutschein setzt Ein-Prozent-Spur voraus). Alles andere ist frei wählbar. Zwangsreihenfolgen über 3 Stufen hinaus töten Autonomie und damit Motivation.

**Akkorde (Auszug):** „Klarer Tag" (Schnitt + Spur + Engstelle) · „Ehrliche Bilanz" (Dehnungs-Effekt + Gutschein + Investition) · „Ruhige Hand" (Strömung + Wurzelphase + Blinder Schwimmer). Ein Akkord ist aktiv, solange alle Beteiligten auf Stufe ≥ Angewendet und frisch sind. Aktive Akkorde geben eine kombinierte Wochenaufgabe und verändern Licht und Klang der Welt. **Das ist der Grund, warum Wiederholung sich nicht wie Hausaufgabe anfühlt: du hältst einen Akkord, du machst keine Karteikarten.**

### 2.3 IP-sichere Umformulierung — die ersten 10

Regel für alles Folgende: kein Buchtext, keine Anekdoten aus der Quelle, keine Zitate, kein Autorenname, kein Buchtitel. Eigene Namen, eigene Bilder, eigene Sätze. Herkunft wird genannt, wo sie bekannt ist.

**1 · Der Schnitt** — *Herkunft: Derek Sivers, 2009*
(b) Wenn eine Sache dich nicht sofort begeistert, ist sie ein Nein — das Lauwarme frisst die Zeit, die das Große bräuchte.
(c) Eine Werkbank mit drei Ablagen: eine glühend, eine kalt, und dazwischen eine graue, die sichtbar überquillt und den halben Raum vollstellt. Der Spieler kippt die graue aus; der Raum wird hell und begehbar.
(d) *7 Min:* Schreib die fünf offenen Dinge auf, die seit über zwei Wochen in deinem Kopf hängen. Markiere jedes mit GLÜHEND oder GRAU. Sag heute zu genau einem GRAUEN ab — eine Nachricht, ein Satz, keine Begründung.
(e) *„Ein Bekannter fragt dich für ein Projekt an. Du denkst: ‚Interessant, könnte man mal machen.'"*
 A) Ein Ja mit Bedenkzeit — du prüfst es in Ruhe. ✗ *Prüf-Falle*
 B) **Ein Nein.** ✓
 C) Ein Vielleicht — du entscheidest, wenn du mehr Infos hast. ✗ *Infos-fehlen-Illusion*

**2 · Die Ein-Prozent-Spur** — *Herkunft: Vilfredo Pareto (Verteilung), Joseph Juran (Anwendung)*
(b) Wenn 20 % deiner Handlungen 80 % bringen, dann bringt 1 % über die Hälfte — dein Job ist, dieses eine Prozent zu finden, nicht mehr zu tun.
(c) Ein dunkler Hangar voller identischer Kisten. Der Spieler dreht einen Ring; ein Lichtkegel schrumpft von der ganzen Halle auf zwanzig Kisten, dann vier, dann eine — und nur diese leuchtet von innen.
(d) *8 Min:* Liste alles, was du letzte Woche gearbeitet hast. Streiche, bis drei Zeilen übrig sind. Streiche weiter, bis eine übrig ist. Trag diese eine für morgen als ersten Termin ein.
(e) *„Du hast 40 Kunden. Sechs davon machen 80 % des Umsatzes. Der Umsatz stagniert."*
 A) Die 34 schwachen reaktivieren — da liegt ungenutztes Potenzial. ✗ *Lücken-Reflex*
 B) **Herausfinden, was die sechs gemeinsam haben, und gezielt mehr davon holen.** ✓
 C) Die Kundenzahl verdoppeln. ✗ *Mehr-vom-Gleichen*

**3 · Die Engstelle** — *Herkunft: Eliyahu M. Goldratt, Theory of Constraints, 1984*
(b) Jedes System hat genau eine Stelle, die den Durchsatz begrenzt — alles, was du woanders verbesserst, ändert nichts.
(c) Eine gläserne Rohrleitung quer durch den Raum, Kugeln fließen hindurch. Eine Stelle ist verengt. Der Spieler kann überall am Rohr drehen — die Kugeln laufen erst weiter, wenn er genau diese eine Verengung aufzieht.
(d) *6 Min:* Nenne dein wichtigstes Vorhaben. Schreib die Kette der Schritte auf, die passieren müssen. Markiere den, der seit über einer Woche steht. Formuliere eine Aktion ≤ 30 Min, die genau ihn löst — und mach sie heute.
(e) *„Design ist fertig. Entwicklung wartet seit acht Tagen auf deine Freigabe. Marketing arbeitet vor."*
 A) Mehr Entwickler einplanen. ✗ *Kapazitäts-Reflex*
 B) Marketing bremsen, damit alle im Takt sind. ✗ *Gleichschritt-Irrtum*
 C) **Heute die Freigabe geben, alles andere danach.** ✓

**4 · Der Dehnungs-Effekt** — *Herkunft: Cyril Northcote Parkinson, 1955*
(b) Arbeit und Ausgaben füllen genau den Raum, den du ihnen gibst — also musst du den Raum kleiner machen, nicht dich schneller.
(c) Ein Behälter mit einer weichen, leuchtenden Masse, die sich an jede Form anpasst. Der Spieler zieht die Wände zusammen: die Masse wird nicht gequetscht, sie wird dichter und leuchtet heller.
(d) *5 Min:* Nimm die Aufgabe, an der du dich gerade festbeißt. Stell einen Timer auf die Hälfte der eingeplanten Zeit. Arbeite bis er klingelt, dann hör auf und schau, was fertig ist.
(e) *„Du bekommst 20 % mehr Gehalt. Nach vier Monaten ist am Monatsende wieder nichts übrig."*
 A) Die Inflation hat es aufgefressen. ✗ *Außen-Ursache*
 B) Die Erhöhung war zu klein — bei 40 % wäre etwas übrig. ✗ *Schwellen-Illusion*
 C) **Die Ausgaben sind mitgewachsen, weil nichts sie begrenzt hat.** ✓

**5 · Die Strömung** — *Herkunft: Gemeingut (actio = reactio, Newton 1687, aufs Handeln übertragen)*
(b) Dauerhafte Anstrengung ist kein Beweis für Fleiß, sondern die Rechnung dafür, dass du gegen etwas arbeitest.
(c) Zwei Rolltreppen nebeneinander. Der Spieler rennt auf der abwärtsfahrenden und kommt nicht vom Fleck. Ein Schritt zur Seite — und er wird getragen, ohne schneller zu gehen.
(d) *7 Min:* Nenne die Aufgabe, die sich seit Wochen zäh anfühlt. Schreib drei Kräfte auf, die dagegendrücken (Markt, Zielgruppe, Werkzeug, deine eigene Lust). Entscheide genau eins: Richtung ändern, Werkzeug wechseln oder stoppen. Schreib die Entscheidung hin.
(e) *„Seit sechs Monaten kämpfst du um jeden Abschluss. Du brauchst fünf Gespräche mehr als Kollegen."*
 A) Härter arbeiten, mehr Gespräche führen. ✗ *Fleiß-Illusion*
 B) **Ein Signal: Zielgruppe, Angebot oder Zeitpunkt stehen quer — prüfen, bevor du weiterpaddelst.** ✓
 C) Verkaufen ist eben hart, das ist normal. ✗ *Normalisierung*

**6 · Die Dreckschleuder** — *Herkunft: Ursachenanalyse aus der Fertigung (Kaoru Ishikawa, Toyota „Fünfmal warum")*
(b) Wiederkehrender Ärger hat fast immer eine einzige Quelle — solange du wischst, statt sie zu finden, wischst du für immer.
(c) Ein Raum mit dreckigem Boden. Der Spieler bekommt einen Wischer; der Dreck ist sofort wieder da. Erst wenn er der Spur zur offenen Luke folgt und sie schließt, bleibt der Boden sauber.
(d) *8 Min:* Schreib die drei Probleme auf, die diesen Monat mehr als einmal auftraten. Suche, was sie gemeinsam haben: dieselbe Person, derselbe Prozessschritt, dieselbe Uhrzeit, dasselbe Werkzeug. Notiere die eine Quelle und einen Zug, der sie schließt.
(e) *„Drei Kunden beschweren sich diesen Monat über späte Rückmeldungen — jedes Mal von einer anderen Person aus deinem Team."*
 A) Alle drei einzeln ermahnen. ✗ *Symptom-Wischen*
 B) **Den gemeinsamen Auslöser suchen: wo Anfragen ankommen und wer sie zuteilt.** ✓
 C) Eine Regel einführen: Antwort binnen 24 Stunden. ✗ *Regel-Pflaster*

**7 · Der weiße Wert** — *Herkunft: Gemeingut der Kognitionspsychologie (verborgene Annahmen)*
(b) In jeder Rechnung, die du im Kopf machst, steckt mindestens eine Zahl, die du nie eingegeben hast — und sie entscheidet mit.
(c) Eine schwebende Tabelle im Raum. Alle Zellen sichtbar, das Ergebnis stimmt trotzdem nicht. Der Spieler kippt die Beleuchtung — plötzlich werden weiße Zellen sichtbar, die die ganze Zeit mitgerechnet haben.
(d) *9 Min:* Nimm eine Entscheidung, die du vor dir herschiebst. Schreib: „Das geht nicht, weil …" Danach fünfmal hintereinander: „Und das stimmt, weil …" Der fünfte Satz ist meist eine Annahme, die du nie geprüft hast. Markiere sie.
(e) *„Jemand sagt: ‚Ich kann keine Immobilie kaufen, ich habe kein Eigenkapital.' Der Satz klingt logisch."*
 A) Er hat recht — ohne Eigenkapital geht es nicht. ✗ *Regel-ohne-Prüfung*
 B) Er ist zu ängstlich, das ist ein Mut-Problem. ✗ *Charakter-Zuschreibung*
 C) **Eine unausgesprochene Annahme rechnet mit — etwa, dass Eigenkapital nur eigenes Geld sein darf.** ✓

**8 · Die falsche Frage** — *Herkunft: „Cui bono" (römische Rechtstradition, Cassius) + Inversion (Carl Gustav Jacob Jacobi)*
(b) Ein Problem, das sich nicht lösen lässt, ist meistens eine Frage, die falsch gestellt ist.
(c) Eine massive Tür ohne Schloss. Der Spieler probiert Schlüssel, nichts passt. Er dreht einen Ring an der Wand — und die Wand daneben wird zur Öffnung. Die Tür war nie der Weg.
(d) *6 Min:* Nimm dein hartnäckigstes Problem und schreib die Frage auf, die du dir dazu stellst. Formuliere drei andere zum selben Sachverhalt: „Wem nützt der aktuelle Zustand?", „Was müsste wahr sein, damit …?", „Was will ich als Ergebnis?" Wähle die, bei der du sofort einen nächsten Schritt siehst.
(e) *„Du fragst dich seit Monaten: ‚Wie werde ich disziplinierter?'"*
 A) „Welche App hilft mir dranzubleiben?" ✗ *Werkzeug-vor-Ziel*
 B) **„Habe ich hier überhaupt ein Ziel, das ich wirklich will — und was zieht mich weg?"** ✓
 C) „Warum bin ich so schwach?" ✗ *Selbst-Etikett*

**9 · Der nächste Stein** — *Herkunft: Gemeingut; operative Fassung u. a. bei David Allen („die nächste physische Handlung")*
(b) Zwischen einer Idee und ihrer Umsetzung liegt immer ein konkreter erster Schritt — wer ihn nicht benennt, hat keinen Plan, sondern einen Wunsch.
(c) Eine Schlucht, das Ziel auf der anderen Seite, kein Sprung möglich. Der Spieler legt einen einzigen Stein ins Leere — er trägt, und erst dann wird der nächste sichtbar. Nie der ganze Weg, immer nur der nächste.
(d) *5 Min:* Nimm die Idee, die du am längsten mit dir herumträgst. Schreib eine Handlung auf, die höchstens 30 Minuten dauert, heute möglich ist und von außen sichtbar wäre. Mach sie jetzt oder trag sie mit Uhrzeit ein.
(e) *„‚Ich will nächstes Jahr mit dem Investieren anfangen.' Was fehlt diesem Satz?"*
 A) Ein Betrag und eine Renditeerwartung. ✗ *Zahlen-vor-Handlung*
 B) Mehr Wissen — erst lernen, dann handeln. ✗ *Vorbereitungs-Endlosschleife*
 C) **Eine sichtbare Handlung, die heute möglich ist.** ✓

**10 · Der Gutschein** — *Herkunft: Gemeingut der Ökonomie (Geld als Anspruch auf gelieferten Wert)*
(b) Geld ist der Beleg dafür, dass jemand anders einen Wert von dir bekommen hat — zu wenig Geld ist deshalb zuerst eine Wertfrage, keine Marketingfrage.
(c) Ein Marktplatz mit einer großen Waage. Links legt der Spieler, was er liefert; rechts fällt automatisch, was er bekommt. Er kann rechts ziehen, so viel er will — nichts bewegt sich. Erst wenn er links auflädt, steigt die andere Seite.
(d) *10 Min:* Schreib in einem Satz ohne Adjektive auf, was jemand tatsächlich bekommt, wenn er dich bezahlt. Frag heute eine Person, die dich bezahlt hat, was der wertvollste Teil daran war. Notiere die Antwort wörtlich.
(e) *„Ein Produkt verkauft sich nicht. Der Gründer sagt: ‚Wir brauchen mehr Reichweite.'"*
 A) Marketing-Budget erhöhen. ✗ *Lautstärke-Reflex*
 B) **Prüfen, ob das Produkt ein Problem löst, das der Zielgruppe wirklich weh tut.** ✓
 C) Den Preis senken. ✗ *Preis-Reflex*

### 2.4 Mastery- und Wiederholungs-System

**Sechs Zustände** (`unseen` ist der Startzustand, nicht sichtbar):

| Von → Nach | Bedingung |
|---|---|
| unseen → **Erkannt** | 3 von 4 Erkennungsfragen richtig, davon ≥ 2 verschiedene Situationen, ohne Hinweis |
| Erkannt → **Verstanden** | Eigene Erklärung ≥ 200 Zeichen oder ≥ 40 s Audio. **Hart geprüft:** keine zusammenhängende Wortfolge ≥ 7 Wörter aus `core`/`expandedCore`. Abschreiben zählt nicht |
| Verstanden → **Angewendet** | 1 Drill-Log, der den `selfCheck` besteht, **und** Zeitstempel ≥ 60 Min nach „Verstanden" (in der Praxis: am Folgetag). Durchklicken ist strukturell unmöglich |
| Angewendet → **Wiederholt** | 2 erfolgreiche Reviews mit Abstand ≥ 7 Tagen (Stabilität ≥ 21 Tage) **und** ein zweiter Drill-Log aus einem anderen Lebensbereich (`lifeDomain` ≠ erster) — erzwungener Far Transfer |
| Wiederholt → **Gelehrt** | `teachArtifact`: 60-Sekunden-Erklärung mit eigenem Beispiel, die die Elementprüfung besteht |

**Intervalle (SM-2-lite, bewusst kein FSRS heute Nacht):** Basisintervalle 1 / 3 / 7 / 16 / 35 Tage, danach `intervall × ease`. Bewertung pro Review: 0 (falsch) / 1 (mit Mühe) / 2 (sofort). `ease` startet bei 2,5; −0,2 bei 1; −0,4 bei 0 (Minimum 1,3); +0,05 bei 2 (Maximum 2,8). Bei 0: Intervall zurück auf 1 Tag, `lapses += 1`, `stability × 0,5`. FSRS ist der Upgrade-Pfad, sobald ≥ 200 Nutzer Reviewdaten geliefert haben — vorher ist es Overengineering ohne Datengrundlage.

**Verfall — und zwar sichtbar.** Erinnerbarkeit `R = exp(−Δt / stability)`. Fällig ab R < 0,9. **Rückstufung** bei R < 0,5 über mehr als 14 Tage: eine Stufe zurück, nie unter „Erkannt". Das Entscheidende ist nicht die Formel, sondern die Darstellung: **das zugehörige Objekt in der 3D-Welt verliert Licht und Farbe.** Der Spieler sieht beim Betreten der Welt in zwei Sekunden, was verblasst. Kein Badge, keine Zahl, kein Push mit schlechtem Gewissen — eine Welt, die dunkler wird, wenn man sie nicht pflegt. Das ist der Sog, den du willst, und er ist ehrlich, weil er der Realität entspricht.

**Ein Review ist nie nur eine Karte:** eine Erkennungsfrage in neuer Situation, und bei jedem dritten Mal die Frage „Wo ist dir das diese Woche begegnet?" mit Eintrag in `ownExample`. Das ist der Unterschied zwischen Auswendiglernen und Transfer.

**„Lehren" im Spiel — drei aufsteigende Formen:**
1. **Eigenes Beispiel anlegen** (niedrigste Schwelle, in-app, wird Teil deiner Karte und taucht in künftigen Reviews auf).
2. **Die 60-Sekunden-Erklärung** (Audio oder ≤ 600 Zeichen). Prompt: „Erklär es jemandem, der es noch nie gehört hat — ohne die Wörter aus der App." Geprüft auf: kein Wortfolgen-Overlap mit dem Karten-Text, mindestens ein konkretes eigenes Beispiel (Zahl, Name, Ort).
3. **Weitergeben** (optional): die eigene Erklärung als Karte an eine echte Person. Der Empfänger kann eine Erkennungsfrage beantworten; das Ergebnis kommt als „Dein Schüler hat's verstanden" zurück. Das ist der virale Loop und gleichzeitig Status-Lift — der Sharer wirkt klug, nicht bedürftig.

**Wichtig und nicht verhandelbar:** Stufe „Gelehrt" wird über Form 2 erreicht. Form 3 gibt einen Meister-Marker und den langsamsten Verfall (90 Tage), ist aber **nie** Voraussetzung für Fortschritt. Fortschritt hinter Teilen zu sperren ist ein Dark Pattern, es fliegt im App-Store-Review auf und es zerstört genau das Vertrauen, von dem dieses Produkt lebt.

### 2.5 Erweiterbarkeit über das Buch hinaus

**Dateilayout** (Content ist Daten, nie Code — ab Zeile 1):

```
Content/
  catalog.json                 # schemaVersion, Welten-Reihenfolge, Prüfsumme
  worlds/
    werkstatt/
      world.json               # Titel, Farbe, Reihenfolge, Freischalt-Regel
      schnitt.json
      ein-prozent-spur.json
      engstelle.json
  fallacies.json               # globale Denkfehler-Registry (Cross-Welt)
Authoring/
  werkstatt/schnitt.md         # YAML-Front-Matter + Markdown, coach-tauglich
Tools/
  contentkit validate          # Build-Gate, bricht den Build bei Verstoß
```

Autoren (Coaches, du, ein Fachredakteur) schreiben Markdown mit Front-Matter. `contentkit` konvertiert nach JSON und validiert. **Der Validator ist der eigentliche Qualitäts- und IP-Schutz und gleichzeitig das dankbarste TDD-Ziel des ganzen Projekts** — reine Funktionen, keine UI, sofort testbar.

**Validierungsregeln (alle als Test formulierbar):**
1. `core` ≤ 140 Zeichen, ein Satz, kein Semikolon.
2. Genau 3 Optionen pro Erkennungsfrage, genau 1 korrekt, jede falsche mit existierender `fallacyID`.
3. `drill.durationMinutes` ≤ 10; `selfCheck.question` binär beantwortbar.
4. Alle `prerequisites` existieren; der Graph ist zyklenfrei (topologische Sortierung muss gelingen).
5. `attribution.originName` gesetzt; bei `.gemeingut` ist `note` Pflicht.
6. **IP-Gate:** keine zusammenhängende Wortfolge ≥ 7 Wörter deckungsgleich mit irgendeiner Datei im lokalen Quellkorpus; keine Begriffe aus der Sperrliste (Buchtitel und dessen Markenbestandteile, Autorenname, markierte Anekdoten — die Liste liegt in `Tools/blocklist.txt`, nicht im Content). Läuft im CI, blockiert den Merge.
7. Jede Welt hat auf Position 1–2 mindestens ein Prinzip mit `difficulty == 1`.
8. Jede Karte hat ≥ 3 Erkennungsfragen und genau 1 Drill.

**Neue Welten** entstehen als reine Content-Lieferung, ohne Code-Änderung: Naval Ravikant (Hebel, spezifisches Wissen, Urteilsvermögen) · Alex Hormozi (Angebot, Volumen, Engpass) · Stoa (Dichotomie der Kontrolle, negative Visualisierung, Amor Fati — gemeinfrei, ideal für eine kostenlose Einstiegswelt) · **Haus-Welt** mit deinen eigenen Learnings (`originKind: .haus`) · Coach-Welten von Partnern gegen Umsatzbeteiligung.

**Aufnahmekriterien für eine neue Welt — alle fünf, sonst kein Release:** 8–10 Karten · jede mit Drill ≤ 10 Min · jede mit ≥ 3 Erkennungsfragen · Validator komplett grün · fünf Testspieler schaffen Tag 1 ohne Rückfrage. **Attribution im Produkt:** eine „Herkunft"-Karte pro Prinzip mit Person/Tradition, Jahr und einem Satz in eigenen Worten. Nie ein Zitat, nie ein Buchcover, nie eine Übernahme fremder Formulierung. Das ist nicht nur Rechtsschutz — „das kommt von Goldratt, 1984" ist teilbares Status-Material.

---

## 3. Nicht verhandelbar

1. **Content ist Daten, nicht Code.** Ab der ersten Zeile. Sonst ist jede neue Welt ein App-Release, und die ganze Erweiterbarkeits-Vision ist tot.
2. **Kein Fortschritt ohne Beleg aus dem echten Leben.** „Angewendet" ist nur über einen Drill-Log außerhalb der Session erreichbar. Wer diese Regel aufweicht, baut Duolingo für Ratgeber-Sprüche.
3. **Der Spieler formuliert in eigenen Worten, bevor er weiterkommt.** Generation Effect und IP-Schutz in einer Mechanik. Der Abschreibe-Check ist nicht optional.
4. **Wiederholung ist eingebaut, Verfall ist sichtbar.** Nicht als Statistik, sondern als Licht in der Welt.
5. **Jede Karte hat eine benannte Herkunft und null Zeilen fremden Ausdruck.** Der Validator blockt den Build. Kein Mensch entscheidet das im Einzelfall.

---

## 4. Der PoC heute Nacht

### 4.1 Scope

**Drin:** Welt 1, Karten 1–3 mit vollständigem Content (unten) · Erkennen-Schleife mit je 3 Fragen und benannten Denkfehlern · ein Eigene-Worte-Feld mit Abschreibe-Prüfung · ein Drill mit lokaler Erinnerung am Folgetag · Mastery-Zustandsmaschine mit Persistenz · **eine** 3D-Szene (die Werkbank für „Der Schnitt") mit echter Interaktion: graue Ablage kippen, Raum wird hell · Onboarding mit 2 Fragen vor dem Spiel.

**Raus:** FSRS · Teilen und Lehren · Audio · alle anderen 40 Karten · drei verschiedene Welten · Accounts · Cloud-Sync · Bestenlisten · Sound-Design.

**Brutal:** Eine Szene richtig schlägt drei Szenen halb. Wenn morgen früh der Raum wirklich hell wird, wenn du die graue Ablage kippst, bist du geflasht. Drei mittelmäßige Szenen flashen niemanden — und sie kosten die Zeit, die die Zustandsmaschine braucht.

### 4.2 Onboarding in Spielsprache

Zwei Fragen **vor** dem ersten Spielzug (max. 15 Sekunden, kein Scrollen), drei **nach** dem ersten Erfolg — dann sind sie verdient und die Abbruchquote bricht nicht ein.

**Vorher:**
1. „Stell dir vor, morgen früh ist das eine Ding gelöst, das dich gerade festhält. **Was ist das Ding?**" → `currentDrag`, freier Text, ≤ 120 Zeichen
2. „Und wenn es gelöst ist — **was machst du als Erstes?**" → `firstMove`

**Nach dem ersten Schnitt** (der Spieler hat gerade seine graue Ablage gekippt):
3. „Du hast gerade Platz gemacht. **Wofür?**" → `northStar`
4. „Und wenn du das hast — **was wäre dann anders in deinem Leben?**" → `goalBehindGoal` ← *das ist das Ziel hinter dem Ziel, und es wird nach einem Erfolg gefragt, nicht vor einem Fremden*
5. „Wonach fühlt sich das an?" — Auswahl: frei · sicher · lebendig · respektiert · gebraucht · stolz → `feelingTarget`

**Der Auszahlungsmoment:** Die Antwort auf 4 wird in der 3D-Welt auf ein Objekt geschrieben, das dauerhaft am Horizont steht — **dein Nordstern**. Jede Review-Session zeigt ihn eine halbe Sekunde. Und jeder Drill-Text setzt ab Welt 2 die eigenen Worte des Spielers ein. Das ist der Unterschied zwischen einer App, die dich kennt, und einer, die dich abfragt.

### 4.3 Vollständiger Content der drei Karten

```json
{
  "schemaVersion": 1,
  "world": "werkstatt",
  "principles": [
    {
      "id": "schnitt",
      "schemaVersion": 1,
      "world": "werkstatt",
      "orderInWorld": 1,
      "title": "Der Schnitt",
      "subtitle": "Glühend oder weg",
      "core": "Wenn eine Sache dich nicht sofort begeistert, ist sie ein Nein.",
      "expandedCore": "Die meisten Entscheidungen fallen nicht zwischen Ja und Nein, sondern versanden im Lauwarmen. Lauwarmes fühlt sich nach Sorgfalt an, ist aber Lagerhaltung: es belegt Kopf, Kalender und Energie, ohne je zu einem Ergebnis zu führen. Wer das Graue konsequent wegkippt, gewinnt nicht Zeit für mehr Graues, sondern Platz für das eine Glühende.",
      "metaphor": {
        "imageLine": "Drei Ablagen: eine glüht, eine ist kalt, die graue dazwischen stellt den ganzen Raum voll.",
        "sceneID": "scene.werkbank",
        "primaryObject": "Die graue Ablage",
        "interaction": "kippen",
        "successState": "Die graue Ablage ist leer, der Raum wird hell und begehbar, die glühende Ablage rückt in die Mitte."
      },
      "recognition": [
        {
          "id": "schnitt.q1",
          "situation": "Ein Bekannter fragt dich für ein Projekt an. Du denkst: „Interessant, könnte man mal machen.“",
          "prompt": "Was ist das?",
          "options": [
            { "id": "a", "text": "Ein Ja mit Bedenkzeit — du prüfst es in Ruhe.", "isCorrect": false, "fallacyID": "pruef-falle", "feedback": "Prüfen fühlt sich sorgfältig an. Tatsächlich verlängerst du nur die Lagerzeit." },
            { "id": "b", "text": "Ein Nein.", "isCorrect": true, "fallacyID": null, "feedback": "Richtig. Was dich nicht sofort packt, packt dich auch in drei Wochen nicht." },
            { "id": "c", "text": "Ein Vielleicht — du entscheidest, wenn du mehr Infos hast.", "isCorrect": false, "fallacyID": "infos-fehlen-illusion", "feedback": "Die fehlende Info ist selten das Problem. Die fehlende Begeisterung ist die Antwort." }
          ]
        },
        {
          "id": "schnitt.q2",
          "situation": "Du hast elf offene Vorhaben. Zwei begeistern dich, neun sind „eigentlich sinnvoll“.",
          "prompt": "Was bringt dich am schnellsten weiter?",
          "options": [
            { "id": "a", "text": "Die neun sinnvollen in eine gute Reihenfolge bringen.", "isCorrect": false, "fallacyID": "sortier-trost", "feedback": "Sortieren ist keine Entscheidung. Elf sortierte Vorhaben sind immer noch elf." },
            { "id": "b", "text": "Die neun beenden oder abgeben — heute, sichtbar.", "isCorrect": true, "fallacyID": null, "feedback": "Ja. Der Gewinn liegt im Wegnehmen, nicht im Ordnen." },
            { "id": "c", "text": "Jedem Vorhaben pro Woche eine Stunde geben.", "isCorrect": false, "fallacyID": "gerechtigkeits-falle", "feedback": "Gleiche Verteilung ist fair zu Aufgaben und unfair zu dir." }
          ]
        },
        {
          "id": "schnitt.q3",
          "situation": "Du sagst zu einer Anfrage ab. Dein erster Impuls: eine lange Begründung schreiben.",
          "prompt": "Was ist besser?",
          "options": [
            { "id": "a", "text": "Ausführlich begründen, damit niemand gekränkt ist.", "isCorrect": false, "fallacyID": "begruendungs-schuld", "feedback": "Eine lange Begründung lädt zur Verhandlung ein — und macht aus dem Nein wieder ein Vielleicht." },
            { "id": "b", "text": "Ein Satz, freundlich, ohne Tür.", "isCorrect": true, "fallacyID": null, "feedback": "Genau. Klar und kurz ist respektvoller als vage und lang." },
            { "id": "c", "text": "Gar nicht antworten, das erledigt sich.", "isCorrect": false, "fallacyID": "aussitz-reflex", "feedback": "Nicht antworten ist kein Nein — die Sache bleibt in deinem Kopf." }
          ]
        }
      ],
      "explainPrompt": "Erklär in eigenen Worten, warum lauwarme Sachen teurer sind als abgelehnte. Nimm ein Beispiel aus deiner letzten Woche.",
      "drill": {
        "id": "schnitt.drill",
        "title": "Kipp die graue Ablage",
        "instruction": "Schreib die fünf offenen Dinge auf, die seit über zwei Wochen in deinem Kopf hängen. Markiere jedes mit GLÜHEND oder GRAU. Sag heute zu genau einem GRAUEN ab — eine Nachricht, ein Satz, keine Begründung.",
        "durationMinutes": 7,
        "inputKind": { "liste": { "min": 5 } },
        "minEvidenceChars": 80,
        "windowHours": 24
      },
      "selfCheck": {
        "question": "Hast du die Absage wirklich abgeschickt?",
        "passCriteria": [
          "Die Liste enthält mindestens 5 Einträge.",
          "Mindestens ein Eintrag ist als GRAU markiert.",
          "Die Absage ist als abgeschickt bestätigt (Name oder Kanal genannt)."
        ]
      },
      "antiPattern": {
        "id": "lauwarm-lager",
        "name": "Das Lauwarm-Lager",
        "tellTale": "„Ich lass es erst mal offen, man weiß ja nie.“",
        "counterMove": "Offen lassen ist eine Entscheidung — für Lagerkosten. Entscheide heute, in einem Satz."
      },
      "teachTask": {
        "prompt": "Erklär jemandem in 60 Sekunden, warum ein schnelles Nein freundlicher ist als ein langes Vielleicht.",
        "maxSeconds": 60,
        "requiredElements": ["eigenes Beispiel", "keine Fachwörter"]
      },
      "prerequisites": [],
      "synergies": [
        { "partner": "ein-prozent-spur", "chordName": "Klarer Tag", "effect": "Erst wegnehmen, dann das eine Prozent finden — sonst suchst du im vollen Raum.", "bonus": 1.25 },
        { "partner": "engstelle", "chordName": "Klarer Tag", "effect": "Weniger Vorhaben heißt: die Engstelle ist überhaupt sichtbar.", "bonus": 1.25 }
      ],
      "tensions": ["blinder-schwimmer"],
      "difficulty": 1,
      "estimatedMinutes": 9,
      "lifeDomains": ["zeit", "klarheit"],
      "attribution": {
        "originName": "Derek Sivers",
        "originKind": "person",
        "originYear": 2009,
        "note": "Sivers hat die Entweder-begeistert-oder-nein-Regel als Entscheidungsfilter bekannt gemacht; das Grundmuster ist älter und findet sich in jeder Portfolio-Logik.",
        "furtherReading": "sive.rs"
      },
      "tags": ["entscheiden", "fokus", "zeit"]
    },

    {
      "id": "ein-prozent-spur",
      "schemaVersion": 1,
      "world": "werkstatt",
      "orderInWorld": 2,
      "title": "Die Ein-Prozent-Spur",
      "subtitle": "Eine Kiste leuchtet",
      "core": "Wenn 20 Prozent deiner Handlungen 80 Prozent bringen, bringt 1 Prozent über die Hälfte.",
      "expandedCore": "Die 80/20-Verteilung ist kein Spruch, sondern eine Verteilung, die sich selbst wiederholt: Wende sie auf ihre eigene Spitze an, und aus 20/80 wird 4/64 und dann 1/51. Praktisch heißt das: In fast jeder Liste, die du führst, steckt eine einzige Zeile, die mehr wiegt als der ganze Rest. Die Arbeit besteht nicht darin, mehr zu tun, sondern diese Zeile zu finden und alles andere leiser zu drehen.",
      "metaphor": {
        "imageLine": "Ein dunkler Hangar voller gleicher Kisten — der Lichtkegel schrumpft, bis nur eine von innen leuchtet.",
        "sceneID": "scene.hangar",
        "primaryObject": "Der Lichtring",
        "interaction": "drehen",
        "successState": "Der Kegel steht auf einer einzigen Kiste, die von innen glüht; der Rest der Halle bleibt dunkel und ruhig."
      },
      "recognition": [
        {
          "id": "spur.q1",
          "situation": "Du hast 40 Kunden. Sechs machen 80 Prozent des Umsatzes. Der Umsatz stagniert.",
          "prompt": "Was ist der stärkste nächste Zug?",
          "options": [
            { "id": "a", "text": "Die 34 schwachen reaktivieren — da liegt ungenutztes Potenzial.", "isCorrect": false, "fallacyID": "luecken-reflex", "feedback": "Der Blick geht automatisch zum Schwachen. Der Hebel liegt beim Starken." },
            { "id": "b", "text": "Herausfinden, was die sechs gemeinsam haben, und gezielt mehr davon holen.", "isCorrect": true, "fallacyID": null, "feedback": "Richtig. Die Spitze ist deine Bauanleitung für die nächste Runde." },
            { "id": "c", "text": "Die Kundenzahl verdoppeln.", "isCorrect": false, "fallacyID": "mehr-vom-gleichen", "feedback": "Verdoppelt auch die anstrengenden Kunden. Doppelt so viel Lärm für dasselbe Ergebnis." }
          ]
        },
        {
          "id": "spur.q2",
          "situation": "Deine Woche hat 30 erledigte Aufgaben. Am Freitag fühlt sich nichts nach Fortschritt an.",
          "prompt": "Was fehlt?",
          "options": [
            { "id": "a", "text": "Mehr Struktur — ein besseres Aufgabensystem.", "isCorrect": false, "fallacyID": "system-flucht", "feedback": "Ein besseres System verwaltet 30 unwichtige Aufgaben schöner." },
            { "id": "b", "text": "Eine ehrliche Antwort, welche eine Aufgabe das Ergebnis bewegt hätte.", "isCorrect": true, "fallacyID": null, "feedback": "Ja. Fortschritt entsteht an einer Stelle, nicht auf dreißig." },
            { "id": "c", "text": "Mehr Zeit — 30 waren zu wenig.", "isCorrect": false, "fallacyID": "mengen-irrtum", "feedback": "Mehr von dem, was nicht wirkt, wirkt nicht mehr." }
          ]
        },
        {
          "id": "spur.q3",
          "situation": "Zwei deiner zwölf Inhalte bringen fast alle Anfragen.",
          "prompt": "Was tust du als Nächstes?",
          "options": [
            { "id": "a", "text": "Die zehn schwachen überarbeiten.", "isCorrect": false, "fallacyID": "luecken-reflex", "feedback": "Reparieren ist teuer und ändert die Verteilung nicht." },
            { "id": "b", "text": "Die zwei starken in fünf Varianten wiederverwenden und breiter ausspielen.", "isCorrect": true, "fallacyID": null, "feedback": "Genau. Das Starke verdoppeln ist billiger als das Schwache heilen." },
            { "id": "c", "text": "Zwölf neue produzieren, um mehr Daten zu haben.", "isCorrect": false, "fallacyID": "mengen-irrtum", "feedback": "Du hast die Daten schon. Sie zeigen auf zwei." }
          ]
        }
      ],
      "explainPrompt": "Erklär in eigenen Worten, warum „mehr tun“ und „das Richtige tun“ fast nie dasselbe sind. Nimm eine Zahl aus deinem eigenen Alltag.",
      "drill": {
        "id": "spur.drill",
        "title": "Streich bis eins übrig ist",
        "instruction": "Liste alles, was du letzte Woche gearbeitet hast. Streiche, bis drei Zeilen übrig sind. Streiche weiter, bis eine übrig ist. Trag diese eine für morgen als ersten Termin ein.",
        "durationMinutes": 8,
        "inputKind": { "liste": { "min": 6 } },
        "minEvidenceChars": 60,
        "windowHours": 24
      },
      "selfCheck": {
        "question": "Steht genau eine Zeile als morgiger Ersttermin fest?",
        "passCriteria": [
          "Die Ausgangsliste hat mindestens 6 Einträge.",
          "Genau ein Eintrag ist als Ein-Prozent-Spur markiert.",
          "Für diesen Eintrag ist eine Uhrzeit oder ein Tag hinterlegt."
        ]
      },
      "antiPattern": {
        "id": "luecken-reflex",
        "name": "Der Lücken-Reflex",
        "tellTale": "„Da ist noch Potenzial, das müssen wir heben.“",
        "counterMove": "Frag zuerst, was schon funktioniert, und verdopple das. Lücken sind fast nie der günstigste Hebel."
      },
      "teachTask": {
        "prompt": "Erklär jemandem in 60 Sekunden, warum aus 20/80 ein 1/51 wird — und was das für seinen Montag heißt.",
        "maxSeconds": 60,
        "requiredElements": ["eigenes Beispiel", "eine Zahl"]
      },
      "prerequisites": [],
      "synergies": [
        { "partner": "schnitt", "chordName": "Klarer Tag", "effect": "Erst wegnehmen, dann fokussieren.", "bonus": 1.25 },
        { "partner": "engstelle", "chordName": "Klarer Tag", "effect": "Die Ein-Prozent-Spur sagt wo, die Engstelle sagt wann zuerst.", "bonus": 1.25 }
      ],
      "tensions": [],
      "difficulty": 1,
      "estimatedMinutes": 10,
      "lifeDomains": ["zeit", "geld", "klarheit"],
      "attribution": {
        "originName": "Vilfredo Pareto / Joseph Juran",
        "originKind": "person",
        "originYear": 1896,
        "note": "Pareto beschrieb die ungleiche Verteilung, Juran machte daraus Jahrzehnte später ein Arbeitsprinzip; die rekursive Zuspitzung folgt direkt aus der Verteilung.",
        "furtherReading": null
      },
      "tags": ["fokus", "hebel", "prioritaet"]
    },

    {
      "id": "engstelle",
      "schemaVersion": 1,
      "world": "werkstatt",
      "orderInWorld": 3,
      "title": "Die Engstelle",
      "subtitle": "Eine Stelle entscheidet",
      "core": "Jedes System hat eine Stelle, die den Durchsatz begrenzt — alles andere zu verbessern ändert nichts.",
      "expandedCore": "Ein System ist nie so schnell wie sein Durchschnitt, sondern so schnell wie seine engste Stelle. Verbesserungen vor der Engstelle erzeugen Stau, Verbesserungen dahinter erzeugen Leerlauf — beides fühlt sich nach Arbeit an und bewegt nichts. Deshalb ist die einzige sinnvolle Frage an einem vollen Tag nicht „Was ist wichtig?“, sondern „Wo steht es gerade?“",
      "metaphor": {
        "imageLine": "Ein Glasrohr voller Kugeln, eine einzige Stelle ist verengt — überall drehen hilft nicht.",
        "sceneID": "scene.rohr",
        "primaryObject": "Der Verengungsring",
        "interaction": "oeffnen",
        "successState": "Die Kugeln laufen gleichmäßig durch, das ganze Rohr leuchtet in einer Farbe."
      },
      "recognition": [
        {
          "id": "engstelle.q1",
          "situation": "Design ist fertig. Entwicklung wartet seit acht Tagen auf deine Freigabe. Marketing arbeitet vor.",
          "prompt": "Was tust du?",
          "options": [
            { "id": "a", "text": "Mehr Entwickler einplanen, damit es schneller geht.", "isCorrect": false, "fallacyID": "kapazitaets-reflex", "feedback": "Mehr Kapazität hinter der Engstelle erzeugt nur mehr Wartende." },
            { "id": "b", "text": "Marketing bremsen, damit alle im Takt sind.", "isCorrect": false, "fallacyID": "gleichschritt-irrtum", "feedback": "Gleichmäßige Auslastung ist kein Ziel. Durchsatz ist das Ziel." },
            { "id": "c", "text": "Heute die Freigabe geben, alles andere danach.", "isCorrect": true, "fallacyID": null, "feedback": "Richtig. Du bist die Engstelle — und das ist die beste Nachricht des Tages." }
          ]
        },
        {
          "id": "engstelle.q2",
          "situation": "Dein Verkauf läuft: viele Anfragen, viele Angebote. Aber kaum Abschlüsse, weil die Verträge wochenlang bei der Prüfung liegen.",
          "prompt": "Wohin gehört dein nächster Euro?",
          "options": [
            { "id": "a", "text": "In mehr Werbung — mehr Anfragen, mehr Abschlüsse.", "isCorrect": false, "fallacyID": "kapazitaets-reflex", "feedback": "Mehr Anfragen verlängern nur die Warteschlange vor der Prüfung." },
            { "id": "b", "text": "In die Vertragsprüfung, bis sie nicht mehr der Flaschenhals ist.", "isCorrect": true, "fallacyID": null, "feedback": "Ja. Der Euro an der Engstelle ist der einzige, der den Durchsatz erhöht." },
            { "id": "c", "text": "In ein besseres Angebot, damit schneller entschieden wird.", "isCorrect": false, "fallacyID": "falsche-baustelle", "feedback": "Das Angebot ist nicht das Problem — die Kunden wollen ja schon." }
          ]
        },
        {
          "id": "engstelle.q3",
          "situation": "Du hast die Engstelle beseitigt. Alles läuft. Nach drei Wochen stockt es wieder — an anderer Stelle.",
          "prompt": "Was bedeutet das?",
          "options": [
            { "id": "a", "text": "Die erste Lösung war falsch.", "isCorrect": false, "fallacyID": "rueckfall-fehlschluss", "feedback": "Nein — sie hat funktioniert. Deshalb ist die Engstelle gewandert." },
            { "id": "b", "text": "Normal: Die Engstelle wandert, sobald sie gelöst ist. Neu suchen.", "isCorrect": true, "fallacyID": null, "feedback": "Genau. Engstelle finden ist keine Aufgabe, sondern eine Gewohnheit." },
            { "id": "c", "text": "Das System ist grundsätzlich überlastet, es braucht mehr Leute.", "isCorrect": false, "fallacyID": "kapazitaets-reflex", "feedback": "Erst die neue Engstelle bestimmen. Sonst kaufst du Kapazität an der falschen Stelle." }
          ]
        }
      ],
      "explainPrompt": "Erklär in eigenen Worten, warum eine Verbesserung an der falschen Stelle nicht nur nutzlos, sondern schädlich sein kann. Nimm ein Beispiel aus deiner Arbeit.",
      "drill": {
        "id": "engstelle.drill",
        "title": "Finde die Verengung",
        "instruction": "Nenne dein wichtigstes Vorhaben. Schreib die Kette der Schritte auf, die passieren müssen. Markiere den Schritt, der seit über einer Woche steht. Formuliere eine Aktion von höchstens 30 Minuten, die genau ihn löst — und mach sie heute.",
        "durationMinutes": 6,
        "inputKind": { "liste": { "min": 4 } },
        "minEvidenceChars": 70,
        "windowHours": 24
      },
      "selfCheck": {
        "question": "Ist die 30-Minuten-Aktion erledigt oder mit Uhrzeit eingetragen?",
        "passCriteria": [
          "Die Schrittkette hat mindestens 4 Einträge.",
          "Genau ein Schritt ist als Engstelle markiert.",
          "Die zugehörige Aktion ist als erledigt oder terminiert bestätigt."
        ]
      },
      "antiPattern": {
        "id": "kapazitaets-reflex",
        "name": "Der Kapazitäts-Reflex",
        "tellTale": "„Wir brauchen einfach mehr Leute / mehr Budget / mehr Zeit.“",
        "counterMove": "Frag zuerst, wo es steht. Kapazität hilft nur genau an der Engstelle — überall sonst erzeugt sie Stau oder Leerlauf."
      },
      "teachTask": {
        "prompt": "Erklär jemandem in 60 Sekunden, warum sein Team nicht schneller wird, wenn alle schneller arbeiten.",
        "maxSeconds": 60,
        "requiredElements": ["eigenes Beispiel", "keine Fachwörter"]
      },
      "prerequisites": [],
      "synergies": [
        { "partner": "schnitt", "chordName": "Klarer Tag", "effect": "Weniger Vorhaben macht die Engstelle überhaupt sichtbar.", "bonus": 1.25 },
        { "partner": "ein-prozent-spur", "chordName": "Klarer Tag", "effect": "Spur sagt wo der Hebel ist, Engstelle sagt was zuerst dran ist.", "bonus": 1.25 }
      ],
      "tensions": [],
      "difficulty": 2,
      "estimatedMinutes": 8,
      "lifeDomains": ["zeit", "klarheit", "menschen"],
      "attribution": {
        "originName": "Eliyahu M. Goldratt",
        "originKind": "person",
        "originYear": 1984,
        "note": "Goldratt formulierte die Engpass-Theorie für Fabriken; sie gilt unverändert für Teams, Projekte und einzelne Tage.",
        "furtherReading": null
      },
      "tags": ["prioritaet", "durchsatz", "diagnose"]
    }
  ]
}
```

**Akkord-Definition für den PoC:** Sind alle drei Karten auf Stufe „Angewendet" und frisch, wird der Akkord **„Klarer Tag"** aktiv. Die Werkstatt wechselt sichtbar die Beleuchtung, und der Spieler bekommt eine einzige Wochenaufgabe: *„Nimm morgen früh drei Minuten: kipp eine graue Sache, benenne deine eine Spur, löse die Engstelle. Dann fang an."* Das ist der Beweis für den Mehrklang, in einer Mechanik, in einer Nacht baubar.

---

## 5. Top-5-Risiken

| # | Risiko | Warum es real ist | Gegenmaßnahme |
|---|---|---|---|
| 1 | **Content wird als Code eingebaut** — heute Nacht „nur schnell" hartcodiert | Unter Zeitdruck ist das Struct mit `let title = "Der Schnitt"` zehn Minuten schneller. Danach ist jede Welt ein Release | JSON-Datei plus `Codable`-Dekoder ab dem ersten Commit; ein Test lädt `catalog.json` und prüft die Anzahl. Kosten heute Nacht: ca. 20 Minuten |
| 2 | **„Angewendet" wird zur Klick-Stufe** — Spieler hakt alles in einer Sitzung ab | Der Reiz, die Zeitsperre für die Demo rauszunehmen, ist morgen früh maximal | Zeitsperre gehört in die Domänenlogik und in einen Test (`applied` ist unerreichbar bei Δt < 60 Min). Demo-Modus als separates Flag, niemals als Regel-Aufweichung |
| 3 | **IP-Rutsch beim Content-Nachziehen** — Karte 11 bis 44 werden schnell aus den Quelldateien abgeschrieben | Zeitdruck, Ermüdung, und die Quellsätze sind griffig | n-Gramm-Prüfung (≥ 7 Wörter) gegen das Quellkorpus als CI-Gate, das den Merge blockiert. Kein menschliches Ermessen im Einzelfall |
| 4 | **3D frisst die Nacht** — drei halbfertige Szenen statt einer fertigen | Szenen sind sichtbar und machen Spaß, Zustandsmaschinen nicht | Harte Regel: eine Szene (`scene.werkbank`). Karten 2 und 3 laufen als 2D-Karten mit der gleichen Datenstruktur. Wenn Zeit übrig ist, kommt Szene 2 — nicht vorher |
| 5 | **Metrik-Drift Richtung Suchtmaschine** — Session-Länge wird zum Erfolgsmaß | Es ist die einfachste Zahl und sie steigt am schnellsten | Ab Tag 1 nur zwei Zahlen im Dashboard: verifizierte Drill-Logs pro Woche und Tag-7-Rückkehr. Session-Länge wird nicht erhoben |

---

## 6. Offene Fragen an dich

1. **Zielgruppe Tag 1:** Baue ich für Leute wie dich (Unternehmer, Kontext vorhanden) oder für Angestellte mit Fernziel Freiheit? Das ändert jede Situation in jeder Erkennungsfrage — und es ändert, ob Welt 3 „Der Motor" mit Geld oder mit Zeit öffnet.
2. **Tägliches Zeitbudget des Spielers:** 5, 10 oder 20 Minuten? Davon hängt ab, ob eine Karte pro Sitzung durchläuft oder über zwei Tage gestreckt wird — und damit die gesamte Freischalt-Kurve.
3. **Eigene Beispiele: Text oder Sprache?** Sprache ist die viel bessere Lehr-Mechanik und der stärkere Feynman-Test, kostet aber Aufnahme-Rechte, Speicher und ein Datenschutz-Kapitel. Entscheidung nötig, bevor der Player-State fixiert wird.
4. **Willst du „43" als Produktversprechen?** Meine klare Empfehlung: nein. Die Zahl ist eine Rekonstruktion aus fremder Quelle, sie verweist erkennbar auf das Buch (IP-Nähe) und sie friert deine Roadmap ein. Verkauf Welten, nicht eine Zahl.
5. **Kommt jemals fremder Content rein** (Coaches, Partner) oder bleibt alles Haus-Content? Falls Partner-Content geplant ist, brauchen `attribution` und die Validator-Pipeline heute schon Priorität — nachrüsten heißt, allen Content einmal anzufassen.
