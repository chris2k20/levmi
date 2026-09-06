# LEVMI — Simulierte Nutzerbefragung zum PoC-Ablauf

**Von:** UX-Researcher · **An:** Christian · **Datum:** 2026-09-07
**Grundlage:** `docs/design/poc-spec.md` (1.1–1.4, 2) · `06-synthese-entscheidungen.md` (4, 7) · `02-psychologe.md` (2.5, 6)
**Methode:** Think-Aloud auf dem Papier, fünf konstruierte Personas, ein Durchlauf pro Person, keine Hilfestellung.

---

## 0. Lies das zuerst, sonst wird dieses Dokument gefährlich

Das hier sind **keine Nutzerdaten**. Es sind fünf durchgerechnete Hypothesen über Stolperstellen, die ich aus deiner Spezifikation ableiten kann, bevor du eine Zeile Code schreibst. Der Wert liegt in den **Abbruchpunkten**, nicht in den Zahlen.

Drei Regeln für den Umgang damit:

1. **Zitiere aus diesem Dokument nie eine Prozentzahl nach außen.** n = 5 simuliert ist eine Hypothesen-Maschine, keine Messung. Abschnitt 7 sagt dir, wie unsicher jede Prognose ist.
2. **Wo ich schreibe „bricht ab", habe ich mich für die pessimistische Lesart entschieden.** Das ist Absicht. Ein UX-Test, der dir recht gibt, hat kein Geld verdient.
3. **Der wichtigste Satz des ganzen Dokuments steht in Abschnitt 3, Zeile 1:** Fünf von fünf zögern bei der allerersten Geste. Der Text-Aus-Test aus Synthese 7.3 ist mit dem Ablauf von heute Nacht **nicht bestanden**, und das kostet dich morgen früh mehr als jeder Bloom-Wert.

---

# Teil A — Die fünf Protokolle

---

## 1. Markus, 44 — Immobilieninvestor, 6 Objekte, dein Kunde

**Kontext:** iPhone 15 Pro, im Auto auf dem Parkplatz, 4 Minuten bis zum Notartermin, **Ton aus** (Klingelton lautlos seit drei Jahren). Kennt das Quellbuch. Hat drei Produktivitäts-Apps installiert und nach zwei Wochen wieder gelöscht.

