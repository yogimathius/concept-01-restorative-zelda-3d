"""Build the Warden and Weaver hero models headlessly.

    Blender -b --factory-startup --python art/characters/build_heroes.py -- \
        --out assets/characters --preview art/heroes

Low-poly armoured parts, each rigidly bound (weight 1.0) to one bone of a
shared 12-bone rig, joined into one skinned mesh. Actions: idle-loop,
walk-loop, attack (Godot strips the -loop suffix and loops those clips).
The character faces Blender -Y, which becomes Godot +Z (the hero's default
facing, toward the camera).
"""
import argparse
import math
import os
import sys

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "kit"))
from kitlib import PALETTE, blob, box, material, prism_arc, transform  # noqa: E402
from mathutils import Matrix  # noqa: E402

PALETTE.update({
    "suit": "#1F4F57",
    "robe": "#2E8A8C",
    "robe_dark": "#1E5A60",
    "hood": "#236E73",
})

FPS = 30


def args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--preview", required=True)
    return ap.parse_args(argv)


def rig_layout(shoulder_x):
    """bone -> (head, tail, parent). Arms and legs hang straight down."""
    sx = shoulder_x
    return {
        "hips": ((0, 0, 0.48), (0, 0, 0.58), None),
        "spine": ((0, 0, 0.58), (0, 0, 0.72), "hips"),
        "chest": ((0, 0, 0.72), (0, 0, 0.86), "spine"),
        "head": ((0, 0, 0.86), (0, 0, 1.06), "chest"),
        "upper_arm.L": ((sx, 0, 0.84), (sx, 0, 0.64), "chest"),
        "forearm.L": ((sx, 0, 0.64), (sx, 0, 0.46), "upper_arm.L"),
        "upper_arm.R": ((-sx, 0, 0.84), (-sx, 0, 0.64), "chest"),
        "forearm.R": ((-sx, 0, 0.64), (-sx, 0, 0.46), "upper_arm.R"),
        "thigh.L": ((0.09, 0, 0.48), (0.09, 0, 0.26), "hips"),
        "shin.L": ((0.09, 0, 0.26), (0.09, 0, 0.03), "thigh.L"),
        "thigh.R": ((-0.09, 0, 0.48), (-0.09, 0, 0.26), "hips"),
        "shin.R": ((-0.09, 0, 0.26), (-0.09, 0, 0.03), "thigh.R"),
    }


def make_armature(name, layout):
    arm = bpy.data.armatures.new(name + "_rig")
    rig = bpy.data.objects.new(name + "_rig", arm)
    bpy.context.scene.collection.objects.link(rig)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="EDIT")
    for bone, (head, tail, parent) in layout.items():
        eb = arm.edit_bones.new(bone)
        eb.head, eb.tail = head, tail
        eb.roll = 0.0
        if parent:
            eb.parent = arm.edit_bones[parent]
            eb.use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    for pb in rig.pose.bones:
        pb.rotation_mode = "XYZ"
    return rig


class Body:
    """Parts, each with one material and rigidly bound to one bone."""

    def __init__(self, name):
        self.name = name
        self.parts = []

    def add(self, bm, mat, bone):
        mesh = bpy.data.meshes.new(f"{self.name}_part")
        bm.to_mesh(mesh)
        bm.free()
        mesh.materials.append(mat)
        obj = bpy.data.objects.new(f"{self.name}_part", mesh)
        bpy.context.scene.collection.objects.link(obj)
        vg = obj.vertex_groups.new(name=bone)
        vg.add(list(range(len(mesh.vertices))), 1.0, "REPLACE")
        self.parts.append(obj)

    def finish(self, rig):
        for o in bpy.context.scene.objects:
            o.select_set(False)
        for o in self.parts:
            o.select_set(True)
        bpy.context.view_layer.objects.active = self.parts[0]
        bpy.ops.object.join()
        body = bpy.context.view_layer.objects.active
        body.name = self.name
        body.data.name = self.name
        body.parent = rig
        mod = body.modifiers.new("rig", "ARMATURE")
        mod.object = rig
        return body


