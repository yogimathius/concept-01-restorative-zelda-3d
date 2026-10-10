class_name RegionBuilder
extends Node3D
## Builds a region from GridLevel text + a manifest: floors, banks, walls
## and pools on a GridMap (MeshLibrary made from the kit, with per-cell
## collision), chasm holes with hazard volumes, and KitPiece / creature
## nodes for everything that transforms.
##
## The opening journey heals stationary groves and springs, creates bridges,
## opens passages and restores the surrounding ground and vegetation.
## restoration_only=false retains the earlier encounter mechanics for tests.

signal restored(id: String)

const BEARER: PackedScene = preload("res://assets/creatures/bearer.glb")
const BRIDGE: PackedScene = preload("res://assets/creatures/bearer_bridge.glb")
const CHARGER: PackedScene = preload("res://assets/creatures/charger.glb")
const TURRET: PackedScene = preload("res://assets/creatures/charger_turret.glb")
const TOON: ShaderMaterial = preload("res://shaders/toon_outline_material.tres")

const GROUND_CHARS := ".,PCBKOL123456789G"
const ORTH := [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]  # S E N W
const STRAIGHT_YAW := {Vector2i(0, 1): 0.0, Vector2i(1, 0): 90.0, Vector2i(0, -1): 180.0, Vector2i(-1, 0): 270.0}

const BEARER_SCALE := 1.35
const CHARGER_SCALE := 1.15

@export_file("*.txt") var level_path := "res://levels/region1.txt"
@export var restoration_only := true
@export var region_id := "R1"
@export var valley_mode := false
var valley: RiverValley
var manifest: GDScript = Region1Manifest

var level: GridLevel
var grid: GridMap
var spawn := Vector3.ZERO
var entities := {}          # id -> {kind, cell, node, body, ...}
var _items := {}            # "shape_variant" -> MeshLibrary item id
var _restored_cells := {}   # Vector2i -> true
var _cell_hazards := {}     # Vector2i -> HazardZone (chasm cells)
var _pool_hazards := {}     # pool id -> HazardZone
var _pool_rims := {}        # pool id -> Array[KitPiece]
var _next := 0
var _generation := 0
var _replaying := false
var ability_journey := false

func _ready() -> void:
	manifest = Region2Manifest if region_id == "R2" else Region1Manifest
	level = GridLevel.load_file(level_path)
	if restoration_only and region_id == "R1":
		# An open southern walking loop replaces the old maze-like backtrack.
		for x in [31, 32]:
			for z in [17, 18]:
				var at := Vector2i(x, z)
				var area := level.area_at(at)
				var local := at - area.origin
				var row: String = area.rows[local.y]
				area.rows[local.y] = row.left(local.x) + "." + row.substr(local.x + 1)
	if not valley_mode: _build_library()
	grid = GridMap.new()
	grid.name = "Grid"
	grid.mesh_library = _library
	grid.cell_size = Vector3.ONE
	grid.cell_center_y = false
	add_child(grid)
	if not valley_mode:
		for c in level.cells(): _place_cell(c)
	else:
		spawn = Vector3(5.5,0.02,6.5)
	_place_entities()
	if valley_mode:
		valley = RiverValley.new()
		valley.builder = self
		add_child(valley)
		for id in manifest.GATES:
			entities[id].body.get_child(0).disabled = true
			for piece in entities[id].pieces: piece.hide()
		for id in manifest.CONDUITS: entities[id].node.hide()
	if not valley_mode: _place_landing()
	_place_scenery()
	var kill := _hazard(Vector3(24, -6, 12), Vector3(220 if valley_mode else 120, 1, 220 if valley_mode else 120))
	kill.name = "KillFloor"
	_place_void()

# --- mesh library ----------------------------------------------------------------

var _library := MeshLibrary.new()

