"""Build Bearer and Charger models (corrupted + restored forms) headlessly.

    Blender -b --factory-startup --python art/characters/build_creatures.py -- \
        --out assets/creatures --preview art/creatures

Silhouettes follow world design §7: the Bearer is low and wide with stacked
shoulders, the Charger narrow with a forward eye. Creatures face Blender -Y
(Godot +Z). Restored forms change silhouette where it matters: the Bearer
lies down as a bridge, the Charger roots into a turret.
"""
import argparse
import math
import os
import sys

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from charlib import Body, export, m, make_armature, pose_keys, setup_scene  # noqa: E402
from kitlib import Piece, blob, box, prism_arc, rng_for, shard, transform  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402


def args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--preview", required=True)
    return ap.parse_args(argv)


def r(*keys):
    return rng_for("creature", *keys)


# --- Bearer (corrupted) ---------------------------------------------------------

BEARER_RIG = {
    "body": ((0, 0.25, 0.5), (0, -0.25, 0.5), None),
    "head": ((0, -0.4, 0.45), (0, -0.7, 0.42), "body"),
    "leg.FL": ((0.3, -0.28, 0.38), (0.3, -0.28, 0.02), "body"),
    "leg.FR": ((-0.3, -0.28, 0.38), (-0.3, -0.28, 0.02), "body"),
    "leg.BL": ((0.3, 0.3, 0.38), (0.3, 0.3, 0.02), "body"),
    "leg.BR": ((-0.3, 0.3, 0.38), (-0.3, 0.3, 0.02), "body"),
    "growth.1": ((0, 0.05, 0.75), (0, 0.05, 0.95), "body"),
    "growth.2": ((0.22, 0.2, 0.7), (0.22, 0.2, 0.88), "body"),
    "growth.3": ((-0.22, 0.2, 0.7), (-0.22, 0.2, 0.88), "body"),
}


def build_bearer(body):
    add = body.add
    add(box((0, 0, 0.5), (0.8, 1.0, 0.48), bevel=0.06, jitter=0.05, rng=r("b-torso")), m("chalk_dark"), "body")
    add(box((0, 0.05, 0.3), (0.7, 0.9, 0.12), jitter=0.03, rng=r("b-belly")), m("charcoal"), "body")
    add(box((0, -0.55, 0.44), (0.42, 0.34, 0.3), bevel=0.05, jitter=0.03, rng=r("b-head")), m("violet"), "head")
    add(box((0, -0.7, 0.38), (0.3, 0.1, 0.12), bevel=0.02), m("charcoal"), "head")
    for side in (1, -1):
        add(box((0.11 * side, -0.72, 0.5), (0.06, 0.02, 0.04)), m("violet_glow", 2.4), "head")
    for leg, (x, y) in (("leg.FL", (0.3, -0.28)), ("leg.FR", (-0.3, -0.28)),
                        ("leg.BL", (0.3, 0.3)), ("leg.BR", (-0.3, 0.3))):
        add(box((x, y, 0.2), (0.22, 0.24, 0.4), bevel=0.04, jitter=0.03, rng=r("b-leg", leg)), m("charcoal"), leg)
        add(box((x, y - 0.02, 0.04), (0.26, 0.3, 0.08), bevel=0.02), m("crust"), leg)
    # stacked shoulder growths: each on its own bone so it can be knocked off
    for i, (x, y) in ((1, (0, 0.05)), (2, (0.22, 0.2)), (3, (-0.22, 0.2))):
        rng = r("growth", i)
        add(blob((x, y, 0.82), 0.2, rng, jitter=0.28, squash=0.9), m("charcoal"), f"growth.{i}")
        for _ in range(2):
            add(shard((x + rng.uniform(-0.06, 0.06), y + rng.uniform(-0.06, 0.06), 0.9),
                      rng.uniform(0.18, 0.3), 0.06, rng, tilt=0.5), m("crust"), f"growth.{i}")
        add(box((x, y - 0.1, 0.84), (0.04, 0.02, 0.1)), m("violet_glow", 1.6), f"growth.{i}")


