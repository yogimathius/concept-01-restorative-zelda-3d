extends "res://dev/review_waykeeper_journey.gd"
func lesson(npc: String, at: Vector3, skill: String) -> void:
	await talk(npc,at)
	while region.story.dialogue._index<region.story.dialogue._pages.size()-1:
		await control(region.story.dialogue._buttons[0])
	var index := -1
	for i in region.story.dialogue._options.size():
		if region.story.dialogue._options[i].action=="learn_"+skill: index=i
	check(index>=0 and index<2,"local touch dialogue offers "+skill)
	if index>=0 and index<2: await control(region.story.dialogue._buttons[index])
	check(region.waykeeper.progress.unlocked.has(skill),"local touch lesson learns "+skill)
	await control(region.story.dialogue._buttons[2])
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/playtest/rpg-foundation")
	region = load("res://scenes/levels/region2.tscn").instantiate()
	region.persist_progress = false
	region.save_path = "user://test-native-marsh-conditions.json"
	root.add_child(region)
	current_scene = region
	region.hero.use_device_input = false
	await frames()
	await mend("M1")
	await lesson("Neri",Vector3(5.5,0.02,5.0),"force")
	await mend("M2")
	check(not region.builder.entities.M2.get("restored",false),"nursery stops at viable partial state")
	await capture("phase-c-nursery-blocked")
	await ability("M2","force")
	await mend("M2")
	await mend("M3")
	check(not region.builder.entities.M3.get("restored",false),"bell requires a stable foundation")
	await capture("phase-c-bell-unstable")
	await lesson("Oren",Vector3(23.5,0.02,18.0),"anchor")
	await ability("M3","anchor")
	await mend("M3")
	await ability("M1","anchor")
	check(region.builder.entities.M1.runtime.ecology.states.cultivated,"touch Anchor secures already restored garden irrigation")
	await capture("phase-c-garden-irrigation")
	region.hero.respawn_at(Vector3(23.5,0.02,5.5))
	await frames(170)
	var neri: Node3D
	for npc in get_nodes_in_group("story_npc"):
		if npc.get_parent()==region and npc.npc_id=="neri": neri=npc
	check(neri.global_position.distance_to(Vector3(5.5,0,3.5))>2,"Neri walks back to the living garden")
	region.hero.respawn_at(neri.global_position+Vector3.BACK*1.6)
	await frames()
	await tap(center(region.get_node("TouchControls/ContextButton")))
	check(region.story.dialogue._body.text.contains("harvest"),"touch conversation remembers improved irrigation")
	await capture("phase-c-neri-harvest")
	await control(region.story.dialogue._buttons[2])
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.free()
	region = load("res://scenes/levels/region2.tscn").instantiate()
	region.persist_progress = false
	root.add_child(region)
	current_scene = region
	region._apply_journey_data(data)
	region._configure_restoration()
	await frames()
	check(region.builder.entities.M1.runtime.ecology.states.cultivated and region.builder.entities.M3.get("restored",false),"garden improvement and chapter sites survive restart")
	print("Native marsh conditions failures: ",failures.size())
	quit(1 if failures.size()>0 else 0)
