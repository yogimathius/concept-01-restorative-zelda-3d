extends SceneTree
const SAVE := "user://test-native-rpg-foundation.json"
var region: Node3D
var failures := []
func _init() -> void: call_deferred("run")
func frames(count := 6) -> void:
	for i in count: await physics_frame
func check(value: bool, label: String) -> void:
	print("PASS " if value else "FAIL ",label)
	if not value: failures.append(label)
func capture(name: String) -> void:
	await frames(12)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/playtest/rpg-foundation/"+name+".png")
func touch(point: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 3
	event.pressed = down
	event.position = root.get_final_transform()*point
	root.push_input(event,false)
	await frames(2)
func tap(point: Vector2) -> void:
	await touch(point,true)
	await touch(point,false)
func center(button: TouchScreenButton) -> Vector2:
	return button.position+button.texture_normal.get_size()*button.scale*0.5
func control(button: Control) -> void:
	await tap(button.get_global_transform_with_canvas()*(button.size*0.5))
func approach(id: String) -> Node3D:
	var target: Node3D = region.builder.entities[id].runtime
	region.hero.respawn_at(target.global_position+Vector3.LEFT*2+Vector3.UP*0.02)
	await frames(6)
	return target
func select_skill(id: String) -> void:
	await control(region.get_node("JourneyHUD/SkillsButton"))
	var screen: Control = region.waykeeper.screen
	await control(screen._tech_tab)
	await control(screen._skills[id])
	if not screen._select.disabled: await control(screen._select)
	await tap(screen.position+Vector2(532,28))
	check(region.waykeeper.progress.active==id and not paused,"touch loadout selects "+id)
func mend(id: String) -> void:
	await approach(id)
	if region.waykeeper.progress.active!="mend": await select_skill("mend")
	var point := center(region.get_node("TouchControls/RestoreButton"))
	await touch(point,true)
	if id == "B1":
		await frames(35)
		await capture("first-mend")
		await frames(63)
	else: await frames(110)
	await touch(point,false)
func ability(id: String, skill: String) -> void:
	await approach(id)
	if region.waykeeper.progress.active!=skill: await select_skill(skill)
	await tap(center(region.get_node("TouchControls/RestoreButton")))
	await frames(30)
func talk(id: String, at: Vector3) -> void:
	region.hero.respawn_at(at)
	await frames()
	await tap(center(region.get_node("TouchControls/ContextButton")))
	check(region.story.dialogue.visible,"touch talks to "+id)
func learn() -> void:
	while region.story.dialogue._index<region.story.dialogue._pages.size()-1:
		await control(region.story.dialogue._buttons[0])
	await control(region.story.dialogue._buttons[0])
	await capture("lesson")
	await control(region.story.dialogue._buttons[2])
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/playtest/rpg-foundation")
	for path in [SAVE,SAVE+".tmp"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	region = load("res://scenes/levels/region1.tscn").instantiate()
	region.save_path = SAVE
	root.add_child(region)
	current_scene = region
	region.hero.use_device_input = false
	await frames()
	await capture("opening-resources")
	await mend("B1")
	check(region.builder.entities.B1.get("restored",false),"first touch Mend restores the broad crossing")
	region.hero.respawn_at(Vector3(22.5,0.02,5.5))
	region.hero.use_device_input = true
	var stick: Control = region.get_node("TouchControls/Virtual Joystick/Base")
	var stick_at := stick.global_position+stick.size*0.5+Vector2(36,0)
	await touch(stick_at,true)
	await frames(100)
	await touch(stick_at,false)
	region.hero.use_device_input = false
	check(region.hero.global_position.x>28,"actual touch stick walks across the safe broad bridge")
	await talk("Iona",Vector3(30,0.02,7.0))
	await learn()
	check(region.waykeeper.progress.unlocked.has("force"),"touch lesson learns Force")
	await mend("C1")
	check(region.builder.entities.C1.runtime.progress>0.4 and not region.builder.entities.C1.get("restored",false),"Mend partially warms blocked water")
	await capture("blocked-spring")
	await ability("C1","force")
	await capture("clear-spring")
	check(region.builder.entities.C1.runtime.ecology.states.cleared,"touch Force moves real stone obstruction")
	await mend("C1")
	await mend("B2")
	check(not region.builder.entities.B2.get("restored",false) and region.builder.entities.B2.runtime.progress>0.5,"a discovered leaning grove waits for future knowledge")
	await capture("leaning-grove")
	await talk("Iona",Vector3(30,0.02,7.0))
	await learn()
	check(region.waykeeper.progress.unlocked.has("anchor"),"second story lesson learns Anchor")
	await ability("B2","anchor")
	await capture("anchored-grove")
	await mend("B2")
	await ability("C3","force")
	check(not region.builder.entities.C3.runtime.ecology.ready_to_restore(),"spillway still needs its foundation after clearing")
	region._save_journey()
	region.persist_progress = false
	region.free()
	region = load("res://scenes/levels/region1.tscn").instantiate()
	region.save_path = SAVE
	root.add_child(region)
	current_scene = region
	region.hero.use_device_input = false
	await frames()
	check(region.builder.entities.C3.runtime.ecology.states.cleared and not region.builder.entities.C3.runtime.ecology.states.stabilized,"native restart retains intermediate ecological states")
	await ability("C3","anchor")
	await mend("C3")
	check(region.builder.entities.G2.get("powered",false),"multi-ability restoration opens real spillway")
	await ability("C2","force")
	await mend("C2")
	await ability("B3","force")
	await ability("B3","anchor")
	await mend("B3")
	for id in region.builder.manifest.ENTITIES: check(region.builder.entities[id].get("restored",false),"native route restores "+id)
	await control(region.get_node("JourneyHUD/SkillsButton"))
	region.waykeeper.screen.view_node("shared_ground")
	await control(region.waykeeper.screen._buy)
	check(region.waykeeper.progress.upgrades.has("shared_ground"),"touch buys real mastery behaviour")
	await capture("mastery")
	await tap(region.waykeeper.screen.position+Vector2(532,28))
	region.equipment_screen.toggle()
	region.equipment_screen.select_item("ferryman_staff")
	await control(region.equipment_screen._equip)
	check(region.inventory.equipped.tool=="ferryman_staff","touch equips the new visible behavioural staff")
	await capture("gear")
	region.equipment_screen.toggle()
	await talk("Oren",Vector3(49,0.02,18.5))
	while region.story.dialogue._index<region.story.dialogue._pages.size()-1: await control(region.story.dialogue._buttons[0])
	await control(region.story.dialogue._buttons[0])
	await frames(25)
	region = current_scene
	check(region.region_id=="R2" and region.waykeeper.progress.upgrades.has("shared_ground"),"touch travel carries skills and mastery into Reedglass")
	region.hero.use_device_input = false
	await mend("M1")
	await mend("M2")
	check(not region.builder.entities.M2.get("restored",false),"nursery holds partial recovery until Force opens its feed")
	await ability("M2","force")
	await mend("M2")
	await mend("M3")
	check(not region.builder.entities.M3.get("restored",false),"bell holds partial recovery until Anchor steadies its foundation")
	await ability("M3","anchor")
	await mend("M3")
	await ability("M4","anchor")
	await mend("M4")
	await ability("M5","force")
	await mend("M5")
	await ability("M6","force")
	await mend("M6")
	check(region.builder.entities.M4.get("restored",false) and region.builder.entities.M5.get("restored",false) and region.builder.entities.M6.get("restored",false),"new techniques restore all three optional marsh places")
	await capture("marsh-restoration")
	await talk("Oren",Vector3(23.5,0.02,18))
	while region.story.dialogue._index<region.story.dialogue._pages.size()-1: await control(region.story.dialogue._buttons[0])
	await control(region.story.dialogue._buttons[0])
	check(region.story_flags.has("marsh_message"),"existing immersive marsh chapter still completes")
	await control(region.story.dialogue._buttons[2])
	await talk("Oren",Vector3(23.5,0.02,18))
	while region.story.dialogue._index<region.story.dialogue._pages.size()-1: await control(region.story.dialogue._buttons[0])
	await control(region.story.dialogue._buttons[0])
	await frames(25)
	region = current_scene
	check(region.region_id=="R1" and region.progression.xp==480,"return retains all twelve unique restoration rewards")
	check(region.inventory.equipped.tool=="ferryman_staff" and region.waykeeper.progress.unlocked.has("anchor"),"return retains outfit and learned traditions")
	region.hero.resources.protection_left = 0
	region.hero.lose_stability(200)
	await capture("unmoored")
	await frames(60)
	check(region.hero.resources.stability > 0 and region.builder.entities.C3.get("restored",false),"Unmoored keeps all restored places")
	await capture("grounded-again")
	region._save_journey()
	var saved = JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	check(saved.version==5 and saved.worlds.R2.restored.has("M3"),"disk save contains skills and both playable worlds")
	region.persist_progress = false
	for path in [SAVE,SAVE+".tmp"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("Native ability-route failures: ",failures.size())
	quit(1 if not failures.is_empty() else 0)