def m(name, glow=0.0):
    return material(name, glow)


# --- Warden: stocky, ivory plate over a deep-teal suit, glowing visor ---------

def build_warden(body):
    add = body.add
    add(box((0, 0, 0.51), (0.3, 0.2, 0.15), bevel=0.02), m("suit"), "hips")
    add(box((0, -0.005, 0.585), (0.32, 0.22, 0.04)), m("gold", 0.8), "hips")
    add(box((0, 0, 0.65), (0.27, 0.19, 0.14), bevel=0.02), m("suit"), "spine")
    add(box((0, 0, 0.79), (0.44, 0.28, 0.2), bevel=0.05), m("ivory"), "chest")
    add(blob((0, -0.15, 0.8), 0.045, _r("wg"), jitter=0.02, subdiv=1), m("turquoise", 2.2), "chest")
    for side, bone in ((1, "upper_arm.L"), (-1, "upper_arm.R")):
        add(blob((0.27 * side, 0, 0.86), 0.12, _r("pauldron", side), jitter=0.05, squash=0.8), m("ivory"), "chest")
        add(box((0.27 * side, 0, 0.74), (0.11, 0.11, 0.18)), m("suit"), bone)
        fore = bone.replace("upper_arm", "forearm")
        add(box((0.27 * side, 0, 0.55), (0.15, 0.15, 0.19), bevel=0.03), m("ivory"), fore)
        add(box((0.27 * side, -0.078, 0.5), (0.1, 0.02, 0.04)), m("turquoise", 2.0), fore)
    add(box((0, 0, 0.97), (0.21, 0.21, 0.2), bevel=0.05), m("ivory"), "head")
    add(box((0, -0.107, 0.97), (0.14, 0.02, 0.03)), m("turquoise", 2.6), "head")
    add(box((0, 0.01, 1.09), (0.04, 0.16, 0.05), bevel=0.01), m("gold", 0.8), "head")
    for side, (thigh, shin) in ((1, ("thigh.L", "shin.L")), (-1, ("thigh.R", "shin.R"))):
        add(box((0.09 * side, 0, 0.37), (0.12, 0.12, 0.2)), m("suit"), thigh)
        add(box((0.09 * side, -0.015, 0.13), (0.14, 0.19, 0.25), bevel=0.03), m("ivory"), shin)


# --- Weaver: slender, flared turquoise robe, ivory mask, gold hand rings -------

def build_weaver(body):
    add = body.add
    skirt = _cone(0.25, 0.13, 0.46, 8)
    transform(skirt, Matrix.Translation((0, 0, 0.3)))
    add(skirt, m("robe"), "hips")
    add(box((0, 0, 0.56), (0.26, 0.17, 0.05)), m("gold", 0.9), "hips")
    add(box((0, 0, 0.66), (0.22, 0.15, 0.16), bevel=0.02), m("robe_dark"), "spine")
    add(box((0, 0, 0.79), (0.3, 0.19, 0.16), bevel=0.04), m("robe"), "chest")
    add(prism_arc(0.1, 0.03, 0.03, 0.0, math.tau, 8, center=(0, -0.02, 0.86), plane="XY"), m("gold", 1.2), "chest")
    add(blob((0, -0.01, 0.98), 0.1, _r("mask"), jitter=0.03, squash=1.15), m("ivory"), "head")
    for side in (1, -1):
        add(box((0.035 * side, -0.095, 1.0), (0.035, 0.02, 0.015)), m("turquoise", 2.6), "head")
    hood = _cone(0.15, 0.03, 0.26, 6)
    transform(hood, Matrix.Translation((0, 0.035, 1.02)))
    add(hood, m("hood"), "head")
    for side, bone in ((1, "upper_arm.L"), (-1, "upper_arm.R")):
        add(box((0.21 * side, 0, 0.75), (0.09, 0.09, 0.18)), m("robe"), bone)
        fore = bone.replace("upper_arm", "forearm")
        sleeve = _cone(0.08, 0.05, 0.16, 6)
        transform(sleeve, Matrix.Translation((0.21 * side, 0, 0.56)) @ Matrix.Rotation(math.pi, 4, "X"))
        add(sleeve, m("robe_dark"), fore)
        add(blob((0.21 * side, 0, 0.46), 0.045, _r("hand", side), subdiv=1), m("ivory"), fore)
        add(prism_arc(0.05, 0.02, 0.025, 0.0, math.tau, 8, center=(0.21 * side, 0, 0.49), plane="XY"),
            m("gold", 2.2), fore)
    for side, shin in ((1, "shin.L"), (-1, "shin.R")):
        add(box((0.08 * side, -0.03, 0.04), (0.08, 0.14, 0.07), bevel=0.02), m("robe_dark"), shin)


