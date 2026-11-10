#!/usr/bin/env bash
# Build an isolated Android playtest APK without opening the Godot window.
set -euo pipefail

cd "$(dirname "$0")/.."
GODOT="${GODOT:-/Users/mathiusjohnson/Downloads/Godot.app/Contents/MacOS/Godot}"
APK="builds/android/broken-waterway-market-test-debug.apk"

"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --export-debug "Android Market Test" "$APK"
bash dev/verify_market_test.sh "$APK"
