extends TestCase
## The gentle opening retains safe movement and gains learned restoration techniques.
const REGION := preload("res://scenes/levels/region1.tscn")
var region: Node3D
var builder: RegionBuilder
var hero: Hero

func load_journey() -> void:
	region = REGION.instantiate()
	region.persist_progress = false
	hero = region.get_node("Hero")
	hero.use_device_input = false
	world.add_child(region)
	builder = region.get_node("Builder")
	await step(4)

func approach(id: String) -> RegionCreature:
	var place: RegionCreature = builder.entities[id].runtime
	hero.respawn_at(place.global_position + Vector3.LEFT * 2.0 + Vector3.UP * 0.02)
	hero.facing = Vector2.LEFT
	await step(2)
	return place

func heal(id: String) -> void:
	await approach(id)
	hero.set_verb_held(Hero.SLOT_RESTORE, true)
	await step(110)
	hero.set_verb_held(Hero.SLOT_RESTORE, false)
	await step(3)

func test_default_world_has_still_groves_springs_and_no_attacks() -> void:
	await load_journey()
	var place := await approach("B1")
	var at := place.global_position
	await step(180)
	check(place.global_position == at, "grove stays put; nothing to lure")
	check(place.model is KitPiece, "world object replaces the giant creature")
	check(place.can_mend(), "ready immediately without growth stripping or socket positioning")
	check(hero.hearts == hero.max_hearts, "standing beside corruption is safe")
	check(hero.gauge.value(&"weight") == 0, "no hostile Weight aura")
	check(tree.get_nodes_in_group("spark").is_empty(), "no hostile projectile encounters")
	check(builder._pool_hazards.is_empty(), "corruption pools are safe to explore")
	for x in [31, 32]:
		for z in [17, 18]:
			check(builder.can_walk(Vector2i(x, z)), "southern gardens have a direct walking connection")

func test_mend_keeps_partial_healing_and_visibly_restores_the_grove() -> void:
	await load_journey()
	var place := await approach("B1")
	hero.set_verb_held(Hero.SLOT_RESTORE, true)
	await step(30)
	hero.set_verb_held(Hero.SLOT_RESTORE, false)
	var saved := place.progress
	await step(90)
	check_near(place.progress, saved, 0.001, "letting go retains all healing")
	check(region._mend_bar.value > 20, "retained progress remains visible")
	hero.set_verb_held(Hero.SLOT_RESTORE, true)
	await step(100)
	hero.set_verb_held(Hero.SLOT_RESTORE, false)
	await step(3)
	check(place.restored, "one resumed hold completes healing from any facing")
	check(place.model.restored_node.visible and not place.model.corrupted_node.visible, "healthy model visibly replaces corruption")
	check(builder._restored_cells.has(Vector2i(20, 5)), "surrounding ground heals")
	check(builder._restored_cells.has(Vector2i(17, 8)), "nearby pool heals too")
	check(region._mend_bar.value == 100, "completion displays 100%")

func test_learned_restoration_opens_both_passages_and_all_six_places() -> void:
	await load_journey()
	for id in ["B1", "C1", "C3", "B2", "C2", "B3"]:
		if id == "C1": check(region.waykeeper.learn("force"), "the first grove enables Iona's Force teaching")
		if id == "C3": check(region.waykeeper.learn("anchor"), "the flowing spring enables Anchor teaching")
		var target := await approach(id)
		for skill in ["force","anchor"]:
			if target.ecology.accepts(skill):
				region.waykeeper.use_skill(skill)
				await step(30)
		await heal(id)
		check(builder.entities[id].get("restored", false), id + " healed with world conditions resolved and no precision positioning")
	check(builder.entities["G1"].get("powered", false), "spring healing opens first passage directly")
	check(builder.entities["G2"].get("powered", false), "spring healing opens the departure directly")
	check(region._healing_count.text == "6 / 6 places healed", "journey records all healing")
	check(tree.get_nodes_in_group("spark").is_empty(), "healing does not require projectile machinery")

