extends "res://dev/review_waykeeper_journey.gd"
## Isolated stills and repeated portrait lifecycle check; no production save.
func still(id: String, at: Vector2) -> void:
	region.hero.respawn_at(Vector3(at.x,RiverValley.height_at(at)+0.02,at.y))
	await frames(30)
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png("res://builds/playtest/valley-watershed/"+id+".png")
func run() -> void:
	region = load("res://scenes/levels/river_valley.tscn").instantiate()
	region.persist_progress = false
	root.add_child(region)
	current_scene = region
	region.hero.use_device_input = false
	await frames(10)
	for id in ["mara","iona","oren","iona"]:
		region.story.talk(id)
		await frames(20)
		RenderingServer.force_draw(false)
		region.story.dialogue.dismiss()
		await frames(10)
	await still("arrival-final",Vector2(5.5,4))
	await still("overlook-final",RiverValley.OVERLOOK)
	var data: Dictionary = region._journey_data()
	region.free()
	await frames(4)
	region = load("res://scenes/levels/river_valley.tscn").instantiate()
	region.persist_progress = false
	root.add_child(region)
	current_scene = region
	region.hero.use_device_input = false
	region._apply_journey_data(data)
	await frames(20)
	for id in ["iona","mara","oren","iona"]:
		region.story.talk(id)
		await frames(20)
		RenderingServer.force_draw(false)
		region.story.dialogue.dismiss()
		await frames(10)
	data.worlds.R1.restored = ["B1","B2","B3","C1","C2","C3"]
	region._apply_journey_data(data)
	region._configure_restoration()
	region._update_level_hud()
	await still("weir-final",Vector2(63,-25))
	await still("landing-final",Vector2(55,35))
	print("Art review and repeated portraits complete; Master mute: ",AudioServer.is_bus_mute(0))
	quit()
