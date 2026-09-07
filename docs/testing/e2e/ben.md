# Levmi E2E-Test – BEN

**Wer testet:** Ben, 26, Junior-Dev Berlin. Kenne die App nicht, jemand aus dem Coworking meinte nur "das ist was für dich".
**Gerät:** iPhone 17 Pro Simulator (`1035520F-…`), Bundle `de.immodigit.levmi`, frisch installiert.
**Datum/Zeit:** 07.09.2026, 05:48–05:58 Uhr (Sim-Zeit), ca. 10 Minuten aktive Testzeit.

---

## Die ersten 10 Sekunden

App auf, und... nichts. Komplett schwarzer Screen, eine leuchtende orange Kugel schwebt mittig, unten ein warmes Glühen. Kein Ladebalken, kein Logo-Intro, kein "Hey, schön dass du da bist". Unten klein und unauffällig ein Satz: "Levmi. Deine Insel wächst, wenn du handelst." Hab den fast übersehen, weil er aussieht wie ein System-Hinweis, nicht wie Copy. Oben rechts zwei Pillen-Buttons, "Demo" und "Neu" – wenigstens ein Ankerpunkt für Interaktion. Erster Gedanke: ist das ein Screensaver oder ein Spiel? Kein Tab-Bar, kein Menü, keine Zahl irgendwo auf dem Screen.

---

## Protokoll

