#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

GODOT="/Users/mathiusjohnson/Downloads/Godot.app/Contents/MacOS/Godot"
PACKAGE="dev.gamelab.restorativezelda3d"
APK_PATH="builds/android/restorative-zelda-3d-debug.apk"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

mkdir -p builds/android

"$GODOT" --headless --editor --quit-after 120 --path .
"$GODOT" --headless --export-debug "Android" "$APK_PATH" --path .

if ! adb devices | grep -q "device$"; then
	emulator -avd godot_lab_phone -no-snapshot-load &
	adb wait-for-device
	# wait for full boot, not just adb visibility
	until [[ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" == "1" ]]; do
		sleep 2
	done
fi

adb install -r "$APK_PATH"

if [[ "${1:-}" != "--no-launch" ]]; then
	adb shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1
fi
