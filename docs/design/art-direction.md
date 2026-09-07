# Art Direction — „Insel im Nebelmeer"

**Ziel in einem Satz:** Ein einzelnes, kleines, warmes Licht in einer großen, dunklen, kalten Welt. Alles andere ist Dunkelheit, Tiefe und Ruhe. Das Auge muss in der ersten Sekunde wissen, wo das Licht ist, und nichts sonst wollen.

## Was in den Baseline-Screenshots (02:05) falsch ist

1. **Zu hell.** Die Welt ist ein mittleres Blauviolett statt fast schwarz. Bloom hat nichts zu tun, wenn alles hell ist. Der Wow von Journey/Sky entsteht aus 90 % Dunkelheit.
2. **Die Insel ist riesig und blass.** Sie füllt das untere Drittel als ausgewaschener Klotz. Sie muss klein, fern und dunkel sein — eine Silhouette mit ein paar beleuchteten Kanten, nicht ein Modell-Viewer.
3. **Das Spieler-Licht ist ein ausgebrannter weißer Fleck.** Es muss ein kleiner warmer Kern (Radius ~0,12) mit weichem, warmem Bloom sein, der die nächsten Kanten der Insel streift.
4. **Harte Horizontlinie, flacher Boden.** Kein Übergang Wasser→Nebel→Himmel. Fog-Farbe und Himmelsfarbe müssen ineinander verlaufen; der Boden darf nur als Spiegelung des Lichts existieren.
5. **Keine Tiefe.** Alles gleich scharf, gleich hell. DoF, Vignette und atmosphärische Perspektive (fernere Teile dunkler und blauer) fehlen.

## Verbindliche Werte

| Element | Wert |
|---|---|
| Hintergrund/Himmel | #04040E unten bis #0B0E22 am Horizont, oben wieder dunkler (#050510). Kein Blau über 0.15 Luminanz |
| Fog | Farbe #0A0D1F, `fogStartDistance` 6, `fogEndDistance` 22, Exponent 1.8. Die Insel liegt bei ~8–10 Einheiten Distanz: teilweise im Nebel |
| Kamera | FOV 48, Höhe 1.6 über dem Wasser (tiefer = dramatischer), Blick leicht nach unten (−8°). Insel nimmt ~35 % der Breite ein, sitzt im unteren Drittel |
| Exposure | `exposureOffset` −0.6 bis −0.3, `averageGray` 0.12, `whitePoint` 1.0. Erst wenn das Bild zu dunkel wirkt, hat man den richtigen Ausgangspunkt |
| Bloom | Intensität 1.2, Threshold 0.65, Radius 22. Bloom nur auf Emission (Licht, Knoten, Wurzeln, Sonne), nie auf diffusem Material |
| Insel-Material | Diffuse #14162A, Roughness 0.85, Metalness 0.0, keine Emission. Flat shaded. Die Kanten leben vom Licht, nicht vom Material |
| Spieler-Licht | Kugel r 0.12, Emission #FFB347 × 2.0, Punktlicht 900 lm warm, Attenuation-Ende 6. Es beleuchtet die Insel *sichtbar*, wenn es nah ist |
| Knoten | Ikosaeder r 0.16; glühend Emission #FFB347 × 1.4 mit langsamem Puls (0.5 Hz); lauwarm gleiche Farbfamilie #FFC27A × 1.2 mit unregelmäßigem Puls (< 2 Hz), bis zur Setzung nicht unterscheidbar; kalt Diffuse #2A2F45 ohne Emission |
| Wurzeln | Gold #FFD37A Emission × 1.6, dünne Zylinder (r 0.02–0.04), nur unter der Nebelkante sichtbar, wenn die Kamera taucht |
| Wasser | `SCNFloor` Reflexion 0.5, `reflectionFalloffEnd` 8, Diffuse #05060F, Roughness 0.15. Die Spiegelung des Lichts ist das zweite Licht im Bild |
| Sonne | Scheibe r 0.9 bei Distanz 30, Emission #FF9A5C → #FFE0B0 beim Aufstieg; beim Aufstieg steigt `key.intensity` von 60 auf 450 und die Fog-Farbe nach #2B2340 |
| Partikel | Umgebungsfunken ≤ 40/s, winzig (0.02–0.04), Alpha 0.35, langsam; sie dürfen nie heller sein als das Spieler-Licht |
| Vignette | Power 1.4, Intensität 1.0. SSAO 0.6. DoF: Fokus Insel, fStop 5.6 |

## Prüfliste („ist es atemberaubend?")

- Ist das Bild zu 80 % dunkel? Wenn nein: Exposure runter, Materialien dunkler.
- Weiß ich in einer Sekunde, wo das Licht ist? Wenn nein: alles andere dunkler.
- Sehe ich das Licht zweimal (Kern und Spiegelung)? Wenn nein: Reflexion hoch, Kamera tiefer.
- Verschwindet die Insel hinten im Nebel? Wenn nein: Fog näher, Insel weiter.
- Ist irgendetwas ausgebrannt weiß? Wenn ja: Bloom-Threshold hoch, Emission runter.
- Hält die Szene 120 Hz im Simulator (p95 < 8 ms)? Wenn nein: Partikel und Schatten zuerst.

Referenzgefühl: Journey (Wüste bei Nacht), Sky, Monument Valley (Farbe statt Textur), Alto's Odyssey (Silhouette und Verlauf).
