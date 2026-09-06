# ADR 01 · SceneKit für den PoC, RealityKit als Zielplattform, Domain framework-frei

**Status:** entschieden (2026-09-07) · **Quelle:** Memo 03 Engine-Architekt, Memo 01 Game Director

## Kontext
Heute Nacht muss ein 3D-PoC im iOS-26-Simulator laufen. SceneKit ist im iOS-26.5-SDK nur „soft deprecated" (kein API_DEPRECATED auf Kern-Symbolen) und liefert HDR/Bloom/Vignette/SSAO/DoF/Partikel in wenigen Property-Zuweisungen; im Simulator verifiziert (Spike). RealityKit hat seit iOS 26 Post-Processing, aber keinen öffentlichen HDR-Schalter; Bloom wäre ein eigener Metal-Pass. Unity/Unreal: Lizenz-/Installzeit, kein Liquid Glass, keine native Haptik-Integration.

## Entscheidung
- PoC und Alpha: **SceneKit** über `UIViewRepresentable`/`SCNView` (nicht `SceneView`, wegen 120 Hz und Delegate-Zugriff).
- Produkt in 6–12 Monaten: **RealityKit, nativ.** Unity nur, wenn Android innerhalb von 12 Monaten kommen muss (Business-Entscheidung, offen).
- Rendering ausschließlich hinter `SceneRenderer`/`SceneCommand`. `LevmiCore` importiert nur `Foundation`. Kein `SCNNode` außerhalb von `Levmi/Scene/`.

## Konsequenzen
Migration = zweite Renderer-Implementierung hinter demselben Protokoll; Domain-Logik wird nie migriert. Swift-6-Strict-Concurrency: `complete` im Core-Package, `minimal` im App-Target (SceneKit-Delegates sind nicht MainActor-annotiert). SceneKit-Float-Rundung: Assertions gegen SceneKit-Properties nur mit Toleranz.

## Verworfen
Metal pur (6–8 h bis zum ersten Dreieck), RealityKit heute Nacht (Bloom = Handarbeit), Unity (Ökosystemwechsel ohne Not).
