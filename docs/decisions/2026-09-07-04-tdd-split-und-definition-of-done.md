# ADR 04 · TDD-Schnitt: Domain wird test-first gebaut, Rendering wird gesehen, nicht assertiert

**Status:** entschieden (2026-09-07) · **Quelle:** Memo 03, Christians Rollenvorgabe (Opus = Tests, Sonnet = Code, Fable = Architekt)

## Entscheidung
- `LevmiCore` (Content, Mastery, Reducer, Beweis, Tage, Rückspiel, Persistenz) wird zu 100 % test-first gebaut: Opus-Chefs schreiben Swift-Testing-Suites gegen den Vertrag in `docs/design/poc-spec.md`, verifizieren RED, Sonnet-Coder implementieren bis GREEN, Opus reviewt. `swift test` läuft auf dem Mac ohne Simulator (~8 s).
- Rendering, Kamera, Partikel, Haptik-Kurven, Sound werden nicht unit-getestet. Absicherung: Smoke-Konstruktion der Szene, Frame-Budget (p95 ≤ 8 ms), ein Screenshot pro grünem Build, ein UI-Smoke-Test.
- Definition of Done (PoC): Build grün ohne eigene Warnungen · Core-Tests grün (≥ 40) · App zeigt Welt in ≤ 2 s · kompletter Loop im Demo-Modus < 4 Min · Screenshots + Recording · README „So testest du morgen früh".

## Konsequenzen
Der Reducer ist eine reine Funktion `(PlayerState, GameAction, Clock, World, Rules) -> (PlayerState, [Effect])`; alle Zeitkonstanten leben in `Rules` (Standard/Demo). Wer die Spec ändert, ändert zuerst die Datei, dann die Tests, dann den Code.