def animate_bearer(rig):
    pose_keys(rig, "idle-loop", {
        0: {}, 30: {"body": ("loc", 0.0), "head": (4, 0, 3), "growth.1": (0, 3, 0)},
        60: {},
    }, 60)
    swing = 20
    pose_keys(rig, "walk-loop", {
        0: {"leg.FL": (-swing, 0, 0), "leg.BR": (-swing, 0, 0), "leg.FR": (swing, 0, 0),
            "leg.BL": (swing, 0, 0), "body": (0, 3, 0)},
        12: {"leg.FL": (swing, 0, 0), "leg.BR": (swing, 0, 0), "leg.FR": (-swing, 0, 0),
             "leg.BL": (-swing, 0, 0), "body": (0, -3, 0)},
        24: {"leg.FL": (-swing, 0, 0), "leg.BR": (-swing, 0, 0), "leg.FR": (swing, 0, 0),
             "leg.BL": (swing, 0, 0), "body": (0, 3, 0)},
    }, 24)
    # 0.9 s telegraph (rear sinks, front rises), 0.1 s slam, 0.2 s recover
    pose_keys(rig, "slam", {
        0: {},
        27: {"body": (-14, 0, 0), "head": (-18, 0, 0), "leg.FL": (-35, 0, 0), "leg.FR": (-35, 0, 0)},
        30: {"body": (8, 0, 0), "head": (10, 0, 0), "leg.FL": (10, 0, 0), "leg.FR": (10, 0, 0)},
        36: {},
    }, 36)
    pose_keys(rig, "stagger", {
        0: {}, 4: {"body": (0, 10, 0), "head": (0, 0, 15)}, 9: {"body": (0, -8, 0), "head": (0, 0, -12)},
        15: {},
    }, 15)
    rig.animation_data.action = None


# --- Bearer bridge (restored, static) -------------------------------------------

def build_bearer_bridge(coll):
    """3 m bridge along -Y from the origin (socket edge); deck top at z = 0."""
    p = Piece("bearer_bridge")
    for i in range(3):
        y = -0.5 - i
        p.add(box((0, y, -0.06), (0.96, 0.94, 0.12), bevel=0.04), m("ivory"))
        p.add(box((0, y + 0.47, -0.01), (0.9, 0.04, 0.02)), m("gold", 1.4))
    for side in (1, -1):
        p.add(box((0.5 * side, -1.5, -0.3), (0.14, 2.9, 0.36), bevel=0.05), m("ivory_shade"))
        for y in (-0.2, -2.8):
            p.add(box((0.46 * side, y, -0.55), (0.2, 0.22, 0.5), bevel=0.04), m("ivory_shade"))
    p.add(box((0, -3.05, -0.1), (0.46, 0.32, 0.26), bevel=0.06), m("ivory"))
    for side in (1, -1):
        p.add(box((0.12 * side, -3.22, -0.04), (0.06, 0.02, 0.04)), m("turquoise", 2.4))
    p.add(box((0, 0.05, -0.1), (0.36, 0.2, 0.2), bevel=0.05), m("ivory_shade"))
    for i in range(3):
        p.add(blob((0.3 * (i - 1), -1.5 + (i - 1) * 0.6, -0.42), 0.12, r("moss", i), jitter=0.1, squash=0.6),
              m("leaf"))
    return p.finish(coll)


# --- Charger (corrupted) -----------------------------------------------------------

CHARGER_RIG = {
    "base": ((0, 0, 0.32), (0, 0, 0.52), None),
    "neck": ((0, 0, 0.52), (0, 0, 0.86), "base"),
    "eye": ((0, -0.04, 0.94), (0, -0.2, 0.94), "neck"),
    "leg.F": ((0, -0.1, 0.34), (0, -0.28, 0.0), "base"),
    "leg.BL": ((0.12, 0.08, 0.34), (0.26, 0.2, 0.0), "base"),
    "leg.BR": ((-0.12, 0.08, 0.34), (-0.26, 0.2, 0.0), "base"),
}


def _limb(p0, p1, width):
    """Box stretched between two points (legs)."""
    a, b = Vector(p0), Vector(p1)
    bm = box((0, 0, 0), (width, width, (b - a).length))
    rot = Vector((0, 0, 1)).rotation_difference((b - a).normalized()).to_matrix().to_4x4()
    transform(bm, Matrix.Translation((a + b) / 2) @ rot)
    return bm


def build_charger(body, restored):
    add = body.add
    shell = m("ivory") if restored else m("charcoal")
    trim = m("gold", 1.4) if restored else m("violet")
    add(box((0, 0, 0.42), (0.34, 0.3, 0.24), bevel=0.05, jitter=0.0 if restored else 0.03, rng=r("c-base")), shell, "base")
    add(box((0, 0, 0.66), (0.14, 0.14, 0.34), bevel=0.02), trim, "neck")
    if not restored:
        for side in (1, -1):
            add(shard((0.07 * side, 0.03, 0.7), 0.22, 0.05, r("fin", side), tilt=0.6), m("crust"), "neck")
    add(prism_arc(0.13, 0.05, 0.06, 0.0, math.tau, 10, center=(0, -0.1, 0.94), plane="XZ"),
        m("gold", 1.6) if restored else m("charcoal"), "eye")
    add(blob((0, -0.1, 0.94), 0.09, r("iris"), jitter=0.03),
        m("turquoise", 2.6) if restored else m("violet_glow", 2.6), "eye")
    add(box((0, -0.02, 0.94), (0.2, 0.16, 0.16), bevel=0.04), shell, "eye")
    for leg, (a, b) in (("leg.F", ((0, -0.1, 0.34), (0, -0.28, 0.0))),
                        ("leg.BL", ((0.12, 0.08, 0.34), (0.26, 0.2, 0.0))),
                        ("leg.BR", ((-0.12, 0.08, 0.34), (-0.26, 0.2, 0.0)))):
        add(_limb(a, b, 0.07), m("ivory_shade") if restored else m("violet"), leg)
        add(box((b[0], b[1], 0.03), (0.1, 0.1, 0.06), bevel=0.02), shell, leg)
    if restored:
        add(box((0, 0, 0.12), (0.5, 0.5, 0.14), bevel=0.05), m("ivory_shade"), "base")
        add(prism_arc(0.24, 0.03, 0.03, 0.0, math.tau, 12, center=(0, 0, 0.2), plane="XY"), m("turquoise", 1.6), "base")


