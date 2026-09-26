extends TestCase
## Kit pieces at runtime: cached toon meshes, batched dressing, swappable pieces.

func test_library_returns_cached_toon_mesh() -> void:
	var a := KitLibrary.mesh("ground", "ground_a_restored")
	var b := KitLibrary.mesh("ground", "ground_a_restored")
	check(a != null, "mesh found")
	check(a == b, "mesh cached")
	check(a.surface_get_material(0) is ShaderMaterial, "surfaces use the toon shader")

func test_library_unknown_piece_is_null() -> void:
	check(KitLibrary.mesh("ground", "nope") == null, "unknown node -> null")

func test_dresser_batches_by_mesh() -> void:
	var d := KitDresser.new()
	world.add_child(d)
	for x in 3:
		d.place("ground", "ground_a_corrupted", Vector3(x, 0, 0))
	d.place("wall_straight", "wall_straight_restored", Vector3(0, 0, -1), 90.0)
	d.build()
	var batches := d.get_children().filter(func(c): return c is MultiMeshInstance3D)
	check(batches.size() == 2, "one MultiMesh per distinct mesh (got %d)" % batches.size())
	var counts := batches.map(func(b): return b.multimesh.instance_count)
	counts.sort()
	check(counts == [1, 3], "instance counts per batch (got %s)" % [counts])

func test_kit_piece_swaps_variants() -> void:
	var p := KitPiece.new()
	p.family = "conduit"
	p.shape = "conduit"
	world.add_child(p)
	check(p.corrupted_node.visible and not p.restored_node.visible, "starts corrupted")
	p.set_restored(true)
	check(p.restored_node.visible and not p.corrupted_node.visible, "swaps to restored")

func test_kit_piece_unique_materials_do_not_share() -> void:
	var a := KitPiece.new()
	a.family = "training_post"
	a.shape = "training_post"
	a.unique_materials = true
	var b := KitPiece.new()
	b.family = "training_post"
	b.shape = "training_post"
	b.unique_materials = true
	world.add_child(a)
	world.add_child(b)
	var ma := (a.corrupted_node as MeshInstance3D).get_active_material(0)
	var mb := (b.corrupted_node as MeshInstance3D).get_active_material(0)
	check(ma != mb, "each piece owns its materials so flashes don't bleed")
