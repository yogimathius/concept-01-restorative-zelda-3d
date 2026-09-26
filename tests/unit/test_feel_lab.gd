extends TestCase

const LAB: PackedScene = preload("res://scenes/test/feel_lab.tscn")

var lab: Node3D
var hero: Hero

func load_lab() -> void:
	lab = LAB.instantiate()
	hero = lab.get_node("Hero")
	hero.use_device_input = false
	world.add_child(lab)
	await step(5)

func test_lab_loads_with_warden_and_full_hearts() -> void:
	await load_lab()
	check(hero.hero_class.display_name == "Warden", "lab uses the Warden")
	check(hero.hearts == 5, "full hearts")
	check(lab.get_node("Dummies").get_child_count() == 3, "three dummies")

func test_pulsing_a_lab_dummy_moves_it() -> void:
	await load_lab()
	var dummy: TrainingDummy = lab.get_node("Dummies/DummyCenter")
	var start_z := dummy.global_position.z
	hero.move_input = Vector2(0, -1)   # turn and walk toward the dummy (at -z)
	for i in 90:
		await step()
		if hero.global_position.distance_to(dummy.global_position) < 1.1:
			break
	hero.move_input = Vector2.ZERO
	hero.set_verb_held(Hero.SLOT_FORCE, true)
	await step(10)
	hero.set_verb_held(Hero.SLOT_FORCE, false)
	await step(30)
	check(dummy.global_position.z < start_z - 1.0, "dummy knocked back away from hero")

func test_weight_pad_builds_weight() -> void:
	await load_lab()
	var pad: Node3D = lab.get_node("WeightPad")
	hero.respawn_at(pad.global_position + Vector3(0, 0.02, 0))
	await step(40)
	check(hero.gauge.value(&"weight") > 15.0, "standing on the weight pad builds weight")

func test_failing_resets_hearts_and_position() -> void:
	await load_lab()
	var start := hero.global_position
	hero.respawn_at(start + Vector3(3, 0, 0))
	for i in 5:
		hero.invulnerable_left = 0.0
		hero.lose_heart(&"test")
	await wait_ms(900)
	check(hero.hearts == 5, "hearts refilled after failure")
	check(hero.global_position.distance_to(start) < 0.1, "hero back at lab start")

func test_state_ring_shows_dominant_state() -> void:
	await load_lab()
	var ring: StateRing = hero.get_node("StateRing")
	hero.gauge.add(&"charge", 60.0)
	await wait_ms(50)
	check(ring.visible, "ring visible with charge")
	check(ring.current_color().b > ring.current_color().r, "charge ring is cyan")

func test_device_force_action_pulses() -> void:
	await load_lab()
	hero.use_device_input = true
	var dummy: TrainingDummy = lab.get_node("Dummies/DummyCenter")
	hero.respawn_at(dummy.global_position + Vector3(0, 0, 1.0))
	hero.facing = Vector2.UP   # face the dummy (-z)
	var hits: Array = []
	dummy.knocked.connect(func(inf: Influence) -> void: hits.append(inf))
	await step(2)
	Input.action_press("force")
	await step(10)
	Input.action_release("force")
	await step(2)
	check(hits.size() == 1, "pressing the force action pulses via the device-input path")

func test_quick_tap_between_physics_frames_still_pulses() -> void:
	await load_lab()
	hero.use_device_input = true
	var dummy: TrainingDummy = lab.get_node("Dummies/DummyCenter")
	hero.respawn_at(dummy.global_position + Vector3(0, 0, 1.0))
	hero.facing = Vector2.UP
	var hits: Array = []
	dummy.knocked.connect(func(inf: Influence) -> void: hits.append(inf))
	await step(2)
	# a fast touch tap: down and up land before the hero's next physics poll
	# (TouchScreenButton delivers InputEventActions exactly like this)
	_tap("force")
	await step(12)
	check(hits.size() == 1, "a tap shorter than one physics frame still pulses")

func test_quick_dash_tap_still_dashes() -> void:
	await load_lab()
	hero.use_device_input = true
	var count := [0]
	hero.dashed.connect(func() -> void: count[0] += 1)
	await step(2)
	_tap("dash")
	await step(3)
	check(count[0] == 1, "a dash tap shorter than one physics frame still dashes")

func _tap(action: String) -> void:
	for pressed in [true, false]:
		var ev := InputEventAction.new()
		ev.action = action
		ev.pressed = pressed
		Input.parse_input_event(ev)

func test_lab_is_dressed_with_the_kit() -> void:
	await load_lab()
	var dresser: KitDresser = lab.get_node("LabDressing/Dresser")
	var batches := dresser.get_children().filter(func(c): return c is MultiMeshInstance3D)
	var total := 0
	for b in batches:
		total += b.multimesh.instance_count
	check(batches.size() >= 12, "many distinct kit pieces (got %d)" % batches.size())
	check(total >= 800, "30x30 dressed field (got %d instances)" % total)
	check(batches.size() <= 60, "draw calls stay batched (got %d)" % batches.size())

func test_dummies_are_kit_training_posts() -> void:
	await load_lab()
	var post := lab.get_node("Dummies/DummyCenter").find_child("*", true, false)
	var pieces := lab.get_node("Dummies/DummyCenter").find_children("*", "KitPiece", true, false)
	check(pieces.size() == 1 and pieces[0].shape == "training_post", "dummy wears the training post")
