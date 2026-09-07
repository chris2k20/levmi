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
