extends SceneTree
## Isolated perspective stills for checking route joins without touching saves.
const OUTPUT := "res://builds/playtest/trail-polish"
var region: Node3D

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	region = load("res://scenes/levels/river_valley.tscn").instantiate()
	region.persist_progress = false
	region.get_node("Hero").use_device_input = false
	root.add_child(region)
	current_scene = region
	await _shot("arrival", Vector2(5.5, 4))
	await _shot("overlook", RiverValley.OVERLOOK)
	await _shot("first-crossing", Vector2(22, 5.5))
	await _shot("east-junction", Vector2(30, 6))
	await _shot("weir-approach", Vector2(58.8, -19.6))
	await _shot("weir", Vector2(63, -25))
	await _shot("southern-trail", Vector2(35, 35))
	await _shot("landing-approach", Vector2(47.5, 35))
	print("Trail review stills saved to ", OUTPUT)
	quit()

func _shot(label: String, at: Vector2) -> void:
	region.hero.respawn_at(ValleyPlaces.point(at) + Vector3.UP * 0.02)
	for frame in 35:
		await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(OUTPUT + "/" + label + ".png")
