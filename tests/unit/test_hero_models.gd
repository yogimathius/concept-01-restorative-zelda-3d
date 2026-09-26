extends TestCase
## Warden and Weaver models: rigged, animated, phone-sized.

const MODELS := ["res://assets/characters/warden.glb", "res://assets/characters/weaver.glb"]

func _tris(root: Node) -> int:
	var total := 0
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		for s in mi.mesh.get_surface_count():
			total += (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
	return total

func test_models_are_rigged_and_animated() -> void:
	for path in MODELS:
		if not ResourceLoader.exists(path):
			check(false, "%s missing" % path)
			continue
		var root: Node = (load(path) as PackedScene).instantiate()
		var ap := root.find_child("AnimationPlayer", true, false) as AnimationPlayer
		check(root.find_child("*", true, false) != null and root.find_children("*", "Skeleton3D", true, false).size() == 1,
			"%s has one skeleton" % path)
		check(ap != null, "%s has an AnimationPlayer" % path)
		if ap:
			for anim in ["idle", "walk", "attack"]:
				check(ap.has_animation(anim), "%s has '%s'" % [path, anim])
			if ap.has_animation("idle") and ap.has_animation("walk"):
				check(ap.get_animation("idle").loop_mode != Animation.LOOP_NONE, "%s idle loops" % path)
				check(ap.get_animation("walk").loop_mode != Animation.LOOP_NONE, "%s walk loops" % path)
			if ap.has_animation("attack"):
				check(ap.get_animation("attack").loop_mode == Animation.LOOP_NONE, "%s attack plays once" % path)
				check_near(ap.get_animation("attack").length, 0.333, 0.05, "%s attack length" % path)
		var tris := _tris(root)
		check(tris > 200 and tris <= 2500, "%s triangle count %d within phone budget" % [path, tris])
		root.free()

func test_classes_use_their_models() -> void:
	var warden: HeroClass = load("res://data/classes/warden.tres")
	var weaver: HeroClass = load("res://data/classes/weaver.tres")
	check(warden.model.resource_path.ends_with("warden.glb"), "Warden wears warden.glb")
	check(weaver.model.resource_path.ends_with("weaver.glb"), "Weaver wears weaver.glb")
	check(weaver.state_overrides.is_empty(), "Weaver has no state affinity")
