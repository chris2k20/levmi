#!/usr/bin/env bash
# Installiert und startet die gebaute App im Simulator.
set -euo pipefail
cd "$(dirname "$0")/.."
source scripts/env.sh
APP="$DERIVED/Build/Products/Debug-iphonesimulator/Levmi.app"
[ -d "$APP" ] || { echo "App nicht gebaut: $APP"; exit 1; }
xcrun simctl bootstatus "$SIM_UDID" -b >/dev/null 2>&1 || xcrun simctl boot "$SIM_UDID"
open -a Simulator --args -CurrentDeviceUDID "$SIM_UDID" >/dev/null 2>&1 || true
xcrun simctl terminate "$SIM_UDID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$SIM_UDID" "$APP"
xcrun simctl launch "$SIM_UDID" "$BUNDLE_ID"
echo "✓ Levmi läuft im Simulator ($SIM_NAME)"