| Schritt | Was ich sehe | Was ich denke | Was ich tue | ✅/⚠️/❌ |
|---|---|---|---|---|
| 1. Start (05:48) | Schwarzer Screen, leuchtende Kugel, unten: „Levmi. Deine Insel wächst, wenn du handelst." Oben rechts „Demo" / „Neu". | Kein Onboarding, keine Erklärung was das Ding überhaupt ist. Insel? Wachsen? Gefühl: **Ratlos**. | Erstmal nur schauen, Screenshot. | ⚠️ |
| 2. Demo an (05:49) | Tippe „Demo" oben rechts (267,100 pt). Button wird zu „Demo an". Hinweistext wechselt zu „Zieh das Licht in den Nebel." | Okay, jetzt sagt er mir wenigstens konkret was zu tun ist. Gefühl: **Neugierig**. | Tap auf Demo-Button. | ✅ |
| 3. Licht ziehen, Versuch 1 | Ziehe die Kugel ca. 100pt nach unten (200,238 → 200,340). Kugel bleibt exakt an derselben Stelle stehen, nur ein paar neue dunkle Pünktchen im Hintergrund. | Hab ich die überhaupt getroffen? Kein Wackeln, kein Widerstand, keine Rückmeldung beim Ziehen selbst. Gefühl: **Unsicher**. | Drag-Geste, kurz. | ⚠️ |
| 4. Licht ziehen, Versuch 2 | Zweiter, weiterer Drag in einem Zug bis (200,420). Nebel reißt komplett auf: dunkle Insel-Silhouette mit 5 Hex-Kacheln (4 gold, 1 schwarz) + gespiegelte Kacheln im „Wasser" darunter. Hinweistext weg. Screenshot: `docs/screens/e2e/ben-04-licht-gezogen2.png` | Oh krass, jetzt kommt was! Aber warum hat Versuch 1 gar nichts gebracht – wie weit muss ich ziehen, damit's zählt? Kein Zwischenfeedback. Gefühl: **Überrascht**. | Drag in mehreren Schritten (7 Punkte, dt_ms ~180). | ✅ (Ergebnis gut) ⚠️ (Schwelle unklar) |
| 5. Tap mittlere Kachel (05:51) | Hinweis: „Halten, bis der Ring voll ist." | Aha, halten statt tippen, gut zu wissen. Aber ich seh nirgendwo einen Ring auf dem Screen. Gefühl: **Gespannt**. | Tap (199,262). | ✅ |
| 6. Halten 1,7s | Zwei Nachbar-Kacheln blitzen als grelle weiße Balken/Rechtecke auf – sieht aus wie eine fehlende Textur. Kein Ring sichtbar. Screenshot: `docs/screens/e2e/ben-06-halten-hex.png`, `ben-07-halten-lang.png` | Was zur Hölle ist DAS? Sieht kaputt aus, nicht wie ein Erfolgs-Effekt. Gefühl: **Verwirrt**. | Halten-Geste (0/700/700/300ms). | ❌ |
| 7. Länger halten (3,5s) | Exakt derselbe kaputte Zustand, nichts verändert sich weiter. | Auch mit mehr Geduld: nix. Gefühl: **Genervt**. | Längere Halten-Geste. | ❌ |
| 8. Warten + Leertap (05:52, **Hänger ~60–90 Sek.**) | Weiße Balken kleben unverändert, auch nach über einer Minute Warten und einem Tap ins Leere. Screenshot: `docs/screens/e2e/ben-08-nach-leertap.png` | Das fixt sich nicht von allein. Für mich eingefroren. Gefühl: **Frustriert**. | Tap ins Leere (200,500), warten, Screenshot. | ❌ (3. Fehlversuch an dieser Stelle → weiter) |
| 9. „Neu" gedrückt | Zurück zum Start (Kugel + Nebel). „Demo an" bleibt aktiv! Kein Hinweistext zunächst. Screenshot: `docs/screens/e2e/ben-09-neu.png` | Wenigstens merkt er sich den Demo-Modus über den Reset hinweg. Kleines Plus. Gefühl: **Erleichtert**. | Tap „Neu" (353,100). | ✅ |
| 10. Licht ziehen (sauberer Durchgang) | Insel erscheint wieder – aber die weißen Balken-Glitches sind SOFORT da, bevor ich auch nur eine Kachel berührt habe! Screenshot: `docs/screens/e2e/ben-10-drag2.png` | Moment... das Ding passiert also von allein beim Erscheinen der Insel und hat gar nichts mit meinem Halten zu tun?! Definitiv ein reproduzierbarer Grafik-Bug (2/2). Gefühl: **Aha-aber-genervt**. | Ein Drag, 7 Punkte. | ❌ (Bug bestätigt reproduzierbar) |
| 11. Tap rechte (heile) Kachel | Hinweis „Halten, bis der Ring voll ist." erneut. | Versuch's an einer Kachel ohne Glitch. Gefühl: **Hoffnungsvoll**. | Tap (306,275). | ✅ |
| 12. 3 Sek. durchgängig halten | Absolut keine Veränderung, kein Ring, kein Fortschritt irgendwo auf dem Screen. Screenshot: `docs/screens/e2e/ben-12-halten-rechts.png` | Ich halte jetzt seit 3 vollen Sekunden – nix passiert, nirgendwo ein Ring zu sehen. Kernmechanik der App wirkt kaputt oder ich verstehe sie komplett falsch. Gefühl: **Ratlos**. | Hold-Geste, 3000ms durchgängig. | ❌ (3. Fehlversuch, Mechanik abgebrochen) |
| 13. Kleines Hex-Fragment antippen | Keine Reaktion. Screenshot: `docs/screens/e2e/ben-13-tap-fragment.png` | Und das komische halb-verdeckte Ding links? Auch tot. Gefühl: **Gleichgültig**. | Tap (146,286). | ❌ |
| 14. Swipe nach oben (freie Fläche) | Keine Kamera-Bewegung, keine Reaktion, nur die üblichen treibenden Deko-Partikel. Screenshot: `docs/screens/e2e/ben-14-swipe-hoch.png` | Kein Pan, kein Zoom – die Szene ist bis auf 5 Kacheln komplett statisch. Gefühl: **Ernüchtert**. | Swipe (200,700)→(200,380). | ❌ |
| 15. Insel-Körper antippen | Keine Reaktion. Screenshot: `docs/screens/e2e/ben-15-tap-insel-koerper.png` | Auch tot. Nur die 5 Kacheln sind „Buttons", der Rest ist reine Deko. Gefühl: **Ernüchtert**. | Tap (197,350). | ❌ |
| 16. App hart beendet + neu gestartet (Persistenz-Test, 05:56) | Nach `terminate` + `launch`: Statt der kaputten weißen Balken jetzt eine komplett neue, viel edlere goldene Kristallstruktur. Fortschritt nicht verloren – im Gegenteil, sieht weiter entwickelt aus! Screenshot: `docs/screens/e2e/ben-16-nach-neustart-app.png` | WAS. Also mein Stand bleibt erhalten, das ist gut. Aber heißt das, die Insel wächst einfach mit der Zeit von selbst, auch während die App zu ist – und mein ganzes Halten vorhin war für die Katz? Kausalität zwischen meiner Aktion und dem Fortschritt ist mir schleierhaft. Gefühl: **Verwirrt-aber-positiv-überrascht**. | `simctl terminate`, kurz warten, `simctl launch`. | ⚠️ (Datenpersistenz ✅, Verständnis ❌) |
| 17. Neuen Kristall antippen (05:58) | Keine Hinweistext, keine Reaktion mehr. Screenshot: `docs/screens/e2e/ben-17-tap-kristall.png` | Und jetzt? Keine Anleitung mehr, ich weiß nicht was als Nächstes kommen soll. Für heute bin ich durch. Gefühl: **Fertig**. | Tap (199,306). | ⚠️ |