func test_first_bridge_is_broad_and_crossable_after_simple_mend() -> void:
	await load_journey()
	await heal("B1")
	for z in [4, 5, 6]:
		for x in [24, 25, 26]:
			check(builder._bridged(Vector2i(x, z)), "broad deck has floor at %s,%s" % [x, z])
	hero.respawn_at(Vector3(22.5, 0.02, 5.5))
	hero.move_input = Vector2.RIGHT
	await step(180)
	hero.move_input = Vector2.ZERO
	check(hero.global_position.x > 28, "actual walking crosses the restored ford")
	check(hero.hearts == hero.max_hearts, "crossing needs no dash or danger")

func touch(index: int, at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = at
	event.pressed = pressed
	tree.root.push_input(event, true)
	await step(2)

func button_center(button: TouchScreenButton) -> Vector2:
	return button.position + button.texture_normal.get_size() * button.scale * 0.5

func test_touch_button_heals_and_keyboard_does_not_drive_mobile_play() -> void:
	await load_journey()
	await approach("B1")
	hero.use_device_input = true
	var press := InputEventKey.new()
	press.physical_keycode = KEY_SPACE
	press.pressed = true
	Input.parse_input_event(press)
	Input.flush_buffered_events()
	await step(10)
	check(not hero.restore_verb.active, "keyboard is not the mobile game's input path")
	var release := InputEventKey.new()
	release.physical_keycode = KEY_SPACE
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	await step(3)
	var controls := region.get_node("TouchControls")
	check(controls.visible, "touch controls also remain visible in desktop preview")
	var at := button_center(controls.get_node("RestoreButton"))
	await touch(1, at, true)
	await step(110)
	await touch(1, at, false)
	check(builder.entities["B1"].get("restored", false), "actual screen touch held on Mend heals the grove")
	check(tree.get_nodes_in_group("push_block").is_empty(), "no growth blocks or Force setup")
	check(not hero.restore_verb.active, "releasing the finger ends the channel")

func test_two_fingers_can_move_and_mend_independently() -> void:
	await load_journey()
	var grove := await approach("B1")
	hero.use_device_input = true
	var controls := region.get_node("TouchControls")
	var stick := controls.get_node("Virtual Joystick")
	var base := stick.get_node("Base") as Control
	var at := base.global_position + base.size * 0.5 + Vector2(36, 0)
	await touch(0, at, true)
	var mend_at := button_center(controls.get_node("RestoreButton"))
	await touch(1, mend_at, true)
	await step(30)
	check(hero.move_input.x > 0.5, "first finger keeps steering while the second holds Mend")
	check(grove.progress > 0.2, "second finger restores while moving")
	await touch(0, at, false)
	check(hero.move_input == Vector2.ZERO, "releasing the stick stops movement")
	check(hero.restore_verb.active, "releasing the stick does not release Mend")
	await touch(1, mend_at, false)
	check(not hero.restore_verb.active, "Mend stops on its own finger release")

func test_touch_glide_and_map_work_without_keyboard() -> void:
	await load_journey()
	hero.use_device_input = true
	var controls := region.get_node("TouchControls")
	var glide_at := button_center(controls.get_node("DashButton"))
	await touch(0, glide_at, true)
	check(hero.is_dashing(), "touching the illustrated Glide action starts travel")
	await touch(0, glide_at, false)
	var map_button := region.get_node("JourneyHUD/MapButton") as TouchScreenButton
	var map_at := button_center(map_button)
	await touch(1, map_at, true)
	check(tree.paused and region.journey_map.visible, "touching Map opens it and pauses the world")
	check(not controls.visible, "thumb controls do not cover the map")
	await touch(1, map_at, false)
	await touch(2, region.journey_map.position + Vector2(389, 20), true)
	check(not tree.paused and controls.visible, "touching the close control resumes the journey")
	await touch(2, region.journey_map.position + Vector2(389, 20), false)