func _build_library() -> void:
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(1, 0.2, 1)
	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(1, 1, 1)
	var entries := []
	for v in ["corrupted", "restored"]:
		for letter in "abc":
			entries.append(["ground", "ground_%s_%s" % [letter, v], floor_shape, -0.1])
		entries.append(["bank_straight", "bank_straight_" + v, floor_shape, -0.1])
		entries.append(["bank_corner", "bank_corner_outer_" + v, floor_shape, -0.1])
		entries.append(["bank_corner", "bank_corner_inner_" + v, floor_shape, -0.1])
		entries.append(["pool", "pool_surface_" + v, floor_shape, -0.1])
		entries.append(["wall_straight", "wall_straight_" + v, wall_shape, 0.5])
		entries.append(["wall_end", "wall_end_" + v, wall_shape, 0.5])
		entries.append(["wall_end", "wall_corner_" + v, wall_shape, 0.5])
	for e in entries:
		var id := _items.size()
		_library.create_item(id)
		_library.set_item_name(id, e[1])
		var mesh: Mesh = KitLibrary.mesh(e[0], e[1]).duplicate()
		for surface in mesh.get_surface_count():
			var material: Material = mesh.surface_get_material(surface).duplicate()
			material.next_pass = null
			mesh.surface_set_material(surface, material)
		if e[0] in ["ground", "pool"]:
			for surface in mesh.get_surface_count():
				var material: ShaderMaterial = mesh.surface_get_material(surface).duplicate()
				material.next_pass = null
				material.set_shader_parameter("terrain_variation", 0.16)
				mesh.surface_set_material(surface, material)
		_library.set_item_mesh(id, mesh)
		_library.set_item_shapes(id, [e[2], Transform3D(Basis(), Vector3(0, e[3], 0))])
		_items[e[1]] = id

func _put(cell: Vector2i, item: String, yaw := 0.0) -> void:
	if valley_mode: return
	var orient := grid.get_orthogonal_index_from_basis(Basis(Vector3.UP, deg_to_rad(yaw)))
	grid.set_cell_item(Vector3i(cell.x, 0, cell.y), _items[item], orient)

# --- cells --------------------------------------------------------------------------------

func _state(cell: Vector2i, ch: String, area: GridLevel.Area) -> String:
	if _restored_cells.has(cell):
		return "restored"
	if ch == ",":
		return "restored"
	if ch == ".":
		return "corrupted"
	return area.default_state

func _is_ground(ch: String) -> bool:
	return ch != "" and GROUND_CHARS.contains(ch)

func _place_cell(c: GridLevel.Cell) -> void:
	var st := _state(c.cell, c.ch, c.area)
	match c.ch:
		"_":
			var hz := _hazard(Vector3(c.cell.x + 0.5, 0, c.cell.y + 0.5), Vector3(1.0, 3, 1.0), -2.0)
			_cell_hazards[c.cell] = hz
		"#":
			_place_wall(c.cell, st)
		"~":
			_put(c.cell, "pool_surface_" + st)
		_:
			if _is_ground(c.ch):
				_place_ground(c.cell, st)
	if c.ch == "P":
		spawn = Vector3(c.cell.x + 0.5, 0.02, c.cell.y + 0.5)

func _place_ground(cell: Vector2i, st: String) -> void:
	var drops := []
	for d in ORTH:
		if level.char_at(cell + d) == "_" and not _bridged(cell + d):
			drops.append(d)
	if drops.size() == 1 or (drops.size() == 2 and drops[0] == -drops[1]):
		_put(cell, "bank_straight_" + st, STRAIGHT_YAW[drops[0]])
	elif drops.size() == 2:
		var pair := {drops[0]: true, drops[1]: true}
		var yaw := 0.0
		if pair.has(Vector2i(1, 0)) and pair.has(Vector2i(0, -1)):
			yaw = 90.0
		elif pair.has(Vector2i(0, -1)) and pair.has(Vector2i(-1, 0)):
			yaw = 180.0
		elif pair.has(Vector2i(-1, 0)) and pair.has(Vector2i(0, 1)):
			yaw = 270.0
		_put(cell, "bank_corner_outer_" + st, yaw)
	else:
		var inner := {Vector2i(1, 1): 0.0, Vector2i(1, -1): 90.0, Vector2i(-1, -1): 180.0, Vector2i(-1, 1): 270.0}
		for d in inner:
			if drops.is_empty() and level.char_at(cell + d) == "_" and not _bridged(cell + d):
				_put(cell, "bank_corner_inner_" + st, inner[d])
				return
		var path := (cell.y in [4, 5, 6] and cell.x < 16) or (cell.y in [3, 7] and cell.x >= 16 and cell.x < 32) or (cell.x in [34, 35, 36, 39, 40] and cell.y < 12) or (cell.y in [16, 17, 18] and cell.x >= 32)
		var letter: String = ["b", "c"][absi(cell.x * 7 + cell.y * 13) % 2] if path else "a"
		_put(cell, "ground_%s_%s" % [letter, st], [0.0, 90.0, 180.0, 270.0][absi(cell.x * 3 + cell.y * 5) % 4])

