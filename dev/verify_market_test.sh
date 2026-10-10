#!/usr/bin/env bash
# Inspect a sideload playtest APK without starting Godot or touching saved games.
set -euo pipefail

cd "$(dirname "$0")/.."
APK="${1:-builds/android/broken-waterway-market-test-debug.apk}"
SDK="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
TOOLS="$SDK/build-tools/36.0.0"
if [[ -z "${JAVA_HOME:-}" && -d "/Applications/Android Studio.app/Contents/jbr/Contents/Home" ]]; then
  export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
fi

test -f "$APK"
BADGING="$("$TOOLS/aapt" dump badging "$APK")"
PERMISSIONS="$("$TOOLS/aapt" dump permissions "$APK")"

[[ "$BADGING" == *"package: name='dev.gamelab.brokenwaterway.playtest'"* ]]
[[ "$BADGING" == *"targetSdkVersion:'36'"* ]]
[[ "$BADGING" == *"application-label:'The Broken Waterway Playtest'"* ]]
if [[ "$PERMISSIONS" == *"android.permission.INTERNET"* ]]; then
  echo "Unexpected INTERNET permission in offline playtest build" >&2
  exit 1
fi

"$TOOLS/zipalign" -c -v 4 "$APK" >/dev/null
"$TOOLS/apksigner" verify --verbose "$APK" >/dev/null

echo "Verified isolated Android playtest APK: $APK"
printf '%s\n' "$BADGING" | rg '^package:|^sdkVersion:|^targetSdkVersion:|^application-label:' | head -4
printf '%s\n' "$PERMISSIONS" | rg '^uses-permission:' || true
shasum -a 256 "$APK"
