# Levmi

**Finde deinen Hebel.** Ein iOS-Spiel zur Persönlichkeitsentwicklung: eine Insel im Nebelmeer, die nur aus dem wächst, was du im echten Leben getan hast.

> Status: Proof of Concept „Erste Nacht" (2026-09-07). Läuft im iOS-26-Simulator. Details: [`docs/design/poc-spec.md`](docs/design/poc-spec.md), Entscheidungen: [`docs/strategy/06-synthese-entscheidungen.md`](docs/strategy/06-synthese-entscheidungen.md) und [`docs/decisions/`](docs/decisions/).

## So testest du morgen früh (Simulator, 3 Minuten)

Voraussetzung: Xcode 26.6, XcodeGen (`brew install xcodegen`, ist installiert).

```bash
cd ~/stage2/levmi && ./scripts/gen.sh && ./scripts/build.sh && ./scripts/run.sh
```

Das generiert das Xcode-Projekt, baut die App und startet sie im Simulator „iPhone 17". Kopfhörer aufsetzen: Der Sound trägt im Simulator die Hälfte des Erlebnisses, weil es dort keine Haptik gibt.

**Demo-Modus:** oben rechts der kleine Schalter (nur in Debug-Builds). Er verkürzt nur Zeitkonstanten (Sperre 60 Min → 30 s, Rückspiel 1 Tag → 1 Min), schaltet keine Regel ab. Damit spielst du den kompletten Loop in unter vier Minuten: erste Minute → Onboarding → Absicht → „Für heute reicht's" → 30 s warten → zurück → Beweis → Sonne hochziehen → Durchbruch → +1 Tag → Kosten-Frage → Befund → Teilen → beim nächsten Öffnen dein eigener Satz.

**Der Go/No-Go-Test** (nicht „gefällt es dir"): Spielst du den 30-Sekunden-Loop dreimal ungefragt (Knopf „Neu" oben rechts setzt zurück)? Fühlst du nach dem Beweis „draußen getan, drinnen gewachsen"? Versteht ein Fremder ohne Text, was zu tun ist? Dauert der Beweis unter 45 Sekunden?

**Die These prüfst du nur im Echt-Modus** (Demo aus): Spiel die erste Minute, wähl eine Absicht, die du heute wirklich tun kannst, lass dich wegschicken. Die Tür öffnet sich 10 Minuten nach der Absicht (nach 20 Uhr: um 06:00). Tu die Sache. Komm zurück, schreib den Beweis, zieh die Sonne hoch. Wenn sich das anfühlt wie „draußen getan, drinnen gewachsen", lebt der Kern. Der Demo-Modus ist ein Vorführwerkzeug für andere, kein Test der These.

**Bedienung ohne Worte:** Licht nach unten in den Nebel ziehen · Knoten gedrückt halten, bis der Ring voll ist (zwei Lichter pro Nacht, lauwarme Knoten fressen das Licht) · Sonne nach oben ziehen.

Alternativ in Xcode: `open Levmi.xcodeproj`, Scheme `Levmi`, Ziel „iPhone 17", ⌘R.

## Auf deinem iPhone

Dein iPhone 15 Pro Max läuft iOS 27.0. Xcode 26.6 kann darauf nicht installieren (fehlende Device-Support-Dateien). Dafür brauchst du Xcode 27 (Release Candidate oder Beta von developer.apple.com) und rund 100 GB freien Speicher; aktuell sind 45 GB frei. Danach: iPhone per Kabel anschließen, in Xcode das Team „ImmoDigit GmbH" (NVN9F2C593) wählen, Gerät als Ziel, ⌘R, auf dem iPhone unter Einstellungen → Allgemein → VPN & Geräteverwaltung dem Entwicklerzertifikat vertrauen. TestFlight geht erst mit einem Apple-Distribution-Zertifikat und einem App-Store-Connect-Eintrag.

## Struktur

```
project.yml              XcodeGen-Spec (Wahrheit; Levmi.xcodeproj wird generiert und ist ignoriert)
Levmi/                   App: App/ (AppModel), Scene/ (SceneKit-Welt), UI/ (SwiftUI-Overlays), Feedback/ (Haptik, prozeduraler Sound)
Packages/LevmiCore/      reine Domain (nur Foundation): Content, Mastery, Reducer, Beweis, Tage, Persistenz; Swift-Testing-Suite
LevmiUITests/            ein Smoke-Test
scripts/                 gen · build · test-core · test-ui · run · shot
docs/strategy/           Briefing, fünf Experten-Memos, Synthese, Red-Team-Kritik, simulierte Nutzerbefragung
docs/design/             PoC-Spezifikation (Vertrag zwischen Tests und Code)
docs/decisions/          ADR-Log
docs/screens/            Screenshots der Schlüsselmomente
```

## Entwicklung

```bash
./scripts/test-core.sh      # Domain-Tests, ~8 s, ohne Simulator
./scripts/build.sh          # Simulator-Build, Log in .derived/build.log
./scripts/run.sh            # installieren und starten
./scripts/shot.sh out.png   # Screenshot
./scripts/test-ui.sh        # UI-Smoke-Test im Simulator
```

Regeln: `LevmiCore` importiert nur Foundation. Kein SceneKit-Typ außerhalb von `Levmi/Scene/`. Content kommt aus JSON, nie aus Swift-Literalen. Tests zuerst (siehe ADR 04). Kein Buchtext, kein Autorname, keine Zahl „43" im Produkt (ADR 03).
