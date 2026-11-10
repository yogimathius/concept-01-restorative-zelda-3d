"""Broken Ford kit families (world design §7) plus lab-only pieces.

Each builder: build(piece: Piece, corrupted: bool) adds parts to `piece`.
Layout randomness is seeded per shape (not per variant) so a restored piece
keeps the same stones as its corrupted twin -- restoration heals, it doesn't
swap in a different object.
"""
import math

from mathutils import Matrix, Vector

from kitlib import (blade, blob, box, flagstones, flat_strip, material, prism_arc,
                    rng_for, shard, transform)


def m(name, glow=0.0):
    return material(name, glow)


def floor_mats(corrupted):
    if corrupted:
        return [m("floor_c"), m("floor_c2")], m("seam_c")
    return [m("floor"), m("floor_2")], m("seam")


def crust(piece, rng, count, area=0.4, h=(0.1, 0.22), z=0.0):
    """Scatter black crust shards over the top of a piece."""
    for _ in range(count):
        base = (rng.uniform(-area, area), rng.uniform(-area, area), z)
        piece.add(shard(base, rng.uniform(*h), rng.uniform(0.045, 0.08), rng), m("crust"))


def pointing(bm_part, direction):
    """Rotate a z-up part so +Z points along direction (about origin)."""
    rot = Vector((0, 0, 1)).rotation_difference(Vector(direction)).to_matrix().to_4x4()
    transform(bm_part, rot)
    return bm_part


# --- 1 ground ----------------------------------------------------------------

def ground(variation):
    def build(p, corrupted):
        layout = rng_for("ground", variation)
        stones, gap = floor_mats(corrupted)
        # Quiet, seamless earth carries irregular stepping stones; foliage
        # belongs to edge dressing rather than every repeated square.
        p.add(box((0, 0, -0.09), (1.002, 1.002, 0.18)), stones[0])
        if variation != "a":
            for i in range(2 if variation == "b" else 3):
                x = (-0.24 if i == 0 else 0.23) + layout.uniform(-0.06, 0.06)
                y = layout.uniform(-0.24, 0.24)
                stone = blob((x, y, 0.006), 0.29 if variation == "b" else 0.22,
                             layout, jitter=0.12, squash=0.08)
                p.add(stone, m("chalk") if corrupted else m("ivory_shade"))
    return build


# --- 2/3 banks ---------------------------------------------------------------

def _cliff(p, corrupted, center, size, rng):
    p.add(box(center, size, jitter=0.03 if corrupted else 0.0, rng=rng),
          m("charcoal") if corrupted else m("ivory_shade"))
    if not corrupted:  # a lighter stratum band across the face
        cx, cy, _ = center
        p.add(box((cx, cy, -0.32), (size[0] + 0.02, size[1] + 0.02, 0.16)), m("ivory"))


def _add_tooth(p, rng, at, direction):
    part = pointing(shard((0, 0, 0), rng.uniform(0.16, 0.3), 0.06, rng, tilt=0.2), direction)
    transform(part, Matrix.Translation(Vector(at)))
    p.add(part, m("crust"))


def _curb(p, corrupted, center, size, rng):
    p.add(box(center, size, bevel=0.0 if corrupted else 0.03,
              jitter=0.035 if corrupted else 0.0, rng=rng),
          m("chalk") if corrupted else m("ivory"))


def _reed_tuft(p, rng, at, count=2, tall=0.45):
    for i in range(count):
        p.add(blade(at, tall * rng.uniform(0.8, 1.1), 0.028, 1.0,
                    rng.uniform(0, math.tau)), m("gold"))


def bank_straight(p, corrupted):
    rng = rng_for("bank_straight")
    flagstones(p, (-0.5, -0.28, 0.5, 0.5), rng, *floor_mats(corrupted), depth=1)
    for x in (-0.25, 0.25):
        _curb(p, corrupted, (x, -0.38, -0.02), (0.48, 0.2, 0.16), rng)
    _cliff(p, corrupted, (0, -0.45, -0.62), (1.0, 0.12, 1.2), rng)
    if corrupted:
        t = rng_for("bank_straight-teeth")
        for x, z in ((-0.3, -0.2), (0.05, -0.45), (0.35, -0.15)):
            _add_tooth(p, t, (x, -0.5, z), (0, -1, -0.4))
    else:
        p.add(flat_strip((-0.5, -0.27), (0.5, -0.27), 0.04, 0.0), m("turquoise", 1.4))
        _reed_tuft(p, rng_for("bank_straight-reed"), (-0.4, -0.34, 0.06))


