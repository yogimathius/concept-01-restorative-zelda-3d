extends SceneTree
## Isolated native visual route for Bryn's first Channel lesson.
const OUT := "res://builds/playtest/channel-first-route/"
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

func tap_channel() -> void:
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
	for id in ["M3","M6"]: region.builder.restore(id)
	check(region.waykeeper.learn("channel"),"Bryn's lesson becomes available after both restorations")
	region.hero.set_physics_process(false)
	region.hero.respawn_at(Vector3(25.5,0.02,18.0))
	await frames(180)
	await shot("01-bell-capacitor")
	await tap_channel()
	check(region.waykeeper.channel_carry and region.charge_circuit._carried.visible,"touch captures visible Charge")
	await shot("02-charge-carried")
	region.hero.respawn_at(Vector3(22.5,0.02,20.0))
	await frames(140)
	await tap_channel()
	check(region.charge_circuit.completed("lantern_beds"),"touch lights the lantern beds")
	await shot("03-lantern-beds-lit")
	region.hero.respawn_at(Vector3(25.5,0.02,18.0))
	await frames(140)
	await tap_channel()
	region.hero.respawn_at(Vector3(12.5,0.02,15.5))
	await frames(180)
	await tap_channel()
	check(region.charge_circuit.completed("exchange_lamp"),"touch lights the exchange")
	await shot("04-exchange-lamp-lit")
	region.exchange.handle("exchange_channel_reward")
	check(region.story_flags.has("bryn_channel_reward"),"Bryn's one-time return reward follows the visible change")
	region.story.dialogue.dismiss()
	region.hero.respawn_at(Vector3(14.0,0.02,16.5))
	await frames(400)
	var bryn: Node3D
	for npc in get_nodes_in_group("story_npc"):
		if npc.get_parent()==region and npc.npc_id=="bryn": bryn=npc
	check(bryn!=null and bryn.global_position.distance_to(Vector3(12.2,0,16.2))<1.3,"Bryn moves her work toward the lit lamp")
	await shot("05-bryn-at-lamp")
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.free()
	region = load("res://scenes/levels/region2.tscn").instantiate()
	region.persist_progress = false
	root.add_child(region)
	current_scene = region
	region._apply_journey_data(data)
	await frames(70)
	check(region.charge_circuit.completed("lantern_beds") and region.charge_circuit.completed("exchange_lamp"),"both lights survive reload")
	await shot("06-channel-reloaded")
	print("Channel native review: %d failures" % failures.size())
	quit(1 if not failures.is_empty() else 0)
