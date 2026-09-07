# Levmi

**Finde deinen Hebel.** Ein iOS-Spiel zur Persönlichkeitsentwicklung: eine Insel im Nebelmeer, die nur aus dem wächst, was du im echten Leben getan hast.

> Status: Proof of Concept „Erste Nacht" (2026-09-07). Läuft im iOS-26-Simulator. Morgen-Übersicht mit Screenshots: https://claude.ai/code/artifact/2d8baa1b-978a-4ca6-8565-dae87b68a864 Details: [`docs/design/poc-spec.md`](docs/design/poc-spec.md), Entscheidungen: [`docs/strategy/06-synthese-entscheidungen.md`](docs/strategy/06-synthese-entscheidungen.md) und [`docs/decisions/`](docs/decisions/).

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

Installation per USB funktioniert auch mit iOS 27 und Xcode 26.6 (verifiziert am 2026-09-07, 11:25):

```bash
xcodebuild -project Levmi.xcodeproj -scheme Levmi -destination 'generic/platform=iOS' -configuration Debug -derivedDataPath .derived -allowProvisioningUpdates -allowProvisioningDeviceRegistration DEVELOPMENT_TEAM=NVN9F2C593 build
```

```bash
xcrun devicectl device install app --device B3E3E1E8-98AF-5B82-897A-54DE0E753CFB .derived/Build/Products/Debug-iphoneos/Levmi.app
```

Danach das Levmi-Icon auf dem iPhone antippen. Erscheint „Nicht vertrauenswürdiger Entwickler": Einstellungen → Allgemein → VPN & Geräteverwaltung → „Christian Simons" vertrauen. Debugging in Xcode (Breakpoints, Konsole) braucht weiterhin Xcode 27. Auf dem Gerät gibt es, anders als im Simulator, Haptik und 120 Hz.

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