def bank_corner_outer(p, corrupted):
    rng = rng_for("bank_corner_outer")
    flagstones(p, (-0.5, -0.28, 0.28, 0.5), rng, *floor_mats(corrupted), depth=1)
    _curb(p, corrupted, (-0.16, -0.38, -0.02), (0.66, 0.2, 0.16), rng)
    _curb(p, corrupted, (0.38, 0.16, -0.02), (0.2, 0.66, 0.16), rng)
    _cliff(p, corrupted, (-0.06, -0.45, -0.62), (0.88, 0.12, 1.2), rng)
    _cliff(p, corrupted, (0.45, 0.06, -0.62), (0.12, 0.88, 1.2), rng)
    if corrupted:
        t = rng_for("bank_corner_outer-teeth")
        for _ in range(3):
            p.add(shard((0.36, -0.36, 0.0), t.uniform(0.25, 0.42), 0.07, t, tilt=0.5), m("crust"))
        _add_tooth(p, t, (0.5, -0.5, -0.3), (1, -1, -0.3))
    else:
        p.add(blob((0.36, -0.36, 0.05), 0.15, rng_for("corner-stone"), jitter=0.08,
                   squash=0.7), m("ivory"))
        p.add(flat_strip((-0.5, -0.27), (0.27, -0.27), 0.04, 0.0), m("turquoise", 1.4))
        p.add(flat_strip((0.27, -0.27), (0.27, 0.5), 0.04, 0.0), m("turquoise", 1.4))


def bank_corner_inner(p, corrupted):
    rng = rng_for("bank_corner_inner")
    stones, gap = floor_mats(corrupted)
    flagstones(p, (-0.5, -0.5, 0.0, 0.5), rng, stones, gap, depth=1)
    flagstones(p, (0.0, 0.0, 0.5, 0.5), rng, stones, gap, depth=0)
    _curb(p, corrupted, (0.27, 0.08, -0.02), (0.46, 0.16, 0.16), rng)
    _curb(p, corrupted, (-0.08, -0.27, -0.02), (0.16, 0.46, 0.16), rng)
    _cliff(p, corrupted, (0.25, -0.02, -0.62), (0.5, 0.08, 1.2), rng)
    _cliff(p, corrupted, (0.02, -0.25, -0.62), (0.08, 0.5, 1.2), rng)
    if corrupted:
        t = rng_for("bank_corner_inner-teeth")
        for _ in range(2):
            p.add(shard((0.05, 0.05, 0.0), t.uniform(0.22, 0.36), 0.06, t, tilt=0.5), m("crust"))
    else:
        _reed_tuft(p, rng_for("inner-reed"), (-0.05, 0.05, 0.06), count=3)


# --- 4/5 walls ---------------------------------------------------------------

def _wall_courses(p, corrupted, x0, x1, depth, rng, seed):
    courses = [(0.0, 0.34), (0.34, 0.68), (0.68, 0.95)]
    for ci, (z0, z1) in enumerate(courses):
        cuts = [x0]
        n = 2 if ci != 1 else 3
        for i in range(1, n):
            cuts.append(x0 + (x1 - x0) * (i / n + rng.uniform(-0.08, 0.08)))
        cuts.append(x1)
        inset = 0.04 * ci
        for a, b in zip(cuts, cuts[1:]):
            is_cap = ci == 2
            mat = (m("charcoal") if rng.random() < 0.6 else m("violet")) if corrupted else \
                (m("ivory") if (ci + int(a * 10)) % 2 == 0 else m("ivory_shade"))
            p.add(box(((a + b) / 2, 0, (z0 + z1) / 2), (b - a - 0.02, depth - inset * 2, z1 - z0 - 0.02),
                      bevel=0.03 if (is_cap and not corrupted) else 0.0,
                      jitter=0.04 if corrupted else 0.008, rng=rng), mat)
    if corrupted:
        crust(p, rng_for(seed, "crust"), 2, area=0.3, h=(0.2, 0.36), z=0.93)
    else:
        p.add(flat_strip((x0 + 0.04, -depth / 2 + 0.1), (x1 - 0.04, -depth / 2 + 0.1), 0.035, 0.94),
              m("gold", 1.6))


