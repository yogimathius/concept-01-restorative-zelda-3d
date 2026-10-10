extends "res://dev/review_waykeeper_journey.gd"
## Isolated touch walkthrough and desktop frame samples. Never uses production save.
var frame_samples: Array[float] = []
var monitor := false
func _process(delta: float) -> bool:
	if monitor and delta>0: frame_samples.append(delta*1000)
	return false
func shot(id: String) -> void:
	await frames(8)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/playtest/opening-benchmark/"+id+".png")
func walk_to(at: Vector3) -> void:
	region.hero.use_device_input = true
	var stick: Control = region.get_node("TouchControls/Virtual Joystick/Base")
	var origin := stick.global_position+stick.size*0.5
	for i in 100:
		var offset: Vector3 = at-region.hero.global_position
		if Vector2(offset.x,offset.z).length()<0.45: break
		await touch(origin+Vector2(offset.x,offset.z).normalized()*40,true)
		await frames(6)
		await touch(origin,false)
	region.hero.use_device_input = false
	region.hero.move_input = Vector2.ZERO
	check(Vector2(at.x-region.hero.global_position.x,at.z-region.hero.global_position.z).length()<0.7,"touch stick reaches "+str(at))
func last_page() -> void:
	while region.story.dialogue._index<region.story.dialogue._pages.size()-1: await control(region.story.dialogue._buttons[0])
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/playtest/opening-benchmark")
	region = load("res://scenes/levels/region1.tscn").instantiate()
	region.persist_progress = false
	region.save_path = "user://test-opening-benchmark-native.json"
	root.add_child(region)
	current_scene = region
	region.hero.use_device_input = false
	await frames(10)
	monitor = true
	await shot("arrival")
	await walk_to(Vector3(5.5,0.02,5.5))
	await tap(center(region.get_node("TouchControls/ContextButton")))
	check(region.story.dialogue.visible and region.story.dialogue._portrait.subject!=null,"Mara touch dialogue shows her actual human portrait")
	await shot("mara")
	await last_page()
	await control(region.story.dialogue._buttons[0])
	await last_page()
	await control(region.story.dialogue._buttons[0])
	check(region.story_flags.has("mara_met") and not paused,"Mara welcomes and guides the player through touch")
	await walk_to(Vector3(21.5,0.02,5.5))
	var mend_at := center(region.get_node("TouchControls/RestoreButton"))
	await touch(mend_at,true)
	await frames(35)
	await shot("connection")
	await frames(56)
	await touch(mend_at,false)
	await shot("reforming")
	check(region.builder.entities.B1.get("restored",false) and region.opening.presentations.B1.completing,"first easy Mend triggers staged restoration without pausing")
	await frames(60)
	await shot("water-finds-path")
	await frames(190)
	await shot("first-reward")
	check(region.opening._card.visible and region.waykeeper.progress.skill_points()==2,"clear first reward offers real Skill Point choice")
	await control(region.opening._skills)
	check(region.waykeeper.screen.visible,"reward opens the touch Skills screen")
	region.waykeeper.screen.view_node("steady_vessel")
	await control(region.waykeeper.screen._buy)
	check(region.waykeeper.progress.purchased.has("steady_vessel"),"touch chooses first node")
	await shot("first-skill-choice")
	await tap(region.waykeeper.screen.position+Vector2(532,28))
	region.equipment_screen.toggle()
	region.equipment_screen.select_item("grove_wand")
	await control(region.equipment_screen._equip)
	check(region.inventory.equipped.tool=="grove_wand","first loot visibly replaces the starter tool")
	await shot("first-equipment")
	region.equipment_screen.toggle()
	await walk_to(Vector3(30,0.02,5.5))
	await tap(center(region.get_node("TouchControls/ContextButton")))
	await last_page()
	await control(region.story.dialogue._buttons[0])
	check(region.waykeeper.progress.unlocked.has("force"),"Iona teaches Force through touch")
	await shot("force-lesson")
	await control(region.story.dialogue._buttons[2])
	await walk_to(Vector3(34.5,0.02,6.5))
	await tap(center(region.get_node("TouchControls/RestoreButton")))
	check(region.builder.entities.C1.runtime.ecology.states.cleared,"first Force physically clears the spring")
	await shot("first-force")
	await select_skill("mend")
	await touch(center(region.get_node("TouchControls/RestoreButton")),true)
	await frames(110)
	await touch(center(region.get_node("TouchControls/RestoreButton")),false)
	check(region.builder.entities.C1.get("restored",false),"Force-assisted Mend restores the spring")
	await frames(280)
	await shot("spring-restored")
	await walk_to(Vector3(28.5,0.02,5.5))
	await walk_to(Vector3(21.5,0.02,5.5))
	await walk_to(Vector3(12.6,0.02,5.5))
	await walk_to(Vector3(12.6,0.02,8.2))
	check(region.opening.landscape.gathering.visible,"return reveals basin, cups and wildlife")
	await shot("return")
	await tap(center(region.get_node("TouchControls/ContextButton")))
	check(region.story.dialogue.visible,"Mara can be touched at her new workplace")
	await shot("mara-return")
	await last_page()
	await control(region.story.dialogue._buttons[0])
	check(region.story_flags.has("opening_return_seen"),"return conversation remembers the restored community")
	await control(region.story.dialogue._buttons[2])
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.free()
	region = load("res://scenes/levels/region1.tscn").instantiate()
	region.persist_progress = false
	root.add_child(region)
	current_scene = region
	region._apply_journey_data(data)
	region._configure_restoration()
	region.opening.landscape.sync(false)
	await frames(20)
	check(region.progression.xp==80 and region.inventory.equipped.tool=="grove_wand" and region.waykeeper.progress.purchased.has("steady_vessel"),"reload keeps unique XP, chosen node and outfit")
	check(region.opening.landscape.gathering.visible and not region.opening.presentations.B1.completing,"reload settles the living world without replaying rewards")
	monitor = false
	frame_samples.sort()
	if not frame_samples.is_empty():
		print("Desktop presentation samples: count=",frame_samples.size()," median_ms=",frame_samples[frame_samples.size()/2]," p95_ms=",frame_samples[int(frame_samples.size()*0.95)]," static_memory_bytes=",OS.get_static_memory_usage())
	print("Opening native touch failures: ",failures.size())
	quit(1 if not failures.is_empty() else 0)