func _place_wall(cell: Vector2i, st: String) -> void:
	var n := {}
	for d in ORTH:
		n[d] = level.char_at(cell + d) == "#"
	var ew: bool = n[Vector2i(1, 0)] and n[Vector2i(-1, 0)]
	var ns: bool = n[Vector2i(0, 1)] and n[Vector2i(0, -1)]
	var count := n.values().count(true)
	if count == 2 and ew:
		_put(cell, "wall_straight_" + st, 0.0)
	elif count == 2 and ns:
		_put(cell, "wall_straight_" + st, 90.0)
	elif count == 1:
		var yaw := 0.0
		if n[Vector2i(1, 0)]:
			yaw = 180.0
		elif n[Vector2i(0, 1)]:
			yaw = 90.0
		elif n[Vector2i(0, -1)]:
			yaw = 270.0
		_put(cell, "wall_end_" + st, yaw)
	else:
		_put(cell, "wall_corner_" + st)

func _bridged(cell: Vector2i) -> bool:
	return _restored_cells.get(cell, false) is String   # bridge cells are tagged "bridge"

# --- entities ------------------------------------------------------------------------------

func _world_cell(area_id: String, colrow: Vector2i) -> Vector2i:
	for a in level.areas:
		if a.id == area_id:
			return a.origin + colrow - Vector2i.ONE
	push_error("unknown area " + area_id)
	return Vector2i.ZERO

func _center(cell: Vector2i) -> Vector3:
	return Vector3(cell.x + 0.5, 0, cell.y + 0.5)

