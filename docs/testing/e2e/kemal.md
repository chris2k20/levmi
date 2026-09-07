# Levmi – Testprotokoll Kemal

**Wer:** Kemal, 31, Außendienst Solaranlagen, Köln
**Gerät:** iPhone Air Simulator (UDID `ED0D0529-917B-4CAF-84BA-0DED056815DC`), Bundle `de.immodigit.levmi`
**Datum:** 2026-09-07
**Zeitbudget:** 25 Minuten (Abbruch nach ca. 5 Minuten wegen technischer Sperre, siehe unten)

---

## Erste 10 Sekunden

App gestartet. Ich seh: schwarzer Bildschirm, Sternenhimmel, in der Mitte oben ein leuchtender oranger Punkt wie eine kleine Sonne, unten ein warmes verschwommenes Glühen im Nebel. Oben rechts zwei kleine Pillen-Buttons "Demo" und "Neu". Unten ein Sprechblasen-Text: "Zieh das Licht in den Nebel."

**Was ich denke:** Häh, okay... kein Logo, kein "Willkommen bei Levmi", keine Erklärung was die App überhaupt macht oder wofür sie gut ist. Sieht aus wie eine Meditations-App oder sowas Esoterisches, nicht wie ein Tool für meinen Arbeitsalltag. Mein Kollege meinte "is was für dich" – bis jetzt seh ich noch nicht wofür. Wirkt aber optisch schick, nicht billig gemacht. Ich will als erstes auf "Demo" tippen, wie gesagt wurde, damit es schneller geht.

**Gefühl in einem Wort:** neugierig-skeptisch

---

## Tabelle

| Schritt | Was ich sehe | Was ich denke | Was ich tue | Status |
|---|---|---|---|---|
| 1 | Startbildschirm: Sternenhimmel, oranger Lichtpunkt, Nebel unten, Buttons "Demo"/"Neu" oben rechts, Text "Zieh das Licht in den Nebel." | Sieht schick aus, aber ich weiß nicht was das Ziel der App ist. Erstmal Demo-Modus an, wie gesagt. | Tippe auf "Demo"-Button oben rechts. | ❌ |

**Was passiert ist:** Der Tap kam nie am Gerät an. Das Steuerungswerkzeug hat jedes Mal denselben Fehler zurückgegeben:

> "The user has not granted Claude access to iPhone Air (iOS 26.5) (a recent request was declined or is awaiting a response)."

Ich habe es an derselben Stelle 3x versucht (2x Tap auf "Demo", 1x "attach" fürs Live-Bild) – jedes Mal exakt derselbe Zugriffsfehler. Das ist keine Wackelkontakt-Sache, das ist eine harte Sperre.

Screenshot (per Shell-Skript, das ging unabhängig davon): `docs/screens/e2e/kemal-01-start.png`

---

## ⚠️ Technischer Hinweis – kein Levmi-Bug, sondern Testumgebung

Das hier ist **kein Befund über die App**, sondern über die Testumgebung selbst, deshalb bewusst außerhalb von Kemals Ich-Perspektive:

- Screenshots per `scripts/shot.sh` (läuft über `xcrun simctl` direkt) funktionieren einwandfrei – der Start-Screenshot oben ist echt.
- Jede Eingabe über `mcp__Claude_Code_iOS_Simulator__control` (tap, touch_path, text, attach) schlägt fehl, weil Claude für dieses Simulator-Gerät noch keinen Zugriff freigeschaltet bekommen hat. Laut Fehlermeldung muss das im Simulator-Panel der Claude-Code-App über den Link "Let Claude use it" freigegeben werden – das kann nur der Mensch vor dem Rechner tun, kein Retry meinerseits behebt das.
- Es gibt für diesen Simulator-Server kein `request_access`-Tool wie bei anderen Steuerungswerkzeugen (geprüft) – die Freigabe läuft ausschließlich über die UI des Simulator-Panels.
- Ergebnis: Ich konnte **keine einzige Geste** (Tippen, Halten, Ziehen, Texteingabe) tatsächlich ausführen. Alles, was über den ersten Screenshot hinausgeht, habe ich nicht getestet – ich schreibe hier bewusst nichts dazu, um keine Ergebnisse zu erfinden.

**Nötig, um weiterzutesten:** Simulator-Panel in Claude Code öffnen, Gerät "iPhone Air" anhängen/freigeben ("Let Claude use it"), dann diesen Testlauf erneut anstoßen. App läuft bereits (PID war aktiv), muss ggf. nicht neu gestartet werden.

---

## Hänger

- **Stelle:** Direkt am Start, beim ersten Tap auf "Demo".
- **Wie lange:** Nach 3 gescheiterten Versuchen (~1 Minute) abgebrochen, wie in der Anleitung vorgesehen – nicht weiter im Kreis gedreht.

## Fehler mit Screenshot

- `docs/screens/e2e/kemal-01-start.png` – Startbildschirm, technisch einwandfrei geladen. Kein visueller App-Fehler erkennbar, nur die Eingabe-Sperre außerhalb der App.

---

## Abschlussfragen

**Würde ich morgen wiederkommen? (0–10)**
Kann ich ehrlich nicht seriös beantworten – ich hab nichts bedienen können, nur ein Standbild gesehen. Rein vom ersten Bildschirm (0 Kontext, keine Erklärung, wirkt esoterisch statt nach Vertriebs-Tool) wäre meine Bauch-Tendenz eher verhalten, aber das wäre geraten, keine echte Bewertung. **Neubewertung nötig, sobald Eingaben funktionieren.**

**Was hätte ich ohne die App heute nicht getan?**
Kann ich nicht beantworten – ich bin nicht über den Startbildschirm hinausgekommen.

**Drei Verbesserungswünsche (ehrlich):**
Kann ich nicht seriös aus einem Standbild ableiten – wäre erfunden. Einzig was mir schon auf dem ersten Screen auffällt: keinerlei Erklärung, was die App tut oder bringt, bevor sie eine Geste von mir verlangt. Für einen Ersteindruck bei jemandem, der (wie ich) nichts über die App weiß, ist das riskant – wirkt wie ein Meditations-Ritual, nicht wie ein Ergebnis-Tool. Ob das stimmt, muss ich erst nach echtem Testen der Kernfunktion beurteilen. Punkte/Rangliste: auf dem ersten Screen nicht sichtbar, aber dazu kann ich nach einem Bildschirm nichts Verlässliches sagen.