def wall_straight(p, corrupted):
    _wall_courses(p, corrupted, -0.5, 0.5, 0.9, rng_for("wall_straight"), "wall_straight")


def wall_end(p, corrupted):
    rng = rng_for("wall_end")
    _wall_courses(p, corrupted, -0.5, 0.12, 0.9, rng, "wall_end")
    cap_mat = m("charcoal") if corrupted else m("ivory")
    p.add(blob((0.2, 0, 0.42), 0.36, rng_for("wall_end-cap"), jitter=0.2 if corrupted else 0.05,
               squash=1.25), cap_mat)
    if corrupted:
        p.add(shard((0.25, 0, 0.8), 0.35, 0.08, rng_for("wall_end-spike"), tilt=0.3), m("crust"))


def wall_corner(p, corrupted):
    # A full-tile pillar: joins walls on any combination of sides (L, T, +).
    rng = rng_for("wall_corner")
    _wall_courses(p, corrupted, -0.45, 0.45, 0.9, rng, "wall_corner")
    if not corrupted:
        p.add(flat_strip((-0.41, -0.35), (-0.41, 0.35), 0.035, 0.94), m("gold", 1.6))


# --- 6 pool ------------------------------------------------------------------

def pool_surface(p, corrupted):
    rng = rng_for("pool_surface")
    if corrupted:
        p.add(box((0, 0, -0.22), (1.0, 1.0, 0.12)), m("crust"))
        p.add(box((0, 0, -0.08), (1.0, 1.0, 0.02)), m("pool_liquid", 0.25))
        for _ in range(3):
            x, y = rng.uniform(-0.35, 0.35), rng.uniform(-0.35, 0.35)
            p.add(box((x, y, -0.065), (rng.uniform(0.08, 0.18), 0.05, 0.01)), m("violet_glow", 2.0))
    else:
        p.add(box((0, 0, -0.12), (1.0, 1.0, 0.1)), m("ivory_shade"))
        for _ in range(2):
            x, y = rng.uniform(-0.25, 0.25), rng.uniform(-0.25, 0.25)
            p.add(box((x, y, -0.065), (rng.uniform(0.25, 0.4), rng.uniform(0.2, 0.3), 0.01),
                      bevel=0.02), m("water", 0.7))


def pool_rim(p, corrupted):
    # Sits on a pool tile along its north edge; rotate for other edges.
    rng = rng_for("pool_rim")
    if corrupted:
        p.add(box((0, 0.44, -0.02), (1.0, 0.12, 0.1), jitter=0.02, rng=rng), m("violet_glow", 2.2))
        for x in (-0.3, 0.25):
            p.add(shard((x, 0.44, 0.02), rng.uniform(0.14, 0.22), 0.05, rng), m("violet_glow", 1.2))
    else:
        p.add(box((0, 0.42, -0.01), (1.0, 0.16, 0.12), bevel=0.04), m("ivory"))
        p.add(flat_strip((-0.45, 0.35), (0.45, 0.35), 0.03, 0.05), m("gold", 1.4))


# --- 7 river marker ------------------------------------------------------------

