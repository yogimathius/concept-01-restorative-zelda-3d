extends TestCase

const HERO_SCENE: PackedScene = preload("res://scenes/hero/hero.tscn")
const DUMMY_SCENE: PackedScene = preload("res://scenes/test_props/training_dummy.tscn")
const WARDEN: HeroClass = preload("res://data/classes/warden.tres")

var hero: Hero

func spawn(dummy_pos: Vector3) -> TrainingDummy:
	add_floor()
	hero = HERO_SCENE.instantiate()
	hero.use_device_input = false
	hero.hero_class = WARDEN
	# position before add_child: a body added at the origin and then moved can
	# overlap the hero for a physics step, and the hero climbs onto it
	hero.position = Vector3(0, 0.02, 0)
	world.add_child(hero)
	var dummy: TrainingDummy = DUMMY_SCENE.instantiate()
	dummy.position = dummy_pos
	world.add_child(dummy)
	return dummy

func pulse() -> void:
	hero.set_verb_held(Hero.SLOT_FORCE, true)
	await step(10)   # wind-up is 0.12 s = ~7 frames
	hero.set_verb_held(Hero.SLOT_FORCE, false)

func test_pulse_hits_dummy_in_front_and_slides_it() -> void:
	var dummy := spawn(Vector3(0, 0.02, 1.0))   # hero faces +z by default
	await step(3)
	var hits: Array = []
	dummy.knocked.connect(func(inf: Influence) -> void: hits.append(inf))
	await pulse()
	check(hits.size() == 1, "dummy in front was knocked back once")
	await step(30)
	check(dummy.global_position.z > 2.0, "dummy slid away along facing")

func test_pulse_misses_dummy_behind() -> void:
	var dummy := spawn(Vector3(0, 0.02, -1.0))
	await step(3)
	var hits: Array = []
	dummy.knocked.connect(func(inf: Influence) -> void: hits.append(inf))
	await pulse()
	check(hits.is_empty(), "dummy behind is outside the arc")

func test_pulse_misses_dummy_out_of_reach() -> void:
	var dummy := spawn(Vector3(0, 0.02, 2.5))
	await step(3)
	var hits: Array = []
	dummy.knocked.connect(func(inf: Influence) -> void: hits.append(inf))
	await pulse()
	check(hits.is_empty(), "dummy beyond reach is not hit")

func test_warden_weight_affinity_strengthens_pulse() -> void:
	var dummy := spawn(Vector3(0, 0.02, 1.0))
	await step(3)
	var hits: Array = []
	dummy.knocked.connect(func(inf: Influence) -> void: hits.append(inf))
	hero.gauge.add(&"weight", 50.0)
	await pulse()
	check(hits.size() == 1, "hit landed")
	if hits.size() == 1:
		check_near(hits[0].amount, 8.0 * lerpf(1.0, 2.2, 0.5), 0.01, "force scaled by Warden weight affinity")

func test_pulse_respects_cooldown() -> void:
	var dummy := spawn(Vector3(0, 0.02, 1.0))
	await step(3)
	var hits: Array = []
	dummy.knocked.connect(func(inf: Influence) -> void: hits.append(inf))
	await pulse()
	dummy.global_position = Vector3(0, 0.02, 1.0)
	dummy.stop()
	await pulse()   # released at ~10 frames, cooldown 0.35 s still running
	check(hits.size() == 1, "second pulse blocked by cooldown")
	await step(25)
	dummy.global_position = Vector3(0, 0.02, 1.0)
	dummy.stop()
	await pulse()
	check(hits.size() == 2, "pulse available after cooldown")

func test_rooted_hero_cannot_pulse() -> void:
	var dummy := spawn(Vector3(0, 0.02, 1.0))
	await step(3)
	var hits: Array = []
	dummy.knocked.connect(func(inf: Influence) -> void: hits.append(inf))
	hero.gauge.add(&"weight", 100.0)   # overload -> ROOT
	await pulse()
	check(hits.is_empty(), "no pulse while rooted")

func test_release_during_root_does_not_stick_verb() -> void:
	var dummy := spawn(Vector3(0, 0.02, 1.0))
	await step(3)
	var hits: Array = []
	dummy.knocked.connect(func(inf: Influence) -> void: hits.append(inf))
	hero.gauge.add(&"weight", 100.0)   # ROOT 1.2 s
	hero.set_verb_held(Hero.SLOT_FORCE, true)
	await step(5)
	hero.set_verb_held(Hero.SLOT_FORCE, false)
	await step(80)   # root over
	check(not hero.force_verb.active, "verb not left active")
	await pulse()
	check(hits.size() == 1, "first press after root pulses normally")

func test_restore_verb_is_available_and_releases() -> void:
	spawn(Vector3(0, 0.02, 5.0))
	await step(3)
	check(hero.restore_verb != null, "Warden can mend")
	hero.set_verb_held(Hero.SLOT_RESTORE, true)
	await step(3)
	hero.set_verb_held(Hero.SLOT_RESTORE, false)
	check(not hero.restore_verb.active, "mend stops on release")   # dev/test.sh fails on SCRIPT ERROR
