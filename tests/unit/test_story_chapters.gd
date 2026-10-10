extends TestCase
const FORD := preload("res://scenes/levels/region1.tscn")
const MARSH := preload("res://scenes/levels/region2.tscn")
const SAVE := "user://test-story-chapters.json"
var region: Node3D
func after_each() -> void:
	tree.paused = false
	tree.root.get_node("JourneySession").pending = {}
	await super.after_each()
	for path in [SAVE,SAVE+".tmp"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func load_region(scene: PackedScene, persist := false) -> Node3D:
	region = scene.instantiate()
	region.persist_progress = persist
	region.save_path = SAVE
	region.get_node("Hero").use_device_input = false
	world.add_child(region)
	await step(5)
	return region

func touch(at: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 1
	event.position = at
	event.pressed = down
	tree.root.push_input(event,true)
	await step(2)

func tap(at: Vector2) -> void:
	await touch(at,true)
	await touch(at,false)

func choose(index: int) -> void:
	var dialogue: DialogueScreen = region.story.dialogue
	var button := dialogue._buttons[index]
	await tap(dialogue.position+button.position+button.size*0.5)

func approach_npc(id: String) -> void:
	for npc in tree.get_nodes_in_group("story_npc"):
		if npc.get_parent() == region and npc.npc_id == id:
			region.hero.respawn_at(npc.global_position+Vector3.BACK*1.6+Vector3.UP*0.02)
	await step(6)

func mend(id: String) -> void:
	var target: RegionCreature = region.builder.entities[id].runtime
	region.hero.respawn_at(target.global_position+Vector3.LEFT*2+Vector3.UP*0.02)
	# Standalone marsh fixtures represent a visitor with Ford traditions.
	for skill in ["force","anchor"]:
		if target.ecology.accepts(skill):
			region.waykeeper.progress.unlock(skill)
			region.waykeeper.use_skill(skill)
			await step(30)
	region.hero.set_verb_held(Hero.SLOT_RESTORE,true)
	await step(110)
	region.hero.set_verb_held(Hero.SLOT_RESTORE,false)

func test_touch_talk_introduces_the_story_and_gives_cups_once() -> void:
	await load_region(FORD)
	await approach_npc("mara")
	var controls := region.get_node("TouchControls")
	var button: TouchScreenButton = controls.get_node("ContextButton")
	check(controls._labels.ContextButton[0].text == "TALK", "context action recognizes nearby character")
	await tap(button.position+button.texture_normal.get_size()*button.scale*0.5)
	check(tree.paused and region.story.dialogue.visible, "touch TALK pauses movement for conversation")
	check(region.story.dialogue._body.text.contains("waykeeper"), "first page introduces player and character")
	await choose(0)
	await choose(0)
	check(region.story_flags.has("mara_met") and region.inventory.count_consumable("bloom_tea")==2, "accepting help records meeting and gives two cups")
	await choose(0)
	check(not tree.paused and controls.visible, "touch leave resumes movement")
	region.story.talk("mara")
	region.story._act("mara_history")
	check(region.inventory.count_consumable("bloom_tea")==2, "repeat conversation never farms gifts")
	region.story.dialogue.dismiss()

func test_marsh_has_connected_walkable_courts_and_named_restorations() -> void:
	await load_region(MARSH)
	check(region.builder.level.areas.size()==4, "second region has four authored courts")
	check(region.builder.entities.size()==6, "six new restoration places")
	var inhabitants := tree.get_nodes_in_group("story_npc")
	check(inhabitants.size()==5, "three story inhabitants and two Reedglass exchange residents")
	var names := []
	for npc in inhabitants: names.append(npc.npc_id)
	for id in ["neri","daro","oren","sela","bryn"]: check(id in names,"Reedglass retains "+id)
	for cell in [Vector2i(15,5),Vector2i(16,5),Vector2i(7,11),Vector2i(7,12),Vector2i(23,11),Vector2i(23,12)]:
		check(region.builder.can_walk(cell), "broad walking connection at "+str(cell))
	region.hero.respawn_at(Vector3(13.5,0.02,5.5))
	region.hero.move_input = Vector2.RIGHT
	await step(130)
	check(region.hero.global_position.x>20, "actual walking crosses the northern seam")
	region.hero.move_input = Vector2.ZERO
	check(tree.get_nodes_in_group("spark").is_empty(), "marsh remains focused on restoration")

func test_full_marsh_story_accepts_work_done_before_meeting_npcs() -> void:
	await load_region(MARSH)
	region.story._act("marsh_message")
	check(not region.story_flags.has("marsh_message"), "chapter cannot complete before main restorations")
	for id in ["M3","M1","M2"]: await mend(id)
	check(region.progression.xp==120, "new region restoration earns experience")
	check(region.inventory.owned.has("marsh_staff") and region.inventory.owned.has("marsh_cloak") and region.inventory.owned.has("bell_charm"), "main restorations drop equippable gear")
	await approach_npc("neri")
	region.story.talk("neri")
	check(region.story.dialogue._body.text.contains("Oren"), "Neri recognizes completed work without requiring quest order")
	region.story.dialogue.dismiss()
	await approach_npc("oren")
	region.story.talk("oren")
	await choose(0)
	await choose(0)
	await choose(0)
	check(region.story_flags.has("marsh_message") and region.inventory.owned.has("messenger_charm"), "real conversation completes chapter and grants visible gear")
	check(region.story.dialogue._heading.text.contains("CHAPTER COMPLETE"), "chapter has a clear payoff")
	region.story.dialogue.dismiss()
	region.story._act("marsh_message")
	check(region.inventory.owned.count("messenger_charm")==1, "quest reward is not duplicated")
	region.story.dialogue.dismiss()
	await approach_npc("neri")
	region.story.talk("neri")
	check(region.story.dialogue._body.text.contains("Lio is alive") and region.story_flags.has("neri_letter"), "bringing the letter back gives a personal resolution")
	region.story.dialogue.dismiss()

func test_neri_reply_touch_route_changes_oren_and_survives_reload() -> void:
	await load_region(MARSH)
	for id in ["M1","M2","M3"]: region.builder.restore(id)
	await step(3)
	check(region.correspondence._found.visible,"Lio's sealed letter appears at the restored bell")
	check(region.builder.can_walk(Vector2i(25,19)) and region.builder.can_walk(Vector2i(7,5)),"Oren's bell post and Neri's writing place are walkable")
	var oren: StoryNPC
	for npc in tree.get_nodes_in_group("story_npc"):
		if npc.get_parent()==region and npc.npc_id=="oren": oren=npc
	var dock_position: Vector3 = oren.global_position
	await step(100)
	check(oren.workplace.distance_to(region.builder.entities.M3.runtime.global_position)<3,"Oren chooses to inspect the bell")
	check(oren.global_position.distance_to(dock_position)>1.0,"Oren physically leaves the landing when the letter arrives")
	var route_walkable := true
	for i in 17:
		var point := dock_position.lerp(oren.workplace,float(i)/16.0)
		if not region.builder.can_walk(Vector2i(floori(point.x),floori(point.z))): route_walkable = false
	check(route_walkable,"Oren's short walk to the bell stays on traversable ground")
	await approach_npc("oren")
	region.story.talk("oren")
	while region.story.dialogue._index<region.story.dialogue._pages.size()-1: await choose(0)
	await choose(0)
	check(region.story_flags.has("marsh_message"),"touch accepts the recovered letter")
	region.story.dialogue.dismiss()
	await approach_npc("neri")
	region.story.talk("neri")
	check(region.story_flags.has("neri_letter"),"Neri receives Lio's letter")
	while region.story.dialogue._index<region.story.dialogue._pages.size()-1: await choose(0)
	await choose(0)
	check(region.story_flags.has("neri_reply_ready"),"touch choice creates Neri's carried reply")
	check(region.journal.observe(region,"quest/R2/neri_reply").status.contains("Oren"),"journal points to the courier handoff")
	region.story.dialogue.dismiss()
	await step(3)
	check(region.correspondence._received.visible and region.correspondence._carried.visible,"Lio's letter and Neri's reply have physical places")
	await approach_npc("oren")
	region.story.talk("oren")
	while region.story.dialogue._index<region.story.dialogue._pages.size()-1: await choose(0)
	var before_xp: int = region.progression.xp
	var before_scrip: int = region.economy.scrip
	await choose(0)
	check(region.story_flags.has("neri_reply_sent") and region.progression.xp==before_xp+15 and region.economy.scrip==before_scrip+4,"reply pays one authored social quest reward")
	region.story.dialogue.dismiss()
	await step(3)
	check(region.correspondence._outgoing.visible and not region.correspondence._carried.visible,"reply moves from player to Oren's landing")
	check(oren.workplace.distance_to(Vector3(23.5,0,16.5))<1,"Oren returns to his boat with the reply")
	region.hero.respawn_at(Vector3(6.5,0.02,5.5))
	await step(110)
	check(oren.global_position.distance_to(Vector3(23.5,0,16.5))<0.6,"Oren actually walks back to the landing")
	region.story._act("neri_reply_send")
	check(region.progression.xp==before_xp+15 and region.economy.scrip==before_scrip+4,"repeated handoff cannot farm XP or scrip")
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.free()
	region = await load_region(MARSH)
	region._apply_journey_data(data)
	await step(3)
	check(region.story_flags.has("neri_reply_sent") and region.correspondence._outgoing.visible,"reply state and physical packet survive save reload")
	check(region.journal.observe(region,"quest/R2/neri_reply").done,"completed social quest persists in the journal")

func test_touch_pack_consumes_one_cup_and_restores_bonuses_on_expiry() -> void:
	await load_region(FORD)
	region.inventory.grant_gift("mara_intro")
	var base: float = region.hero.restore_verb.reach
	region.story.open_pack()
	await choose(0)
	check(not tree.paused and region.inventory.count_consumable("bloom_tea")==1, "touching tea consumes one cup and resumes play")
	check_near(region.hero.restore_verb.reach,base+1.5,0.001,"tea widens actual Mend reach")
	region.story.open_pack()
	check(region.story.dialogue._buttons[0].disabled, "active tea cannot be consumed twice")
	var time: float = region.hero.tea_left
	await step(30)
	check_near(region.hero.tea_left,time,0.001,"paused conversation does not spend buff duration")
	await choose(2)
	region.hero.tea_left = 0.02
	await step(4)
	check_near(region.hero.restore_verb.reach,base,0.001,"expiry removes temporary range")
	region.story.open_pack()
	await choose(0)
	region.story.open_pack()
	check(region.story.dialogue._buttons[0].disabled, "empty tea cannot be used")
	await choose(2)
	check(not tree.paused, "pack always has a touch close even when choices are disabled")

func test_brewing_spends_supplies_and_json_reload_preserves_used_cups() -> void:
	var bag := RestorationInventory.new()
	bag.discover("R1/B1")
	bag.discover("R1/C1")
	check(bag.brew("bloom_tea") and bag.seeds==0, "tea costs three seeds")
	check(not bag.brew("bloom_tea"), "cannot brew without supplies")
	check(bag.brew("reed_cordial") and bag.crystals==0, "cordial costs two crystals")
	bag.use_consumable("bloom_tea")
	bag.use_consumable("reed_cordial")
	var restored := RestorationInventory.new()
	restored.apply_data(JSON.parse_string(JSON.stringify(bag.to_data())))
	check(restored.count_consumable("bloom_tea")==1 and restored.count_consumable("reed_cordial")==1, "JSON numbers retain brewing and consumption")
	check(restored.seeds==0 and restored.crystals==0, "spent supplies stay spent after restart")

func test_multiregion_save_preserves_worlds_outfit_story_and_effects() -> void:
	var ford := await load_region(FORD,true)
	await mend("B1")
	ford.inventory.equip("grove_wand")
	ford.story_flags.mara_met = true
	ford.inventory.grant_gift("mara_intro")
	ford.hero.use_cup("bloom_tea")
	ford.inventory.use_consumable("bloom_tea")
	var data: Dictionary = ford._journey_data("R2")
	ford.persist_progress = false
	ford.free()
	var marsh := await load_region(MARSH,true)
	marsh._apply_journey_data(data)
	marsh._configure_restoration()
	await mend("M1")
	marsh.story_flags.neri_met = true
	marsh._save_journey()
	marsh.persist_progress = false
	marsh.free()
	var resumed := await load_region(MARSH,true)
	check(resumed.builder.entities.M1.get("restored",false), "marsh world remains restored")
	check(resumed._worlds.R1.restored.has("B1"), "ford world is preserved alongside marsh")
	check(resumed.inventory.equipped.tool == "grove_wand" and resumed.story_flags.has("neri_met"), "outfit and NPC state survive reload")
	check(resumed.hero.tea_left>0 and resumed.inventory.used.bloom_tea==1, "active effect and its consumed count survive reload")
	check(resumed.progression.xp==80, "XP counts each region's places once")
	var back_data: Dictionary = resumed._journey_data("R1")
	resumed.persist_progress = false
	resumed.free()
	var back := await load_region(FORD,false)
	back._apply_journey_data(back_data)
	back._configure_restoration()
	check(back.builder.entities.B1.get("restored",false) and back.builder._bridged(Vector2i(25,5)), "returning restores the old bridge")

func test_daro_touch_rewards_brewing_and_cordial_change_actual_movement() -> void:
	await load_region(MARSH)
	await mend("M5")
	await approach_npc("daro")
	region.story.talk("daro")
	while region.story.dialogue._index<region.story.dialogue._pages.size()-1: await choose(0)
	await choose(0)
	check(region.inventory.gifts.has("daro_spring"), "helping Daro earns his first batch")
	while region.story.dialogue._index<region.story.dialogue._pages.size()-1: await choose(0)
	await choose(0)
	check(region.story.dialogue._heading.text.contains("BREWING"), "Daro opens the touch recipes")
	while region.story.dialogue._index<region.story.dialogue._pages.size()-1: await choose(0)
	await choose(1)
	check(region.inventory.crystals==0 and region.inventory.brewed.reed_cordial==1, "touch recipe spends the actual two crystals")
	region.story.dialogue.dismiss()
	var speed: float = region.hero._top_speed()
	var cups: int = region.inventory.count_consumable("reed_cordial")
	region.story.open_pack()
	await choose(1)
	check_near(region.hero._top_speed(),speed*1.2,0.001,"cordial changes actual walking speed")
	check(region.inventory.count_consumable("reed_cordial")==cups-1,"one cordial is consumed")

func test_completed_legacy_ford_is_preserved_and_acknowledged_by_mara() -> void:
	var file := FileAccess.open(SAVE,FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1,"restored":["B1","C1","C3","B2","C2","B3"],"progression":{}}))
	file.close()
	await load_region(FORD,true)
	for id in Region1Manifest.ENTITIES: check(region.builder.entities[id].get("restored",false),"legacy completion survives for "+id)
	check(region.progression.xp==240 and region.inventory.owned.size()==9,"legacy levels and earned loot are preserved")
	await approach_npc("mara")
	region.story.talk("mara")
	check(region.story.dialogue._body.text.contains("flowing again"),"Mara's first meeting recognizes the already restored ford")
	region.story._act("mara_intro")
	check(" ".join(region.story.dialogue._pages).contains("Reedglass Marsh"),"Mara sends a returning player to the actual next region")
	region.story.dialogue.dismiss()
