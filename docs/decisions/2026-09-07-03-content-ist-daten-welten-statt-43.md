# ADR 03 · Content ist Daten (JSON-Welten mit Validator und IP-Gate); keine Zahl „43" im Produkt

**Status:** entschieden (2026-09-07) · **Quelle:** Memo 05 Learning-Designer, Memo 01 Director, Memo 04 Growth

## Kontext
Die Quelle (RADG) liefert 43 rekonstruierte Prinzipien in Buchreihenfolge (24 Kapitel Mindset zuerst). Buchreihenfolge optimiert Argumentation, nicht Minute 1 und Tag 2. Die Zahl 43 führt für jeden zur Quelle zurück (IP-Nähe). Später sollen weitere Quellen (Naval, Hormozi, Stoa, Haus-Content, Coaches) als Welten dazukommen.

## Entscheidung
- Jedes Prinzip ist ein Datensatz (`Principle`, Schema aus Memo 05) in `Packages/LevmiCore/Resources/worlds/<welt>.json`; nie Swift-Literale. Neue Welt = neue JSON, kein Code.
- Eigene Reihenfolge: **Welt 1 „Die Werkstatt" (Sehen & Schneiden)** zuerst; Tag 1 = Der Schnitt, Die Ein-Prozent-Spur, Die Engstelle (Akkord „Klarer Tag"). Kompass/Warum wird als Charaktererstellung gespielt, nicht gelehrt.
- Validator als Build-Gate (Regeln: `core` ≤ 140 Zeichen, genau 3 Optionen/1 korrekt, jede falsche mit `fallacyID`, Drill ≤ 10 Min, Graph zyklenfrei, Attribution Pflicht, Sperrliste: Buchtitel, Autorname, „Geissens", n-Gramm-Prüfung ≥ 7 Wörter gegen den Quellkorpus im CI).
- **Nie eine Zahl nennen.** Levmi hat Welten. Kein Titel, kein Name, keine Anekdote, kein Zitat aus der Quelle im Produkt, im Marketing oder in App-Store-Keywords.

## Konsequenzen
Der Engpass des Produkts ist Content, nicht Code: eine Karte komplett als Referenz-Vertikale, dann die nächsten. Attribution pro Karte (Sivers, Pareto/Juran, Goldratt …) ist gleichzeitig Rechtsschutz und teilbares Status-Material. Lizenzgespräch mit dem Autor der Quelle bleibt die Option, die IP und Distribution zugleich löst (Christians Entscheidung).
