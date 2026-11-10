extends TestCase
const REGION := preload("res://scenes/levels/region1.tscn")
const SAVE := "user://test-restoration-levels.json"

func after_each() -> void:
	await super.after_each()
	for path in [SAVE, SAVE + ".tmp"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func test_healing_levels_reward_progress_without_repeat_farming() -> void:
	var progress := RestorationProgression.new()
	check(progress.get_level() == 1, "begin at Level 1")
	var reward := progress.award("R1/B1")
	check(reward.earned == 40 and progress.get_level() == 2, "first restoration earns a visible Level 2")
	check(progress.award("R1/B1").earned == 0 and progress.xp == 40, "the same place cannot be farmed")
	for id in ["C1", "C3", "B2", "C2", "B3"]: progress.award("R1/" + id)
	check(progress.get_level() == 4 and progress.xp == 240, "six real restorations reach Level 4")
	var resumed := RestorationProgression.new()
	resumed.apply_data(progress.to_data())
	check(resumed.get_level() == 4 and resumed.award("R1/C1").earned == 0, "saved levels preserve one reward per place")

func make_region() -> Node3D:
	var region: Node3D = REGION.instantiate()
	region.save_path = SAVE
	region.get_node("Hero").use_device_input = false
	world.add_child(region)
	await step(4)
	return region

func test_actual_mend_awards_levels_and_reloads_the_healed_world() -> void:
	var region := await make_region()
	var hero: Hero = region.get_node("Hero")
	var builder: RegionBuilder = region.get_node("Builder")
	var grove: RegionCreature = builder.entities["B1"].runtime
	hero.respawn_at(grove.global_position + Vector3.LEFT * 2 + Vector3.UP * 0.02)
	hero.set_verb_held(Hero.SLOT_RESTORE, true)
	await step(110)
	hero.set_verb_held(Hero.SLOT_RESTORE, false)
	check(region.progression.get_level() == 2, "real Mend grants the level, not a debug grant")
	check(hero.restore_verb.reach > 4 and hero.restore_verb.rate > 0.65, "Mend mastery improves Mend independently of character level")
	check(region._level_label.text == "LEVEL 2", "HUD reflects the earned level")
	check(FileAccess.file_exists(SAVE), "healing autosaves")
	region.persist_progress = false
	region.free()
	var resumed := await make_region()
	check(resumed.progression.xp == 40 and resumed.progression.get_level() == 2, "XP and level reload")
	check(resumed.builder.entities["B1"].get("restored", false), "the grove remains healthy after restart")
	check(resumed.builder._bridged(Vector2i(25, 5)), "its bridge remains crossable after restart")
	check(resumed.progression.award("R1/B1").earned == 0, "reloading does not grant a second reward")
	check(resumed.hero.restore_verb.reach > 4, "Mend's upgrade is reapplied after loading")

func test_partial_healing_reloads_without_earning_premature_xp() -> void:
	var region := await make_region()
	var hero: Hero = region.get_node("Hero")
	var grove: RegionCreature = region.builder.entities["B1"].runtime
	hero.respawn_at(grove.global_position + Vector3.LEFT * 2 + Vector3.UP * 0.02)
	hero.set_verb_held(Hero.SLOT_RESTORE, true)
	await step(30)
	hero.set_verb_held(Hero.SLOT_RESTORE, false)
	var healing := grove.progress
	region._save_journey()
	region.persist_progress = false
	region.free()
	var resumed := await make_region()
	check_near(resumed.builder.entities["B1"].runtime.progress, healing, 0.001, "unfinished healing survives restarting")
	check(resumed.progression.xp == 0 and resumed.progression.get_level() == 1, "XP requires completed restoration")
	check(not resumed.builder.entities["B1"].get("restored", false), "partial healing is not incorrectly completed")
