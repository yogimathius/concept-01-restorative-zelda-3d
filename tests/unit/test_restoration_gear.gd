extends TestCase
const REGION := preload("res://scenes/levels/region1.tscn")
const SAVE := "user://test-restoration-gear.json"

func after_each() -> void:
	tree.paused = false
	await super.after_each()
	for path in [SAVE, SAVE + ".tmp"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func make_region(persist := false) -> Node3D:
	var region: Node3D = REGION.instantiate()
	region.persist_progress = persist
	region.save_path = SAVE
	region.get_node("Hero").use_device_input = false
	world.add_child(region)
	await step(4)
	return region

func touch(at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = at
	event.pressed = pressed
	tree.root.push_input(event,true)
	await step(2)

func test_discoveries_are_guaranteed_and_never_repeat() -> void:
	var bag := RestorationInventory.new()
	check(bag.owned.size() == 3, "three starter pieces")
	check(not bag.equip("river_staff"), "locked pieces cannot equip")
	for place in RestorationInventory.DISCOVERIES.keys().filter(func(key): return key.begins_with("R1/")):
		check(not bag.discover(place).is_empty(), "every restoration discovers a named piece")
		check(bag.discover(place).is_empty(), "restoring a place twice never duplicates loot")
	check(bag.owned.size() == 9 and bag.seeds == 9 and bag.crystals == 6, "all six rewards and supplies")
	bag.equip("grove_wand")
	bag.equip("river_staff")
	check(bag.equipped.tool == "river_staff" and bag.owned.has("grove_wand"), "previous item remains in inventory")
	check_near(bag.bonus("reach"), 0.9, 0.001, "same-slot bonuses replace rather than stack")
	var restored := RestorationInventory.new()
	restored.apply_data(bag.to_data())
	check(restored.equipped.tool == "river_staff" and restored.owned.size() == 9, "inventory choices survive reload")

func test_actual_mend_rewards_gear_and_touch_equips_visible_replacement() -> void:
	var region := await make_region()
	var grove: RegionCreature = region.builder.entities.B1.runtime
	region.hero.respawn_at(grove.global_position+Vector3.LEFT*2+Vector3.UP*0.02)
	region.hero.set_verb_held(Hero.SLOT_RESTORE,true)
	await step(110)
	region.hero.set_verb_held(Hero.SLOT_RESTORE,false)
	check(region.inventory.owned.has("grove_wand"), "real Mend unlocks loot")
	check(region._gear_label.text.contains("+1"), "gear badge announces discovery")
	var gear: TouchScreenButton = region.get_node("JourneyHUD/GearButton")
	var center := gear.position+gear.texture_normal.get_size()*0.5
	await touch(center,true)
	await touch(center,false)
	var screen: EquipmentScreen = region.equipment_screen
	check(tree.paused and screen.visible, "actual touch opens equipment")
	check(screen.selected_id == "grove_wand", "new reward is previewed")
	var reach: float = region.hero.restore_verb.reach
	await touch(screen.position+screen._equip.position+screen._equip.size*0.5,true)
	await touch(screen.position+screen._equip.position+screen._equip.size*0.5,false)
	check(region.inventory.equipped.tool == "grove_wand", "actual touch equips reward")
	check_near(region.hero.restore_verb.reach, reach+0.5, 0.001, "equipped tool changes Mend")
	var root: Node = region.hero.visuals.get_child(0).get_node("Equipment")
	check(root.get_child_count() == 3 and root.get_node("Tool").get_child(0).name == "grove_wand", "character wears one piece per slot")
	check(root.find_child("wayfarer_wand",true,false) == null, "old tool is removed from the character")
	check(not region.get_node("TouchControls").visible, "equipping keeps thumb controls hidden under inventory")
	await touch(screen.position+Vector2(530,32),true)
	await touch(screen.position+Vector2(530,32),false)
	check(not tree.paused and region.get_node("TouchControls").visible, "touch close resumes play")

func test_cloak_and_charm_replace_and_follow_the_rig() -> void:
	var region := await make_region()
	for place in RestorationInventory.DISCOVERIES.keys().filter(func(key): return key.begins_with("R1/")): region.inventory.discover(place)
	for id in ["spring_cloak", "sunleaf_cloak", "river_charm"]:
		region.inventory.equip(id)
		region._configure_restoration()
	var root: Node = region.hero.visuals.get_child(0).get_node("Equipment")
	check(root.get_node("Cloak").get_child(0).name == "sunleaf_cloak", "new cloak is physically worn")
	check(root.find_child("spring_cloak",true,false) == null and root.find_child("wayfarer_cloak",true,false) == null, "old cloaks are gone")
	for slot in ["Tool","Cloak","Charm"]:
		var piece := root.get_node(slot) as BoneAttachment3D
		check(piece.use_external_skeleton and piece.get_skeleton() != null, slot+" follows the live animation skeleton")
	check_near(region.hero._top_speed(), region.hero.hero_class.base_speed*1.1, 0.001, "cloak applies walking bonus")
	check_near(region.hero.restore_verb.rate, 0.79, 0.001, "charm applies healing bonus")
	region.swap_class()
	check(region.hero.visuals.get_child(0).get_node("Equipment/Cloak").get_child(0).name == "sunleaf_cloak", "class rebuilding preserves outfit")

func test_existing_saves_grant_missed_loot_and_preserve_equipment() -> void:
	var file := FileAccess.open(SAVE,FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":1,"restored":["B1","C1"],"progression":{}}))
	file.close()
	var region := await make_region(true)
	check(region.inventory.owned.has("grove_wand") and region.inventory.owned.has("spring_cloak"), "older world saves receive earned loot")
	region.inventory.equip("spring_cloak")
	region.inventory.equip("grove_wand")
	region._configure_restoration()
	region._save_journey()
	region.persist_progress = false
	region.free()
	var resumed := await make_region(true)
	check(resumed.inventory.equipped.cloak == "spring_cloak" and resumed.inventory.equipped.tool == "grove_wand", "worn gear reloads")
	check(resumed.inventory.seeds == 3 and resumed.inventory.crystals == 2, "reload does not duplicate supplies")
	check(resumed.hero.visuals.get_child(0).get_node("Equipment/Cloak").get_child(0).name == "spring_cloak", "loaded gear is visible")

func test_invalid_saved_items_and_duplicate_claims_are_sanitized() -> void:
	var bag := RestorationInventory.new()
	bag.apply_data({"claimed":["R1/B1","R1/B1","fake",null],"equipped":{"tool":"sunleaf_cloak","cloak":"sunleaf_cloak","charm":"fake"},"seeds":999})
	check(bag.owned.size() == 4 and bag.seeds == 3, "claims validated and duplicates removed")
	check(bag.equipped == RestorationInventory.STARTERS, "unknown, unowned or wrong-slot equipment cannot load")

func test_touch_cloak_cards_preview_replace_and_requip_previous_piece() -> void:
	var region := await make_region()
	region.builder.restore("C1")
	region.builder.restore("B3")
	var screen: EquipmentScreen = region.equipment_screen
	screen.toggle()
	await touch(screen.position+screen._tabs[0].position+screen._tabs[0].size*0.5,true)
	await touch(screen.position+screen._tabs[0].position+screen._tabs[0].size*0.5,false)
	check(screen.selected_slot == "tool", "touch tabs change the displayed slot")
	await touch(screen.position+screen._tabs[1].position+screen._tabs[1].size*0.5,true)
	await touch(screen.position+screen._tabs[1].position+screen._tabs[1].size*0.5,false)
	await touch(screen.position+screen._cards[2].position+screen._cards[2].size*0.5,true)
	await touch(screen.position+screen._cards[2].position+screen._cards[2].size*0.5,false)
	check(screen.selected_id == "sunleaf_cloak" and region.inventory.equipped.cloak == "wayfarer_cloak", "touch card previews without changing the outfit")
	await touch(screen.position+screen._equip.position+screen._equip.size*0.5,true)
	await touch(screen.position+screen._equip.position+screen._equip.size*0.5,false)
	check(region.hero.visuals.get_child(0).get_node("Equipment/Cloak").get_child(0).name == "sunleaf_cloak", "touch Equip swaps the visible cloak")
	await touch(screen.position+screen._cards[0].position+screen._cards[0].size*0.5,true)
	await touch(screen.position+screen._cards[0].position+screen._cards[0].size*0.5,false)
	await touch(screen.position+screen._equip.position+screen._equip.size*0.5,true)
	await touch(screen.position+screen._equip.position+screen._equip.size*0.5,false)
	check(region.inventory.equipped.cloak == "wayfarer_cloak" and region.hero.gear_speed_bonus == 0, "old gear can be worn again and upgrade bonus is removed")
	check(region.inventory.owned.has("sunleaf_cloak"), "replaced cloak remains owned")
	screen.toggle()
