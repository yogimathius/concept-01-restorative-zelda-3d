"""Build the Broken Ford kit headlessly.

    Blender -b --factory-startup --python art/kit/build_kit.py -- \
        --out assets/kit --blend art/kit.blend --sheet art/kit_sheet.png [--only ground,pool]

Exports one .glb per family with nodes <shape>_corrupted / <shape>_restored
at the origin, saves the .blend for hand inspection, and renders review
sheets from the game camera's angle (orthographic, 45°, from the south).
"""
import argparse
import math
import os
import sys

import bpy

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import families  # noqa: E402
from kitlib import Piece  # noqa: E402


def args():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--blend", required=True)
    ap.add_argument("--sheet", required=True)
    ap.add_argument("--only", default="")
    return ap.parse_args(argv)


def build_family(name, shapes):
    coll = bpy.data.collections.new(f"kit_{name}")
    bpy.context.scene.collection.children.link(coll)
    objs = []
    for shape, builder in shapes.items():
        for variant in ("corrupted", "restored"):
            piece = Piece(f"{shape}_{variant}")
            builder(piece, variant == "corrupted")
            objs.append(piece.finish(coll))
    return coll, objs


def export(objs, path):
    for o in bpy.context.scene.objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.export_scene.gltf(filepath=path, use_selection=True, export_apply=True,
                              export_yup=True, export_materials="EXPORT")


def sheet(all_objs, path, exclude=("spillway_ring",)):
    """Grid of every shape: corrupted row in front, restored row behind."""
    sheet_coll = bpy.data.collections.new("sheet")
    bpy.context.scene.collection.children.link(sheet_coll)
    pairs = {}
    for o in all_objs:
        shape, variant = o.name.rsplit("_", 1)
        if any(shape.startswith(e) for e in exclude):
            continue
        pairs.setdefault(shape, {})[variant] = o
    shapes = list(pairs)
    per_row = math.ceil(len(shapes) / 2)
    for i, shape in enumerate(shapes):
        col, band = i % per_row, i // per_row
        for variant, dy in (("corrupted", 0.0), ("restored", 2.2)):
            src = pairs[shape][variant]
            dup = src.copy()
            sheet_coll.objects.link(dup)
            dup.location = (col * 2.1, band * 5.5 + dy, 0)
    for c in bpy.data.collections:
        if c.name.startswith("kit_"):
            c.hide_render = True
    width = per_row * 2.1
    render_view(path, center=(width / 2 - 1.05, 3.8, 0), ortho=width * 1.02, res=(2400, 1500))
    bpy.data.collections.remove(sheet_coll)
    for c in bpy.data.collections:
        c.hide_render = False


def render_view(path, center, ortho, res):
    scene = bpy.context.scene
    cam = scene.camera
    cx, cy, cz = center
    cam.location = (cx, cy - 12, cz + 12)
    cam.rotation_euler = (math.radians(45), 0, 0)
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = ortho
    scene.render.resolution_x, scene.render.resolution_y = res
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)


def setup_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    world = bpy.data.worlds.new("sky")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.05, 0.045, 0.08, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.6
    scene.world = world
    cam = bpy.data.objects.new("review_cam", bpy.data.cameras.new("review_cam"))
    scene.collection.objects.link(cam)
    scene.camera = cam
    sun = bpy.data.objects.new("key", bpy.data.lights.new("key", "SUN"))
    sun.data.energy = 3.5
    sun.data.color = (1.0, 0.93, 0.82)
    sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(-35))
    scene.collection.objects.link(sun)


def main():
    a = args()
    only = set(filter(None, a.only.split(",")))
    setup_scene()
    os.makedirs(a.out, exist_ok=True)
    all_objs = []
    for name, shapes in families.FAMILIES.items():
        if only and name not in only:
            continue
        coll, objs = build_family(name, shapes)
        export(objs, os.path.join(a.out, f"{name}.glb"))
        all_objs += objs
        print(f"KIT exported {name}: {[o.name for o in objs]}")
    bpy.ops.wm.save_as_mainfile(filepath=os.path.abspath(a.blend))
    sheet(all_objs, os.path.abspath(a.sheet))
    ring = [o for o in all_objs if o.name.startswith("spillway_ring")]
    if ring:
        ring[1].location.x = 5.0
        render_view(os.path.abspath(a.sheet.replace(".png", "_ring.png")),
                    center=(2.5, 0, 6.5), ortho=14, res=(1600, 1000))
        ring[1].location.x = 0.0
    print("KIT done")


main()