def _cone(r1, r2, depth, segments):
    import bmesh
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=r1, radius2=r2, depth=depth)
    return bm


def _r(*keys):
    from kitlib import rng_for
    return rng_for("hero", *keys)


# --- animation ---------------------------------------------------------------------

def pose_keys(rig, action_name, keys, frame_end):
    """keys: {frame: {bone: (rx_deg, ry_deg, rz_deg) | ('loc', y)}}"""
    rig.animation_data_create()
    action = bpy.data.actions.new(action_name)
    action.use_fake_user = True
    rig.animation_data.action = action
    for frame in sorted(keys):
        for pb in rig.pose.bones:
            pb.rotation_euler = (0, 0, 0)
            pb.location = (0, 0, 0)
        for bone, value in keys[frame].items():
            pb = rig.pose.bones[bone]
            if value[0] == "loc":
                pb.location = (0, value[1], 0)
            else:
                pb.rotation_euler = tuple(math.radians(v) for v in value)
        for pb in rig.pose.bones:
            pb.keyframe_insert("rotation_euler", frame=frame)
            pb.keyframe_insert("location", frame=frame)
    action.frame_range = (0, frame_end)
    return action


def animate(rig, heavy):
    arm_swing = 22 if heavy else 30
    leg = 32 if heavy else 26
    # Limb bones hang down (-Z): +X rotation swings the far end backward (+Y),
    # -X swings it forward (-Y, the facing direction).
    pose_keys(rig, "idle-loop", {
        0: {"chest": (0, 0, 0), "upper_arm.L": (0, 0, 4), "upper_arm.R": (0, 0, -4)},
        24: {"chest": (3, 0, 0), "head": (-2, 0, 0), "upper_arm.L": (2, 0, 7), "upper_arm.R": (2, 0, -7),
             "hips": ("loc", -0.012)},
        48: {"chest": (0, 0, 0), "upper_arm.L": (0, 0, 4), "upper_arm.R": (0, 0, -4)},
    }, 48)
    stride = {"thigh.L": (-leg, 0, 0), "thigh.R": (leg, 0, 0), "shin.R": (28, 0, 0),
              "upper_arm.L": (arm_swing, 0, 4), "upper_arm.R": (-arm_swing, 0, -4)}
    mirror = {"thigh.L": (leg, 0, 0), "thigh.R": (-leg, 0, 0), "shin.L": (28, 0, 0),
              "upper_arm.L": (-arm_swing, 0, 4), "upper_arm.R": (arm_swing, 0, -4)}
    pose_keys(rig, "walk-loop", {
        0: {**stride, "chest": (4, 4, 0)},
        3: {"hips": ("loc", 0.025), "chest": (4, 0, 0), "shin.L": (35, 0, 0)},
        6: {**mirror, "chest": (4, -4, 0)},
        9: {"hips": ("loc", 0.025), "chest": (4, 0, 0), "shin.R": (35, 0, 0)},
        12: {**stride, "chest": (4, 4, 0)},
    }, 12)
    push = -95 if heavy else -80
    pose_keys(rig, "attack", {
        0: {},
        3: {"upper_arm.L": (45, 0, 10), "upper_arm.R": (45, 0, -10), "forearm.L": (-50, 0, 0),
            "forearm.R": (-50, 0, 0), "chest": (-10, 0, 0), "hips": ("loc", -0.03)},
        4: {"upper_arm.L": (push, 0, 12), "upper_arm.R": (push, 0, -12), "chest": (12, 0, 0),
            "head": (-6, 0, 0), "thigh.L": (-18, 0, 0), "thigh.R": (14, 0, 0)},
        6: {"upper_arm.L": (push + 5, 0, 12), "upper_arm.R": (push + 5, 0, -12), "chest": (10, 0, 0),
            "thigh.L": (-18, 0, 0), "thigh.R": (14, 0, 0)},
        10: {"upper_arm.L": (-15, 0, 5), "upper_arm.R": (-15, 0, -5), "chest": (3, 0, 0)},
    }, 10)
    rig.animation_data.action = None