def river_marker(p, corrupted):
    rng = rng_for("river_marker")
    p.add(box((0, 0, -0.02), (0.5, 0.5, 0.06), bevel=0.02),
          m("chalk_dark") if corrupted else m("turquoise", 0.8))
    for i, deg in enumerate((90, 210, 330)):
        rib = prism_arc(0.42, 0.11, 0.13, 0.0, math.pi * 0.52, 4, plane="XZ")
        transform(rib, Matrix.Diagonal((1, 1, 1.9, 1)))
        tilt = Matrix.Rotation(rng.uniform(0.25, 0.4) if corrupted else 0.0, 4, "Y")
        spread = 0.14 if corrupted else 0.0
        transform(rib, Matrix.Rotation(math.radians(deg), 4, "Z")
                  @ Matrix.Translation((0.08 + spread, 0, 0)) @ tilt)
        p.add(rib, m("chalk") if corrupted else m("ivory"))
        if not corrupted:
            inset = prism_arc(0.42, 0.04, 0.15, 0.1, math.pi * 0.45, 3, plane="XZ")
            transform(inset, Matrix.Diagonal((1, 1, 1.9, 1)))
            transform(inset, Matrix.Rotation(math.radians(deg), 4, "Z") @ Matrix.Translation((0.08, 0, 0)))
            p.add(inset, m("gold", 1.8))
    if corrupted:
        p.add(shard((0.2, -0.1, 0.0), 0.22, 0.06, rng), m("crust"))
    else:
        ring = prism_arc(0.12, 0.05, 0.05, 0.0, math.tau, 8, center=(0, 0, 0.8), plane="XY")
        p.add(ring, m("gold", 2.0))


# --- 8 tree ----------------------------------------------------------------------

def tree(p, corrupted):
    rng = rng_for("tree")
    if corrupted:
        z = 0.0
        for i, (w, h) in enumerate(((0.3, 0.6), (0.22, 0.55), (0.15, 0.5))):
            seg = box((0, 0, h / 2), (w, w, h), jitter=0.03, rng=rng)
            transform(seg, Matrix.Translation((0, 0, z)) @ Matrix.Rotation(rng.uniform(-0.2, 0.2), 4, "X"))
            p.add(seg, m("charcoal"))
            z += h * 0.95
        for i in range(4):
            yaw = i * math.tau / 4 + rng.uniform(-0.4, 0.4)
            br = box((0, 0, 0.35), (0.06, 0.06, 0.7))
            transform(br, Matrix.Translation((0, 0, z - rng.uniform(0.2, 0.6)))
                      @ Matrix.Rotation(yaw, 4, "Z") @ Matrix.Rotation(0.85, 4, "Y"))
            p.add(br, m("charcoal"))
            tip = shard((0, 0, 0), 0.22, 0.05, rng, tilt=0.2)
            transform(tip, Matrix.Translation((0, 0, z - 0.3)) @ Matrix.Rotation(yaw, 4, "Z")
                      @ Matrix.Rotation(0.85, 4, "Y") @ Matrix.Translation((0, 0, 0.62)))
            p.add(tip, m("violet_glow", 0.8))
        crust(p, rng_for("tree-crust"), 2, area=0.3)
    else:
        p.add(box((0, 0, 0.45), (0.28, 0.28, 0.9), bevel=0.03), m("bark"))
        p.add(box((0, 0, 1.2), (0.2, 0.2, 0.7), bevel=0.02), m("bark"))
        for (x, y, z, r, mat) in ((0, 0, 1.95, 0.72, "leaf"), (0.42, -0.2, 1.6, 0.5, "leaf_light"),
                                  (-0.38, 0.22, 1.7, 0.55, "leaf")):
            p.add(blob((x, y, z), r, rng, jitter=0.12, squash=0.85), m(mat))
        p.add(blob((0.15, -0.35, 2.15), 0.16, rng, jitter=0.1, subdiv=0), m("gold", 1.2))


# --- 9 reed ---------------------------------------------------------------------

def reed(p, corrupted):
    rng = rng_for("reed")
    p.add(blob((0, 0, 0.02), 0.12, rng, squash=0.4, subdiv=1), m("charcoal") if corrupted else m("bark"))
    for i in range(6):
        yaw = i * math.tau / 6 + rng.uniform(-0.3, 0.3)
        tall = rng.uniform(0.35, 0.6) if corrupted else rng.uniform(0.5, 0.8)
        broken = corrupted and i % 3 == 0
        if broken:
            tall *= 0.45
        mat = (m("violet") if i % 2 else m("charcoal")) if corrupted else m("gold")
        p.add(blade((0, 0, 0.02), tall, 0.03, 1.0 if not broken else 0.3, yaw,
                    curl=0.25 if corrupted else 0.35), mat)
        if not corrupted and i % 2 == 0:
            tip = (math.cos(yaw) * 0.35 * 1.1, math.sin(yaw) * 0.35 * 1.1, tall * 1.08 + 0.02)
            p.add(blob(tip, 0.035, rng, jitter=0.05, subdiv=0), m("turquoise", 1.8))


