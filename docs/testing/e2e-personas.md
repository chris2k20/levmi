# End-to-End-Test mit neuen Nutzern (Simulator, Personas)

**Zweck:** Nach der Integration spielen fünf Agenten als *neue* Nutzer die App im iPhone-17-Simulator wirklich durch (Tippen, Halten, Ziehen, Tippen von Text), ohne Vorwissen über die Spec. Sie protokollieren, was sie sehen, wo sie stocken, und bewerten. Anschließend werden die Befunde priorisiert und eingebaut („ausbauen, verbessern").

## Werkzeug

Die Agenten steuern den Simulator über die iOS-Simulator-Werkzeuge (`screenshot`, `tap`, `swipe`, `touch_path` für Halten/Ziehen, `text`). Koordinaten in Punkten; das iPhone 17 hat 402 × 874 Punkte. Vor jedem Durchlauf: App per Debug-Knopf „Neu" zurücksetzen; **Demo-Modus an**, damit die Sperre 30 Sekunden dauert. Jeder Agent bekommt nur die Persona und die Aufgabe „Probier die App aus, sag laut, was du denkst", nicht die Spec.

## Personas (neu, nicht die aus der Papier-Befragung)

1. **Nadine, 38, Physiotherapeutin mit eigener Praxis** — pragmatisch, wenig Zeit, Handy in der Pause.
2. **Kemal, 31, Vertriebler im Außendienst** — will Ergebnisse, mag Wettbewerb, tippt schnell.
3. **Ute, 57, Buchhändlerin, will ihr Geschäft übergeben** — geduldig, misstraut Technik, liest jeden Text.
4. **Ben, 26, Junior-Entwickler mit Startup-Idee** — probiert alles aus, wischt schnell, sucht Bugs.
5. **Claudia, 45, Führungskraft im Mittelstand, Coach-Ausbildung** — kennt Persönlichkeitsentwicklung, prüft Substanz und Datenschutz.

## Protokoll pro Persona

| Schritt | Was aufschreiben |
|---|---|
| Erste 10 Sekunden | Was sehe ich, was mache ich als Erstes, wie lange bis zur ersten Geste? |
| Licht setzen | Habe ich verstanden, dass ich halten muss? Welchen Knoten und warum? |
| Sonne | Habe ich verstanden, dass ich ziehen soll? |
| Durchbruch | Ein Wort für das Gefühl. |
| Kacheln / Umkehr / Warum | Übersprungen? Was getippt? Fühlte es sich sicher an („Bleibt auf deinem Gerät")? |
| Absicht | Welche gewählt? Würde ich das wirklich tun? |
| Wegschicken | Reaktion auf „Für heute reicht's". |
| Rückkehr / Sperre | Verstanden, warum ich warten soll? Uhrzeit gesehen? |
| Beweis | Was getippt, wie lange gebraucht, abgelehnt worden? |
| +1 Tag / Satz über mich | Stimmt der Satz? Unangenehm? Ausgewählt „Stimmt"/„Stimmt nicht"? |
| Bugs | Alles, was hängt, springt, doppelt erscheint oder unlesbar ist (mit Screenshot-Pfad). |
| Urteil | „Würde ich morgen wiederkommen?" 0–10 · „Was hätte ich ohne die App heute nicht getan?" |

Screenshots nach `docs/screens/e2e/<persona>-<schritt>.png`.

## Auswertung

- Heatmap der Stolperstellen über fünf Durchläufe.
- Bugs nach Schwere: Blocker (Loop nicht abschließbar) → Stolperer (> 5 s Zögern) → Kosmetik.
- Top-5-Verbesserungen nach (Wirkung × Aufwand), umgesetzt vor dem Morgen, danach zweiter Durchlauf mit zwei Personas zur Bestätigung.
- Go/No-Go-Kriterien aus `docs/strategy/06-synthese-entscheidungen.md` Abschnitt 7 mit den fünf Ergebnissen vorab bewerten.
