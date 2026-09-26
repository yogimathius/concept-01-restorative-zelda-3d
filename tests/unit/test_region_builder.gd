extends TestCase
## Region 1 built from the world design grids, plus the F2 restoration preview.

const SCENE: PackedScene = preload("res://scenes/levels/region1.tscn")

var region: Node3D
var builder: RegionBuilder
var hero: Hero

func load_region() -> void:
	region = SCENE.instantiate()
	hero = region.get_node("Hero")
	hero.use_device_input = false
	world.add_child(region)
	builder = region.get_node("Builder")
	await step(4)

func _hazard_at(p: Vector3) -> bool:
	for h in tree.get_nodes_in_group("hazard"):
		if h.is_inside_tree() and h.contains_point(p, 0.0) and not h.is_queued_for_deletion():
			return true
	return false

func _floor_at(p: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.5, p + Vector3.DOWN * 0.5)
	return not region.get_world_3d().direct_space_state.intersect_ray(q).is_empty()

func test_region_builds_grid_and_spawns_hero_at_p() -> void:
	await load_region()
	check(builder.grid.get_used_cells().size() > 500, "grid filled (%d cells)" % builder.grid.get_used_cells().size())
	check(hero.global_position.distance_to(Vector3(2.5, 0, 6.5)) < 0.3, "hero at S1 P (3,7) (got %s)" % hero.global_position)

func test_chasm_is_a_hole_with_a_hazard() -> void:
	await load_region()
	var chasm := Vector3(25.5, 0, 3.5)   # S2 (10,4)
	check(not _floor_at(chasm), "no floor over the ford")
	check(_hazard_at(chasm), "ford is hazardous")
	check(_floor_at(Vector3(22.5, 0, 3.5)), "near bank has floor")

func test_restoring_b1_bridges_the_north_socket() -> void:
	await load_region()
	check(builder.restore("B1"), "B1 restores")
	await step(2)
	for x in [24.5, 25.5, 26.5]:
		check(_floor_at(Vector3(x, 0, 3.5)), "bridge deck at x=%s" % x)
		check(not _hazard_at(Vector3(x, 0, 3.5)), "no hazard on the bridge at x=%s" % x)
	check(_hazard_at(Vector3(25.5, 0, 7.5)), "south span stays open")
	check(not _hazard_at(Vector3(17.5, 0, 8.5)), "pool F1 cleared")
	check(builder.entities["A1"].node.restored, "A1 river marker wakes")

func test_restoring_c1_opens_g1() -> void:
	await load_region()
	var gate_cell := Vector3(39.5, 0.5, 8.5)   # S3 (8,9)
	var body: StaticBody3D = builder.entities["G1"].body
	check(not body.get_child(0).disabled, "G1 starts closed")
	builder.restore("C1")
	await step(2)
	check(body.get_child(0).disabled, "G1 open after C1 restored")
	check(builder.entities["K1"].node.restored, "K1 lit")

func test_restore_next_walks_the_preview_order() -> void:
	await load_region()
	var ids := []
	for i in 7:
		ids.append(builder.restore_next())
	check(ids == ["B1", "C1", "C3", "B2", "C2", "B3", ""], "order (got %s)" % [ids])
