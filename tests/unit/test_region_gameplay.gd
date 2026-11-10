extends TestCase

const REGION := preload("res://scenes/levels/region1.tscn")
const WEAVER := preload("res://data/classes/weaver.tres")
var region: Node3D
var builder: RegionBuilder
var hero: Hero

func load_region() -> void:
	region = REGION.instantiate()
	region.persist_progress = false
	# Preserve coverage of the earlier mechanics in their opt-in configuration.
	region.get_node("Builder").restoration_only = false
	hero = region.get_node("Hero")
	hero.use_device_input = false
	world.add_child(region)
	builder = region.get_node("Builder")
	await step(4)

func force_once() -> void:
	hero.set_verb_held(Hero.SLOT_FORCE, true)
	await step(9)
	hero.set_verb_held(Hero.SLOT_FORCE, false)
	await step(24)

func approach_bearer() -> RegionCreature:
	var bearer: RegionCreature = builder.entities["B1"].runtime
	bearer.global_position = Vector3(23.5, 0, 3.5)
	hero.respawn_at(Vector3(22.15, 0.02, 3.5))
	hero.facing = Vector2.RIGHT
	await step(2)
	return bearer

func test_physical_mend_keys_activate_and_restore_with_range_feedback() -> void:
	await load_region()
	hero.use_device_input = true
	for key in [KEY_K, KEY_E]:
		var event := InputEventKey.new()
		event.physical_keycode = key
		event.pressed = true
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await step(4)
		check(hero.restore_verb.active, "physical %s activates Mend" % OS.get_keycode_string(key))
		check(is_instance_valid(hero.restore_verb._reach_ring) and hero.restore_verb._reach_ring.visible, "holding Mend shows its radius without a target")
		check(not hero.restore_verb.feedback.is_empty(), "Mend explains missing targets")
		var release := InputEventKey.new()
		release.physical_keycode = key
		Input.parse_input_event(release)
		Input.flush_buffered_events()
		await step(3)
		check(not hero.restore_verb.active, "%s release stops Mend (input=%s held=%s delivered=%s)" % [OS.get_keycode_string(key), Input.is_action_pressed("restore"), hero._held[Hero.SLOT_RESTORE], hero._delivered[Hero.SLOT_RESTORE]])
	var bearer := await approach_bearer()
	hero.use_device_input = false
	for i in 3: await force_once()
	hero.use_device_input = true
	var event := InputEventKey.new()
	event.physical_keycode = KEY_E
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await step(80)
	var release := InputEventKey.new()
	release.physical_keycode = KEY_E
	Input.parse_input_event(release)
	Input.flush_buffered_events()
	await step(3)
	check(builder.entities["B1"].get("restored", false), "physical E mends the actual stripped Bearer")

func test_warden_strips_and_mends_bearer_through_real_verbs() -> void:
	await load_region()
	var bearer := await approach_bearer()
	for i in 3: await force_once()
	check(bearer.growths == 0, "three heavy Force pulses detach the armor")
	check(bearer.can_mend(), "bare Bearer beside the socket is eligible")
	hero.set_verb_held(Hero.SLOT_RESTORE, true)
	await step(80)
	hero.set_verb_held(Hero.SLOT_RESTORE, false)
	check(builder.entities["B1"].get("restored", false), "Mend creates the bridge without the preview key")
	check(builder._bridged(Vector2i(25, 3)), "actual ford deck is recorded")
	check(not builder._pool_hazards.has("F1"), "restoration clears the paired pool")
	check(builder._restored_cells.has(Vector2i(19, 5)), "color returns across the ford ground")

