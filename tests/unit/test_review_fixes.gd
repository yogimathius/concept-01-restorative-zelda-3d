extends TestCase
## Regression tests for the final-review findings on step 1.

const HERO_SCENE: PackedScene = preload("res://scenes/hero/hero.tscn")
const DUMMY_SCENE: PackedScene = preload("res://scenes/test_props/training_dummy.tscn")
const WARDEN: HeroClass = preload("res://data/classes/warden.tres")

class RecordingVerb extends Verb:
	var events: Array[String] = []
	func on_pressed() -> void:
		events.append("pressed")
	func on_held(_delta: float) -> void:
		if events.is_empty() or events[-1] != "held":
			events.append("held")
	func on_released() -> void:
		events.append("released")

var hero: Hero

func spawn(cls: HeroClass) -> void:
	add_floor()
	hero = HERO_SCENE.instantiate()
	hero.use_device_input = false
	hero.hero_class = cls
	hero.position = Vector3(0, 0.02, 0)
	world.add_child(hero)

func install_recorder() -> RecordingVerb:
	var rec := RecordingVerb.new()
	hero.verbs_root.add_child(rec)
	rec.setup(hero)
	hero.force_verb = rec
	return rec

# --- finding 1: attack animation must play through the impact ---

func test_attack_animation_plays_past_impact() -> void:
	spawn(WARDEN)
	await step(3)
	hero.set_verb_held(Hero.SLOT_FORCE, true)
	await step(10)   # wind-up (0.12 s) has landed; verb no longer active
	hero.set_verb_held(Hero.SLOT_FORCE, false)
	check(not hero.force_verb.active, "pulse has landed")
	check(hero.anim_player.current_animation == &"attack", "attack clip still playing after impact")

# --- finding 2: haptics need the Android VIBRATE permission ---

func test_android_preset_grants_vibrate() -> void:
	var cfg := ConfigFile.new()
	check(cfg.load("res://export_presets.cfg") == OK, "export presets load")
	var found := false
	for section in cfg.get_sections():
		if section.ends_with(".options") and cfg.has_section_key(section, "permissions/vibrate"):
			found = true
			check(cfg.get_value(section, "permissions/vibrate") == true, "%s grants VIBRATE" % section)
	check(found, "an Android preset exists")

# --- finding 3: verb lifecycle is always paired ---

func test_press_while_rooted_then_hold_past_root_sends_nothing() -> void:
	spawn(HeroClass.new())
	await step(2)
	var rec := install_recorder()
	hero.gauge.add(&"weight", 100.0)   # ROOT 1.2 s
	hero.set_verb_held(Hero.SLOT_FORCE, true)
	await step(80)   # root ends while still held
	hero.set_verb_held(Hero.SLOT_FORCE, false)
	check(rec.events.is_empty(), "no held/released without a delivered press (got %s)" % [rec.events])

func test_losing_control_while_held_releases_the_verb() -> void:
	spawn(HeroClass.new())
	await step(2)
	var rec := install_recorder()
	hero.set_verb_held(Hero.SLOT_FORCE, true)
	await step(3)
	hero.gauge.add(&"weight", 100.0)   # rooted mid-hold
	await step(2)
	check(Array(rec.events) == ["pressed", "held", "released"], "released the moment control is lost (got %s)" % [rec.events])
	await step(80)   # root ends, button still held
	hero.set_verb_held(Hero.SLOT_FORCE, false)
	check(rec.events.size() == 3, "no resumed channel or second release after the root (got %s)" % [rec.events])

func test_rebuilding_verbs_clears_held_state() -> void:
	spawn(HeroClass.new())
	await step(2)
	hero.set_verb_held(Hero.SLOT_FORCE, true)
	hero.apply_class(HeroClass.new())
	var rec := install_recorder()
	hero.set_verb_held(Hero.SLOT_FORCE, true)
	check(Array(rec.events) == ["pressed"], "fresh press after class swap is delivered (got %s)" % [rec.events])

# --- finding 4: Review Focus #1 in its named order ---

func test_held_when_rooted_then_released_does_not_stick() -> void:
	spawn(WARDEN)
	var dummy: TrainingDummy = DUMMY_SCENE.instantiate()
	dummy.position = Vector3(0, 0.02, 1.0)
	world.add_child(dummy)
	await step(3)
	var hits: Array = []
	dummy.knocked.connect(func(inf: Influence) -> void: hits.append(inf))
	hero.set_verb_held(Hero.SLOT_FORCE, true)   # held first...
	hero.gauge.add(&"weight", 100.0)            # ...then rooted
	await step(3)
	hero.set_verb_held(Hero.SLOT_FORCE, false)  # released during the root
	await step(80)
	check(hits.size() == 1, "a wind-up already started is a committed action and lands")
	check(not hero.force_verb.active, "verb not left active")
	dummy.position = Vector3(0, 0.02, 1.0)
	dummy.stop()
	hero.set_verb_held(Hero.SLOT_FORCE, true)
	await step(10)
	hero.set_verb_held(Hero.SLOT_FORCE, false)
	check(hits.size() == 2, "first press after the root pulses")
