"""Shared helpers for the Broken Ford kit build (Blender, headless).

Axis convention (Blender): +X east, +Y north, +Z up. The glTF exporter maps
Blender +Y to Godot -Z, so "north" stays north in Godot (camera looks north).
Every piece: 1 x 1 m footprint centred on the origin, walkable top at z = 0.
"""
import math
import random
import zlib

import bmesh
import bpy
from mathutils import Matrix, Vector

# --- palette (world design §3, R1 Broken Ford) -----------------------------
PALETTE = {
    # corrupted
    "chalk": "#777381",
    "chalk_dark": "#5F5B69",
    "charcoal": "#454655",
    "violet": "#59465F",
    "crust": "#323543",
    "pool_liquid": "#1B1422",
    "violet_glow": "#B45CE0",
    # restored
    "ivory": "#E8DAB2",
    "ivory_shade": "#CDBE96",
    "turquoise": "#32B8AF",
    "gold": "#E1AD4E",
    "bark": "#8C6A45",
    "leaf": "#3FAE8F",
    "leaf_light": "#7FD0A0",
    "water": "#5FD6CF",
    # walkable ground: calmer than accent ivory so the floor never glares
    "floor": "#638575",
    "floor_2": "#799381",
    "seam": "#52766B",
    "floor_c": "#686B7C",
    "floor_c2": "#78768A",
    "seam_c": "#3A3743",
}

_materials = {}


def srgb_to_linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def hex_linear(hex_str):
    h = hex_str.lstrip("#")
    return tuple(srgb_to_linear(int(h[i:i + 2], 16) / 255.0) for i in (0, 2, 4))