func test_creature_panel_counts_force_hits_and_shows_mend_completion() -> void:
	await load_region()
	var bearer := await approach_bearer()
	check(region._creature_title.text.contains("0 / 3"), "preparation shows all three growths remaining")
	await force_once()
	check(region._creature_title.text.contains("1 / 3"), "Force advances the preparation counter, not Mend progress")
	check(region._mend_bar.value == 0, "Force does not fill the Mend bar")
	for i in 2: await force_once()
	hero.set_verb_held(Hero.SLOT_RESTORE, true)
	await step(25)
	check(bearer.progress > 0.2 and bearer.progress < 0.6, "a single held Mend steadily fills restoration")
	check(region._mend_bar.value > 20 and region._mend_bar.value < 60, "player sees live partial progress")
	check(region._creature_steps.text.contains("left"), "player sees time remaining, not an unexplained hit count")
	await step(60)
	check(region._mend_bar.value == 100, "completion stays visible at 100%")
	check(region._creature_title.text.contains("RESTORED"), "completion explicitly confirms restoration")
	check(hero.restore_verb.feedback.contains("Restored"), "holding past completion keeps confirmation")
	hero.set_verb_held(Hero.SLOT_RESTORE, false)

func test_valid_mend_keeps_late_charger_opening_until_completion() -> void:
	await load_region()
	var charger: RegionCreature = builder.entities["C1"].runtime
	hero.respawn_at(charger.global_position + Vector3.LEFT * 1.35 + Vector3.UP * 0.02)
	hero.facing = Vector2.RIGHT
	await force_once()
	await step(62)
	check(charger.stagger_left > 0 and charger.stagger_left < 0.6, "start Mend late in the actual stagger opening")
	hero.set_verb_held(Hero.SLOT_RESTORE, true)
	await step(80)
	hero.set_verb_held(Hero.SLOT_RESTORE, false)
	check(builder.entities["C1"].get("restored", false), "valid continuous channel finishes rather than losing its opening partway")

func test_weaver_can_strip_first_bearer_without_borrowed_sparks() -> void:
	await load_region()
	hero.apply_class(WEAVER)
	var bearer := await approach_bearer()
	for i in 6: await force_once()
	check(bearer.growths == 0, "two weak hits per growth keep Weaver on the critical path")
	hero.set_verb_held(Hero.SLOT_RESTORE, true)
	await step(60)
	hero.set_verb_held(Hero.SLOT_RESTORE, false)
	check(builder.entities["B1"].get("restored", false), "Weaver beam restores the bare Bearer")

func test_premature_mend_regrows_armor_instead_of_bridging() -> void:
	await load_region()
	var bearer := await approach_bearer()
	await force_once()
	check(bearer.growths == 2, "one growth shed")
	hero.set_verb_held(Hero.SLOT_RESTORE, true)
	await step(10)
	hero.set_verb_held(Hero.SLOT_RESTORE, false)
	check(bearer.growths == 3, "early Mend restores the armor")
	check(not builder.entities["B1"].get("restored", false), "does not skip the transformation condition")

func test_weaver_catch_and_feed_opens_gate_without_restoring_source() -> void:
	await load_region()
	hero.apply_class(WEAVER)
	hero.respawn_at(Vector3(39.5, 0.02, 6.5))
	hero.facing = Vector2.LEFT
	hero.set_verb_held(Hero.SLOT_FORCE, true)
	var spark := ChargeSpark.new()
	spark.builder = builder
	spark.hero = hero
	spark.source_id = "C1"
	spark.direction = Vector3.RIGHT
	builder.add_child(spark)
	spark.global_position = hero.global_position + Vector3.LEFT + Vector3.UP * 0.65
	await step(3)
	check(spark.captured, "Force hold catches the incoming spark")
	hero.facing = Vector2.RIGHT
	await step(2)
	hero.set_verb_held(Hero.SLOT_FORCE, false)
	await step(30)
	check(builder.entities["G1"].get("powered", false), "released spark latches the gate")
	check(not builder.entities["C1"].get("restored", false), "source can remain hostile")
	check(builder._pool_hazards.has("F2"), "borrowed fire does not cleanse the source pool")

