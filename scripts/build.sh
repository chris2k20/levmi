#!/usr/bin/env bash
# Baut die App für den Simulator. Ausgabe wird gefiltert; volles Log in .derived/build.log
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh
mkdir -p "$DERIVED"
set -o pipefail
xcodebuild -project Levmi.xcodeproj -scheme "$SCHEME" -destination "$DEST" \
  -derivedDataPath "$DERIVED" -configuration Debug \
  CODE_SIGNING_ALLOWED=NO build 2>&1 | tee "$DERIVED/build.log" \
  | grep -E "error:|warning: .*Levmi/|BUILD (SUCCEEDED|FAILED)|\*\* " || true
grep -q "BUILD SUCCEEDED" "$DERIVED/build.log"
