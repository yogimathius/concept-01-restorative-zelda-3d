extends SceneTree
## Isolated native presentation route for Daro's second Weave connection.
const OUT := "res://builds/playtest/weave-living-route/"
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

func touch(at: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 3
	event.position = at
	event.pressed = down
	root.push_input(event,true)
	await frames(3)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	region = load("res://scenes/levels/region2.tscn").instantiate()
	region.persist_progress = false
	region.save_path = "user://test-native-living-route.json"
	root.add_child(region)
	current_scene = region
	region.hero.use_device_input = false
	await frames(15)
	check(AudioServer.is_bus_mute(0),"prototype audio remains muted")
	for id in ["M1","M2","M4","M5"]: region.builder.restore(id)
	region.waykeeper.learn("weave")
	region.hero.respawn_at(Vector3(6.5,0.02,18.0))
	region.hero.set_physics_process(false)
	await frames(150)
	var relay = region.weave_relays.spring_refuge
	check(relay.ready() and not relay.linked(),"restored spring and willow leave a readable severed feed")
	await shot("01-severed-living-route")
	region.story._act("daro_link_quest")
	check(region.journal.observe(region,"quest/R2/daro_water_route").status.contains("Weave"),"Daro's request appears in the journal")
	region.story.dialogue.dismiss()
	var button: TouchScreenButton = region.get_node("TouchControls/RestoreButton")
	var center: Vector2 = button.position+button.texture_normal.get_size()*button.scale*0.5
	await touch(center,true)
	check(relay._gesture,"touch medallion selects the nearby living route")
	var destination: Vector2 = relay._screen(1-relay._source)
	var drag := InputEventScreenDrag.new()
	drag.index = 3
	drag.position = destination
	drag.relative = destination-center
	root.push_input(drag,true)
	await frames(3)
	check(relay._candidate,"second halo magnetizes under the drag")
	await shot("02-living-route-preview")
	await touch(relay._screen(1-relay._source),false)
	await frames(80)
	check(relay.linked() and relay._herb_bed.visible,"water and mint appear at the connected feed")
	check(not region.weave_relay.linked(),"garden link remains an independent choice")
	await shot("03-living-route-restored")
	region.story._act("daro_link_reward")
	check(region.story_flags.has("daro_link_reward") and region.economy.scrip>=6,"Daro acknowledges and rewards the return")
	region.story.dialogue.dismiss()
	region.hero.respawn_at(Vector3(15,0.02,16.5))
	await frames(450)
	var daro: Node3D
	for npc in get_nodes_in_group("story_npc"):
		if npc.get_parent()==region and npc.npc_id=="daro": daro=npc
	check(daro != null and daro.global_position.distance_to(Vector3(8.3,0,17.7))<2.0,"Daro independently moves toward the new mint bed")
	region.hero.respawn_at(Vector3(6.5,0.02,18.0))
	await frames(120)
	await shot("04-daro-at-mint-bed")
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.free()
	region = load("res://scenes/levels/region2.tscn").instantiate()
	region.persist_progress = false
	root.add_child(region)
	current_scene = region
	region._apply_journey_data(data)
	await frames(60)
	check(region.weave_relays.spring_refuge.linked() and region.story_flags.has("daro_link_reward"),"route and quest reward survive reload")
	await shot("05-living-route-reloaded")
	region.waykeeper.screen.toggle()
	region.waykeeper.screen._scroll.scroll_vertical = 400
	region.waykeeper.screen.view_node("living_echo")
	check(region.waykeeper.screen._node_title.text == "Living Echo","connected tree exposes the new chosen cross-skill node")
	await shot("06-living-echo-tree")
	region.waykeeper.screen.toggle()
	print("Living route native review: %d failures" % failures.size())
	quit(1 if not failures.is_empty() else 0)
