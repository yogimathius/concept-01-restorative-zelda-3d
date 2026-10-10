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
		var skeleton: Skeleton3D = root.find_children("*", "Skeleton3D", true, false)[0]
		for bone in ["hips","spine","chest","head","upper_arm.L","forearm.L","upper_arm.R","forearm.R","thigh.L","shin.L","thigh.R","shin.R", "neck","clavicle.L","clavicle.R","hand.L","hand.R","foot.L","foot.R","index1.L","index2.L","thumb1.R","thumb2.R"]:
			check(skeleton.find_bone(bone) >= 0, path+" retains anatomical/compatibility bone "+bone)
		if ap:
			for anim in ["idle", "walk", "attack"]:
				check(ap.has_animation(anim), "%s has '%s'" % [path, anim])
			if ap.has_animation("idle") and ap.has_animation("walk"):
				check(ap.get_animation("idle").loop_mode != Animation.LOOP_NONE, "%s idle loops" % path)
				check(ap.get_animation("walk").loop_mode != Animation.LOOP_NONE, "%s walk loops" % path)
			if ap.has_animation("attack"):
				check(ap.get_animation("attack").loop_mode == Animation.LOOP_NONE, "%s attack plays once" % path)
				check_near(ap.get_animation("attack").length, 0.333, 0.05, "%s attack length" % path)
		var shaded_vertices := 0
		var darkest := 1.0
		var lightest := 0.0
		var blended_vertices := 0
		var anatomical_influences := {}
		for node in root.find_children("*", "MeshInstance3D",true,false):
			for surface in node.mesh.get_surface_count():
				var arrays: Array = node.mesh.surface_get_arrays(surface)
				var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
				var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				if not weights.is_empty():
					var stride := weights.size() / vertices.size()
					for vertex in vertices.size():
						var influences := 0
						for influence in stride:
							var index := vertex * stride + influence
							if weights[index] > 0.001:
								influences += 1
								var name: StringName = node.skin.get_bind_name(bones[index])
								anatomical_influences[name] = anatomical_influences.get(name,0)+1
						if influences > 1: blended_vertices += 1
				var colours: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
				check(colours.size() == (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size(), path+" retains baked surface colour per vertex")
				for colour in colours:
					shaded_vertices += 1
					darkest = minf(darkest,colour.r)
					lightest = maxf(lightest,colour.r)
		check(shaded_vertices > 200 and lightest-darkest > 0.1, path+" preserves useful crevice shading through import")
		check(blended_vertices > 100, path+" retains blended soft-surface skinning rather than rigid limb segments")
		for bone in ["clavicle.L","neck","hand.R","index1.L","index2.L","thumb1.R","foot.L","arm_twist.L","forearm_twist.R"]:
			check(anatomical_influences.get(StringName(bone),0) > 10, path+" actually skins anatomy to "+bone)
		var tris := _tris(root)
		check(tris > 200 and tris <= 24000, "%s triangle count %d within revised body budget" % [path, tris])
		root.free()

func test_articulated_footwork_and_equipment_follow_the_exported_pose() -> void:
	for path in MODELS:
		var model: Node3D = (load(path) as PackedScene).instantiate()
		world.add_child(model)
		GearVisuals.apply(model,RestorationInventory.STARTERS)
		var ap: AnimationPlayer = model.find_child("AnimationPlayer",true,false)
		var skeleton: Skeleton3D = model.find_children("*","Skeleton3D",true,false)[0]
		var left := skeleton.find_bone("foot.L")
		var right := skeleton.find_bone("foot.R")
		ap.play("walk")
		ap.seek(0.2,true)
		ap.pause()
		await step(2)
		var ground := skeleton.get_bone_global_rest(left).origin.y
		check_near(skeleton.get_bone_global_pose(left).origin.y,ground,0.025,path+" support ankle retains ground contact")
		check(skeleton.get_bone_global_pose(right).origin.y > ground+0.04,path+" swing ankle clears the ground")
		var tool: BoneAttachment3D = model.get_node("Equipment/Tool")
		check(tool.bone_name == "hand.R",path+" staff follows the articulated wrist")
		var hand := skeleton.global_transform*skeleton.get_bone_global_pose(skeleton.find_bone("hand.R"))
		check(tool.global_position.distance_to(hand.origin) < 0.002,path+" staff attachment follows the actual exported hand pose")
		model.free()

func test_classes_use_their_models() -> void:
	var warden: HeroClass = load("res://data/classes/warden.tres")
	var weaver: HeroClass = load("res://data/classes/weaver.tres")
	check(warden.model.resource_path.ends_with("warden.glb"), "Warden wears warden.glb")
	check(weaver.model.resource_path.ends_with("weaver.glb"), "Weaver wears weaver.glb")
	check(weaver.state_overrides.is_empty(), "Weaver has no state affinity")

func test_all_gear_meshes_fit_mobile_geometry_budget() -> void:
	for id in RestorationInventory.ITEMS:
		var piece := GearVisuals.make_piece(id)
		var meshes := piece.find_children("*", "MeshInstance3D",true,false)
		check(meshes.size() == 1, id+" is batched into one equipment mesh")
		var triangles := _tris(piece)
		check(triangles > 100 and triangles <= 3000, "%s: %d triangles within gear budget" % [id,triangles])
		for node in meshes:
			check(node.mesh.get_surface_count() <= 8, id+" has a bounded number of draw surfaces")
			for surface in node.mesh.get_surface_count():
				var arrays: Array = node.mesh.surface_get_arrays(surface)
				check(not (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).is_empty(), id+" retains indexed decorative geometry after batching")
		piece.free()
