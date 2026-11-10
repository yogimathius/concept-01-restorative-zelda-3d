#!/usr/bin/env python3
"""Emulator-only Bloom touch route; restores the original main-game save exactly."""
import hashlib
import json
from pathlib import Path

from review_channel_android import adb, read_save, write_save, stop, start, tap_channel

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "builds/playtest/bloom-first-route"


def capture(name):
    (OUT / name).write_bytes(adb("exec-out", "screencap", "-p"))


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    original = read_save()
    digest = hashlib.sha256(original).hexdigest()
    (OUT / "emulator-original-save.json").write_bytes(original)
    try:
        fixture = json.loads((ROOT / "builds/playtest/weave-living-route/android-living-route-fixture.json").read_text())
        fixture["worlds"]["R2"] = {
            "restored": ["M1", "M2", "M4", "M5"], "partial": {},
            "position": [11.5, 0.02, 7.5],
            "ecology": {site: {"linked": True} for site in ["M1", "M2", "M4", "M5"]},
        }
        fixture["skills"].update({"active": "bloom", "channel_carry": False,
                                  "unlocked": ["mend", "force", "anchor", "weave", "bloom"]})
        fixture["story"]["neri_bloom_started"] = True
        fixture["resources"]["flow"] = 100.0
        stop()
        write_save(json.dumps(fixture, separators=(",", ":")).encode())
        start()
        capture("android-bloom-garden-before.png")
        tap_channel()  # same right-hand technique medallion and screen coordinate
        garden = json.loads(read_save())
        assert garden["worlds"]["R2"]["ecology"]["M1"]["bloomed"] is True, "touch did not grow garden"
        assert garden["skills"]["events"].get("bloom/R2/M1/bloomed") == 3, "garden mastery missing"
        capture("android-bloom-garden-after.png")
        stop()
        garden["worlds"]["R2"]["position"] = [10.5, 0.02, 17.5]
        write_save(json.dumps(garden, separators=(",", ":")).encode())
        start()
        capture("android-bloom-refuge-before.png")
        tap_channel()
        refuge = json.loads(read_save())
        assert refuge["worlds"]["R2"]["ecology"]["M4"]["bloomed"] is True, "touch did not grow refuge"
        assert refuge["skills"]["events"].get("bloom/R2/M4/bloomed") == 3, "refuge mastery missing"
        (OUT / "android-bloom-after.json").write_text(json.dumps(refuge, indent=2))
        capture("android-bloom-refuge-after.png")
        print("PASS emulator touch grows garden and refuge; both ecological states and Bloom mastery saved")
    finally:
        stop()
        write_save(original)
        restored = hashlib.sha256(read_save()).hexdigest()
        assert restored == digest, "the original emulator save was not restored byte for byte"
        print(f"PASS original emulator save restored SHA-256 {digest}")


if __name__ == "__main__":
    main()