# --- build / export / preview -----------------------------------------------------------

def setup_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    import kitlib
    kitlib._materials.clear()   # the reset above deleted them
    scene = bpy.context.scene
    scene.render.fps = FPS
    scene.render.engine = "BLENDER_EEVEE"
    world = bpy.data.worlds.new("sky")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.05, 0.045, 0.08, 1)
    scene.world = world
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = 1.6
    scene.collection.objects.link(cam)
    scene.camera = cam
    sun = bpy.data.objects.new("key", bpy.data.lights.new("key", "SUN"))
    sun.data.energy = 3.5
    sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(-35))
    scene.collection.objects.link(sun)
    scene.render.resolution_x, scene.render.resolution_y = 600, 600


def export(rig, body, path):
    for o in bpy.context.scene.objects:
        o.select_set(False)
    rig.select_set(True)
    body.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.export_scene.gltf(filepath=path, use_selection=True, export_animations=True,
                              export_animation_mode="ACTIONS", export_skins=True,
                              export_yup=True, export_materials="EXPORT")


def preview(rig, name, out_dir):
    scene = bpy.context.scene
    cam = scene.camera
    shots = [("idle", "idle-loop", 0), ("walk_a", "walk-loop", 0), ("walk_b", "walk-loop", 6),
             ("windup", "attack", 3), ("release", "attack", 4)]
    for label, action, frame in shots:
        rig.animation_data.action = bpy.data.actions[action]
        scene.frame_set(frame)
        for view, loc, rot in (("front", (0.9, -1.6, 1.5), (60, 0, 30)), ("side", (2.0, 0, 0.6), (90, 0, 90))):
            cam.location = loc
            cam.rotation_euler = tuple(math.radians(v) for v in rot)
            scene.render.filepath = os.path.join(out_dir, f"{name}_{label}_{view}.png")
            bpy.ops.render.render(write_still=True)
    rig.animation_data.action = None


def main():
    a = args()
    os.makedirs(a.out, exist_ok=True)
    os.makedirs(a.preview, exist_ok=True)
    for name, builder, shoulder, heavy in (("warden", build_warden, 0.27, True),
                                           ("weaver", build_weaver, 0.21, False)):
        setup_scene()
        rig = make_armature(name, rig_layout(shoulder))
        body = Body(name)
        builder(body)
        mesh_obj = body.finish(rig)
        animate(rig, heavy)
        export(rig, mesh_obj, os.path.join(a.out, f"{name}.glb"))
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.path.abspath(a.preview), f"{name}.blend"))
        preview(rig, name, a.preview)
        print(f"HERO built {name}: {len(mesh_obj.data.polygons)} faces")
    print("HERO done")


main()
