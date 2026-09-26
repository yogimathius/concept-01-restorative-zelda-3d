class_name RegionBuilder
extends Node3D
## Builds a region from GridLevel text + a manifest: floors, banks, walls
## and pools on a GridMap (MeshLibrary made from the kit, with per-cell
## collision), chasm holes with hazard volumes, and KitPiece / creature
## nodes for everything that transforms.
##
## restore(id) plays a creature's authored restoration (bridge / turret,
## gate, pool, ground ripple). Until creature AI exists (systems step 2+) the
## region scene drives it from the F2 "restore next" debug key.

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

func _ready() -> void:
	level = GridLevel.load_file(level_path)
	_build_library()
	grid = GridMap.new()
	grid.name = "Grid"
	grid.mesh_library = _library
	grid.cell_size = Vector3.ONE
	grid.cell_center_y = false
	add_child(grid)
	for c in level.cells():
		_place_cell(c)
	_place_entities()
	_place_landing()
	_place_scenery()
	var kill := _hazard(Vector3(24, -6, 12), Vector3(120, 1, 120))
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
		_library.set_item_mesh(id, KitLibrary.mesh(e[0], e[1]))
		_library.set_item_shapes(id, [e[2], Transform3D(Basis(), Vector3(0, e[3], 0))])
		_items[e[1]] = id

func _put(cell: Vector2i, item: String, yaw := 0.0) -> void:
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
			var hz := _hazard(Vector3(c.cell.x + 0.5, 0, c.cell.y + 0.5), Vector3(0.5, 3, 0.5), -2.0)
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
		var letter: String = ["a", "b", "c"][absi(cell.x * 7 + cell.y * 13) % 3]
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
	for id in Region1Manifest.ENTITIES:
		var spec: Dictionary = Region1Manifest.ENTITIES[id]
		var cell := _world_cell(spec.area, spec.at)
		var scene := BEARER if spec.kind == "bearer" else CHARGER
		var model := _creature(scene, _center(cell), "idle", BEARER_SCALE if spec.kind == "bearer" else CHARGER_SCALE)
		var body := _blocker(_center(cell), 0.55 if spec.kind == "bearer" else 0.3)
		entities[id] = {"kind": spec.kind, "cell": cell, "node": model, "body": body, "spec": spec}
	for id in Region1Manifest.CONDUITS:
		var spec: Dictionary = Region1Manifest.CONDUITS[id]
		var cell := _world_cell(spec.area, spec.at)
		entities[id] = {"kind": "conduit", "cell": cell, "node": _piece("conduit", "conduit", _center(cell), false)}
	for id in Region1Manifest.GATES:
		var spec: Dictionary = Region1Manifest.GATES[id]
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
	for id in Region1Manifest.POOLS:
		var spec: Array = Region1Manifest.POOLS[id]
		var corner := _world_cell(spec[0], spec[1])
		var size: Vector2i = spec[2]
		var center := Vector3(corner.x + size.x * 0.5, 0, corner.y + size.y * 0.5)
		_pool_hazards[id] = _hazard(center, Vector3(size.x - 0.3, 1, size.y - 0.3))
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
		var lm: Array = Region1Manifest.LANDMARKS.get(c.area.id, ["river_marker", false])
		var node := _piece(lm[0], lm[0], _center(c.cell), lm[1])
		if Region1Manifest.ANCHOR_AREA.values().has(c.area.id):
			entities["A1"] = {"kind": "anchor", "cell": c.cell, "node": node}
	for c in level.find("O"):
		_piece("stone_chunk", "stone_chunk", _center(c.cell), c.area.default_state == "restored")
		_blocker(_center(c.cell), 0.4)

func _creature(scene: PackedScene, at: Vector3, anim: String, scale_by := 1.0) -> Node3D:
	var model: Node3D = scene.instantiate()
	add_child(model)
	model.global_position = at
	model.scale = Vector3.ONE * scale_by
	ToonUtil.apply_toon(model, TOON)
	var ap := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
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
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.035, 0.03, 0.06)
	plane.material = mat
	var mi := MeshInstance3D.new()
	mi.name = "Void"
	mi.mesh = plane
	add_child(mi)
	mi.global_position = Vector3(24, -2.5, 12)

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
	sign.text = "Reedglass Marsh — next region"
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.font_size = 48
	sign.outline_size = 12
	sign.modulate = Color(0.95, 0.9, 0.75)
	add_child(sign)
	sign.global_position = Vector3(50.5, 1.4, 17.5)

func _place_scenery() -> void:
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
	# the snapped spillway ring arching over the ford's north end
	for i in range(5):
		if i == 2:
			continue   # the snap
		var basis := Basis(Vector3.BACK, deg_to_rad(-60.0 + i * 30.0)).scaled(Vector3.ONE * 0.4)
		dresser.place_xform("spillway_ring", "spillway_ring_corrupted", Transform3D(basis, Vector3(25.5, -0.6, -1.3)))
	dresser.build()

# --- restoration -----------------------------------------------------------------------------

func restore_next() -> String:
	while _next < Region1Manifest.RESTORE_ORDER.size():
		var id: String = Region1Manifest.RESTORE_ORDER[_next]
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
	var at := _center(e.cell)
	Juice.wave(at + Vector3.UP * 0.4, 2.5, Color(1.0, 0.85, 0.45), 0.45)
	Juice.burst(at + Vector3.UP * 0.6, Color(1.0, 0.85, 0.45), 26)
	Juice.sfx("restore")
	Juice.shake(0.25)
	if e.kind == "bearer":
		_restore_bearer(e, spec)
	else:
		_restore_charger(e, spec)
	if spec.has("pool"):
		_clear_pool(spec.pool)
	if spec.has("wakes") and entities.has(spec.wakes):
		entities[spec.wakes].node.set_restored(true, true)
	_ripple(e.cell, spec.get("ripple", 3))
	restored.emit(id)
	return true

func _restore_bearer(e: Dictionary, spec: Dictionary) -> void:
	e.node.visible = false
	e.body.get_child(0).disabled = true
	var socket := _world_cell(spec.area, spec.socket)
	var dir: Vector2i = spec.bridge_dir
	var length: int = spec.bridge_len
	var edge := _center(socket) + Vector3(dir.x, 0, dir.y) * 0.5
	var bridge: Node3D = BRIDGE.instantiate()
	add_child(bridge)
	ToonUtil.apply_toon(bridge, TOON)
	bridge.global_transform = Transform3D(
		Basis(Vector3.UP, deg_to_rad(STRAIGHT_YAW[dir])) * Basis.from_scale(Vector3(1, 1, length / 3.0)), edge)
	e["bridge"] = bridge
	for i in length:
		var cell := socket + dir * (i + 1)
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
	if spec.has("conduit"):
		var k: Dictionary = entities[spec.conduit]
		k.node.set_restored(true, true)
		var gate_id: String = Region1Manifest.CONDUITS[spec.conduit].gate
		var g: Dictionary = entities[gate_id]
		for p in g.pieces:
			p.set_restored(true, true)
		g.body.get_child(0).disabled = true

func _clear_pool(id: String) -> void:
	if _pool_hazards.has(id):
		_pool_hazards[id].queue_free()
		_pool_hazards.erase(id)
	for rim in _pool_rims.get(id, []):
		rim.set_restored(true, true)
	var spec: Array = Region1Manifest.POOLS[id]
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
		get_tree().create_timer(delay, true, false, true).timeout.connect(func() -> void:
			if not is_inside_tree():
				return
			if cell.ch == "#":
				_place_wall(cell.cell, "restored")
			else:
				_place_ground(cell.cell, "restored"))
