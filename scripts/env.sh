#!/usr/bin/env bash
# Gemeinsame Variablen für alle Build-/Test-/Run-Skripte.
export SIM_NAME="${SIM_NAME:-iPhone 17}"
export SIM_UDID="${SIM_UDID:-BF1EBB30-A4E2-4CB4-8714-25111EA5C915}"
export SCHEME="${SCHEME:-Levmi}"
export BUNDLE_ID="${BUNDLE_ID:-de.immodigit.levmi}"
export DERIVED="${DERIVED:-$(cd "$(dirname "$0")/.." && pwd)/.derived}"
export DEST="platform=iOS Simulator,id=${SIM_UDID}"
