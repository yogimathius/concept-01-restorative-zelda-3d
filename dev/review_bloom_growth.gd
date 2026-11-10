extends SceneTree
## Visual and touch-input inspection of the first Bloom route, in memory only.
const OUT := "res://builds/playtest/bloom-first-route/"
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
	await frames(8)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+id+".png")

func tap_bloom() -> void:
	var button: TouchScreenButton = region.get_node("TouchControls/RestoreButton")
	var at: Vector2 = button.position+button.texture_normal.get_size()*button.scale*0.5
	var event := InputEventScreenTouch.new()
	event.index = 4
	event.position = at
	event.pressed = true
	root.push_input(event,true)
	await frames(3)
	event.pressed = false
	root.push_input(event,true)
	await frames(3)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	region = load("res://scenes/levels/region2.tscn").instantiate()
	region.persist_progress = false
	root.add_child(region)
	current_scene = region
	region.hero.use_device_input = false
	await frames(15)
	check(AudioServer.is_bus_mute(0),"prototype audio stays muted")
	for id in ["M1","M2","M4","M5"]: region.builder.restore(id)
	region.waykeeper.learn("weave")
	region.hero.set_physics_process(false)
	for entry in [["garden_nursery",Vector3(8.5,0.02,9.0)],["spring_refuge",Vector3(6.5,0.02,18.0)]]:
		region.hero.respawn_at(entry[1])
		await frames(30)
		var relay: Node3D = region.weave_relays[entry[0]]
		check(relay.begin() and relay.end(relay._screen(1-relay._source)),"waterway linked before growth: "+entry[0])
	region.story._act("learn_bloom")
	check(region.waykeeper.progress.active=="bloom" and region.story_flags.has("neri_bloom_started"),"Neri's lesson equips Bloom")
	region.story.dialogue.dismiss()
	region.hero.respawn_at(Vector3(11.5,0.02,7.5))
	await frames(180)
	await shot("01-linked-garden-before")
	await tap_bloom()
	check(region.bloom_growth.completed("M1") and region.bloom_growth._growth.M1.visible,"touch grows Neri's garden")
	await frames(75)
	await shot("02-garden-bloomed")
	region.hero.respawn_at(Vector3(10.5,0.02,17.5))
	await frames(180)
	await shot("03-linked-refuge-before")
	await tap_bloom()
	check(region.bloom_growth.completed("M4") and region.bloom_growth.sheltered(),"touch grows a useful willow shelter")
	await frames(130)
	await shot("04-refuge-bloomed")
	var daro: Node3D
	for npc in get_nodes_in_group("story_npc"):
		if npc.get_parent()==region and npc.npc_id=="daro": daro=npc
	check(daro!=null and daro.global_position.distance_to(Vector3(9.2,0,17.3))<1.4,"Daro moves his work under new shelter")
	region.progression.award_activity(100)
	region._configure_restoration()
	for node in ["deep_reserve","spring_attunement","living_conduit","living_network"]: check(region.waykeeper.buy_node(node),"chosen network path: "+node)
	region.hero.respawn_at(region.builder.entities.M5.runtime.global_position)
	await frames(150)
	check(region.bloom_growth.sheltered() and region.bloom_growth._shared_shelter.visible,"the linked spring receives shared shelter")
	await shot("05-living-network-at-spring")
	region.story._act("bloom_reward")
	check(region.story_flags.has("neri_bloom_reward"),"Neri's return reward follows both living changes")
	region.story.dialogue.dismiss()
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.free()
	region = load("res://scenes/levels/region2.tscn").instantiate()
	region.persist_progress = false
	root.add_child(region)
	current_scene = region
	region._apply_journey_data(data)
	await frames(80)
	check(region.bloom_growth.completed("M1") and region.bloom_growth.completed("M4") and region.journal.observe(region,"quest/R2/neri_new_season").done,"both growths and quest survive reload")
	await shot("06-bloom-reloaded")
	print("Bloom native review: %d failures" % failures.size())
	quit(1 if not failures.is_empty() else 0)
