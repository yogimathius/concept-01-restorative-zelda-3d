extends SceneTree
## Native touch UI inspection in a private, nonpersistent fixture.
var region: Node3D
var folder := "res://builds/playtest/journal/"

func _init() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i in count: await process_frame

func touch(at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 8
	event.position = at
	event.pressed = pressed
	root.push_input(event,true)
	await frames(3)

func tap(control: Control) -> void:
	var at := control.get_global_rect().get_center()
	await touch(at,true)
	await touch(at,false)

func shot(id: String) -> void:
	await frames(10)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+id+".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(folder)
	region = load("res://scenes/levels/region1.tscn").instantiate()
	region.persist_progress = false
	region.save_path = "user://test-journal-native.json"
	root.add_child(region)
	current_scene = region
	region.hero.use_device_input = false
	await frames(10)
	region.builder.entities.B2.runtime.ecology.states.seen = true
	region.builder.entities.B2.runtime.progress = 0.55
	region.journey_map.toggle(region.checkpoint_position)
	await tap(region.journey_map._journal_button)
	var screen = region.journey_map.journal_screen
	await tap(screen._cards["R1/B2"])
	await shot("remembered-refuge")
	await tap(screen._pin)
	await shot("pinned-refuge")
	region.journey_map.toggle(region.checkpoint_position)
	await shot("navigation")
	region.waykeeper.progress.unlock("force")
	region.builder.entities.C1.runtime.ecology.states.seen = true
	region.journey_map.toggle(region.checkpoint_position)
	await tap(region.journey_map._journal_button)
	await tap(screen._cards["R1/C1"])
	await shot("ready-force")
	await tap(screen._technique)
	var passed: bool = region.journal.pinned == "R1/B2" and region.waykeeper.progress.active == "force" and not paused and not region.builder.entities.C1.runtime.ecology.states.cleared
	print("Journal native touch: ", "PASS" if passed else "FAIL")
	quit(0 if passed else 1)