def animate_charger(rig, restored):
    if restored:
        pose_keys(rig, "idle-loop", {0: {"neck": (0, 0, -22)}, 45: {"neck": (0, 0, 22)}, 90: {"neck": (0, 0, -22)}}, 90)
        pose_keys(rig, "fire", {0: {}, 2: {"neck": (-14, 0, 0), "eye": ("scale", 0.85)}, 9: {}}, 9)
    else:
        pose_keys(rig, "idle-loop", {
            0: {"neck": (0, 0, -6)}, 20: {"neck": (3, 0, 6), "base": ("loc", 0.015)}, 40: {"neck": (0, 0, -6)},
        }, 40)
        pose_keys(rig, "aim", {
            0: {}, 12: {"neck": (-18, 0, 0), "eye": ("scale", 1.3), "base": ("loc", -0.03)},
            18: {"neck": (-6, 0, 0), "eye": ("scale", 1.35)},
        }, 18)
        pose_keys(rig, "fire", {
            0: {"neck": (-6, 0, 0), "eye": ("scale", 1.35)}, 2: {"neck": (16, 0, 0), "eye": ("scale", 0.8)},
            9: {},
        }, 9)
        pose_keys(rig, "stagger", {
            0: {}, 6: {"neck": (25, 0, 18), "eye": ("scale", 0.8)}, 18: {"neck": (20, 0, -15), "eye": ("scale", 0.85)},
            30: {"neck": (8, 0, 0)},
        }, 30)
    rig.animation_data.action = None


# --- previews ---------------------------------------------------------------------------

def preview(name, rig, shots, out_dir, dist=2.4, height=1.8):
    scene = bpy.context.scene
    cam = scene.camera
    cam.data.ortho_scale = 2.2 if name != "bearer_bridge" else 4.2
    for label, action, frame in shots:
        if rig:
            rig.animation_data.action = bpy.data.actions[action] if action else None
            scene.frame_set(frame)
        cam.location = (dist * 0.55, -dist, height)
        cam.rotation_euler = (math.radians(58), 0, math.radians(28))
        if name == "bearer_bridge":
            cam.location = (2.4, -4.0, 2.6)
        scene.render.filepath = os.path.join(out_dir, f"{name}_{label}.png")
        bpy.ops.render.render(write_still=True)
    if rig:
        rig.animation_data.action = None


def main():
    a = args()
    os.makedirs(a.out, exist_ok=True)
    os.makedirs(a.preview, exist_ok=True)

    setup_scene()
    rig = make_armature("bearer", BEARER_RIG)
    body = Body("bearer")
    build_bearer(body)
    mesh = body.finish(rig)
    animate_bearer(rig)
    export([rig, mesh], os.path.join(a.out, "bearer.glb"))
    preview("bearer", rig, [("idle", "idle-loop", 0), ("slam_up", "slam", 27), ("walk", "walk-loop", 6)], a.preview)
    print("CREATURE built bearer")

    setup_scene()
    coll = bpy.context.scene.collection
    bridge = build_bearer_bridge(coll)
    export([bridge], os.path.join(a.out, "bearer_bridge.glb"), animated=False)
    preview("bearer_bridge", None, [("rest", None, 0)], a.preview)
    print("CREATURE built bearer_bridge")

    for name, restored in (("charger", False), ("charger_turret", True)):
        setup_scene()
        rig = make_armature(name, CHARGER_RIG)
        body = Body(name)
        build_charger(body, restored)
        mesh = body.finish(rig)
        animate_charger(rig, restored)
        export([rig, mesh], os.path.join(a.out, f"{name}.glb"))
        shots = [("idle", "idle-loop", 0), ("fire", "fire", 2)] if restored else \
            [("idle", "idle-loop", 0), ("aim", "aim", 12), ("stagger", "stagger", 6)]
        preview(name, rig, shots, a.preview)
        print(f"CREATURE built {name}")
    print("CREATURE done")


main()
