extends SceneTree
## Isolated, phone-sized art and touch review. No production save is opened.
const OUT := "res://builds/playtest/living-care/"
var region: Node3D
var failures := []

func _init() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count: await physics_frame

func check(value: bool, description: String) -> void:
	print("PASS " if value else "FAIL ",description)
	if not value: failures.append(description)

func shot(id: String) -> void:
	await frames(12)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+id+".png")

func visit(id: String) -> Node3D:
	var patch: Node3D = region.renewal_world.get_node("Care_"+id)
	region.hero.respawn_at(patch.global_position+Vector3(0.0,0.02,2.1))
	await frames(55)
	return patch

func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	region = load("res://scenes/levels/region1.tscn").instantiate()
	region.persist_progress = false
	root.add_child(region)
	current_scene = region
	region.hero.use_device_input = false
	await frames(12)
	check(AudioServer.is_bus_mute(0),"prototype audio remains muted")
	for id in ["B1","C1","B2","C2"]: region.builder.restore(id)
	region._toast_left = 0.0
	region._level_toast.hide()
	await frames(8)
	var patch: Node3D = await visit("B1")
	print("Care B1 at ",patch.global_position)
	check(patch._last_stage==0,"reed condition starts strained")
	await shot("01-reeds-strained")
	region.economy.patch("B1").progress=0.45
	await shot("02-reeds-responding")
	region.economy.patch("B1").progress=0.78
	await shot("03-reeds-nearly-tended")
	patch = await visit("C1")
	await shot("04-riverglass-strained")
	region.economy.patch("C1").progress=0.78
	await shot("05-riverglass-clearing")
	patch = await visit("C2")
	await shot("06-silt-strained")
	region.economy.patch("C2").progress=0.78
	await shot("07-silt-water-thread")
	patch = await visit("B2")
	check(region.renewal_world.get_node("Skipper_B2").visible,"skipper inhabits restored refuge")
	await shot("08-habitat-with-skipper")
	region.journey_map.toggle(region.checkpoint_position)
	await shot("09-map-care-ready")
	region.journey_map.show_journal()
	region.journey_map.journal_screen._show_mode("care")
	await shot("10-care-journal")
	print("Living care native review: %d failures" % failures.size())
	quit(1 if not failures.is_empty() else 0)