func test_snapshot_restores_bridge_and_rolls_back_later_gate_and_chunks() -> void:
	await load_region()
	builder.restore("B1")
	await step(3)
	var snapshot := builder.capture_snapshot()
	builder.restore("C1")
	builder.power_conduit("K1")
	builder.spawn_block(Vector2i(33, 5))
	await step(2)
	builder.rollback(snapshot)
	await step(3)
	check(builder.entities["B1"].get("restored", false), "saved first bridge survives")
	check(builder._bridged(Vector2i(25, 3)), "saved bridge collision restored")
	check(not builder.entities["C1"].get("restored", false), "later Charger re-corrupts")
	check(not builder.entities["G1"].get("powered", false), "later gate closes")
	var blocks := tree.get_nodes_in_group("push_block")
	check(blocks.size() == snapshot.blocks.size(), "no duplicate or stray growth blocks after rollback")

func test_dash_cannot_skip_the_unbridged_ford() -> void:
	await load_region()
	hero.respawn_at(Vector3(23.2, 0.02, 7.5))
	hero.move_input = Vector2.RIGHT
	hero.gauge.add(&"charge", 80)
	hero.request_dash()
	await step(18)
	hero.move_input = Vector2.ZERO
	check(hero.global_position.x < 24, "dash returns to near bank rather than bypassing restoration")
	check(hero.hearts < hero.max_hearts, "the unbridged cut costs a heart")

func test_warden_mends_both_chargers_and_their_fire_opens_the_route() -> void:
	await load_region()
	for id in ["C1", "C3"]:
		var charger: RegionCreature = builder.entities[id].runtime
		hero.respawn_at(charger.global_position + Vector3.LEFT * 1.15 + Vector3.UP * 0.02)
		hero.facing = Vector2.RIGHT
		await force_once()
		check(charger.stagger_left > 0, id + " staggered through Force")
		hero.set_verb_held(Hero.SLOT_RESTORE, true)
		await step(70)
		hero.set_verb_held(Hero.SLOT_RESTORE, false)
		check(builder.entities[id].get("restored", false), id + " mended through player input")
		await step(100)
		var gate := "G1" if id == "C1" else "G2"
		check(builder.entities[gate].get("powered", false), gate + " powered by actual turret fire")

func test_actual_anchor_failure_preserves_first_bridge_and_resets_later_work() -> void:
	await load_region()
	builder.restore("B1")
	hero.respawn_at(Vector3(34.5, 0.02, 2.5))
	await step(5)
	check(region.checkpoint_position.x > 32, "approaching river marker secures the first bridge")
	builder.power_conduit("K1")
	for i in hero.max_hearts:
		hero.invulnerable_left = 0
		hero.lose_heart(&"test_failure")
	await step(65)
	check(hero.hearts == hero.max_hearts, "failure refills hearts")
	check(hero.global_position.distance_to(Vector3(34.5, 0, 2.5)) < 0.4, "failure returns to the actual anchor")
	check(builder.entities["B1"].get("restored", false), "committed bridge survives actual failure")
	check(not builder.entities["G1"].get("powered", false), "uncommitted gate reverts on actual failure")

func test_bearer_can_restore_at_the_south_socket() -> void:
	await load_region()
	var bearer: RegionCreature = builder.entities["B1"].runtime
	bearer.global_position = Vector3(23.5, 0, 7.5)
	hero.respawn_at(Vector3(22.15, 0.02, 7.5))
	hero.facing = Vector2.RIGHT
	for i in 3: await force_once()
	hero.set_verb_held(Hero.SLOT_RESTORE, true)
	await step(80)
	hero.set_verb_held(Hero.SLOT_RESTORE, false)
	check(builder._bridged(Vector2i(25, 7)), "south bridge can be chosen by mending at its notch")
	check(not builder._bridged(Vector2i(25, 3)), "north bridge does not appear remotely")

func test_map_pauses_danger_and_clears_held_inputs() -> void:
	await load_region()
	hero.set_verb_held(Hero.SLOT_RESTORE, true)
	hero.move_input = Vector2.RIGHT
	Input.action_press("move_right")
	region.journey_map.toggle(region.checkpoint_position)
	check(tree.paused, "viewing the map pauses the encounter")
	check(not hero.restore_verb.active, "map entry cancels a held Mend")
	check(not Input.is_action_pressed("move_right"), "map does not leave a movement input stuck")
	region.journey_map.toggle(region.checkpoint_position)
	check(not tree.paused, "closing the map resumes play")
