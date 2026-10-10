"""Shared rig / skinning / animation / export helpers for character builds."""
import math
import os
import sys

import bpy

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "kit"))
import kitlib  # noqa: E402
from kitlib import PALETTE, material  # noqa: E402

PALETTE.update({
    "suit": "#1F4F57",
    "robe": "#2E8A8C",
    "robe_dark": "#1E5A60",
    "hood": "#236E73",
    "cloak": "#28495A",
    "armor": "#BCC0AC",
    "porcelain": "#D7D6C7", "metal_gold": "#B68D4F", "metal_bronze": "#846F53",
    "cloth_indigo": "#293D63", "cloth_midnight": "#182D42", "cloth_teal": "#346E77",
    "cloth_linen": "#ADA895", "skin": "#B77F5D", "skin_shadow": "#8F5947",
    "hair": "#28272C", "lip": "#713E3C", "eye_white": "#D4D8D1", "iris": "#3C898B",
    "ink": "#20252A", "leather": "#685141", "leather_dark": "#3D3533",
})

FPS = 30


def m(name, glow=0.0):
    mat = material(name, glow)
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Metallic"].default_value = .72 if name.startswith("metal_") else 0
    bsdf.inputs["Roughness"].default_value = .35 if name.startswith("metal_") else .78
    return mat


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
    for bone, (_, _, parent) in layout.items():
        eb = arm.edit_bones[bone]
        if parent:
            eb.parent = arm.edit_bones[parent]
            eb.use_connect = False
    bpy.ops.object.mode_set(mode="OBJECT")
    for pb in rig.pose.bones:
        pb.rotation_mode = "XYZ"
    return rig


class Body:
    """Authored parts with rigid armour bindings or blended soft-surface weights."""

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
        if callable(bone):
            groups={}
            for vertex in mesh.vertices:
                weights=bone(vertex.co)
                total=sum(weights.values())
                for name,weight in weights.items():
                    if weight<=0.0001: continue
                    if name not in groups: groups[name]=obj.vertex_groups.new(name=name)
                    groups[name].add([vertex.index],weight/total,"REPLACE")
        else:
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
            pb.scale = (1, 1, 1)
        for bone, value in keys[frame].items():
            pb = rig.pose.bones[bone]
            if isinstance(value,dict):
                pb.rotation_euler=tuple(math.radians(v) for v in value.get("rot",(0,0,0)))
                pb.location=value.get("loc",(0,0,0))
            elif value[0] == "loc":
                pb.location = (0, value[1], 0)
            elif value[0] == "scale":
                pb.scale = (value[1],) * 3
            else:
                pb.rotation_euler = tuple(math.radians(v) for v in value)
        for pb in rig.pose.bones:
            pb.keyframe_insert("rotation_euler", frame=frame)
            pb.keyframe_insert("location", frame=frame)
            pb.keyframe_insert("scale", frame=frame)
    action.frame_range = (0, frame_end)
    return action


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
    cam.data.ortho_scale = 1.8
    scene.collection.objects.link(cam)
    scene.camera = cam
    sun = bpy.data.objects.new("key", bpy.data.lights.new("key", "SUN"))
    sun.data.energy = 3.5
    sun.rotation_euler = (math.radians(50), math.radians(10), math.radians(-35))
    scene.collection.objects.link(sun)
    scene.render.resolution_x, scene.render.resolution_y = 600, 600


def export(objs, path, animated=True, surface_colors=False):
    for o in bpy.context.scene.objects:
        o.select_set(False)
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    colour_options={"export_vertex_color":"ACTIVE","export_all_vertex_colors":False} if surface_colors else {}
    bpy.ops.export_scene.gltf(filepath=path, use_selection=True, export_animations=animated,
                              export_animation_mode="ACTIONS", export_skins=True,
                              export_yup=True, export_materials="EXPORT", **colour_options)
