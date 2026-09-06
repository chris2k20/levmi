#!/usr/bin/env bash
# UI-Smoke-Tests im Simulator.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh
mkdir -p "$DERIVED"
set -o pipefail
xcodebuild -project Levmi.xcodeproj -scheme "$SCHEME" -destination "$DEST" \
  -derivedDataPath "$DERIVED" -only-testing:LevmiUITests \
  CODE_SIGNING_ALLOWED=NO test 2>&1 | tee "$DERIVED/test-ui.log" \
  | grep -E "error:|Test Case|passed|failed|\*\* " || true
grep -q "TEST SUCCEEDED" "$DERIVED/test-ui.log"
