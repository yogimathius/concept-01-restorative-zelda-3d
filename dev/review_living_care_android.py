#!/usr/bin/env python3
"""Emulator touch check for renewable care; restore the main save exactly."""
import hashlib
import json
import time
from pathlib import Path

from review_channel_android import adb, read_save, write_save, stop, start

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "builds/playtest/living-care"


def capture(name):
    (OUT / name).write_bytes(adb("exec-out", "screencap", "-p"))


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    original = read_save()
    digest = hashlib.sha256(original).hexdigest()
    try:
        fixture = json.loads((ROOT / "builds/playtest/weave-living-route/android-living-route-fixture.json").read_text())
        fixture["active_region"] = "R1"
        fixture["worlds"]["R1"]["position"] = [21.5, 0.02, 8.6]
        fixture["worlds"]["R1"]["restored"] = ["B1"]
        fixture["economy"]["patches"] = {}
        fixture["skills"]["active"] = "mend"
        fixture["resources"]["flow"] = 100.0
        fixture["journal"]["pinned"] = "care/R1/B1"
        stop()
        write_save(json.dumps(fixture, separators=(",", ":")).encode())
        start()
        capture("android-care-before.png")
        adb("shell", "input", "swipe", "1950", "780", "1950", "780", "8000")
        time.sleep(4)
        after = json.loads(read_save())
        capture("android-care-after.png")
        patch = after["economy"]["patches"]["B1"]
        assert patch["cycles"] == 1, f"Mend did not complete care: {patch}"
        assert after["economy"]["materials"]["reed_fiber"] >= 2, "reed yield missing"
        assert after["economy"]["scrip"] >= 1, "river scrip missing"
        assert "B1" in after["worlds"]["R1"]["restored"], "original grove lost its restoration"
        assert after["journal"]["pinned"] == "care/R1/B1", "care pin did not persist"
        adb("shell", "input", "tap", "2010", "80")
        time.sleep(1)
        capture("android-care-map.png")
        adb("shell", "input", "tap", "1608", "888")
        time.sleep(1)
        adb("shell", "input", "tap", "816", "276")
        time.sleep(1)
        capture("android-care-journal.png")
        print("PASS emulator held Mend tends a reed patch; yield, cooldown, original restoration and pin saved")
    finally:
        stop()
        write_save(original)
        restored = hashlib.sha256(read_save()).hexdigest()
        assert restored == digest, "original emulator save was not restored byte for byte"
        print(f"PASS original emulator save restored SHA-256 {digest}")


if __name__ == "__main__":
    main()