func _place_entities() -> void:
	for id in manifest.ENTITIES:
		var spec: Dictionary = manifest.ENTITIES[id].duplicate(true)
		if restoration_only and id == "B1": spec.socket = Vector2i(8, 6)
		var cell := _world_cell(spec.area, spec.at)
		var scene := BEARER if spec.kind == "bearer" else CHARGER
		var actor := RegionCreature.new()
		actor.id = id
		actor.kind = spec.kind
		actor.builder = self
		actor.hero = get_parent().get_node("Hero")
		var bounds := {"B1": Rect2(17.5, 2.5, 6.8, 5.8), "C1": Rect2(36.5, 3.5, 7.8, 3.8),
			"B2": Rect2(18.5, 19.5, 7.8, 3.8), "C2": Rect2(23.5, 13.5, 5.8, 4.8),
			"B3": Rect2(35.5, 19.5, 4.8, 1.8), "C3": Rect2(41.5, 15.5, 3.8, 4.8)}
		actor.home = bounds.get(id, Rect2(Vector2(level.area_at(cell).origin) + Vector2.ONE, Vector2(14,10)))
		var collision := CollisionShape3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = 0.55 if spec.kind == "bearer" else 0.3
		shape.height = 1.2
		collision.shape = shape
		collision.position.y = 0.6
		collision.disabled = restoration_only
		actor.add_child(collision)
		var model: Node3D
		if restoration_only:
			var place := KitPiece.new()
			place.family = spec.get("visual", "tree" if spec.kind == "bearer" else "river_marker")
			place.shape = place.family
			if region_id == "R1" and id == "B1":
				place.family = "homecoming_grove"
				place.shape = "grove"
			place.unique_materials = true
			place.scale = Vector3.ONE * (0.7 if spec.kind == "bearer" else 0.85)
			model = place
		else:
			model = scene.instantiate()
			model.scale = Vector3.ONE * (BEARER_SCALE if spec.kind == "bearer" else CHARGER_SCALE)
		actor.add_child(model)
		actor.model = model
		actor.position = ValleyPlaces.point(ValleyPlaces.POSITIONS[id]) if valley_mode and ValleyPlaces.POSITIONS.has(id) else _center(cell)
		entities[id] = {"kind": spec.kind, "cell": cell, "node": model, "body": actor, "runtime": actor, "spec": spec}
		add_child(actor)
		ToonUtil.apply_toon(model, TOON)
		actor._play("idle-loop")
	for id in manifest.CONDUITS:
		var spec: Dictionary = manifest.CONDUITS[id]
		var cell := _world_cell(spec.area, spec.at)
		entities[id] = {"kind": "conduit", "cell": cell, "node": _piece("conduit", "conduit", _center(cell), false)}
	for id in manifest.GATES:
		var spec: Dictionary = manifest.GATES[id]
		var cells: Array = spec.cells.map(func(cr): return _world_cell(spec.area, cr))
		var pieces := []
		var vertical: bool = cells.size() > 1 and cells[0].x == cells[1].x
		var lo := Vector3(INF, 0, INF)
		var hi := Vector3(-INF, 0, -INF)
		for cell in cells:
			var p := _piece("gate_rib", "gate_rib", _center(cell), false)
			p.rotation.y = deg_to_rad(90.0 if vertical else 0.0)
			pieces.append(p)
			lo = lo.min(_center(cell))
			hi = hi.max(_center(cell))
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(hi.x - lo.x + 1.0, 1.5, hi.z - lo.z + 1.0)
		shape.shape = box
		body.add_child(shape)
		add_child(body)
		body.global_position = (lo + hi) * 0.5 + Vector3.UP * 0.75
		entities[id] = {"kind": "gate", "cells": cells, "pieces": pieces, "body": body}
	for id in ([] if valley_mode else manifest.POOLS.keys()):
		var spec: Array = manifest.POOLS[id]
		var corner := _world_cell(spec[0], spec[1])
		var size: Vector2i = spec[2]
		var center := Vector3(corner.x + size.x * 0.5, 0, corner.y + size.y * 0.5)
		if not restoration_only: _pool_hazards[id] = _hazard(center, Vector3(size.x - 0.3, 1, size.y - 0.3))
		_pool_rims[id] = []
		for x in size.x:
			for y in size.y:
				var cell := corner + Vector2i(x, y)
				for side in [[Vector2i(0, -1), 0.0], [Vector2i(-1, 0), 90.0], [Vector2i(0, 1), 180.0], [Vector2i(1, 0), 270.0]]:
					if level.char_at(cell + side[0]) != "~":
						var rim := _piece("pool", "pool_rim", _center(cell), false)
						rim.rotation.y = deg_to_rad(side[1])
						_pool_rims[id].append(rim)
	for c in level.find("L"):
		var lm: Array = manifest.LANDMARKS.get(c.area.id, ["river_marker", false])
		var node := _piece(lm[0], lm[0], _center(c.cell), lm[1])
		if manifest.ANCHOR_AREA.values().has(c.area.id):
			entities["A1"] = {"kind": "anchor", "cell": c.cell, "node": node}
	for c in level.find("O"):
		if not restoration_only: spawn_block(c.cell, c.area.default_state == "restored")

func _creature(scene: PackedScene, at: Vector3, anim: String, scale_by := 1.0) -> Node3D:
	var model: Node3D = scene.instantiate()
	add_child(model)
	model.global_position = at
	model.scale = Vector3.ONE * scale_by
	ToonUtil.apply_toon(model, TOON)
	var ap := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap and not ap.has_animation(anim) and ap.has_animation(anim + "-loop"):
		anim += "-loop"
	if ap and ap.has_animation(anim):
		ap.play(anim)
		ap.seek(randf() * ap.current_animation_length)
	return model

func _piece(family: String, shape: String, at: Vector3, restored: bool) -> KitPiece:
	var p := KitPiece.new()
	p.family = family
	p.shape = shape
	p.restored = restored
	add_child(p)
	p.global_position = at
	return p

