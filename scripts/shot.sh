#!/usr/bin/env bash
# Screenshot des Simulators: scripts/shot.sh [datei.png]
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh
OUT="${1:-$DERIVED/shot-$(date +%H%M%S).png}"
mkdir -p "$(dirname "$OUT")"
xcrun simctl io "$SIM_UDID" screenshot "$OUT" >/dev/null
echo "$OUT"