| Schritt | Think-Aloud | |
|---|---|---|
| Erste Minute | „Schwarz. Ok. Ein Punkt. Ich warte mal." *(2 Sekunden)* „Was soll ich machen? Ich tippe drauf." *(nichts)* „Nochmal." *(nichts)* „Ist die App abgestürzt oder ist das Kunst?" | ⚠️ |
| | „Ich wisch mal drüber." *(Licht bewegt sich)* „Ah — ziehen. Warum steht das nirgends. Ok, runter in den Nebel." *(Insel hebt sich)* „Das sieht teuer aus, das muss ich sagen." | ✅ |
| | „Drei Kristalle. Einer glüht, einer ist grau, einer flackert. Ton ist aus, ich hör nichts. Der Glühende ist offensichtlich der richtige." | ⚠️ |
| | *„Du hast ein Licht."* — „Ein Licht, drei Optionen. Verstanden, das ist Pareto. Das kenne ich, das ist der Filter." | ✅ |
| | „Ich halt drauf." *(Ring füllt sich, Haptik rampt)* „Oh, das fühlt sich gut an. Das ist besser als jede Animation." *(Einschlag, Kamera taucht unter den Nebel, Wurzeln)* „Es passiert unten was und oben seh ich nichts. Das ist die Aussage. Ok, verstanden, sogar ohne Ton." | ✅ |
| Sonne | „Da ist eine Sonne. Ziehen kann ich ja jetzt." *(zieht)* „Nebel sinkt." | ✅ |
| Durchbruch | *(Kristall bricht durch, harte Haptik)* „Ok. **Das** war ein Moment. Das hat mein Bauch gespürt, nicht mein Kopf." | ✅ |
| Onboarding | „Was nervt dich gerade am meisten. Zeit weg. Alles hängt an mir. Zu viel Lauwarmes." *(drei Kacheln)* „Das ist unangenehm präzise formuliert." | ✅ |
| Umkehr | *(Kacheln drehen sich)* „Deine Zeit gehört dir. — Ja, gut gemacht. Ich weiß, dass das ein Trick ist, und es wirkt trotzdem." | ✅ |
| „Wofür?" | „Wofür — was? Wofür die App? Wofür mein Geld? Wofür meine Zeit? Ich versteh die Frage nicht." *(tippt „Skip")* | ⚠️ |
| | *(Zweiter Gedanke)* „Und wo landet das eigentlich, wenn ich da was reinschreibe? Steht nirgends. Deshalb hab ich auch geskippt." | ⚠️ |
| Absicht | „Sag heute zu einer lauwarmen Sache ab, ein Satz, keine Begründung. — Ich weiß sofort, welche. Das Objekt in Gelsenkirchen, das der Makler mir seit sechs Wochen schickt." | ✅ |
| Wegschicken | *„Für heute reicht's."* — „Moment. Die App schickt mich **raus**? Nach drei Minuten?" *(schaut auf die Uhr)* „Das ist das Erste, was mich an dem Ding überzeugt. Jede andere App will jetzt meine E-Mail." | ✅ |
| Rückkehr (nach 25 Min) | „Ich hab abgesagt, direkt nach dem Notar, per WhatsApp. Ich will das eintragen." *(öffnet)* — *„Noch nicht. Die Wurzeln arbeiten."* | ❌ |
| | **„Wie, noch nicht? Ich hab es doch getan. Wann denn dann? Da steht keine Uhrzeit. Soll ich raten?"** *(schließt die App)* | |
| Rückkehr (2. Versuch, 19:40) | „Ich hab's zufällig gesehen, als ich das Handy in der Hand hatte. Ohne den Zufall wär's weg gewesen." | ⚠️ |
| Beweis | „Hast du es getan. Ja. — *Makler Rehberg abgesagt, 14:10, per WhatsApp, ein Satz, er hat nicht geantwortet.*" *(41 Sekunden)* „Grenzwertig lang zum Tippen, aber ok." | ✅ |
| Sonne + Durchbruch | *(größer als beim ersten Mal, Nebel sinkt eine Stufe)* „Ja. **Ich habe draußen was getan und hier drinnen ist was gewachsen.** Genau das." | ✅ |
| +1 Tag / 1/30 | „+1 Tag. Ok. Balken eins von dreißig." *(Pause)* „Dreißig wovon? Was passiert bei dreißig? Wenn ich einen Balken sehe, will ich wissen, was am Ende steht." | ⚠️ |
| Kosten-Frage | „Was hat es dich gekostet. — Nichts, war ja nur eine Absage." *(Pause)* „Oder meint ihr Geld? Das Objekt war 340k mit Faktor 19, das hätte ich eh nicht genommen. Ich weiß nicht, was ihr wissen wollt." *(Skip)* | ⚠️ |
| Befund | *„Du erkennst Glühendes sofort. Dein Engpass liegt nicht im Entscheiden, sondern im Wegräumen."* — „…" *(liest zweimal)* „Das trifft. Das ist genau mein Problem seit drei Jahren. **Stimmt.**" | ✅ |
| Share | „Teilen? Nein. Wem denn — meinen Mietern?" | ❌ |
| Nächstes Öffnen | *„Du hast geschrieben: Makler Rehberg abgesagt, 14:10…"* — „Ha. Ja. Das hab ich schon fast wieder vergessen. Das ist der Punkt, an dem das Ding anfängt, mich zu kennen." | ✅ |

**Würde ich morgen wiederkommen? 7/10.**
> „Weil ich neugierig bin, ob der nächste Satz genauso sitzt. Nicht wegen der Grafik. Der Grund, warum es keine 9 ist: Ich hab die Rückkehr fast verpasst, weil mir keiner gesagt hat, wann ich wiederkommen soll."

**Was hätte ich ohne Levmi heute nicht getan?**
> „Die Absage. Ehrlich. Die lag seit sechs Wochen in meinem Kopf und ich hab sie in vier Minuten erledigt, weil eine App mir gesagt hat, ich soll eine lauwarme Sache absagen und keine Begründung mitschicken. Der Teil ‚keine Begründung' war das, was es leicht gemacht hat."

---

## 2. Lena, 29 — Marketing-Angestellte mit Etsy-Nebenprojekt

**Kontext:** iPhone 13, 23:10 Uhr, im Bett, **Kopfhörer auf**. Duolingo-Streak: 412 Tage. Finch-Vogel heißt Pesto. Notion-Board mit 40 offenen Ideen, davon 3 angefangen.

| Schritt | Think-Aloud | |
|---|---|---|
| Erste Minute | „Oh. Ok, der Bass. **Mit Kopfhörern ist das etwas völlig anderes.**" *(3 Sekunden Stille)* „Ein Punkt. Ich soll ihn wahrscheinlich anfassen." *(hält, zieht versehentlich)* „Oh, er folgt mir. Runter?" *(lässt los, Insel hebt sich)* „Okaaay." | ⚠️ |
| | *(Kamerafahrt, warmes Pad)* „Das ist Journey. Das ist wirklich Journey-Level. Ich hab gerade eine Gänsehaut, das ist mir peinlich." | ✅ |
| Knoten | „Drei Steine. Der eine **singt**. Der andere brummt so unangenehm. Und der dritte… der flackert so komisch, wie ein Handy mit 3 % Akku." | ✅ |
| Text 1 | *„Du hast ein Licht."* — „Nur eins? Für drei? Oh nein. Ok, das ist die Lektion, ich hab's." | ✅ |
| Setzen | „Ich weiß, was passieren soll, ich nehm trotzdem den flackernden, weil ich wissen will, was passiert." *(hält)* *(Licht wird aufgesaugt, Sanduhr, graue Wurzel)* *„Das Lauwarme hat dein Licht gefressen."* | ✅ |
| | **„Autsch. Das ist mein ganzes Notion-Board. Vierzig flackernde Steine."** *(sitzt kurz still)* | ✅ |
| | *(neues Licht erscheint)* „Ok, ich krieg ein neues. Diesmal der Singende." *(Wurzeln unter dem Nebel)* | ✅ |
| Sonne/Durchbruch | *(zieht, Durchbruch, Akkord löst sich)* „Ohhh. Ok, den Ton hätte ich gerne als Klingelton." | ✅ |
| Onboarding | „Sechs Kacheln. Zeit weg, kein Fortschritt, alles hängt an mir. Ja, ja und ja." | ✅ |
| Umkehr | *(Flip mit Haptik pro Kachel)* „**Das ist so gut.** Ok, das würde ich screenshotten. Wenn ich könnte." | ✅ |
| „Wofür?" | „Wofür… hm. *Damit ich abends nicht das Gefühl hab, ich hab nichts geschafft.*" *(tippt 62 Zeichen)* „Das war ehrlicher als geplant." | ✅ |
| Absicht | „Sag heute zu einer lauwarmen Sache ab." *(schaut auf die Uhr: 23:14)* **„Heute? Es ist gleich Mitternacht. Ich kann heute niemandem mehr absagen."** *(wählt trotzdem)* „Ich mach's morgen, dann stimmt halt der Text nicht." | ⚠️ |
| Wegschicken | *„Für heute reicht's. Die Wurzeln arbeiten."* — „Endlich mal eine App, die nicht sagt ‚noch eine Lektion'. Ok. Gute Nacht." | ✅ |
| Rückkehr (nächster Tag, 21:00) | „Ich hab's gemacht — Kundin abgesagt, die seit Wochen ‚vielleicht' sagt." *(öffnet, Sperre ist längst abgelaufen)* „Da ist meine Absicht, in meinen Worten. Schön." | ✅ |
| Beweis | *„Melanie abgesagt heute 15:30 per Mail, sie war ok damit, ich hab drei Stunden zurück."* *(28 Sekunden, sie tippt schnell)* | ✅ |
| Sonne/Durchbruch | *(Tier 2, größer)* „Ja! Ok, das ist besser als ein Duolingo-Level, weil ich es wirklich gemacht hab." | ✅ |
| +1 Tag | „Plus ein Tag. Balken eins von dreißig." *(Pause)* **„Eins von dreißig ist so… wenig. Ich hab einen 412-Tage-Streak nebenan. Das fühlt sich an wie bei null anfangen."** | ⚠️ |
| Kosten-Frage | „Was hat es dich gekostet — *ein schlechtes Gewissen für ungefähr zehn Minuten.*" | ✅ |
| Befund | *„Dein Muster: Du prüfst das Lauwarme, statt es zu kippen."* — „Uff. Ja. Das ist… ja. **Stimmt.**" | ✅ |
| Share | „Teilen." *(öffnet die Karte)* „Hm. Es steht meine Schwäche drauf. Ich teil ungern meine Schwächen auf Instagram. Die umgedrehte Kachel von vorhin hätte ich geteilt, die war schön." *(schließt)* | ⚠️ |
| Nächstes Öffnen | *„Du hast geschrieben: Damit ich abends nicht das Gefühl hab…"* — „Oh. **Das ist der Moment.** Das ist wie Finch, nur erwachsen." | ✅ |

**Würde ich morgen wiederkommen? 8/10.**
> „Ich komm wieder, aber ich hab Angst, dass es zu wenig ist. Ich hab abends 20 Minuten und die App will 4. Was mach ich mit den anderen 16?"

**Was hätte ich ohne Levmi heute nicht getan?**
> „Melanie absagen. Definitiv. Die zieht sich seit sechs Wochen und ich hab jedes Mal gedacht ‚nächste Woche schreib ich ihr'. Der Stein, der mein Licht gefressen hat, war ziemlich genau sie."

---

## 3. Tobias, 36 — Handwerksmeister, 8 Mitarbeiter

**Kontext:** iPhone SE (kleines Display), 6:40 Uhr im Transporter vor der Baustelle, Kaffee in der anderen Hand. Spielt abends Clash of Clans. Liest keine Texte, die länger als eine Zeile sind.

| Schritt | Think-Aloud | |
|---|---|---|
| Erste Minute | „Schwarz. Lädt das noch?" *(tippt)* *(nichts)* „Tippt man nicht drauf?" *(tippt fester, zweimal)* *(nichts)* | ❌ |
| | **„Ey, was soll ich denn machen. Bei Clash weiß ich in einer Sekunde, was ich anfassen muss."** *(kurz vor dem Schließen)* *(wischt frustriert)* „Oh, jetzt geht's." | |
| | *(Insel hebt sich, Einschlag, Haptik)* „Ok, das rummst gut. Das ist ordentlich gemacht." | ✅ |
| Knoten | „Drei Steine. Kleine Dinger. Meine Finger sind für sowas nicht gebaut." *(tippt daneben)* *(tippt auf den glühenden — nichts, weil Tap statt Halten)* | ⚠️ |
| | „Der reagiert nicht. Kaputt?" *(tippt fünfmal schnell)* *(hält zufällig länger, Ring füllt sich)* **„Ah — draufbleiben. Das hätte man sagen können."** | ⚠️ |
| | *(Einschlag, Tauchgang, Wurzeln)* „Wurzeln. Ok. Wächst also was." | ✅ |
| Sonne/Durchbruch | *(zieht, Durchbruch, harte Haptik)* „Boah, ok. Das war gut. **Das** hat gesessen." | ✅ |
| Onboarding | „Jetzt Fragen. Sechs Kacheln." *(liest zwei, überspringt vier)* „Alles hängt an mir. Ja, das ist meine Firma in vier Wörtern." *(wählt eine)* | ✅ |
| Umkehr | *(Flip)* „Ok, hübsch." *(3 Sekunden, keine weitere Reaktion)* | ⚠️ |
| „Wofür?" | „Wofür? Wofür was?" *(zwei Sekunden)* „Skip." | ⚠️ |
| Absicht | „Sag heute zu einer lauwarmen Sache ab, ein Satz, keine Begründung." — „Ich hab drei Angebote draußen, die keiner will. Ok. Das kann ich." | ✅ |
| Wegschicken | *„Für heute reicht's."* — „Das war's? **Und was bringt mir das jetzt?**" *(sucht nach einem Menü, findet keins)* „Also: Ich hab jetzt vier Minuten damit verbracht, einen Stein anzuleuchten, und die App sagt tschüss. Hm." | ⚠️ |
| Rückkehr | *(mittags, 12:20, hat abgesagt)* „Ok, ich hab dem Bauträger abgesagt. Ich trag das ein." *(öffnet, Sperre ist abgelaufen)* | ✅ |
| Beweis | „Hast du es getan. Ja." *(tippt: „ja")* — *„Konkreter: Wer, wann, was ist passiert?"* | ❌ |
| | **„Ey, jetzt muss ich einen Aufsatz schreiben? Ich hab Dreck an den Händen und stehe auf einer Baustelle."** *(tippt „Bauträger abgesagt")* — *(23 Zeichen, wieder abgelehnt)* | |
| | *(dritter Versuch, 74 Sekunden Gesamtzeit)* „*Herrn Kaiser vom Bauträger abgesagt heute Mittag am Telefon.*" — „Durch. Aber das war Arbeit." *(genervt)* | ⚠️ |
| Sonne/Durchbruch | *(Tier 2)* „Ok, das ist schön. Aber der Weg dahin hat mich mehr gekostet als die Absage selbst." | ⚠️ |
| +1 Tag | „Ein Tag. Von dreißig. In dreißig Tagen ist der Rohbau fertig, was ist hier in dreißig Tagen?" | ⚠️ |
| Kosten-Frage | „Was hat es dich gekostet — **6.800 Euro Auftragsvolumen**, das hat es mich gekostet." *(tippt es)* „Ist das die Frage?" | ⚠️ |
| Befund | *„Du erkennst Glühendes sofort. Dein Engpass liegt nicht im Entscheiden, sondern im Wegräumen."* — „Hä. Ich hab einen Stein angeleuchtet und jetzt weiß die App, wo mein Engpass ist? Bisschen dick." *(tippt „Stimmt nicht")* | ⚠️ |
| Share | *(schaut nicht mal hin)* | ❌ |
| Nächstes Öffnen | *(öffnet nicht wieder)* | ❌ |

**Würde ich morgen wiederkommen? 3/10.**
> „Der Durchbruch war stark, das nehm ich mit. Aber ich schreib nicht jeden Tag einen Aufsatz über meinen Arbeitstag. Wenn ich reinsprechen könnte, wäre das eine ganz andere Nummer."

**Was hätte ich ohne Levmi heute nicht getan?**
> „Die Absage. Aber ehrlich: die hätte ich diese Woche eh gemacht. Die App hat sie um vielleicht drei Tage vorgezogen. Das ist mir 74 Sekunden Tippen nicht wert."

---

## 4. Sabine, 52 — Steuerberaterin, Kanzleiführung

**Kontext:** iPad-Nutzerin, hier auf dem iPhone 14, Sonntagvormittag am Küchentisch. **Reduce Motion ist systemweit aktiviert** (Migräne). Liest 30 Sachbücher im Jahr. Hat bei „Gamification" einen Reflex.

| Schritt | Think-Aloud | |
|---|---|---|
| Erste Minute | *(Reduce Motion: Dolly-In wird zum Schnitt)* „Ein Punkt auf schwarzem Grund. Ich soll etwas tun, aber es steht nirgends, was." *(wartet 6 Sekunden — sie ist geduldiger als die anderen)* „Ich probiere: ziehen." *(funktioniert)* | ⚠️ |
| | *(Insel, Kamerafahrt fehlt wegen Reduce Motion, harter Schnitt)* **„Das ist sprunghaft. Aber immerhin respektiert die App meine Einstellung — das ist bei so etwas selten."** | ✅ |
| Knoten | „Drei Objekte, unterschiedlich beleuchtet und beklungen. Der linke singt sauber, der mittlere brummt, der rechte flackert und hat — ist das eine Sanduhr? Dann weiß ich ja schon, dass ich ihn nicht nehmen soll." | ⚠️ |
| | „Wenn Sie mir die Falle beschriften, ist es keine Falle mehr, sondern ein Test, den ich bestehen soll. Ich nehme den Singenden." | ⚠️ |
| Setzen/Wurzeln | *(hält, Einschlag, Wurzeln unter dem Nebel — bei Reduce Motion nur ein Überblenden)* „Ich sehe: unten wächst etwas, oben nicht. Die Metapher verstehe ich. Sie ist gut." | ✅ |
| Durchbruch | *(gedämpft, ohne Kamerafahrt, aber mit Haptik und Sound)* „Angenehm. Nicht kitschig. Ich hatte etwas Infantileres erwartet." | ✅ |
| Onboarding | „‚Was nervt dich gerade am meisten' — sechs Kacheln. Zeit weg. Immer erreichbar. Alles hängt an mir." *(wählt drei)* „Ich merke gerade, dass ich das noch nie so klar aufgeschrieben habe." | ✅ |
| Umkehr | *(Reduce Motion: kein Flip, die Kachel wechselt den Text)* **„Da war offenbar ein Effekt geplant. Bei mir tauscht sich nur der Text aus. Das ist ein bisschen enttäuschend, ich vermute, ich verpasse gerade den Moment, den die Entwickler gemeint haben."** | ⚠️ |
| „Wofür?" | „Wofür — die Frage ist unvollständig. Wofür was?" | ⚠️ |
| | **„Und der wichtigere Punkt: Ich soll hier eine persönliche Antwort eintippen und nirgendwo steht, wo diese Daten liegen. Keine Datenschutzerklärung, kein Hinweis, kein Impressum. Ich bin berufsbedingt vorsichtig — ich schreibe hier nichts hinein."** *(Skip)* | ❌ |
| Absicht | „Drei Vorschläge. ‚Sag heute zu einer lauwarmen Sache ab, ein Satz, keine Begründung.' Der Satz ist gut. Er ist ausführbar und er ist klein." *(wählt ihn)* | ✅ |
| Wegschicken | *„Für heute reicht's. Die Wurzeln arbeiten."* — **„Das ist der Moment, in dem ich dieses Produkt ernst zu nehmen beginne.** Eine App, die aufhört. Das habe ich in dieser Kategorie noch nie gesehen." | ✅ |
| Rückkehr | *(Montag, 18:00 — sie hat eine Mandatsanfrage abgelehnt)* „Meine Absicht steht da, in der Formulierung von gestern. Ordentlich." | ✅ |
| Beweis | „*Mandatsanfrage Bauunternehmen heute 11:00 abgelehnt, telefonisch, ohne Alternativvorschlag.*" *(34 Sekunden)* „Der Zeichenzähler ist gut, ich weiß, wann ich fertig bin." | ✅ |
| | „Aber wieder: Ich schreibe hier Mandantenbezüge hinein. **Ohne einen Satz darüber, dass das lokal bleibt, würde ich das nicht tun.** Ich tue es jetzt, weil das ein Test ist." | ⚠️ |
| Sonne/Durchbruch | „Die Sonne aufziehen ist eine schöne Geste. Der Zusammenhang Handlung → Wachstum ist eindeutig." | ✅ |
| +1 Tag / 1/30 | „Ein Tag von dreißig. Also ein 30-Tage-Programm. Das hat mir niemand gesagt. **Wenn Sie mich in einen Dreißig-Tage-Vertrag stecken, sagen Sie es mir vorher.**" | ⚠️ |
| Kosten-Frage | „‚Was hat es dich gekostet' — Sie meinen vermutlich emotional. Ich lese zuerst monetär, das ist mein Beruf. *Etwa 12.000 Euro Jahresumsatz, und ein unangenehmes Telefonat.*" | ⚠️ |
| Befund | *„Du erkennst Glühendes sofort. Dein Engpass liegt nicht im Entscheiden, sondern im Wegräumen."* | ⚠️ |
| | **„Das ist Barnum. Der Satz passt auf jede Führungskraft in Deutschland. Und er basiert auf einer einzigen Berührung eines Kristalls und drei angetippten Kacheln. Ich weiß, wie eine belastbare Aussage entsteht, und das ist keine."** *(tippt „Stimmt")* „Er trifft trotzdem. Das ärgert mich noch mehr." | |
| Share | „Nein. Ich teile keine Selbstdiagnosen." | ❌ |
| Nächstes Öffnen | *(Skip beim „Wofür?" → sie hat nur den Beweis als eigenen Satz)* „*Du hast geschrieben: Mandatsanfrage Bauunternehmen…*" — „Das ist eine Wiedervorlage. Die kenne ich. Sie funktioniert." | ✅ |

**Würde ich morgen wiederkommen? 5/10.**
> „Ich komme wieder, weil der Wegschick-Moment und der Beweis-Zusammenhang seriös sind. Ich bleibe nicht, solange mir niemand sagt, wo meine Sätze liegen, und solange die App so tut, als hätte sie mich nach vier Minuten analysiert."

**Was hätte ich ohne Levmi heute nicht getan?**
> „Nichts. Die Mandatsanfrage hätte ich auch so abgelehnt, das ist Routine. Was Levmi getan hat: Es hat mich die Ablehnung **aufschreiben** lassen. Das ist nicht nichts — aber es ist auch keine Verhaltensänderung."

---

## 5. Jonas, 23 — Student, TikTok-Generation

**Kontext:** iPhone 12, 14:50 in der Bib, Ton an über AirPods. Erwartet Wow in 3 Sekunden. Hat 14 Spiele auf dem Handy, spielt drei. Screenshottet alles, was gut aussieht.

| Schritt | Think-Aloud | |
|---|---|---|
| Erste Minute | „Schwarz… schwarz… komm schon." *(1,5 Sekunden — er ist bei 3 Sekunden raus)* *(Lichtpunkt + Subbass)* „Ok ok ok, das ist ein Vibe." | ✅ |
| | *(wischt sofort und wild)* „Was geht — oh, er folgt. Ich zieh ihn runter." *(Insel)* **„OKAY das ist sick. Screenshot."** | ✅ |
| Knoten | „Drei Kristalle. Einer singt. Ich nehm natürlich den, der komisch flackert, weil ich wissen will, was kaputt geht." | ✅ |
| | *(Licht wird gefressen)* *„Das Lauwarme hat dein Licht gefressen."* — „HA. Ok, gut. Fair. Nochmal." | ✅ |
| Sonne | „Sonne hochziehen. Warum weiß ich das. Weil ich das schon zweimal gemacht hab. Gutes Design eigentlich." | ✅ |
| Durchbruch | *(Kristall, Partikelburst, Akkord)* **„OK DAS IST DER SHOT.** Screenshot. Das post ich." | ✅ |
| Onboarding | „Oh nein, Text." *(scannt die sechs Kacheln in 2 Sekunden)* „Kein Fortschritt. Zeit weg. Fertig." | ⚠️ |
| Umkehr | *(Flip)* „Ohhh, ok, das ist der Move. Das ist der TikTok-Moment. **Das** wäre mein Post, nicht der Kristall." | ✅ |
| „Wofür?" | *(sieht ein Textfeld)* „Nope. Skip." *(0,8 Sekunden)* | ⚠️ |
| Absicht | „Sag heute zu einer lauwarmen Sache ab… ok, whatever, ja." *(wählt den ersten Vorschlag, ohne die anderen zu lesen)* | ⚠️ |
| Wegschicken | *„Für heute reicht's."* — **„WAS. Nein. Das war noch nicht mal fünf Minuten. Wo ist Level 2?"** | ❌ |
| | *(sucht nach einem Weiter-Button, findet keinen)* „Es gibt keine Punkte, kein Level, keine Coins, keinen Streak, kein nichts. Was **ist** das? Ein Screensaver mit Hausaufgaben?" | |
| | *(schließt die App)* *(öffnet sie 20 Sekunden später wieder — die Grafik zieht ihn)* — *„Noch nicht. Die Wurzeln arbeiten."* — „Also wirklich gar nichts. Ok, tschüss." | ❌ |
| Rückkehr | *(kommt nicht wieder)* | ❌ |
| Beweis | *(nicht erreicht)* | — |
| Sonne / Durchbruch 2 / +1 Tag / Kosten / Befund | *(nicht erreicht)* | — |
| Share | *(nicht erreicht — er hätte als Einziger geteilt)* | ❌ |
| Nächstes Öffnen | *(nicht erreicht)* | — |

**Würde ich morgen wiederkommen? 2/10.**
> „Die ersten 60 Sekunden waren die schönsten 60 Sekunden, die ich diesen Monat auf dem Handy hatte. Dann war Schluss und ich hab nichts zurückbekommen. Ich hab einen Screenshot und kein Spiel."

**Was hätte ich ohne Levmi heute nicht getan?**
> „Nichts. Ich hab zwei Screenshots. Ich hätte was gepostet, wenn das Ding mich gelassen hätte — hat es aber nicht, weil der Teilen-Knopf hinter einer Aufgabe liegt, die ich nie mache."

---

# Teil B — Der Researcher-Blick

---

## 3. Heatmap der Abbruchpunkte

Skala pro Schritt: ❌ = harter Ausstieg oder Beinahe-Ausstieg · ⚠️ = Stolperer, kostet Vertrauen oder Zeit · ✅ = trägt.

| # | Schritt | Markus | Lena | Tobias | Sabine | Jonas | Verlust |
|---|---|:---:|:---:|:---:|:---:|:---:|---|
| 1 | **Erster Griff (Licht in den Nebel ziehen)** | ⚠️ | ⚠️ | ❌ | ⚠️ | ✅ | **4 von 5 stolpern, 1 fast raus** |
| 2 | Insel erscheint / Kamera | ✅ | ✅ | ✅ | ✅ | ✅ | 0 |
| 3 | Knoten lesen (ohne Ton / klein) | ⚠️ | ✅ | ⚠️ | ⚠️ | ✅ | 3 |
| 4 | **Langer Druck (Affordance)** | ✅ | ⚠️ | ⚠️ | ✅ | ✅ | 2 |
| 5 | Wurzeln unter dem Nebel | ✅ | ✅ | ✅ | ✅ | ✅ | **0 — trägt bei allen** |
| 6 | Sonne + Durchbruch Tier 1 | ✅ | ✅ | ✅ | ✅ | ✅ | **0 — trägt bei allen** |
| 7 | Hass-Kacheln | ✅ | ✅ | ✅ | ✅ | ⚠️ | 1 |
| 8 | Umkehr-Animation | ✅ | ✅ | ⚠️ | ⚠️ | ✅ | 2 (davon 1× Reduce Motion) |
| 9 | **„Wofür?"** | ⚠️ | ✅ | ⚠️ | ❌ | ⚠️ | **4 von 5, 3× geskippt** |
| 10 | Absicht wählen | ✅ | ⚠️ | ✅ | ✅ | ⚠️ | 2 |
| 11 | „Für heute reicht's" | ✅ | ✅ | ⚠️ | ✅ | ❌ | **1 harter Abbruch, sonst stärkster Moment** |
| 12 | **Rückkehr während der Sperre** | ❌ | — | — | — | ❌ | **2 von 3, die es versuchen** |
| 13 | **Beweis tippen (≥ 40 Zeichen)** | ✅ | ✅ | ❌ | ⚠️ | — | **1 Abbruch, 74 s Spitzenzeit** |
| 14 | Sonne + Durchbruch Tier 2 | ✅ | ✅ | ⚠️ | ✅ | — | 1 |
| 15 | **„+1 Tag" / Balken 1 von 30** | ⚠️ | ⚠️ | ⚠️ | ⚠️ | — | **4 von 4, die ihn sehen** |
| 16 | **„Was hat es dich gekostet?"** | ⚠️ | ✅ | ⚠️ | ⚠️ | — | **3 von 4 lesen „Euro"** |
| 17 | Befund | ✅ | ✅ | ⚠️ | ⚠️ | — | 2 |
| 18 | **Share-Card** | ❌ | ⚠️ | ❌ | ❌ | ❌ | **5 von 5 teilen nicht** |
| 19 | Eigener Satz beim nächsten Öffnen | ✅ | ✅ | — | ✅ | — | **0 — trägt bei allen, die ankommen** |

### Die drei teuersten Stellen

**Platz 1 — Der erste Griff (Schritt 1).** Vier von fünf zögern zwischen 2 und 6 Sekunden, einer war einen Wisch vom Löschen entfernt. Das ist der teuerste Punkt, weil er **vor** allem liegt, was gut ist. Jede Sekunde hier verliert dir den ganzen Rest. Und er ist gleichzeitig der billigste zu reparieren.

**Platz 2 — Die Sperre bei der Rückkehr (Schritt 12).** *„Noch nicht. Die Wurzeln arbeiten."* ohne Zeitangabe ist eine Sackgasse. Markus **hatte die Handlung bereits ausgeführt** und wurde weggeschickt. Das ist die schlimmste Variante: Du bestrafst genau den Nutzer, der das tut, was das ganze Produkt will. Die 60-Minuten-Sperre soll Anticipation erzeugen — sie erzeugt sie beim Enthusiasten und verhindert nichts beim Schummler, der einfach 61 Minuten wartet.

**Platz 3 — Die Share-Card (Schritt 18).** Fünf von fünf teilen nicht. Der einzige, der geteilt hätte, erreicht sie strukturell nie, weil sie hinter Beweis und Sperre liegt. Damit ist der **einzige Wachstumsmechanismus im PoC untestbar** — und das war laut Synthese 8.1 ausdrücklich der Grund, ihn einzubauen.

### Was komplett durchträgt (nicht anfassen)

- **Wurzeln unter dem Nebel** (5/5) — die Metapher funktioniert ohne ein einziges Wort, sogar ohne Ton und mit Reduce Motion.
- **Der Durchbruch** (5/5) — bei allen fünf der körperliche Höhepunkt. Haptik trägt hier mehr als die Grafik.
- **„Für heute reicht's"** (4/5 positiv, davon 3× als *bester Moment der ganzen Session* genannt) — das ist dein Produktversprechen, nicht deine Grafik.
- **Der eigene Satz beim nächsten Öffnen** (3/3, die ihn erreichen) — funktioniert genau so, wie Memo 02 es versprochen hat.

---

## 4. Top-5-Änderungen für heute Nacht

Priorisiert nach Wirkung × Umsetzbarkeit. Alle fünf sind in **unter drei Stunden** zusammen machbar und berühren keine Architekturentscheidung.

---

### Ä1 — Geste-Hinweis in den ersten Sekunden *(Wirkung: sehr hoch · Aufwand: ~30 Min)*

**Problem:** Vier von fünf wissen nach 2 Sekunden nicht, was sie tun sollen. Synthese 7.3 („Versteht ein Fremder ohne Beschriftung in 60 Sekunden, was er tun soll?") ist damit **nicht bestanden**.

**Lösung, drei Stufen, ohne Text:**
1. Nach **1,5 s** Untätigkeit: Der Lichtpunkt atmet leicht (Scale 1.0 → 1.08, 1,2 s Loop).
2. Nach **3 s**: Eine dünne, gebogene Partikelspur zeichnet sich vom Punkt nach unten in den Nebel und verblasst. Wiederholung alle 3 s.
3. Nach **7 s**: Erst jetzt ein Text, klein, unten:

> **„Zieh das Licht in den Nebel."** *(6 Wörter)*

**Gleiches Muster beim Knoten** (Tobias tippte fünfmal): Sobald der Finger den Knoten berührt, beginnt der Ring sofort sichtbar zu füllen — auch bei einem 100-ms-Tap füllt er 10 % und fällt sichtbar zurück. Das lehrt „halten" in einem einzigen Fehlversuch, ohne ein Wort. Fallback nach zwei abgebrochenen Taps:

> **„Halten, bis der Ring voll ist."** *(6 Wörter)*

**Warum zuerst:** Es ist die einzige Änderung, die *alle* anderen Ergebnisse verbessert, weil sie vor allem anderen liegt.

---

### Ä2 — „Bleibt auf deinem Gerät." unter jedes Freitextfeld *(Wirkung: hoch · Aufwand: ~10 Min)*

**Problem:** Sabine bricht am „Wofür?" ab, Markus skippt es mit derselben Begründung. Die App verlangt in vier Minuten drei persönliche Freitexte (Wofür, Beweis, Kosten) und sagt kein einziges Mal, wo die landen. Dass es laut Synthese 5 lokal bleibt, weiß nur ihr.

**Lösung:** Ein Label, 12 pt, 60 % Deckkraft, unter jedem Textfeld:

> **„Bleibt auf deinem Gerät."** *(4 Wörter)*

**Bonus, den du gratis mitnimmst:** Memo 04 nennt On-Device-Privacy als einen der fünf Hebel für Apple-Featuring. Dieses Label ist die günstigste Zeile Code im ganzen Projekt gemessen an ihrer Wirkung.

---

### Ä3 — Die Sperre bekommt eine Uhrzeit *(Wirkung: hoch · Aufwand: ~20 Min)*

**Problem:** Markus hatte gehandelt und wurde ohne Information weggeschickt. Er kam nur durch Zufall zurück.

**Lösung, zwei Zeilen statt einer:**

> **„Die Wurzeln arbeiten."** *(3 Wörter)*
> **„Zurück ab 14:20."** *(3 Wörter)*

Eine **Uhrzeit ist kein Verlust-Countdown** und verletzt Ethik-Regel 3 aus Memo 02 nicht — es wird nichts weggenommen, es wird nur gesagt, wann es weitergeht. Ein rückwärts laufender Timer wäre die verbotene Variante; nimm die Uhrzeit.

**Dazu, gleiches Paket:** Beweisfeld mit drei Mikro-Prompts als Platzhalter statt eines Fehlerhinweises danach:

> **„Wer? Wann? Was ist passiert?"** *(5 Wörter)*

Tobias' 74 Sekunden entstanden dadurch, dass er zweimal abgelehnt wurde. Der Hinweis muss **vor** dem Tippen stehen, nicht danach. Das ist die günstigste Maßnahme für Go/No-Go-Kriterium 4 (Beweis unter 45 s).

**Was ich heute Nacht NICHT machen würde**, obwohl es naheliegt: einen „Ich habe es getan"-Knopf, der die Sperre überspringt. Er würde Markus retten und gleichzeitig die Anticipation-Lücke aus Memo 02 (2.3) aufweichen, bevor du sie ein einziges Mal gemessen hast. Erst messen, dann aufweichen.

---

### Ä4 — Der lauwarme Knoten darf nicht beschriftet sein *(Wirkung: hoch · Aufwand: ~45 Min)*

**Problem, zwei Teile:**

*Teil 1:* Der lauwarme Knoten trägt laut Spec einen **Sanduhr-Puls** — also ein Warnsymbol. Sabine erkennt die Falle sofort und weicht aus. Eine Falle, die sich selbst beschriftet, lehrt nichts. Der lauwarme Knoten muss verführerisch aussehen, sonst ist er kein Test, sondern ein Quiz.

*Teil 2, der teurere:* Wer den glühenden Knoten zuerst setzt — und das tun die meisten, weil er glüht und singt —, **erlebt den Kernsatz „Das Lauwarme hat dein Licht gefressen" nie.** Damit fehlt der einzige Lernmoment der einzigen Station. Und der Befund fällt in die dritte Variante zurück, die aus einer einzigen Berührung eine Diagnose macht. Genau daran ist Sabine hängengeblieben („Das ist Barnum").

**Lösung:**
1. Der lauwarme Knoten leuchtet **bis zur Setzung genauso warm** wie der singende. Unterschied nur im Ton (schwebendes Detune) und in einem leicht unregelmäßigen Puls. **Die Sanduhr erscheint erst beim Aufsaugen** — als Konsequenz, nicht als Warnung.
2. In der Tutorial-Nacht `lightsPerNight = 2`. Der Spieler darf zweimal setzen. Damit steigt die Wahrscheinlichkeit, dass er den Lernmoment erlebt, von etwa einem Drittel auf über zwei Drittel — und der Befund hat plötzlich zwei Datenpunkte statt einem.

**Achtung Testplan:** `GameEngineTests` Regel 3 und `RulesTests` prüfen `lightsPerNight = 1`. Diese Änderung berührt zwei bestehende Tests. Entscheide sie jetzt, nicht um 4 Uhr.

---

### Ä5 — Eine Share-Karte, die vor dem Beweis liegt *(Wirkung: hoch für die Wachstumsfrage · Aufwand: ~30 Min)*

**Problem:** Fünf von fünf teilen die Befund-Karte nicht. Zwei Gründe, beide strukturell:
- Sie zeigt eine **Selbstdiagnose**. Niemand postet seine Schwäche. Lena: „Ich teil ungern meine Schwächen auf Instagram."
- Sie liegt **hinter** Beweis und Sperre. Der einzige Nutzer mit Teil-Reflex (Jonas) kommt nie dort an.

**Lösung:** Zusätzlich zur Befund-Karte eine zweite, die **direkt nach der Umkehr-Animation** angeboten wird — dem Moment, den vier von fünf spontan als schön bezeichnet haben. Inhalt: die umgedrehten Kacheln als Karte („Deine Zeit gehört dir." / „Alles hängt an mir." → das Gegenteil), Inselfarbe im Hintergrund, Wortmarke klein. Positiv, ohne Beichte, ohne Beweis.

`ImageRenderer` + `ShareLink` baust du für die Befund-Karte ohnehin — das ist derselbe Code mit anderem Inhalt.

**Und eine Sache, die dich nichts kostet:** Auf beide Karten gehört ein sichtbarer Weg zurück zur App (Wortmarke plus `levmi.app` oder ein kleiner Code). Eine Share-Card ohne Rückweg ist ein Screenshot, kein Kanal.

---

### Knapp verpasst — aber vor dem Release fällig

| # | Änderung | Warum nicht in den Top 5 | Aufwand |
|---|---|---|---|
| Ä6 | **Reduce-Motion-Pfad:** Kamerafahrten → Crossfade, Flip → schnelles Cross-Dissolve mit Haptik. Der Umkehr-Moment darf nicht ersatzlos ausfallen. | Betraf in dieser Runde nur 1 von 5 — ist aber ein **Release-Blocker** und laut Memo 04 ein Featuring-Hebel. | ~30 Min |
| Ä7 | **„1 von 30" streichen.** „+1 Tag" groß, darunter die gesunkene Nebelkante. Ein erster Fortschrittsbalken bei 3 % demotiviert. Falls ein Balken sein muss: **1/7**, „Deine erste Woche". | Vier von vier fanden es irritierend, keiner ist daran abgebrochen. | ~10 Min |
| Ä8 | **Attribution sichtbar machen.** „Der Schnitt" geht auf Derek Sivers zurück, das ist IP-frei und steht bereits im Schema. Zwei von fünf (Markus, Sabine) vermissen aktiv die Herkunft. Eine Zeile, eine Geste tief: **„Nach Derek Sivers."** *(3 Wörter)* | Erhöht Vertrauen, rettet aber niemanden, der schon abgesprungen ist. | ~15 Min |
| Ä9 | **Reset-Knopf im DEBUG-Build.** Ohne ihn kannst du den Dreimal-Test aus Synthese 7.1 morgen früh **gar nicht durchführen** — nach dem Durchbruch kommt Onboarding und dann „Für heute reicht's". Es gibt keinen zweiten Durchlauf. | Kein Nutzer-, sondern ein Test-Problem. Aber es blockiert eines deiner vier Go/No-Go-Kriterien. | ~15 Min |

---

## 5. Das Textblatt — alle Formulierungen an einem Ort

Regel: **max. 8 Wörter pro Zeile.** Mehrzeiliges ist als eigene Zeile ausgewiesen.

| Stelle | Heute | Vorschlag | Warum |
|---|---|---|---|
| Erster Griff (nach 7 s) | *(kein Text)* | **„Zieh das Licht in den Nebel."** | 4 von 5 wissen es nicht |
| Knoten (nach 2 Fehltaps) | *(kein Text)* | **„Halten, bis der Ring voll ist."** | Tobias tippte fünfmal |
| Unter jedem Textfeld | *(nichts)* | **„Bleibt auf deinem Gerät."** | Sabines Abbruchgrund |
| „Wofür?" | „Wofür?" | **„Wenn das wahr wäre — was wäre anders?"** *(7 Wörter)* | 3 von 5 verstehen die Frage nicht; das ist die Formulierung aus Memo 02, 2.5 |
| Wegschicken, Zeile 1 | „Die Wurzeln arbeiten. Komm zurück, wenn du es getan hast." *(10 Wörter, zu lang)* | **„Die Wurzeln arbeiten."** | Bricht auf zwei Zeilen |
| Wegschicken, Zeile 2 | — | **„Komm zurück, wenn du's getan hast."** *(6 Wörter)* | |
| Sperre, Zeile 1 | „Noch nicht. Die Wurzeln arbeiten." | **„Die Wurzeln arbeiten."** | „Noch nicht" ist eine Abfuhr ohne Ausweg |
| Sperre, Zeile 2 | — | **„Zurück ab 14:20."** | Markus' Abbruchgrund |
| Beweisfeld, Platzhalter | *(Hinweis kommt erst nach Ablehnung)* | **„Wer? Wann? Was ist passiert?"** | Spart Tobias zwei Fehlversuche |
| Beweis abgelehnt | „Konkreter: Wer, wann, was ist passiert?" | *(bleibt, wird aber selten gebraucht)* | |
| Absicht (nach 20 Uhr) | „klein genug für heute" | **„Klein genug für morgen früh."** *(4 Wörter)* | Lena um 23:14: „Ich kann heute niemandem mehr absagen" |
| Kosten-Frage | „Was hat es dich gekostet?" | **„Was war unangenehm daran?"** *(4 Wörter)* | 3 von 4 antworten in Euro |
| Fortschritt | „+1 Tag", Balken 1/30 | **„+1 Tag"** *(Balken streichen oder 1/7)* | 4 von 4 irritiert |
| Attribution (eine Geste tief) | *(fehlt in der UI)* | **„Nach Derek Sivers."** | 2 von 5 fragen nach der Herkunft |
| Interne Bezeichnung „Befund" | — | **Taucht niemals als Überschrift auf.** Nur der Satz, ohne Label. | „Befund" ist Arztbrief-Deutsch; der Satz wirkt stärker allein |

Unverändert stark, nicht anfassen: **„Du hast ein Licht."** · **„Das Lauwarme hat dein Licht gefressen."** · **„Für heute reicht's."** · **„Stimmt / Stimmt nicht."**

---

## 6. Was die fünf einte — und wo sie sich widersprechen

### 6.1 Einigkeit (das ist dein Fundament)

1. **Der Wegschick-Moment ist das Produkt.** Drei von fünf nannten „Für heute reicht's" spontan als besten Moment der Session — vor der Grafik, vor dem Durchbruch. Sabine: „Das ist der Moment, in dem ich dieses Produkt ernst zu nehmen beginne." Markus: „Jede andere App will jetzt meine E-Mail." **Das ist deine Positionierung, nicht dein Rendering.** Wenn du morgen einen Satz für den App Store brauchst, kommt er aus dieser Zeile.
2. **Körper vor Auge.** Haptik und Sound wurden häufiger positiv erwähnt als Bloom, Nebel und Spiegelung zusammen. Memo 06, Punkt 6 („Haptik und Sound sind Kern-Feature, nicht Polish") ist bestätigt. Der Durchbruch trug bei allen fünf — auch bei Ton aus und bei Reduce Motion.
3. **Die Wurzel-Metapher braucht keine Sprache.** Fünf von fünf verstanden „unten wächst etwas, oben noch nicht" ohne einen einzigen Erklärtext. Das ist selten und wertvoll.
4. **Niemand fand den ersten Griff von allein flüssig.** Fünf von fünf zögerten, vier von fünf spürbar.
5. **Niemand teilte freiwillig.** Fünf von fünf. Deine Wachstumsannahme ist in dieser Runde ohne Gegenbeweis durchgefallen.
6. **Der Diagnose-Satz war der stärkste Text im ganzen Produkt.** Auch bei Sabine, die ihn methodisch zerlegt hat und ihn trotzdem angenommen hat. Das stützt die These aus Memo 04: Levmi ist ein **Diagnose-Instrument mit außergewöhnlicher Oberfläche**, kein Spiel. Der Befund gehört näher an den Anfang, nicht ans Ende — aber erst, wenn er auf mehr als einem Tap steht (siehe Ä4).

### 6.2 Widersprüche (hier musst du dich entscheiden)

| Frage | Markus (44) | Lena (29) | Tobias (36) | Sabine (52) | Jonas (23) |
|---|---|---|---|---|---|
| Zahlen | genau eine (Tage) | will einen Streak | will Euro | will gar keine | will XP/Level |
| Sitzungslänge | 4 Min ist perfekt | 4 Min ist zu wenig | 4 Min ist zu viel | 4 Min ist angemessen | 4 Min ist ein Trailer |
| Texteingabe | akzeptiert (41 s) | schnell (28 s) | **Abbruch (74 s)** | akzeptiert (34 s) | verweigert (0,8 s) |
| Herkunft/Autorität | will die Quelle | egal | egal | **will die Quelle** | egal |
| Gamification | misstrauisch | liebt sie | egal | **ablehnend** | **braucht sie** |
| Teilen | nein | nur Positives | nein | nein | **ja, sofort** |

**Der harte Widerspruch: Jonas und Sabine sind nicht im selben Produkt unterzubringen.** Was Jonas hält (Punkte, Level, sofortige Fortsetzung, Streak-Druck), ist exakt das, was Sabine vertreibt — und es verletzt die Ethik-Regeln 1, 2 und 7 aus Memo 02. Das ist keine Balancing-Frage, das ist eine Produktentscheidung.

**Meine Empfehlung, deutlich:**

- **Ziel: Markus und Lena.** Sie tragen mit 7 und 8, und sie sind exakt die „Umsetzer 28–48" aus Synthese 8.3. Beide haben eine echte Handlung ausgeführt, die ohne Levmi nicht oder später passiert wäre. Das ist der einzige Beleg, der zählt.
- **Sabine ist mit zwei Textzeilen gewinnbar** (Ä2 Datenschutz, Ä8 Attribution) plus dem Reduce-Motion-Pfad. Sie ist die günstigste Verbesserung im ganzen Feld: von 5 auf geschätzt 7, für rund eine Stunde Arbeit. Sie ist außerdem die glaubwürdigste Empfehlerin von allen fünf — Führungskräfte empfehlen, was seriös wirkt.
- **Tobias ist nicht verloren, sondern vertagt.** Sein einziger echter Abbruchgrund ist die Texteingabe. Sprach-Beweis (Memo 02 nennt das explizit als „später") holt ihn zurück, und er bringt eine ganze Berufsgruppe mit. Nicht heute Nacht.
- **Jonas gibst du auf, und zwar bewusst und schriftlich.** Der Versuch, ihn zu halten, zerstört genau das, was Markus, Lena und Sabine überzeugt hat. Schreib das in die Entscheidungsdokumente, sonst baut es jemand in Monat vier trotzdem ein — Memo 02, Risiko 5, sagt genau das voraus.

**Die unbequeme Folge:** Wenn Jonas nicht die Zielgruppe ist, ist deine Share-Card ein Werkzeug für Menschen, die nicht teilen. Dann ist der PoC-Wachstumstest kein Test der Share-Card, sondern die Erkenntnis, dass Levmi über **Empfehlung im Gespräch** wächst, nicht über Screenshots. Das ändert Memo 04 nicht im Ergebnis (Lizenzpartner + Featuring), aber es entwertet die Share-Card als Wachstumshoffnung. Ä5 baust du trotzdem — als Messung, nicht als Strategie.

---

## 7. Prognose der Kennzahlen aus Memo 02, Abschnitt 6

**Unsicherheitswarnung vorab, ernst gemeint:** n = 5, simuliert, von mir konstruiert. Ich habe die Personas so gebaut, dass sie die Spec belasten — nicht als repräsentative Stichprobe. Jede Zahl unten ist eine **Größenordnung mit Vorzeichen**, keine Schätzung. Der belastbare Teil dieses Dokuments sind die Abbruchpunkte in Abschnitt 3, nicht diese Tabelle.

Ich trenne drei Populationen, weil sie sich um den Faktor 3 unterscheiden:
- **L (Labor):** deine 50 Tester aus der Community. Wohlwollend, kontextstark, kennen dich.
- **A (Alpha):** geworbene Fremde mit Interesse am Thema.
- **O (Offen):** App-Store-Traffic ohne Vorbindung.

| Metrik | Ziel Memo 02 | Prognose **heutiger** Ablauf | Prognose **mit Ä1–Ä5** | Unsicherheit |
|---|---|---|---|---|
| **Onboarding-Completion bis zur ersten Absicht** | ≥ 70 % | **L 55–70 % · A 35–50 % · O 25–40 %** | **L 75–85 % · A 55–70 % · O 40–55 %** | **mittel.** Der Abbruch liegt fast vollständig im ersten Griff — das ist eine gut isolierte Ursache. Ä1 sollte in der Alpha 15–25 Punkte bringen. |
| **Proof Rate (Nordstern), ≥ 1 Beweis in 7 Tagen** | ≥ 30 % | **L 25–40 % · A 12–22 % · O 6–14 %** | **L 35–50 % · A 18–30 % · O 8–18 %** | **hoch.** In meiner Runde: 3 von 5 lieferten einen Beweis (Markus, Lena, Sabine) = 60 %. Diese Zahl ist **zu gut**, weil alle fünf den Durchlauf zu Ende gespielt haben statt ihn zu vergessen. Das reale Loch ist nicht die Motivation, sondern der Tag dazwischen. |
| **D1** | 25–35 % Ø, 40 %+ stark | **L 35–50 % · A 20–30 % · O 12–22 %** | **L 45–60 % · A 28–38 % · O 18–28 %** | **hoch.** Größter Hebel ist Ä3 (Uhrzeit) — Markus wäre ohne Zufall nicht wiedergekommen, obwohl er gehandelt hatte. Das ist ein D1-Verlust bei einem hochmotivierten Nutzer. |
| Absicht → Beweis-Conversion | ≥ 40 % | 3 von 4, die eine Absicht wählten (Jonas ausgenommen) = **hoch, aber unbelastbar** | — | **sehr hoch.** Der Vorschlag „Sag heute zu einer lauwarmen Sache ab, ein Satz, keine Begründung" ist außergewöhnlich gut kalibriert (Fogg-Ability). Vier von fünf wussten **sofort**, auf wen er zutrifft. Das ist der stärkste einzelne Content-Befund dieser Runde. |
| Median Zeichen pro Beweis | > 60 | Markus 71 · Lena 78 · Sabine 79 · Tobias 56 → **Median ~75** | — | mittel. Erwachsene mit echtem Anlass schreiben von selbst genug. Der 40-Zeichen-Mindestwert ist richtig gesetzt. |
| Median Session-Länge | 2–5 Min | **~3,5 Min** — im Zielkorridor | — | niedrig. Die App schickt zuverlässig weg. |
| Zeit für den Beweis (Kriterium 7.4: < 45 s) | < 45 s | **28 / 34 / 41 / 74 s** → Median 38 s, aber **ein Ausreißer verursacht einen Abbruch** | mit Ä3-Prompts erwartet 25–45 s | mittel |

### Die Go/No-Go-Kriterien aus Synthese 7, vorab bewertet

| # | Kriterium | Heute | Mit Ä1–Ä5 |
|---|---|---|---|
| 1 | **Dreimal-Test** | **nicht durchführbar** — nach dem Durchbruch kommt Onboarding und „Für heute reicht's". Es gibt keinen zweiten Durchlauf (→ Ä9) | durchführbar |
| 2 | **Beweis-Test** („draußen getan, drinnen gewachsen") | **bestanden** — Markus und Lena sagen fast wörtlich den Zielsatz | bestanden |
| 3 | **Text-Aus-Test** (Fremder versteht in 60 s) | **nicht bestanden** — 5 von 5 zögern, 1 fast Abbruch | bestanden |
| 4 | **Hausaufgaben-Test** (< 45 s) | **grenzwertig** — Median 38 s, aber der Ausreißer bricht ab | bestanden |

**Stand heute: 1 sicher bestanden, 1 grenzwertig, 1 gescheitert, 1 nicht messbar.** Deine eigene Schwelle lautet „zwei von vier = Kern lebt". Du stehst damit **auf der Kippe, und zwar aus lauter reparierbaren Gründen** — keiner der vier Punkte scheitert am Loop selbst. Der Loop trägt. Die Verpackung der ersten zehn Sekunden und die Rückkehr tragen nicht.

### Die eine Frage, die Memo 02 stellt und die kein Dashboard beantwortet

*„Was hast du letzte Woche getan, das du ohne Levmi nicht getan hättest?"*

Aus dieser Runde:

| | Antwort | Wert |
|---|---|---|
| Markus | Makler-Absage, sechs Wochen aufgeschoben, in 4 Minuten erledigt | **echt** |
| Lena | Kundin abgesagt, sechs Wochen aufgeschoben | **echt** |
| Tobias | Absage um ~3 Tage vorgezogen | **schwach** |
| Sabine | nichts — „ich habe es nur aufgeschrieben" | **nichts** |
| Jonas | nichts — zwei Screenshots | **nichts** |

**Zwei von fünf mit einem echten Ergebnis.** Nach dem Maßstab von Memo 02 („Nennt keiner etwas, sind alle Zahlen darüber Dekoration") ist das **kein Scheitern**. Es ist das Minimum, das die These am Leben hält — und beide echten Fälle kommen aus derselben Zielgruppe, die Synthese 8.3 als Markt benennt.

Bemerkenswert und leicht zu übersehen: **Beide echten Fälle nannten denselben Auslöser** — nicht die Grafik, nicht den Durchbruch, sondern den Zusatz **„ein Satz, keine Begründung"** in der Absicht. Markus: „Der Teil ‚keine Begründung' war das, was es leicht gemacht hat." Wenn du morgen früh einen einzigen Content-Befund mitnimmst, dann den: **Der Wirkstoff sitzt im Handlungsvorschlag, nicht in der Szene.** Das verschiebt deinen Engpass von der 3D-Engine zum Content — genau dorthin, wo Memo 02, Risiko 2, ihn schon vermutet hat.

---

## 8. Zusammenfassung in fünf Zeilen

1. Der Loop trägt. Wurzeln, Durchbruch, Wegschicken und der eigene Satz funktionieren bei allen, die ankommen.
2. Es kommen zu wenige an, und zwar wegen der ersten drei Sekunden und der stummen Sperre — beides in unter einer Stunde reparierbar.
3. Die Falle ist beschriftet und der Kernsatz optional: Wer den glühenden Knoten wählt, lernt die einzige Lektion der einzigen Station nie.
4. Der Share-Mechanismus ist strukturell untestbar, weil er hinter dem Beweis liegt und eine Schwäche zeigt.
5. Zielgruppe schriftlich festlegen: Markus und Lena ja, Sabine mit zwei Textzeilen dazu, Tobias vertagen, Jonas bewusst aufgeben.