func _blocker(at: Vector3, radius: float) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = radius
	cyl.height = 1.0
	shape.shape = cyl
	body.add_child(shape)
	add_child(body)
	body.global_position = at + Vector3.UP * 0.5
	return body

func _hazard(at: Vector3, size: Vector3, y_offset := 0.0) -> HazardZone:
	var hz := HazardZone.new()
	hz.size = size
	hz.y_offset = y_offset
	hz.show_visual = false
	add_child(hz)
	hz.global_position = at
	return hz

func _place_void() -> void:
	# a dark floor far below, so chasms and the level edge read as a drop
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/river.gdshader")
	plane.material = mat
	var mi := MeshInstance3D.new()
	mi.name = "Void"
	mi.mesh = plane
	add_child(mi)
	mi.global_position = Vector3(24, -0.85, 12)

# --- landing + scenery ---------------------------------------------------------------------

func _place_landing() -> void:
	# World design §4 S5: three-tile landing past G2, then a temporary rail.
	for x in range(48, 51):
		for z in range(16, 19):
			_place_ground(Vector2i(x, z), "restored")
	for z in range(16, 19):
		_put(Vector2i(51, z), "wall_straight_corrupted", 90.0)   # the temporary rail
	for x in range(48, 52):
		_put(Vector2i(x, 15), "wall_straight_restored", 0.0)
		_put(Vector2i(x, 19), "wall_straight_restored", 0.0)
	var sign := Label3D.new()
	sign.text = "Reedglass Marsh
Talk to Oren at the landing"
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.font_size = 48
	sign.outline_size = 12
	sign.modulate = Color(0.95, 0.9, 0.75)
	add_child(sign)
	sign.global_position = Vector3(50.5, 1.4, 17.5)

func _place_scenery() -> void:
	if valley_mode: return
	var old := get_node_or_null("Scenery")
	if old:
		remove_child(old)
		old.queue_free()
	var dresser := KitDresser.new()
	dresser.name = "Scenery"
	add_child(dresser)
	for c in level.cells():
		var st := _state(c.cell, c.ch, c.area)
		var h := absi(c.cell.x * 73856093 ^ c.cell.y * 19349663)
		# trees just outside the north/west/east walls (never south: camera side)
		if c.ch == "#":
			for d in [Vector2i(0, -1), Vector2i(-1, 0), Vector2i(1, 0)]:
				var out: Vector2i = c.cell + d * 2
				if level.char_at(c.cell + d) == "" and level.char_at(out) == "" and h % 4 == 0:
					dresser.place("tree", "tree_" + st, _center(out), float(h % 360), 0.8 + (h % 30) / 100.0)
		# reeds on banks
		if _is_ground(c.ch) and h % 5 == 0:
			for d in ORTH:
				if level.char_at(c.cell + d) == "_":
					dresser.place("reed", "reed_" + st, _center(c.cell), float(h % 360), 0.8)
					break
	# Sparse bankside planting, deliberately outside the open fight rectangles.
	for c in level.cells():
		if not _is_ground(c.ch): continue
		var near_wall := level.char_at(c.cell + Vector2i(-1, 0)) == "#" or level.char_at(c.cell + Vector2i(1, 0)) == "#" or level.char_at(c.cell + Vector2i(0, 1)) == "#"
		if not near_wall: continue
		var h := absi(c.cell.x * 93263 + c.cell.y * 37181)
		if h % 3 != 0: continue
		var st := _state(c.cell, c.ch, c.area)
		for i in 3:
			var offset := Vector3(float((h + i * 11) % 13) / 25.0 - 0.24, 0, float((h + i * 7) % 13) / 25.0 - 0.24)
			dresser.place("reed", "reed_" + st, _center(c.cell) + offset, float(h % 360 + i * 81), 0.65 + i * 0.08)
	# The safe landing is a small planted garden, not a bare test room.
	for grove in [[Vector3(10.8, 0, 1.9), 1.35], [Vector3(13.9, 0, 2.7), 1.15], [Vector3(2.1, 0, 2.0), 1.0]]:
		dresser.place("tree", "tree_restored", grove[0], 37, grove[1])
	for bush in [Vector3(4.2, 0, 10.2), Vector3(8.1, 0, 10.5), Vector3(12.2, 0, 10.4)]:
		dresser.place("tree", "tree_restored", bush, 82, 0.38)
	# Paired amber notches make the two possible bridge approaches legible.
	for socket in ([] if restoration_only else manifest.ENTITIES.B1.sockets):
		var cell := _world_cell("R1-S2", socket)
		for offset in [-0.35, 0.35]:
			dresser.place("stone_chunk", "stone_chunk_restored", _center(cell) + Vector3(0.38, 0, offset), 18, 0.22)
	# A broken architectural silhouette, not a repeating little wall prop.
	# the snapped spillway ring arching over the ford's north end
	for i in range(5):
		if i == 2:
			continue   # the snap
		var basis := Basis(Vector3.BACK, deg_to_rad(-60.0 + i * 30.0)).scaled(Vector3.ONE * 0.85)
		dresser.place_xform("spillway_ring", "spillway_ring_corrupted", Transform3D(basis, Vector3(25.5, -0.8, -1.8)))
	dresser.build()

