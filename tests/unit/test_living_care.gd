extends TestCase
const FORD := preload("res://scenes/levels/region1.tscn")
const MARSH := preload("res://scenes/levels/region2.tscn")

func open_region(scene: PackedScene) -> Node3D:
	var region: Node3D = scene.instantiate()
	region.persist_progress = false
	region.get_node("Hero").use_device_input = false
	world.add_child(region)
	await step(5)
	return region

func test_care_types_stage_and_saved_ledger_follow_the_original_sites() -> void:
	var expected := {"B1":["reeds","reed_fiber"],"C1":["glass","riverglass"],"B2":["habitat","reed_fiber"],"C2":["silt","silt_clay"],"B3":["reeds","reed_fiber"],"C3":["glass","riverglass"],"M1":["reeds","reed_fiber"],"M2":["reeds","reed_fiber"],"M3":["glass","riverglass"],"M4":["habitat","reed_fiber"],"M5":["glass","riverglass"],"M6":["silt","silt_clay"]}
	for id in expected:
		var profile: Dictionary = CareProfiles.for_site(id)
		check(profile.kind==expected[id][0] and profile.material==expected[id][1],id+" keeps its existing material with a distinct condition")
	var region: Node3D = await open_region(FORD)
	region.builder.restore("B1")
	await step(2)
	var patch: RenewalPatch = region.renewal_world.get_node("Care_B1")
	check(patch._last_stage==0 and patch._strain.visible and not patch._response.visible,"fresh care is visibly strained")
	region.economy.patch("B1").progress=0.42
	await step(2)
	check(patch._last_stage==1 and patch._response.visible and not patch._renewed.visible,"saved partial care reveals responding water")
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.free()
	region = await open_region(FORD)
	region._apply_journey_data(data)
	await step(2)
	patch = region.renewal_world.get_node("Care_B1")
	check(patch._last_stage==1 and patch.progress>0.4 and region.builder.entities.B1.restored,"partial care and original restoration survive reload")
	region.economy.patch("B1").progress=0.76
	await step(2)
	check(patch._last_stage==2 and patch._renewed.visible,"nearly tended growth is a third visible stage")
	var before: int = region.economy.materials.reed_fiber
	patch.receive_influence(Influence.restore(region.hero,0.3))
	check(region.economy.materials.reed_fiber==before+2 and region.economy.patch("B1").cycles==1,"care pays its authored material once")
	check(region.builder.entities.B1.restored and patch.restored,"care cooldown never damages the main site")

func test_mend_prefers_viable_story_restoration_then_available_care() -> void:
	var region: Node3D = await open_region(FORD)
	region.builder.restore("B1")
	await step(2)
	var care: RenewalPatch = region.renewal_world.get_node("Care_B1")
	var story: RegionCreature = region.builder.entities.C1.runtime
	story.ecology.states.cleared = true
	story.position = care.position+Vector3(0.9,0,0)
	region.hero.respawn_at(care.global_position+Vector3(-0.9,0.02,0))
	await step(4)
	region.hero.set_verb_held(Hero.SLOT_RESTORE,true)
	await step(12)
	check(region.hero.restore_verb.target==story and story.progress>0 and region.economy.patch("B1").progress==0,"nearer care cannot steal Mend from viable story restoration")
	story.progress=story.ecology.mend_limit()
	story.ecology.states.cleared=false
	await step(12)
	check(region.hero.restore_verb.target==care and region.economy.patch("B1").progress>0,"care remains usable while the story site needs Force")
	region.hero.set_verb_held(Hero.SLOT_RESTORE,false)

func test_restored_habitat_has_noncombat_life_and_journal_care_is_touch_ready() -> void:
	var region: Node3D = await open_region(MARSH)
	check(region.journal.care_entries(region).is_empty(),"unrestored places do not advertise renewable care")
	var skipper: ReedSkipper = region.renewal_world.get_node("Skipper_M4")
	check(not skipper.visible and not skipper.is_in_group("influenceable"),"habitat creature waits for restoration and cannot steal Mend")
	region.builder.restore("M4")
	await step(3)
	check(skipper.visible,"restored refuge gains a visible living inhabitant")
	var entry: Dictionary = region.journal.observe(region,"care/R2/M4")
	check(entry.actionable and entry.skill=="mend" and entry.benefit.contains("reed fiber"),"care journal names its action and actual yield")
	check(region.journal.pin(region,entry.id),"care can be pinned for a later visit")
	region.economy.patch("M4").progress=0.5
	entry=region.journal.observe(region,"care/R2/M4")
	check(entry.status.contains("50%"),"care journal reads retained partial progress")
	region.economy.patch("M4").cooldown=30.0
	entry=region.journal.observe(region,"care/R2/M4")
	check(not entry.actionable and entry.status.contains("Recovering"),"cooldown is explained without implying the refuge broke again")
	region.economy.patch("M4").cooldown=0.0
	region.journey_map.toggle(region.checkpoint_position)
	region.journey_map.show_journal()
	var screen: JournalScreen = region.journey_map.journal_screen
	screen._show_mode("care")
	check(screen.selected=="care/R2/M4" and screen._technique.text=="READY MEND","touch journal exposes a ready care action")
	var flow: float = region.hero.resources.flow
	screen._ready_technique()
	check(region.waykeeper.progress.active=="mend" and not tree.paused,"care ready selects Mend and closes the journal")
	check_near(region.hero.resources.flow,flow,0.001,"journal selection does not cast or spend Flow")
