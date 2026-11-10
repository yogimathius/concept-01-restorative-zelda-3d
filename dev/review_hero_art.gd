extends SceneTree
func _init() -> void: call_deferred("run")
func settle() -> void:
	for i in 25: await process_frame
	await RenderingServer.frame_post_draw
func snap(path: String) -> void:
	await settle()
	root.get_texture().get_image().save_png(path)
func run() -> void:
	root.msaa_3d = Viewport.MSAA_4X
	DirAccess.make_dir_recursive_absolute("res://builds/playtest/hero-art")
	var world := Node3D.new()
	root.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("182937")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("bbc8dc")
	env.environment.ambient_light_energy = 0.55
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-38,-35,0)
	light.light_color = Color("fff1da")
	light.light_energy = 1.3
	world.add_child(light)
	light.shadow_enabled = true
	var ground := MeshInstance3D.new()
	ground.mesh = PlaneMesh.new()
	ground.mesh.size = Vector2(6,6)
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color("233744")
	ground_material.roughness = 1.0
	ground.material_override = ground_material
	world.add_child(ground)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-25,135,0)
	rim.light_color = Color("7cbbd1")
	rim.light_energy = 0.55
	world.add_child(rim)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.94
	camera.position = Vector3(0,0.88,3.5)
	world.add_child(camera)
	camera.look_at(Vector3(0,0.83,0))
	var util = load("res://scripts/toon_util.gd")
	var gear = load("res://scripts/gear/gear_visuals.gd")
	var material = load("res://shaders/hero_surface_material.tres")
	var models := []
	for cls in ["warden","weaver"]:
		var model: Node3D = load("res://assets/characters/"+cls+".glb").instantiate()
		world.add_child(model)
		model.position.x = -0.55 if cls == "warden" else 0.55
		model.rotation.y = -0.15 if cls == "warden" else 0.15
		util.apply_toon(model,material)
		gear.apply(model,{"tool":"river_staff" if cls=="warden" else "marsh_staff","cloak":"sunleaf_cloak" if cls=="warden" else "marsh_cloak","charm":"stonekeeper_charm" if cls=="warden" else "messenger_charm"})
		var tris := 0
		var surfaces := 0
		for mi in model.find_children("*","MeshInstance3D",true,false):
			var part_tris := 0
			for s in mi.mesh.get_surface_count():
				var arrays = mi.mesh.surface_get_arrays(s)
				var indices = arrays[Mesh.ARRAY_INDEX]
				var count: int = indices.size()/3 if indices != null and indices.size()>0 else arrays[Mesh.ARRAY_VERTEX].size()/3
				tris += count
				part_tris += count
				surfaces += 1
			print(mi.name, " triangles=",part_tris)
		print(cls," equipped triangles=",tris," surfaces=",surfaces)
		models.append(model)
	if "--motion" in OS.get_cmdline_user_args():
		for clip in ["idle", "walk", "attack"]:
			for model in models:
				model.rotation.y = 0.65
				model.find_child("AnimationPlayer",true,false).play(clip)
			for frame in (120 if clip != "attack" else 40):
				if clip == "attack" and frame % 15 == 0:
					for model in models: model.find_child("AnimationPlayer",true,false).play(clip)
				await process_frame
		quit()
		return
	await snap("res://builds/playtest/hero-art/heroes-front.png")
	var full_camera := camera.transform
	var full_size := camera.size
	var full_positions := []
	for model in models:
		full_positions.append(model.position)
		model.position.x *= 0.46
	camera.size = 0.58
	camera.position = Vector3(0,1.3,3.5)
	camera.look_at(Vector3(0,1.285,0))
	await snap("res://builds/playtest/hero-art/faces-front.png")
	for model in models: model.rotation.y = 0.6
	await snap("res://builds/playtest/hero-art/faces-three-quarter.png")
	camera.transform = full_camera
	camera.size = full_size
	for index in models.size(): models[index].position = full_positions[index]
	for model in models:
		model.rotation.y = 0.48
		var animation: AnimationPlayer = model.find_child("AnimationPlayer",true,false)
		animation.play("idle")
		animation.seek(0.6,true)
		animation.pause()
	await snap("res://builds/playtest/hero-art/heroes-three-quarter.png")
	for model in models: model.rotation.y = PI
	await snap("res://builds/playtest/hero-art/heroes-back.png")
	for model in models:
		model.rotation.y = 0.35
		var ap: AnimationPlayer = model.find_child("AnimationPlayer",true,false)
		ap.play("walk")
		ap.seek(0.12,true)
		ap.pause()
	await snap("res://builds/playtest/hero-art/heroes-walk.png")
	for phase in [0.0,0.133,0.267,0.4]:
		for model in models:
			model.rotation.y = 1.1
			var ap: AnimationPlayer = model.find_child("AnimationPlayer",true,false)
			ap.play("walk")
			ap.seek(phase,true)
			ap.pause()
		await snap("res://builds/playtest/hero-art/walk-phase-%03d.png" % int(phase*1000))
	for model in models:
		model.rotation.y = 0.35
		var ap: AnimationPlayer = model.find_child("AnimationPlayer",true,false)
		ap.play("attack")
		ap.seek(0.16,true)
		ap.pause()
	await snap("res://builds/playtest/hero-art/heroes-mend.png")
	for model in models: model.free()
	ground.free()
	camera.size = 5.5
	camera.position = Vector3(0,2.5,8)
	camera.look_at(Vector3(0,2.5,0))
	var registry = load("res://scripts/gear/restoration_inventory.gd")
	var failed := false
	for row in 3:
		var slot: String = registry.SLOTS[row]
		var items: Array = registry.ITEMS.keys().filter(func(id): return registry.ITEMS[id].slot == slot)
		for column in items.size():
			var id: String = items[column]
			var piece: Node3D = gear.make_piece(id)
			world.add_child(piece)
			var x := (float(column)-float(items.size()-1)*0.5)*1.35
			var y := 3.5-float(row)*1.65
			piece.position = Vector3(x,y,0)
			if slot == "tool": piece.position.x += 0.32
			if slot == "cloak": piece.rotation.y = PI
			if slot == "charm":
				piece.scale = Vector3.ONE*3.0
				piece.position += Vector3(0,-2.43,0)
			var mesh: ArrayMesh = piece.get_child(0).mesh
			var count := 0
			for surface in mesh.get_surface_count(): count += mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size()/3
			print(id," triangles=",count," surfaces=",mesh.get_surface_count())
			if count > 3000 or mesh.get_surface_count() > 8: failed = true
			var label := Label3D.new()
			label.text = registry.ITEMS[id].name
			label.font_size = 32
			label.pixel_size = 0.003
			label.position = Vector3(x,y+0.02,0.2)
			world.add_child(label)
	await snap("res://builds/playtest/hero-art/gear-catalogue.png")
	quit(1 if failed else 0)