# --- restoration -----------------------------------------------------------------------------

func restore_next() -> String:
	while _next < manifest.RESTORE_ORDER.size():
		var id: String = manifest.RESTORE_ORDER[_next]
		_next += 1
		if restore(id):
			return id
	return ""

func restore(id: String) -> bool:
	if not entities.has(id) or entities[id].get("restored", false):
		return false
	var e: Dictionary = entities[id]
	e["restored"] = true
	var spec: Dictionary = e.spec
	var at: Vector3 = e.runtime.global_position if valley_mode else _center(e.cell)
	e.runtime.restored = true
	if not _replaying and (not restoration_only or region_id != "R1"):
		Juice.wave(at + Vector3.UP * 0.4, 3.5, Color(0.35, 1.0, 0.75), 0.8)
		Juice.burst(at + Vector3.UP * 0.6, Color(1.0, 0.85, 0.45), 36)
		Juice.sfx("restore")
		Juice.shake(0.25)
	if restoration_only:
		e.node.set_restored(true, not _replaying)
		e.runtime.progress = 1.0
		if e.kind == "bearer" and spec.has("socket") and (not valley_mode or id=="B1"): _restore_bearer(e, spec)
		if spec.has("conduit"): power_conduit(spec.conduit)
	else:
		if e.kind == "bearer" and spec.has("socket"): _restore_bearer(e, spec)
		else: _restore_charger(e, spec)
	if spec.has("pool"):
		_clear_pool(spec.pool)
	if spec.has("wakes") and entities.has(spec.wakes):
		entities[spec.wakes].node.set_restored(true, true)
	if id == ("M3" if region_id == "R2" else "B1") or (ability_journey and region_id == "R1" and id == "C3"):
		var river: ShaderMaterial = $Void.mesh.material
		var recovery := 0.35 if ability_journey and region_id == "R1" and id == "B1" else 1.0
		if _replaying: river.set_shader_parameter("restored", recovery)
		else:
			var previous = river.get_shader_parameter("restored")
			var start := float(previous) if previous is float or previous is int else 0.0
			create_tween().bind_node($Void).tween_method(func(value: float): river.set_shader_parameter("restored", value), start, recovery, 1.2)
	if valley_mode: valley.refresh_restoration()
	else: _ripple(e.cell, 20 if restoration_only or id in ["B1", "C1"] else 6)
	if not _replaying: _place_scenery()
	restored.emit(id)
	return true