# --- 10 stone chunk ------------------------------------------------------------

def stone_chunk(p, corrupted):
    rng = rng_for("stone_chunk")
    if corrupted:
        p.add(blob((0, 0, 0.32), 0.38, rng, jitter=0.28, squash=0.85), m("charcoal"))
        for _ in range(3):
            base = (rng.uniform(-0.15, 0.15), rng.uniform(-0.15, 0.15), 0.45)
            p.add(shard(base, rng.uniform(0.15, 0.28), 0.06, rng, tilt=0.6), m("crust"))
    else:
        p.add(box((0, 0, 0.3), (0.68, 0.68, 0.58), bevel=0.08), m("ivory"))
        p.add(box((0, 0, 0.3), (0.71, 0.71, 0.06)), m("gold", 1.2))


# --- 11 gate rib ---------------------------------------------------------------

def gate_rib(p, corrupted):
    rng = rng_for("gate_rib")
    if corrupted:
        for x in (-0.38, 0.38):
            p.add(box((x, 0, 0.75), (0.18, 0.3, 1.5), jitter=0.03, rng=rng), m("charcoal"))
            p.add(box((x, -0.16, 0.8), (0.03, 0.02, 1.0)), m("violet_glow", 2.0))
            p.add(shard((x, 0, 1.5), 0.3, 0.08, rng, tilt=0.2), m("crust"))
        for z in (0.35, 0.75, 1.15):
            p.add(box((0, 0, z), (0.62, 0.12, 0.12), jitter=0.02, rng=rng), m("violet"))
    else:
        for x in (-0.38, 0.38):
            p.add(box((x, 0, 0.15), (0.18, 0.3, 0.3), bevel=0.04), m("ivory"))
            p.add(box((x, 0, 0.32), (0.14, 0.24, 0.04)), m("gold", 2.2))


# --- 12 conduit receiver -----------------------------------------------------------

def conduit(p, corrupted):
    rng = rng_for("conduit")
    p.add(box((0, 0, 0.12), (0.62, 0.62, 0.24), bevel=0.04, jitter=0.02 if corrupted else 0.0, rng=rng),
          m("charcoal") if corrupted else m("ivory"))
    p.add(box((0, 0, 0.36), (0.12, 0.12, 0.24)), m("charcoal") if corrupted else m("ivory_shade"))
    ring = prism_arc(0.2, 0.07, 0.07, 0.0, math.tau, 10, center=(0, 0, 0.58), plane="XZ")
    p.add(ring, m("violet") if corrupted else m("turquoise", 1.0))
    p.add(blob((0, 0, 0.58), 0.1, rng, jitter=0.05),
          m("violet_glow", 1.4) if corrupted else m("gold", 2.4))


# --- 13 signal groove ------------------------------------------------------------

def signal_groove(p, corrupted):
    rng = rng_for("signal_groove")
    if corrupted:
        x = -0.5
        while x < 0.5:
            seg = rng.uniform(0.15, 0.3)
            p.add(flat_strip((x, rng.uniform(-0.02, 0.02)), (min(x + seg, 0.5), rng.uniform(-0.02, 0.02)),
                             0.07, 0.02), m("charcoal"))
            x += seg + rng.uniform(0.06, 0.14)
    else:
        p.add(flat_strip((-0.5, 0), (0.5, 0), 0.07, 0.02), m("gold", 1.3))


# --- 14 spillway ring ------------------------------------------------------------

def spillway_ring(p, corrupted):
    # One 30° wedge of a 7 m standing hoop in the XZ plane; origin = ring centre.
    rng = rng_for("spillway_ring")
    a0, a1 = math.radians(75), math.radians(105)
    p.add(prism_arc(7.0, 0.9, 0.9, a0, a1, 4), m("charcoal") if corrupted else m("ivory"))
    if corrupted:
        for _ in range(3):
            a = a0 + rng.uniform(0, 0.08)
            p.add(shard((math.cos(a) * 7.0, rng.uniform(-0.3, 0.3), math.sin(a) * 7.0 - 0.4),
                        rng.uniform(0.3, 0.55), 0.1, rng, tilt=0.8), m("crust"))
    else:
        p.add(prism_arc(7.0, 0.22, 0.95, a0 + 0.01, a1 - 0.01, 4), m("gold", 1.4))