def material(name, emission=0.0):
    """Flat-colour material from PALETTE[name]; emission > 0 makes it glow."""
    key = (name, emission)
    if key in _materials:
        return _materials[key]
    mat = bpy.data.materials.new(f"{name}_glow" if emission else name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    rgb = hex_linear(PALETTE[name])
    bsdf.inputs["Base Color"].default_value = (*rgb, 1.0)
    bsdf.inputs["Roughness"].default_value = 0.8
    if emission > 0.0:
        bsdf.inputs["Emission Color"].default_value = (*rgb, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission
    _materials[key] = mat
    return mat


# --- mesh building ----------------------------------------------------------

class Piece:
    """Accumulates parts (each with one material) into a single mesh object."""

    def __init__(self, name):
        self.name = name
        self.bm = bmesh.new()
        self.mats = []

    def _slot(self, mat):
        if mat not in self.mats:
            self.mats.append(mat)
        return self.mats.index(mat)

    def add(self, part_bm, mat):
        """Merge a finished part bmesh, tagging all its faces with mat."""
        slot = self._slot(mat)
        for f in part_bm.faces:
            f.material_index = slot
        tmp = bpy.data.meshes.new("tmp")
        part_bm.to_mesh(tmp)
        part_bm.free()
        self.bm.from_mesh(tmp)
        bpy.data.meshes.remove(tmp)

    def finish(self, collection):
        bmesh.ops.recalc_face_normals(self.bm, faces=self.bm.faces)
        mesh = bpy.data.meshes.new(self.name)
        self.bm.to_mesh(mesh)
        self.bm.free()
        for m in self.mats:
            mesh.materials.append(m)
        obj = bpy.data.objects.new(self.name, mesh)
        collection.objects.link(obj)
        return obj


def transform(bm, matrix):
    bmesh.ops.transform(bm, matrix=matrix, verts=bm.verts)


def box(center, size, bevel=0.0, jitter=0.0, rng=None, top_jitter_only=False):
    """Axis-aligned box, optionally bevelled and vertex-jittered (hand-cut)."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    transform(bm, Matrix.Diagonal((*size, 1.0)))
    if bevel > 0.0:
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=min(bevel, min(size) * 0.45),
                        segments=1, affect="EDGES")
    if jitter > 0.0 and rng is not None:
        for v in bm.verts:
            if top_jitter_only and v.co.z < 0:
                continue
            v.co.x += rng.uniform(-jitter, jitter)
            v.co.y += rng.uniform(-jitter, jitter)
            v.co.z += rng.uniform(-jitter, jitter) * 0.5
    transform(bm, Matrix.Translation(Vector(center)))
    return bm


def shard(base, height, radius, rng, tilt=0.35, sides=4):
    """Jagged crystal spike: the corruption crust motif."""
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=sides, radius1=radius,
                          radius2=0.0, depth=height)
    transform(bm, Matrix.Translation((0, 0, height / 2)))
    rot = (Matrix.Rotation(rng.uniform(-tilt, tilt), 4, "X")
           @ Matrix.Rotation(rng.uniform(-tilt, tilt), 4, "Y")
           @ Matrix.Rotation(rng.uniform(0, math.tau), 4, "Z"))
    transform(bm, Matrix.Translation(Vector(base)) @ rot)
    return bm


def blob(center, radius, rng, jitter=0.18, subdiv=1, squash=1.0):
    """Faceted jittered icosphere (canopy clumps, rough stones)."""
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=subdiv, radius=radius)
    for v in bm.verts:
        v.co *= 1.0 + rng.uniform(-jitter, jitter)
        v.co.z *= squash
    transform(bm, Matrix.Translation(Vector(center)))
    return bm


def blade(base, height, width, lean, yaw, curl=0.35):
    """Two-segment tapered reed blade leaning outward."""
    bm = bmesh.new()
    pts = [(0.0, 0.0), (0.45, curl * 0.4), (1.0, curl)]
    rings = []
    for i, (t, off) in enumerate(pts):
        w = width * (1.0 - t * 0.9)
        z = height * t
        x = off * lean
        ring = [bm.verts.new((x - w, -w * 0.4, z)), bm.verts.new((x + w, -w * 0.4, z)),
                bm.verts.new((x, w * 0.8, z))]
        rings.append(ring)
    for a, b in zip(rings, rings[1:]):
        for k in range(3):
            bm.faces.new((a[k], a[(k + 1) % 3], b[(k + 1) % 3], b[k]))
    bm.faces.new(rings[0][::-1])
    tip = bm.verts.new((curl * lean * 1.1, 0.0, height * 1.08))
    top = rings[-1]
    for k in range(3):
        bm.faces.new((top[k], top[(k + 1) % 3], tip))
    transform(bm, Matrix.Translation(Vector(base)) @ Matrix.Rotation(yaw, 4, "Z"))
    return bm


def prism_arc(radius, thickness, depth, a0, a1, segments, center=(0, 0, 0), plane="XZ"):
    """Thick arc segment (spillway ring, marker ribs). Angles in radians."""
    bm = bmesh.new()
    inner, outer = radius - thickness / 2, radius + thickness / 2
    rings = []
    for i in range(segments + 1):
        a = a0 + (a1 - a0) * i / segments
        c, s = math.cos(a), math.sin(a)
        quad = []
        for r in (inner, outer):
            for d in (-depth / 2, depth / 2):
                if plane == "XZ":
                    quad.append(bm.verts.new((c * r, d, s * r)))
                else:
                    quad.append(bm.verts.new((c * r, s * r, d)))
        rings.append(quad)  # order: (in,-d),(in,+d),(out,-d),(out,+d)
    order = (0, 2, 3, 1)
    for a, b in zip(rings, rings[1:]):
        for k in range(4):
            i0, i1 = order[k], order[(k + 1) % 4]
            bm.faces.new((a[i0], a[i1], b[i1], b[i0]))
    bm.faces.new([rings[0][i] for i in order][::-1])
    bm.faces.new([rings[-1][i] for i in order])
    transform(bm, Matrix.Translation(Vector(center)))
    return bm


def flat_strip(p0, p1, width, z, height=0.012):
    """Thin raised strip between two xy points (grooves, glowing seams)."""
    v = Vector((p1[0] - p0[0], p1[1] - p0[1]))
    length = v.length
    ang = math.atan2(v.y, v.x)
    mid = ((p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2, z + height / 2)
    bm = box((0, 0, 0), (length, width, height))
    transform(bm, Matrix.Translation(Vector(mid)) @ Matrix.Rotation(ang, 4, "Z"))
    return bm


def split_rect(x0, y0, x1, y1, rng, depth=2):
    """Recursive irregular split of a rectangle into flagstones."""
    w, h = x1 - x0, y1 - y0
    if depth == 0 or max(w, h) < 0.45:
        return [(x0, y0, x1, y1)]
    if w >= h:
        cut = x0 + w * rng.uniform(0.38, 0.62)
        return (split_rect(x0, y0, cut, y1, rng, depth - 1)
                + split_rect(cut, y0, x1, y1, rng, depth - 1))
    cut = y0 + h * rng.uniform(0.38, 0.62)
    return (split_rect(x0, y0, x1, cut, rng, depth - 1)
            + split_rect(x0, cut, x1, y1, rng, depth - 1))


def flagstones(piece, rect, rng, stone_mat, gap_mat, gap=0.035, depth=2,
               thickness=0.12, raise_max=0.018):
    """Irregular flagstone surface over rect with a gap/underlayer slab."""
    x0, y0, x1, y1 = rect
    piece.add(box(((x0 + x1) / 2, (y0 + y1) / 2, -0.06), (x1 - x0, y1 - y0, 0.1)), gap_mat)
    for (a, b, c, d) in split_rect(x0, y0, x1, y1, rng, depth):
        w, h = c - a - gap, d - b - gap
        top = rng.uniform(0.0, raise_max)
        mat = rng.choice(stone_mat) if isinstance(stone_mat, (list, tuple)) else stone_mat
        piece.add(box(((a + c) / 2, (b + d) / 2, top - thickness / 2), (w, h, thickness),
                      jitter=0.012, rng=rng, top_jitter_only=True), mat)


def rng_for(*keys):
    # zlib.crc32, not hash(): str hashing is salted per process, and the kit
    # must rebuild byte-identical
    return random.Random(zlib.crc32(repr(keys).encode()))
