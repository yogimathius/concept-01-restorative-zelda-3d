extends SceneTree
## Isolated visual smoke review. Never opens or writes the production save.
const OUT := "res://builds/playtest/restorative-economy/"
var region: Node3D
var failures := []

func _init() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count: await physics_frame

func check(value: bool, message: String) -> void:
	print("PASS " if value else "FAIL ",message)
	if not value: failures.append(message)

func shot(id: String) -> void:
	await frames(6)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+id+".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	region=load("res://scenes/levels/region1.tscn").instantiate()
	region.persist_progress=false
	region.save_path="user://test-native-restorative-economy.json"
	root.add_child(region)
	current_scene=region
	region.hero.use_device_input=false
	await frames(12)
	check(AudioServer.is_bus_mute(0),"prototype audio remains muted")
	var tavi: Node3D
	for npc in get_nodes_in_group("story_npc"):
		if npc.get_parent()==region and npc.npc_id=="tavi": tavi=npc
	check(tavi!=null,"Ford exchange inhabitant is present")
	if tavi:
		region.hero.respawn_at(tavi.global_position+Vector3.BACK*1.4+Vector3.UP*0.02)
		await shot("ford-exchange")
		region.story.talk("tavi")
		await shot("exchange-dialogue")
		region.story.dialogue.dismiss()
	region.builder.restore("B1")
	await frames(12)
	var patch: Node3D = region.renewal_world.get_node("Care_B1")
	check(not patch.restored and region.renewal_world.get_node("Moth_B1").visible,"restored grove wakes care and wildlife")
	region.hero.respawn_at(patch.global_position+Vector3.LEFT*1.4+Vector3.UP*0.02)
	await shot("grove-care")
	region.hero.set_verb_held(&"restore",true)
	await frames(100)
	region.hero.set_verb_held(&"restore",false)
	check(region.economy.patch("B1").cycles==1,"Mend pays care materials and scrip")
	await shot("care-reward")
	region.free()
	region=load("res://scenes/levels/region2.tscn").instantiate()
	region.persist_progress=false
	region.save_path="user://test-native-restorative-economy-marsh.json"
	root.add_child(region)
	current_scene=region
	region.hero.use_device_input=false
	await frames(10)
	var sela: Node3D
	for npc in get_nodes_in_group("story_npc"):
		if npc.get_parent()==region and npc.npc_id=="sela": sela=npc
	check(sela!=null,"Reedglass exchange inhabitant is present")
	if sela:
		region.hero.respawn_at(sela.global_position+Vector3.BACK*1.4+Vector3.UP*0.02)
		region.story.talk("sela")
		await shot("reedglass-exchange")
	print("Economy visual review: %d failures" % failures.size())
	quit(1 if not failures.is_empty() else 0)
