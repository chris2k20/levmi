# ADR 02 · Fortschritt nur durch verifizierte Handlung; eine sichtbare Währung „Tage"

**Status:** entschieden (2026-09-07) · **Quelle:** Memo 02 Psychologe, Memo 01 Director, Memo 05 Learning-Designer, Memo 04 Growth („Zwei-Schlüssel-Regel")

## Kontext
„Suchtfaktor" und „im echten Leben wachsen" ziehen gegeneinander, solange Bindung an Bildschirmzeit hängt. Alle fünf Memos fordern unabhängig, dass Fortschritt ausschließlich aus Handlung außerhalb der App entsteht. Der Director will genau eine Währung („Tage"), der Psychologe verbietet Punkte/Zahlen vor der ersten Handlung, der Learning-Designer setzt „Angewendet" nur mit Zeitsperre.

## Entscheidung
- **Licht** ist die knappe Session-Ressource im Spiel (erzeugt Wurzeln, keine Tage).
- **Tage** sind die einzige sichtbare Währung und entstehen nur aus angenommenen Beweisen (≥ 40 Zeichen, konkret, keine Abschrift). Ein Beweis = Sonne geht auf = Insel wächst = +1 Tag. Höchstens ein Tag pro Prinzip pro 24 h.
- Keine Punkte, kein XP, keine Sterne, kein Ranking, kein Leaderboard. Keine Streak-Bestrafung, kein Verlust-Countdown. Streaks (später) in Wochen mit ≥ 3 Beweis-Tagen.
- Der Beweis ist frühestens ab `readyAt` möglich: 10 Minuten nach der Absicht, bei Absichten nach 20 Uhr ab 06:00 des Folgetags (gekoppelt an die Absicht, nicht an das Schließen der App). Das ersetzt die ursprünglich diskutierte 60-Minuten-Sperre: Sie bestrafte genau den Nutzer, der gehandelt hat (Nutzerbefragung, Red Team). Der Demo-Modus verkürzt nur Zeitkonstanten (30 s), schaltet keine Regel ab.
- Lauwarme Entscheidungen kosten wirklich: Ein auf einen lauwarmen Knoten gesetztes Licht ist weg (kein Ersatz); der Durchbruch fällt kleiner aus. Ohne Preis gäbe es nur einen möglichen Ausgang und keine Diagnose (Red Team A1).
- Die App schickt den Spieler nach der Session aktiv weg („Für heute reicht's").

## Konsequenzen
Session-Länge ist eine invertierte Metrik (2–5 Min gut, > 8 Min Warnsignal). Nordstern: Proof Rate ≥ 30 % in Woche 1; D7 < 8 % = Loop kaputt. Kein Pay-to-Progress, nie (siehe ADR 05).