**Texteingabe:** Ich habe in den ganzen 10 Minuten keine einzige Textfrage, kein Eingabefeld und keine Tastatur gesehen – die `text`-Aktion aus meinem Werkzeugkasten kam nie zum Einsatz, weil es nirgends etwas zu tippen gab.

**Wörtliche Texte, die die App zeigt** (alles, was ich gesehen habe):
- „Levmi. Deine Insel wächst, wenn du handelst."
- „Zieh das Licht in den Nebel."
- „Halten, bis der Ring voll ist."

Das war's. Kein Tutorial, kein Tooltip, kein Zurück-Button, kein Menü, keine Zahl, kein Score.

---

## Bugs im Überblick

1. **Weißer Balken-Glitch auf den Hex-Kacheln** (reproduzierbar 2/2 nach Reset): Direkt beim Erscheinen der Insel zeigen 2 der 5 Kacheln grelle weiße Rechtecke statt normaler Grafik – sieht aus wie fehlende/kaputte Assets. Bleibt über 1+ Minute unverändert stehen, egal was ich tue. Screenshots: `ben-06-halten-hex.png`, `ben-07-halten-lang.png`, `ben-08-nach-leertap.png`, `ben-10-drag2.png`.
2. **„Halten, bis der Ring voll ist." – aber es gibt keinen sichtbaren Ring.** Weder kurzes (1,7s) noch langes (3,5s) noch sauberes 3-Sekunden-Halten auf einer unbeschädigten Kachel erzeugt irgendein Fortschritts-Feedback. Screenshot: `ben-12-halten-rechts.png`.
3. **Unklare Zieh-Schwelle:** Der erste, kürzere Zug am Licht hat sichtbar nichts bewirkt, erst ein zweiter, weiterer Zug hat die Insel enthüllt. Ohne Fortschrittsanzeige während des Ziehens wirkt das wie Zufall.
4. **Tote Flächen:** Insel-Körper, Kachel-Fragment und freie Fläche reagieren auf Tap/Swipe überhaupt nicht – nicht mal ein "das geht nicht"-Feedback.

## Hänger

- **1 klarer Hänger, ca. 60–90 Sekunden**: nach dem ersten Halten-Versuch blieb der weiße Balken-Glitch minutenlang unverändert stehen (Schritt 6–8), auch nach Tap ins Leere. Kein Crash, kein Absturz – die App reagierte weiter auf Taps (Neu funktionierte), aber der visuelle Zustand war eingefroren.

---

## Würde ich morgen wiederkommen? **2/10**

Ehrlich gesagt: nein, nicht in dem Zustand. Die Optik ist stellenweise richtig schön (der goldene Kristall am Ende!), aber ich hab nach 10 Minuten aktivem Rumprobieren immer noch nicht kapiert, was die App von mir will, ob meine Aktionen überhaupt etwas bewirken, oder ob die Insel einfach nach einer Zeitschaltuhr wächst und ich nur Staffage bin. Die einzige klar kommunizierte Interaktion („Halten, bis der Ring voll ist.") hat bei mir in keinem einzigen Versuch sichtbar funktioniert. Ohne Ziel, ohne Score, ohne Erklärung gibt's für mich keinen Grund, morgen nochmal reinzuschauen – außer um zu checken, ob der Glitch gefixt ist.

## Was hätte ich ohne die App heute nicht getan?

Ganz ehrlich: nichts. Ich hab keine Aufgabe erledigt, keine Notiz gemacht, nichts organisiert – ich hab zehn Minuten lang eine leuchtende Insel angestupst, die mal glitcht und mal nicht. Wenn's hochkommt: Ich hab mal probiert, wie geduldig ich für eine unklare Halten-Geste wirklich bin (Antwort: nicht sehr).

## Drei Verbesserungswünsche

1. **Sichtbares, funktionierendes Ring-Feedback für die Halten-Geste** – aktuell unsichtbar bzw. kaputt. Das ist die einzige benannte Interaktion der App und sie liefert bei mir in 3/3 Versuchen null Rückmeldung.
2. **Den weißen Balken-Grafikfehler fixen**, der reproduzierbar (2/2) direkt beim schönsten Moment (Insel-Reveal) auftritt – macht im allerersten Eindruck einen kaputten Eindruck, genau da wo die App am meisten überzeugen müsste.
3. **Irgendein Ziel, ein Zähler oder eine kurze Erklärung**, was die Insel überhaupt darstellt und warum/wodurch sie wächst (meine Aktion vs. reine Zeit) – ohne das fehlt mir jeder Grund, wiederzukommen.
