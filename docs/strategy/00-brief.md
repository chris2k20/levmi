# LEVMI — Briefing für die Strategie-Runde

**Datum:** 2026-09-07 · **Auftraggeber:** Christian Simons (ImmoDigit GmbH, Gründer) · **Architekt/Planer:** Claude Fable 5.1
**Sprache aller Dokumente:** Deutsch, du-Form.

## 1. Die Vision (Originalton Christian, verdichtet)

- Ein **3D-Spiel für iOS** namens **Levmi**, das „total umwerfend“ ist. Ambition: Platz 1 im App Store (iOS), der Hit der nächsten Gamescom, „so atemberaubend, dass Tim Cook staunen würde“, „so durch die Decke wie GTA“.
- **Zweck:** Persönlichkeitsentwicklung, interaktiv. Der Spieler soll die Prinzipien/Gesetze aus Alex Fischers Buch „Reicher als die Geissens“ (RADG) **komplett verstehen, verinnerlichen und visuell einmal durchgehen** — Kapitel-/Prinzipienstruktur als Spielstruktur.
- **Psychologie:** Das Spiel soll das Belohnungszentrum im Hirn so ansprechen („Endorphine“, „Suchtfaktor“), dass man immer weiterspielen will — **aber so, dass man dadurch im echten Leben wächst**. Wiederholbar, mit Gesetzmäßigkeiten.
- **Nicht auf das Buch beschränkt:** RADG ist der Einstieg. Danach weitere Quellen/Prinzipien. Rechte von Alex Fischer dürfen nicht verletzt werden — die Prinzipien sollen aber „richtig geil hervorgehen“.
- **Bedienung:** total intuitiv, „geflasht von Minute 1“.

## 2. Harte Rahmenbedingungen

| Thema | Vorgabe |
|---|---|
| Plattform | iOS, nativ (Swift 6 / SwiftUI, 3D via SceneKit, RealityKit oder Metal — Entscheidung offen, Expertenvotum erwünscht). Kein Unity/Unreal für den PoC (keine Lizenz-/Install-Zeit). |
| Toolchain | Xcode 26.6, iOS-26.5-Simulator (iPhone 17), Swift 6.3, XcodeGen vorhanden. Christians iPhone 15 Pro Max läuft iOS 27.0 (Xcode 27 nicht installiert — Risiko für Device-Deploy). |
| Zeit | **Heute Nacht.** Morgen früh muss ein Proof of Concept in Xcode bauen und im Simulator (idealerweise auf dem Gerät) laufen. |
| Methode | Test-Driven Development. Opus-5-Agenten = Chefs, schreiben die Tests. Sonnet-5-Agenten schreiben den Code. Fable 5.1 = Architekt. |
| IP | **Kein Buchtext, keine Zitate, kein Buchtitel, kein Autorenname, keine „Geissens“ im Produkt.** Prinzipien/Ideen sind frei (Pareto, Parkinson, „Hell yeah or no“ stammt von Derek Sivers, Bambus-Parabel ist Gemeingut). Eigene Namen, eigene Formulierungen, eigene Metaphern. Fischers spezifische Anekdoten (Kindbettfieber-Story, Hendrik-Klöters-Story, „PIN in den Schredder“) sind Ausdruck, nicht Idee — nicht übernehmen. |

## 3. Quellmaterial (nur lesen, nichts ändern)

- Struktur des Buchs: `/Users/A1A7D65/stage2/cs-main/kb/radg/INDEX.md`
- Die 43 synthetisierten Gesetze (zentrale Datei!): `/Users/A1A7D65/stage2/cs-main/kb/radg/_43-gesetze.md`
- Einzelkapitel (Pareto-Zusammenfassungen): `/Users/A1A7D65/stage2/cs-main/kb/radg/t1-k*.md` (Teil 1 Mindset, 23 Kapitel), `t2-k*.md` (Teil 2 Werkzeuge, 20 Kapitel), `t3-k*.md` (Teil 3 Geldmaschine, 23 Kapitel)
- Lesehinweise des Autors selbst (Warnung: Buch muss durchgearbeitet werden, Wiederholung, Lehren als höchste Form): `/Users/A1A7D65/stage2/cs-main/kb/radg/00-warnung.md`
- Denk-Betriebssystem (wie Christian arbeitet): `/Users/A1A7D65/stage2/cs-main/kb/alex-fischer/RADG-Buch-Arbeitsprinzipien-SKILL.md`

Buch-Architektur in einem Satz: **Teil 1 Mindset (wer du sein musst) → Teil 2 Werkzeuge (wie du operativ arbeitest) → Teil 3 Geldmaschine (Anwendung auf eine Marktnische, Immobilien).** Die 43 Gesetze sollen wie ein Akkord *gleichzeitig* erklingen — kein Einzelhack.

## 4. Dein Mandat als Experte

Du bist **kein Ja-Sager**. Christian will Leute, die das schon hundertmal erfolgreich gemacht haben und die ihm Schwächen, Denkfehler und Risiken *zuerst* sagen, nicht im letzten Absatz. Eine Empfehlung, kein Optionen-Menü. Lob nur, wenn verdient und begründet. Wenn ein Teil der Vision unrealistisch ist (z. B. „GTA-Niveau in einer Nacht“, „Platz 1 durch Grafik“), sag es klar und sag, was stattdessen der Weg zu genau diesem Ziel ist.

Arbeite nach den RADG-Prinzipien selbst: Endergebnis & Warum zuerst, richtige Frage stellen, Engpass finden, Pareto, Hell-Yeah-or-No, erst testen dann skalieren, Anwenden schlägt Perfektion.

## 5. Pflicht-Output (Markdown, Deutsch, max. ~2.500 Wörter)

1. **Urteil über das Briefing** — was ist naiv, was ist stark, welche verdeckte Annahme („weiße Information“) steckt drin?
2. **Deine Strategie für dein Fachgebiet** — konkret, entscheidungsreif, mit Begründung.
3. **Nicht verhandelbar** — 3–5 Punkte, ohne die das Produkt aus deiner Sicht scheitert.
4. **Der PoC für heute Nacht** — was genau muss in einem vertikalen Schnitt drin sein, damit Christian morgen früh „geflasht“ ist UND wir etwas Belastbares lernen? Was fliegt raus?
5. **Top-5-Risiken** mit Gegenmaßnahme.
6. **Offene Fragen an Christian** (max. 5, nur solche, die die Arbeit materiell ändern würden).

Speichere dein Memo unter dem dir genannten Pfad. Gib am Ende eine Zusammenfassung von max. 12 Zeilen zurück.
