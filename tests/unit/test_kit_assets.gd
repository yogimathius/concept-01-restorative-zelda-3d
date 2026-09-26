extends TestCase
## The Broken Ford environment kit (world design §7) plus lab-only pieces.
## Every shape must export a corrupted and a restored variant, under budget.

const KIT_DIR := "res://assets/kit/"
## glb file -> [shape names inside it, triangle budget per variant]
const FAMILIES := {
	"ground": [["ground_a", "ground_b", "ground_c"], 80],
	"bank_straight": [["bank_straight"], 200],
	"bank_corner": [["bank_corner_outer", "bank_corner_inner"], 260],
	"wall_straight": [["wall_straight"], 260],
	"wall_end": [["wall_end", "wall_corner"], 320],
	"pool": [["pool_surface", "pool_rim"], 160],
	"river_marker": [["river_marker"], 420],
	"tree": [["tree"], 500],
	"reed": [["reed"], 200],
	"stone_chunk": [["stone_chunk"], 200],
	"gate_rib": [["gate_rib"], 240],
	"conduit": [["conduit"], 260],
	"signal_groove": [["signal_groove"], 80],
	"spillway_ring": [["spillway_ring"], 500],
	"training_post": [["training_post"], 360],
	"pad": [["pad_weight", "pad_charge"], 360],   # 2x2 tiles
}

func _find(root: Node, name: String) -> MeshInstance3D:
	var n := root.find_child(name, true, false)
	return n as MeshInstance3D

func _triangles(mi: MeshInstance3D) -> int:
	var tris := 0
	for s in mi.mesh.get_surface_count():
		var arrays := mi.mesh.surface_get_arrays(s)
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		tris += idx.size() / 3 if idx.size() > 0 else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
	return tris

func test_every_family_exports_both_variants_under_budget() -> void:
	for family in FAMILIES:
		var path: String = KIT_DIR + family + ".glb"
		if not ResourceLoader.exists(path):
			check(false, "%s missing" % path)
			continue
		var root: Node = (load(path) as PackedScene).instantiate()
		var shapes: Array = FAMILIES[family][0]
		var budget: int = FAMILIES[family][1]
		for shape in shapes:
			for variant in ["corrupted", "restored"]:
				var node_name := "%s_%s" % [shape, variant]
				var mi := _find(root, node_name)
				if mi == null:
					check(false, "%s: node %s missing" % [family, node_name])
					continue
				var tris := _triangles(mi)
				check(tris > 0 and tris <= budget, "%s: %s has %d tris (budget %d)" % [family, node_name, tris, budget])
		root.free()
