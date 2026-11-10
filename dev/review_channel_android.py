#!/usr/bin/env python3
"""Emulator-only Channel touch smoke test. Restores the original save byte for byte."""
import hashlib
import json
import subprocess
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "builds/playtest/channel-first-route"
ADB = "/Users/mathiusjohnson/Library/Android/sdk/platform-tools/adb"
PACKAGE = "dev.gamelab.restorativezelda3d"
SAVE = "files/restoration-journey.json"


def adb(*args, data=None):
    return subprocess.run([ADB, *args], input=data, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, check=True).stdout


def read_save():
    return adb("exec-out", "run-as", PACKAGE, "cat", SAVE)


def write_save(data):
    adb("shell", "run-as", PACKAGE, "sh", "-c", f"'cat > {SAVE}'", data=data)


def stop():
    adb("shell", "am", "force-stop", PACKAGE)


def start():
    adb("shell", "monkey", "-p", PACKAGE, "-c", "android.intent.category.LAUNCHER", "1")
    time.sleep(35)  # let the camera and first scene settle before touching the medallion


def capture(name):
    (OUT / name).write_bytes(adb("exec-out", "screencap", "-p"))


def tap_channel():
    adb("shell", "input", "tap", "1950", "780")
    time.sleep(2)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    original = read_save()
    original_hash = hashlib.sha256(original).hexdigest()
    (OUT / "emulator-original-save.json").write_bytes(original)
    try:
        fixture = json.loads((ROOT / "builds/playtest/weave-living-route/android-living-route-fixture.json").read_text())
        fixture["worlds"]["R2"] = {"restored": ["M3", "M6"], "partial": {},
                                  "position": [25.5, 0.02, 18.0], "ecology": {}}
        fixture["skills"].update({"active": "channel", "channel_carry": False,
                                  "unlocked": ["mend", "force", "anchor", "channel"]})
        fixture["story"]["bryn_channel_started"] = True
        fixture["resources"]["flow"] = 100.0
        stop()
        write_save(json.dumps(fixture, separators=(",", ":")).encode())
        start()
        capture("android-channel-source.png")
        tap_channel()
        carried = json.loads(read_save())
        assert carried["skills"]["channel_carry"] is True, "medallion tap did not capture Charge"
        assert carried["resources"]["flow"] < 100, "capture did not spend Flow"
        capture("android-channel-carried.png")
        stop()
        carried["worlds"]["R2"]["position"] = [20.5, 0.02, 21.5]
        write_save(json.dumps(carried, separators=(",", ":")).encode())
        start()
        capture("android-channel-beds-before.png")
        tap_channel()
        lit = json.loads(read_save())
        assert lit["worlds"]["R2"]["ecology"]["M6"]["charged"] is True, "touch did not light beds"
        assert lit["skills"]["channel_carry"] is False, "delivery did not release Charge"
        assert lit["skills"]["events"].get("channel/R2/lantern_beds/charged") == 3, "delivery mastery missing"
        (OUT / "android-channel-after.json").write_text(json.dumps(lit, indent=2))
        capture("android-channel-beds-lit.png")
        print("PASS emulator touch captures and delivers Channel Charge; Flow, ecology and mastery saved")
    finally:
        stop()
        write_save(original)
        restored_hash = hashlib.sha256(read_save()).hexdigest()
        assert restored_hash == original_hash, "original emulator save was not restored byte for byte"
        print(f"PASS original emulator save restored SHA-256 {original_hash}")


if __name__ == "__main__":
    main()