# --- lab-only ---------------------------------------------------------------------

def training_post(p, corrupted):
    rng = rng_for("training_post")
    p.add(box((0, 0, 0.05), (0.7, 0.7, 0.1), bevel=0.03), m("chalk_dark") if corrupted else m("ivory_shade"))
    z = 0.1
    for i, (w, h) in enumerate(((0.5, 0.32), (0.44, 0.3), (0.38, 0.28))):
        mat = (m("charcoal") if i % 2 == 0 else m("violet")) if corrupted else m("ivory")
        p.add(box((0, 0, z + h / 2), (w, w, h - 0.02), bevel=0.03, jitter=0.02 if corrupted else 0.0,
                  rng=rng), mat)
        z += h
    if corrupted:
        crust(p, rng_for("post-crown"), 3, area=0.1, h=(0.18, 0.3), z=z - 0.02)
    else:
        p.add(box((0, 0, 0.42), (0.46, 0.46, 0.05)), m("turquoise", 1.6))
        p.add(blob((0, 0, z + 0.1), 0.14, rng, jitter=0.06), m("gold", 1.4))


def pad_weight(p, corrupted):
    rng = rng_for("pad_weight")
    for x in (-0.5, 0.5):
        for y in (-0.5, 0.5):
            p.add(box((x, y, -0.03), (0.94, 0.94, 0.12), bevel=0.03, jitter=0.01, rng=rng),
                  m("floor_c") if corrupted else m("floor_2"))
    border = m("chalk") if corrupted else m("gold", 1.1)
    for (a, b) in (((-0.98, -0.98), (0.98, -0.98)), ((-0.98, 0.98), (0.98, 0.98)),
                   ((-0.98, -0.98), (-0.98, 0.98)), ((0.98, -0.98), (0.98, 0.98))):
        p.add(flat_strip(a, b, 0.06, 0.03), border)
    p.add(box((0, 0, 0.1), (0.4, 0.4, 0.14), bevel=0.03), m("charcoal") if corrupted else m("ivory"))
    p.add(box((0, 0, 0.22), (0.26, 0.26, 0.1), bevel=0.02), m("charcoal") if corrupted else m("ivory"))


def pad_charge(p, corrupted):
    p.add(box((0, 0, -0.04), (2.0, 2.0, 0.1), bevel=0.03), m("charcoal"))
    glow = 0.35 if corrupted else 1.8
    for r in (0.85, 0.55, 0.25):
        for (a, b) in (((-r, -r), (r, -r)), ((-r, r), (r, r)), ((-r, -r), (-r, r)), ((r, -r), (r, r))):
            p.add(flat_strip(a, b, 0.06, 0.01), m("turquoise", glow))


# --- registry ---------------------------------------------------------------------

FAMILIES = {
    "ground": {f"ground_{v}": ground(v) for v in "abc"},
    "bank_straight": {"bank_straight": bank_straight},
    "bank_corner": {"bank_corner_outer": bank_corner_outer, "bank_corner_inner": bank_corner_inner},
    "wall_straight": {"wall_straight": wall_straight},
    "wall_end": {"wall_end": wall_end, "wall_corner": wall_corner},
    "pool": {"pool_surface": pool_surface, "pool_rim": pool_rim},
    "river_marker": {"river_marker": river_marker},
    "tree": {"tree": tree},
    "reed": {"reed": reed},
    "stone_chunk": {"stone_chunk": stone_chunk},
    "gate_rib": {"gate_rib": gate_rib},
    "conduit": {"conduit": conduit},
    "signal_groove": {"signal_groove": signal_groove},
    "spillway_ring": {"spillway_ring": spillway_ring},
    "training_post": {"training_post": training_post},
    "pad": {"pad_weight": pad_weight, "pad_charge": pad_charge},
}
