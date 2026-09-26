extends Node3D
## Dresses the feel lab as a patch of the Broken Ford with the kit. Purely
## visual: colliders and gameplay nodes live in feel_lab.tscn. The west side
## is restored, the east corrupted, split by a jagged seam near x = 0.

const HALF := 15          # dressed field: cells -15..14 (30 x 30)
const WALL := 11.5        # wall ring cell centre (matches the lab colliders)
const POOL_X := [-1.5, -0.5, 0.5, 1.5]
const POOL_Z := [7.5, 8.5]
const PADS := [Vector3(-6, 0, 5), Vector3(6, 0, 5)]
const PILLAR_X := 5.5
const PILLAR_Z := [-5.5, -4.5, -3.5, -2.5]
const MARKER := Vector3(-8.5, 0, -7.5)

var dresser: KitDresser

func _ready() -> void:
	dresser = KitDresser.new()
	dresser.name = "Dresser"
	add_child(dresser)
	for i in range(-HALF, HALF):
		for j in range(-HALF, HALF):
			_dress_cell(Vector3(i + 0.5, 0, j + 0.5), i, j)
	_dress_features()
	dresser.build()

func _restored(p: Vector3) -> bool:
	return p.x < 0.5 + roundf(sin(p.z * 0.7) * 1.5)

func _v(p: Vector3) -> String:
	return "restored" if _restored(p) else "corrupted"

func _hash(i: int, j: int) -> int:
	return absi((i * 73856093) ^ (j * 19349663))

func _is_pool(p: Vector3) -> bool:
	return p.x in POOL_X and p.z in POOL_Z

func _under_pad(p: Vector3) -> bool:
	for pad in PADS:
		if absf(p.x - pad.x) < 1.0 and absf(p.z - pad.z) < 1.0:
			return true
	return false

func _dress_cell(p: Vector3, i: int, j: int) -> void:
	var on_ring := absf(absf(p.x) - WALL) < 0.01 and absf(p.z) <= WALL \
		or absf(absf(p.z) - WALL) < 0.01 and absf(p.x) <= WALL
	var is_pillar := absf(p.x - PILLAR_X) < 0.01 and p.z in PILLAR_Z
	if on_ring:
		var corner := absf(absf(p.x) - WALL) < 0.01 and absf(absf(p.z) - WALL) < 0.01
		if corner:
			dresser.place("wall_end", "wall_corner_" + _v(p), p)
		else:
			var yaw := 0.0 if absf(absf(p.z) - WALL) < 0.01 else 90.0
			dresser.place("wall_straight", "wall_straight_" + _v(p), p, yaw)
		return
	if is_pillar:
		if p.z == PILLAR_Z[0]:
			dresser.place("wall_end", "wall_end_corrupted", p, 90.0)
		elif p.z == PILLAR_Z[-1]:
			dresser.place("wall_end", "wall_end_corrupted", p, -90.0)
		else:
			dresser.place("wall_straight", "wall_straight_corrupted", p, 90.0)
		return
	if _is_pool(p):
		dresser.place("pool", "pool_surface_corrupted", p)
		for side in [[Vector3(0, 0, -1), 0.0], [Vector3(-1, 0, 0), 90.0],
				[Vector3(0, 0, 1), 180.0], [Vector3(1, 0, 0), -90.0]]:
			if not _is_pool(p + side[0]):
				dresser.place("pool", "pool_rim_corrupted", p, side[1])
		return
	if not _under_pad(p):
		var letter: String = ["a", "b", "c"][_hash(i, j) % 3]
		dresser.place("ground", "ground_%s_%s" % [letter, _v(p)], p, [0.0, 90.0, 180.0, 270.0][_hash(j, i) % 4])
	var outside := absf(p.x) > WALL or absf(p.z) > WALL
	var h := _hash(i + 7, j - 3)
	if outside:
		# nothing tall south of the play area: it sits between camera and hero
		if h % 5 == 0 and p.z < WALL:
			dresser.place("tree", "tree_" + _v(p), p, float(h % 360), 0.85 + (h % 30) / 100.0)
		elif h % 3 == 0:
			dresser.place("reed", "reed_" + _v(p), p, float(h % 360))
	elif (absf(absf(p.x) - (WALL - 1.0)) < 0.01 or absf(absf(p.z) - (WALL - 1.0)) < 0.01) and h % 4 == 0:
		# wall-foot dressing: reeds, and stones on the corrupted side
		if _restored(p) or h % 8 != 0:
			dresser.place("reed", "reed_" + _v(p), p, float(h % 360))
		else:
			dresser.place("stone_chunk", "stone_chunk_corrupted", p, float(h % 360), 0.7)

func _dress_features() -> void:
	dresser.place("pad", "pad_weight_restored", PADS[0])
	dresser.place("pad", "pad_charge_restored", PADS[1])
	dresser.place("river_marker", "river_marker_restored", MARKER, 30.0)
	# a lit groove path from the marker toward the weight pad, and its broken
	# twin on the corrupted side
	for z in range(-6, 4):
		dresser.place("signal_groove", "signal_groove_restored", Vector3(-8.5, 0, z + 0.5), 90.0)
	for z in range(-6, 4):
		dresser.place("signal_groove", "signal_groove_corrupted", Vector3(8.5, 0, z + 0.5), 90.0)
	for p in [Vector3(-3.5, 0, 8.5), Vector3(3.5, 0, 7.5), Vector3(2.5, 0, 9.5), Vector3(-2.5, 0, 6.5)]:
		dresser.place("reed", "reed_" + _v(p), p, p.x * 40.0)
	for p in [Vector3(-9.5, 0, -9.5), Vector3(-7.5, 0, -9.5)]:
		dresser.place("stone_chunk", "stone_chunk_restored", p, 15.0, 0.75)
