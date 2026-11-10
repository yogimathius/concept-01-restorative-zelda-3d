extends SceneTree
## Native visual smoke route; uses an isolated in-memory journey.
const OUT := "res://builds/playtest/weave-first-link/"
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

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	region = load("res://scenes/levels/region2.tscn").instantiate()
	region.persist_progress = false
	region.save_path = "user://test-native-weave.json"
	root.add_child(region)
	current_scene = region
	region.hero.use_device_input = false
	await frames(15)
	check(AudioServer.is_bus_mute(0),"prototype audio remains muted")
	region.builder.restore("M1")
	region.builder.restore("M2")
	region.hero.respawn_at(Vector3(10.5,0.02,9.0))
	await frames(300)
	check(region.weave_relay.ready() and not region.weave_relay.linked(),"two restored places reveal an unlinked feed")
	await shot("01-severed-feed")
	region.waykeeper.learn("weave")
	await shot("02-weave-selected")
	check(region.weave_relay.begin(),"Weave finds a nearby ceramic relay")
	region.weave_relay.drag(region.weave_relay._screen(1))
	await shot("03-link-preview")
	check(region.weave_relay.end(region.weave_relay._screen(1)),"releasing on the broad halo carries water")
	await shot("04-water-linked")
	await frames(280)
	await shot("04b-water-settled")
	region.hero.respawn_at(Vector3(23,0.02,8.5))
	await frames(440)
	var neri: Node3D
	for npc in get_nodes_in_group("story_npc"):
		if npc.get_parent()==region and npc.npc_id=="neri": neri=npc
	check(neri!=null and neri.global_position.distance_to(Vector3(9.5,0,9.5))<1.0,"Neri independently moves her work to the shared channel")
	region.hero.respawn_at(Vector3(10.5,0.02,9.0))
	await shot("05-neri-returns")
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.free()
	region = load("res://scenes/levels/region2.tscn").instantiate()
	region.persist_progress = false
	root.add_child(region)
	current_scene = region
	region._apply_journey_data(data)
	region._configure_restoration()
	await frames(15)
	check(region.weave_relay.linked() and region.weave_relay._water.visible,"reload keeps the water connected")
	await shot("06-link-reloaded")
	region.waykeeper.screen.toggle()
	region.waykeeper.screen._scroll.scroll_vertical = 300
	region.waykeeper.screen._scroll.scroll_horizontal = 0
	region.waykeeper.screen.view_node("living_conduit")
	await shot("07-weaver-tree")
	region.waykeeper.screen.toggle()
	print("Weave visual review: %d failures" % failures.size())
	quit(1 if not failures.is_empty() else 0)
