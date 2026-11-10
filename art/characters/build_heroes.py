"""Build the Warden and Weaver hero models headlessly.

    Blender -b --factory-startup --python art/characters/build_heroes.py -- \
        --out assets/characters --preview art/heroes

Sculpted stylized armour and tailored garments, with blended soft-surface weights and rigid plate bindings on a
shared articulated human rig, joined into one skinned mesh. Actions: idle-loop,
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
sys.path.insert(0, HERE)
from charlib import Body, export, m, make_armature, pose_keys, setup_scene  # noqa: E402
from kitlib import blob, box, prism_arc, transform  # noqa: E402
from mathutils import Matrix  # noqa: E402


def args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--preview", required=True)
    ap.add_argument("--no-preview", action="store_true")
    return ap.parse_args(argv)


def rig_layout(shoulder_x):
    """bone -> (head, tail, parent). Arms and legs hang straight down."""
    sx = shoulder_x
    return {
        "hips": ((0, 0, 0.58), (0, 0, 0.70), None),
        "spine": ((0, 0, 0.70), (0, 0, 0.84), "hips"),
        "chest": ((0, 0, 0.84), (0, 0, 1.02), "spine"),
        "head": ((0, 0, 1.02), (0, 0, 1.28), "chest"),
        "upper_arm.L": ((sx, 0, 0.97), (sx, 0, 0.72), "chest"),
        "forearm.L": ((sx, 0, 0.72), (sx, 0, 0.51), "upper_arm.L"),
        "upper_arm.R": ((-sx, 0, 0.97), (-sx, 0, 0.72), "chest"),
        "forearm.R": ((-sx, 0, 0.72), (-sx, 0, 0.51), "upper_arm.R"),
        "thigh.L": ((0.09, 0, 0.58), (0.09, 0, 0.30), "hips"),
        "shin.L": ((0.09, 0, 0.30), (0.09, 0, 0.04), "thigh.L"),
        "thigh.R": ((-0.09, 0, 0.58), (-0.09, 0, 0.30), "hips"),
        "shin.R": ((-0.09, 0, 0.30), (-0.09, 0, 0.04), "thigh.R"),
    }


# Hero construction uses sculpted surfaces and authored tailoring.
from hero_craft import build_warden, build_weaver
from hero_finish import bake_surface, fit_stature, stature_point
from hero_anatomy import skeleton, bake_footwork


# --- animation ---------------------------------------------------------------------

def animate(rig, heavy):
    # Resting weight sits slightly to one side. The tool arm carries, the free arm relaxes.
    rest={"hips":(0,0,-1.4),"spine":(0,0,.7),"chest":(1,-1,.7),
          "head":(-1,1,0),"upper_arm.L":(3,0,2),"forearm.L":(-8,0,0),
          "upper_arm.R":(-3,0,-2),"forearm.R":(-12,0,0)}
    rest.update({"neck":(-1,0,0),"clavicle.L":(0,0,2),"clavicle.R":(0,0,-2),
                 "hand.L":(4,-3,0),"hand.R":(0,0,0)})
    for name in ["index","middle","ring","little"]:
        rest[name+"1.L"]=(5,0,0)
        rest[name+"2.L"]=(6,0,0)
    breath={**rest,"spine":(1.2,0,.8),"chest":(2,-.5,.6),"head":(-2,.5,0),
            "upper_arm.L":(4,0,2.5),"forearm.R":(-13,0,0)}
    pose_keys(rig,"idle-loop",{0:rest,36:breath,72:rest},72)
    # Eight phases include contact, weight acceptance, passing and toe-off.
    poses={}
    stride=36 if heavy else 33
    for frame in range(0,25,3):
        phase=math.tau*frame/24
        wave=math.cos(phase)
        passing=math.sin(phase)
        left=-stride*wave
        right=stride*wave
        left_knee=4+max(0,-passing)*38
        right_knee=4+max(0,passing)*38
        poses[frame]={
            **rest,
            "hips":{"rot":(0,wave*2,passing*1.6),"loc":(0,-.035+.006*(1-math.cos(phase*2)),0)},
            "spine":(2,-wave*1.5,-passing*1.0),"chest":(2,-wave*2.5,-passing*.8),
            "head":(-2,wave*1.0,0),"thigh.L":(left,0,0),"thigh.R":(right,0,0),
            "shin.L":(left_knee,0,0),"shin.R":(right_knee,0,0),
            "upper_arm.L":(wave*17+2,0,2),"forearm.L":(-12-max(0,wave)*6,0,0),
            "upper_arm.R":(-wave*7-3,0,-2),"forearm.R":(-16,0,0),
            "clavicle.L":(0,wave*1.5,2),"clavicle.R":(0,-wave*1.5,-2),
            "hand.L":(4+passing*3,-3,0),"hand.R":(passing*1.5,0,0),
            "arm_twist.L":(0,passing*2,0),"forearm_twist.L":(0,-passing*3,0)}
    walk=pose_keys(rig,"walk-loop",poses,24)
    bake_footwork(rig,walk,24)
    # A supported asymmetric offering gesture; preserve the 0.333s ability clip contract.
    gather={**rest,"chest":(-3,-4,0),"spine":(-2,0,0),
            "upper_arm.R":(8,0,-7),"forearm.R":(-30,0,0),
            "upper_arm.L":(-12,0,13),"forearm.L":(-22,0,0)}
    release={**rest,"hips":(0,-4,-1),"spine":(3,2,0),"chest":(5,4,0),"head":(-4,-2,0),
             "upper_arm.R":(-61 if heavy else -55,0,-12),"forearm.R":(-24,0,0),
             "upper_arm.L":(-43,0,21),"forearm.L":(-18,0,0),
             "thigh.L":(-9,0,0),"thigh.R":(7,0,0),"shin.R":(8,0,0)}
    release.update({"clavicle.R":(-7,0,-4),"clavicle.L":(-5,0,5),
                    "neck":(-2,0,0),"hand.L":(-12,-8,0),"hand.R":(4,0,0)})
    for name in ["index","middle","ring","little"]:
        release[name+"1.L"]=(-19,0,0)
        release[name+"2.L"]=(-20,0,0)
    follow={**release,"chest":(4,3,0),"upper_arm.R":(-57 if heavy else -51,0,-11)}
    pose_keys(rig,"attack",{0:rest,2:gather,4:release,6:follow,10:rest},10)
    rig.animation_data.action=None


# --- build / export / preview -----------------------------------------------------------

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
    for name, builder, shoulder, heavy in (("warden", build_warden, 0.29, True),
                                           ("weaver", build_weaver, 0.245, False)):
        setup_scene()
        layout=skeleton(shoulder,rig_layout(shoulder))
        fitted={bone: (stature_point(a),stature_point(b),parent) for bone,(a,b,parent) in layout.items()}
        rig = make_armature(name, fitted)
        body = Body(name)
        body.layout=layout
        builder(body)
        mesh_obj = body.finish(rig)
        fit_stature(mesh_obj)
        bake_surface(mesh_obj)
        animate(rig, heavy)
        export([rig, mesh_obj], os.path.join(a.out, f"{name}.glb"), surface_colors=True)
        bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.path.abspath(a.preview), f"{name}.blend"))
        if not a.no_preview:
            preview(rig, name, a.preview)
        print(f"HERO built {name}: {len(mesh_obj.data.polygons)} faces")
    print("HERO done")


main()