func _restore_bearer(e: Dictionary, spec: Dictionary) -> void:
	if not restoration_only:
		e.node.visible = false
		e.body.get_child(0).set_deferred("disabled", true)
	var socket := _world_cell(spec.area, spec.socket)
	var dir: Vector2i = spec.bridge_dir
	var length: int = spec.bridge_len
	var edge := _center(socket) + Vector3(dir.x, 0, dir.y) * 0.5
	var bridge: Node3D = BRIDGE.instantiate()
	add_child(bridge)
	ToonUtil.apply_toon(bridge, TOON)
	bridge.global_transform = Transform3D(
		Basis(Vector3.UP, deg_to_rad(STRAIGHT_YAW[dir])) * Basis.from_scale(Vector3(1, 1, length / 3.0)), edge)
	var half_width := (3 if valley_mode else 1) if restoration_only and e.runtime.id == "B1" else 0
	if half_width > 0: bridge.scale.x *= float(half_width*2+1)
	if not _replaying:
		if not restoration_only:
			e.node.visible = true
			var morph := create_tween().bind_node(e.node).set_parallel(true)
			morph.tween_property(e.node, "global_position", _center(socket), 0.4)
			morph.tween_property(e.node, "scale", Vector3.ONE * 0.05, 0.4)
			morph.chain().tween_callback(e.node.hide)
		var final_scale := bridge.scale
		bridge.scale = final_scale * Vector3(1, 1, 0.08)
		create_tween().bind_node(bridge).tween_property(bridge, "scale", final_scale, 1.7 if restoration_only and e.runtime.id=="B1" else 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	e["bridge"] = bridge
	for side in range(-half_width, half_width + 1):
		var start := socket + Vector2i(-dir.y, dir.x) * side
		for i in length:
			var cell := start + dir * (i + 1)
			_restored_cells[cell] = "bridge"
			if _cell_hazards.has(cell):
				_cell_hazards[cell].queue_free()
				_cell_hazards.erase(cell)
			var deck := StaticBody3D.new()
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(1, 0.2, 1)
			shape.shape = box
			deck.add_child(shape)
			add_child(deck)
			deck.global_position = _center(cell) + Vector3.DOWN * 0.1
		_refresh_banks_near(start, dir, length)
	# banks beside the bridge lose their drop on the bridged side
	_refresh_banks_near(socket, dir, length)

func _refresh_banks_near(socket: Vector2i, dir: Vector2i, length: int) -> void:
	for i in range(0, length + 2):
		var cell := socket + dir * i
		for d in [Vector2i.ZERO] + ORTH:
			var n: Vector2i = cell + d
			var ch := level.char_at(n)
			if _is_ground(ch):
				_place_ground(n, _state(n, ch, level.area_at(n)))

func _restore_charger(e: Dictionary, spec: Dictionary) -> void:
	var at := _center(e.cell)
	e.node.queue_free()
	e.node = _creature(TURRET, at, "idle", CHARGER_SCALE)
	e.runtime.model = e.node
	e.runtime.recovery_left = 0.25

func _clear_pool(id: String) -> void:
	if _pool_hazards.has(id):
		_pool_hazards[id].queue_free()
		_pool_hazards.erase(id)
	for rim in _pool_rims.get(id, []):
		rim.set_restored(true, true)
	var spec: Array = manifest.POOLS[id]
	var corner := _world_cell(spec[0], spec[1])
	for x in spec[2].x:
		for y in spec[2].y:
			var cell: Vector2i = corner + Vector2i(x, y)
			_restored_cells[cell] = true
			_put(cell, "pool_surface_restored")

## Ground and walls within radius heal outward in rings (0.12 s per ring).
func _ripple(center: Vector2i, radius: int) -> void:
	var area := level.area_at(center)
	for c in level.cells():
		if c.area != area or c.ch == "_" or c.ch == "~":
			continue
		var d := Vector2(c.cell - center).length()
		if d > radius or _restored_cells.has(c.cell):
			continue
		_restored_cells[c.cell] = true
		var cell := c
		var delay := d * 0.12
		var generation := _generation
		if _replaying:
			_place_cell(cell)
			continue
		get_tree().create_timer(delay, true, false, true).timeout.connect(func() -> void:
			if not is_inside_tree() or generation != _generation:
				return
			if cell.ch == "#":
				_place_wall(cell.cell, "restored")
			else:
				_place_ground(cell.cell, "restored"))


func surface_height(at: Vector2) -> float:
	return RiverValley.height_at(at) if valley_mode else 0.0

func can_walk(cell: Vector2i) -> bool:
	if valley_mode: return valley.walkable(Vector2(cell)+Vector2.ONE*0.5)
	if region_id == "R1" and cell.x in [48,49,50] and cell.y in [16,17,18]: return true
	var ch := level.char_at(cell)
	if ch == "_": return _bridged(cell)
	if ch == "~" or ch == "#" or ch == "": return false
	if ch == "G":
		for id in manifest.GATES:
			if entities[id].cells.has(cell): return entities[id].get("powered", false)
	return true

func spawn_block(cell: Vector2i, restored := false) -> PushBlock:
	var block := PushBlock.new()
	block.builder = self
	block.cell = cell
	block.restored = restored
	block.position = _center(cell)
	add_child(block)
	return block

func drop_chunk(at: Vector3, direction: Vector3) -> void:
	var first := Vector2i(floori(at.x + direction.x * 1.4), floori(at.z + direction.z * 1.4))
	var candidates := [first]
	for d in ORTH: candidates.append(first + d)
	var origin := Vector2i(floori(at.x), floori(at.z))
	for d in ORTH: candidates.append(origin + d * 2)
	for cell in candidates:
		if not can_walk(cell): continue
		var occupied := false
		for block in get_tree().get_nodes_in_group("push_block"):
			if block.cell == cell: occupied = true
		for creature in get_tree().get_nodes_in_group("creature"):
			if not creature.restored and _center(cell).distance_to(creature.global_position) < 1.0: occupied = true
		if occupied: continue
		spawn_block(cell)
		return

func try_power_near(at: Vector3, radius: float) -> bool:
	for id in manifest.CONDUITS:
		var offset := _center(entities[id].cell) - at
		offset.y = 0
		if offset.length() < radius:
			power_conduit(id)
			return true
	return false

func power_conduit(id: String) -> void:
	if entities[id].get("powered", false): return
	entities[id]["powered"] = true
	entities[id].node.set_restored(true, not _replaying)
	var gate_id: String = manifest.CONDUITS[id].gate
	var gate: Dictionary = entities[gate_id]
	gate["powered"] = true
	gate.body.get_child(0).set_deferred("disabled", true)
	for piece in gate.pieces:
		piece.set_restored(true, not _replaying)
		if _replaying: piece.position.y = -1.4
		else: create_tween().tween_property(piece, "position:y", -1.4, 0.6)
	if not _replaying:
		Juice.sfx("anchor")

func capture_snapshot() -> Dictionary:
	var creatures := {}
	for id in manifest.ENTITIES:
		var e: Dictionary = entities[id]
		creatures[id] = {"runtime": e.runtime.snapshot(), "spec": e.spec.duplicate(true), "cell": e.cell}
	var powered := []
	for id in manifest.CONDUITS:
		if entities[id].get("powered", false): powered.append(id)
	var blocks := []
	for block in get_tree().get_nodes_in_group("push_block"):
		if block.builder == self and not block.is_queued_for_deletion(): blocks.append({"cell": block.cell, "restored": block.restored})
	return {"creatures": creatures, "powered": powered, "blocks": blocks, "cells": _restored_cells.duplicate(true), "next": _next}

func rollback(snapshot: Dictionary) -> void:
	_generation += 1
	for child in get_children(): child.free()
	entities.clear()
	_items.clear()
	_restored_cells.clear()
	_cell_hazards.clear()
	_pool_hazards.clear()
	_pool_rims.clear()
	_library = MeshLibrary.new()
	_replaying = true
	_ready()
	for block in get_tree().get_nodes_in_group("push_block"):
		if block.builder == self: block.free()
	for id in snapshot.creatures:
		var data: Dictionary = snapshot.creatures[id]
		var e: Dictionary = entities[id]
		e.spec = data.spec.duplicate(true)
		e.cell = data.cell
		e.runtime.apply_snapshot(data.runtime)
		if data.runtime.restored: restore(id)
	for id in snapshot.powered: power_conduit(id)
	for data in snapshot.blocks: spawn_block(data.cell, data.restored)
	_restored_cells = snapshot.cells.duplicate(true)
	if not valley_mode:
		for c in level.cells():
			if c.ch != "_": _place_cell(c)
	_next = snapshot.next
	_place_scenery()
	_replaying = false
