#!/usr/bin/env bash
# Führt die reinen Domain-Tests (Swift Testing) des LevmiCore-Pakets auf macOS aus — schnell, ohne Simulator.
set -euo pipefail
cd "$(dirname "$0")/../Packages/LevmiCore"
swift test "$@" 2>&1 | grep -vE "^\[[0-9]+/[0-9]+\]|^Compiling|^Build complete|^Fetching|^Creating" || true
# Exit-Status des swift test durchreichen:
swift test "$@" >/dev/null 2>&1
