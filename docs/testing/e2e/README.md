# End-to-End-Nutzertests am Simulator (neue Personas), 2026-09-07 früh

Agenten haben als Nutzer ohne Vorwissen die App im Simulator bedient (Tippen, Halten, Ziehen, Tippen von Text) und protokolliert. Eingaben waren synthetisch (Simulator-Steuerung), was Halten und Ziehen unzuverlässiger macht als ein echter Finger — die Befunde sind trotzdem ernst zu nehmen, weil sie die Stellen ohne Feedback zeigen.

## Nadine, 38, Physiotherapeutin — 3 von 10

Protokoll: [nadine.md](nadine.md). Gefallen: Optik, das Ziehen des Lichts („neugierig"). Abbrüche:

| Befund | Ursache | Fix (eingebaut) |
|---|---|---|
| Nach der Insel-Enthüllung drei Minuten ohne Ahnung, was zu tun ist | Kein Hinweis zwischen „Du hast ein Licht." und dem Halte-Hinweis (erst nach zwei Abbrüchen) | Halte-Hinweis schon nach dem ersten Abbruch; Bestätigung „Licht gesetzt. Die Wurzeln wachsen." nach dem Setzen |
| Halten zeigt keinen Fortschritt (Ring zu klein, aus 7 Einheiten kaum sichtbar) | Ring-Ticks 0,035 × 0,1 Einheiten | Kristall wächst mit dem Halten (+55 %), Ring-Ticks fast verdoppelt, Radius 0,38 |
| Zwei Laderinge gleichzeitig nach Knotenwechsel | Verwaister Touch ohne `ended` | Andere Ringe werden beim Start eines neuen Ladens zurückgesetzt |
| Nach „Neu" fehlt der Start-Hinweis | Timer lief nur beim ersten Erscheinen | Timer startet auch beim Phasenwechsel zurück auf `firstLight` |
| „Was ist das hier überhaupt?" | Kein Rahmensatz | Erste 3,5 Sekunden: „Levmi. Deine Insel wächst, wenn du handelst." |
| Sonne wird nicht als Ziehbares erkannt | Kein Hinweis | Nach 5 Sekunden in der Sonnenphase: „Zieh die Sonne hoch." |

## Kemal, 31, Vertriebler — nicht bewertbar

Das Gerät (iPhone Air) war für die Simulator-Steuerung nicht freigegeben; nur ein Standbild. Protokoll: [kemal.md](kemal.md).

## Ute, 57, Buchhändlerin · Ben, 26, Junior-Entwickler

Siehe [ute.md](ute.md) und [ben.md](ben.md) (Ben lief bereits auf dem Build mit den Nadine-Fixes).

## Nach den Fixes (Architekt, 06:05)

- Halten ist jetzt timergetrieben (ruhiger Finger lädt). Verifiziert mit dem Vier-Punkt-Halten der Simulator-Steuerung (Licht wird gesetzt). **Werkzeug-Artefakt:** Ein `touch_path` mit nur zwei identischen Punkten wird als Tipp ohne Haltedauer zugestellt und löst nichts aus — das erklärt einen Teil der „Halten zeigt nichts"-Befunde von Nadine und Ben, nicht alle.
- Ben (2/10) testete den Build **ohne** den Ring-Reset und ohne den Timer; Nadine und Ute (3 und 4/10) den Build ohne alle Halte-Fixes. Die Scores sind der ehrliche Stand vor den Fixes. Ein neuer Persona-Durchlauf auf dem finalen Build steht aus.
- Was alle drei mochten: Optik und Stimmung, das Ziehen des Lichts, das Wachsen von Insel und Sonne.
- Was alle drei vermissten: ein Satz, was Levmi ist (jetzt in den ersten 3,5 Sekunden), sichtbarer Fortschritt beim Halten (jetzt Kristallwachstum plus Timer), Bestätigung nach dem Setzen (jetzt „Licht gesetzt. Die Wurzeln wachsen.").
