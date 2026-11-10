extends TestCase
const REGION := preload("res://scenes/levels/region1.tscn")
const MARSH := preload("res://scenes/levels/region2.tscn")
const SAVE := "user://test-waykeeper-skills.json"
var region: Node3D

func after_each() -> void:
	tree.paused = false
	tree.root.get_node("JourneySession").pending = {}
	await super.after_each()
	for path in [SAVE,SAVE+".tmp"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func load_region(persist := false, scene := REGION) -> void:
	region = scene.instantiate()
	region.persist_progress = persist
	region.save_path = SAVE
	region.get_node("Hero").use_device_input = false
	world.add_child(region)
	await step(4)

func approach(id: String) -> RegionCreature:
	var target: RegionCreature = region.builder.entities[id].runtime
	region.hero.respawn_at(target.global_position+Vector3.LEFT*2+Vector3.UP*0.02)
	await step(2)
	return target

func mend(id: String, frames := 110) -> void:
	await approach(id)
	region.hero.set_verb_held(Hero.SLOT_RESTORE,true)
	await step(frames)
	region.hero.set_verb_held(Hero.SLOT_RESTORE,false)
	await step(2)

func use(id: String, skill: String) -> void:
	await approach(id)
	region.waykeeper.select(skill)
	region.waykeeper.use_active()
	await step(30)

func touch(at: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 2
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

func iona() -> void:
	region.hero.respawn_at(Vector3(30,0.02,7.0))
	await step(4)
	var controls := region.get_node("TouchControls")
	var button: TouchScreenButton = controls.get_node("ContextButton")
	await tap(button.position+button.texture_normal.get_size()*button.scale*0.5)

func test_unlocks_require_world_learning_and_mastery_cannot_be_spammed() -> void:
	await load_region()
	check(region.waykeeper.progress.unlocked == PackedStringArray(["mend"]),"new waykeeper begins with Mend and Glide only")
	check(not region.waykeeper.learn("force") and not region.waykeeper.learn("anchor"),"character XP cannot bypass the teaching milestones")
	check(not region.waykeeper.use_skill("force"),"unknown technique refuses safely")
	check(region.waykeeper.feedback.contains("Iona"),"unavailable technique has useful guidance")
	check(not region.waykeeper.select("weave"),"future disciplines are not falsely playable")
	await mend("B1")
	check(region.waykeeper.progress.points("mend")==3,"real completed restoration earns Mend mastery")
	check(region.waykeeper.learn("force"),"restoring the grove makes Force learnable")
	for i in 20:
		region.waykeeper.use_skill("force")
		await step(1)
	check(region.waykeeper.progress.points("force")==0,"pulses into nothing do not earn mastery")
	check(region.progression.get_level()==2,"overall character progression remains")
	check(region.waykeeper.progress.rank("force")==1,"new technique still begins at its own mastery rank")

func test_real_touch_teaching_pulse_swipe_and_skills_loadout() -> void:
	await load_region()
	await mend("B1")
	await iona()
	check(region.story.dialogue.visible and tree.paused,"touch TALK opens the bridgekeeper's lesson")
	while region.story.dialogue._index<region.story.dialogue._pages.size()-1: await choose(0)
	await choose(0)
	check(region.waykeeper.progress.active=="force" and region.inventory.owned.has("ferryman_staff"),"touch lesson teaches Force and grants gear")
	region.story.dialogue.dismiss()
	var spring := await approach("C1")
	region.hero.facing = Vector2.LEFT
	var button: TouchScreenButton = region.get_node("TouchControls/RestoreButton")
	var center := button.position+button.texture_normal.get_size()*button.scale*0.5
	await tap(center)
	check(spring.ecology.states.cleared,"actual action touch clears stone even when facing away")
	check(region.waykeeper.progress.points("force")==2,"clearing earns mastery once")
	await touch(center,true)
	var drag := InputEventScreenDrag.new()
	drag.index = 2
	drag.position = center-Vector2(0,38)
	drag.relative = Vector2(0,-38)
	tree.root.push_input(drag,true)
	await step(2)
	await touch(center-Vector2(0,38),false)
	check(region.waykeeper.progress.active=="mend","swipe cycles the same medallion back to Mend")
	check(not region.hero.restore_verb.active,"switching cannot leave Mend held")
	await touch(center,true)
	await step(110)
	await touch(center,false)
	check(spring.restored,"touch hold on switched medallion completes the spring")
	var skills: Button = region.get_node("JourneyHUD/SkillsButton")
	await tap(skills.position+skills.size*0.5)
	check(region.waykeeper.screen.visible and tree.paused,"touch opens skill loadout")
	check(not region.get_node("TouchControls").visible,"skill screen prevents gameplay click-through")
	region.waykeeper.screen.selected = "force"
	region.waykeeper.screen.refresh()
	region.waykeeper.screen.view_node("groundwave")
	var node: Button = region.waykeeper.screen._buy
	await tap(region.waykeeper.screen.position+node.position+node.size*0.5)
	check(region.waykeeper.progress.upgrades.has("groundwave"),"touch learns an earned behavioural upgrade")
	region.waykeeper.screen.toggle()

func test_partial_site_can_be_discovered_before_anchor_and_finished_after_return() -> void:
	await load_region(true)
	await mend("B1")
	region.waykeeper.learn("force")
	await use("C1","force")
	await mend("C1")
	await mend("B2")
	var grove: RegionCreature = region.builder.entities.B2.runtime
	check_near(grove.progress,0.55,0.001,"Mend makes unstable grove viable but cannot finish it")
	check(not grove.restored and grove.ecology.states.seen,"discovered unfinished site is remembered")
	check(grove.ecology.status().contains("Learn Anchor"),"refusal explains the world's condition and a teacher")
	check(region.progression.xp==80,"partial ecological recovery earns no full-site XP")
	region._save_journey()
	region.persist_progress = false
	region.free()
	await load_region(true)
	grove = region.builder.entities.B2.runtime
	check_near(grove.progress,0.55,0.001,"numeric partial recovery reloads")
	check(grove.ecology.states.seen and not grove.ecology.states.stabilized,"ecological state reloads independently")
	await iona()
	while region.story.dialogue._index<region.story.dialogue._pages.size()-1: await choose(0)
	await choose(0)
	check(region.waykeeper.progress.unlocked.has("anchor"),"return to bridgekeeper teaches Anchor through dialogue")
	region.story.dialogue.dismiss()
	await use("B2","anchor")
	await step(90)
	check(grove.ecology.states.stabilized,"stability persists without a technical timing window")
	check(grove.ecology.get_node("GroundedRoots").visible,"grounding visibly changes the roots")
	await mend("B2")
	check(grove.restored,"return with new knowledge completes the same site")
	check(region.waykeeper.progress.points("anchor")==2,"meaningful grounding earns individual mastery")

func test_spillway_requires_force_anchor_and_mend_with_saved_intermediate_states() -> void:
	await load_region()
	await mend("B1")
	region.waykeeper.learn("force")
	await use("C1","force")
	await mend("C1")
	region.waykeeper.learn("anchor")
	await mend("C3")
	check_near(region.builder.entities.C3.runtime.progress,0.40,0.001,"damaged spillway supports partial healing")
	await use("C3","force")
	check(not region.builder.entities.C3.runtime.ecology.ready_to_restore(),"physical clearing alone does not steady foundation")
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.free()
	await load_region()
	region._apply_journey_data(data)
	region._configure_restoration()
	var site: RestorationSite = region.builder.entities.C3.runtime.ecology
	check(site.states.cleared and not site.states.stabilized,"save/load preserves exactly the solved conditions")
	await use("C3","anchor")
	await mend("C3")
	check(region.builder.entities.C3.get("restored",false) and region.builder.entities.G2.get("powered",false),"multi-ability recovery opens the actual travel route")
	check(region.waykeeper.progress.points("force")==4 and region.waykeeper.progress.points("anchor")==2,"each technique credits its own contribution")
	check(region.progression.xp==120,"three completed sites earn three overall rewards")

func test_equipment_creates_alternative_restoration_paths_and_visible_replacements() -> void:
	await load_region()
	await mend("B1")
	region.waykeeper.learn("force")
	await use("C1","force")
	await mend("C1")
	region.waykeeper.learn("anchor")
	region.inventory.equip("ferryman_staff")
	region._configure_restoration()
	await use("C3","force")
	var site: RestorationSite = region.builder.entities.C3.runtime.ecology
	check(site.states.cleared and site.states.stabilized,"staff's Force carries stability into the same spring")
	check(region.hero.visuals.get_child(0).get_node("Equipment/Tool").get_child(0).name=="ferryman_staff","behavioural tool is visibly worn")
	region.inventory.equip("stonekeeper_charm")
	region._configure_restoration()
	await use("B3","anchor")
	site = region.builder.entities.B3.runtime.ecology
	check(site.states.stabilized and site.states.cleared,"brooch's Anchor roots lift obstructing stone: another build approach")
	check(region.hero.visuals.get_child(0).get_node("Equipment/Charm").get_child(0).name=="stonekeeper_charm","behavioural charm visibly replaces the starter")
	region.inventory.equip("wayfarer_wand")
	region.inventory.equip("wayfarer_charm")
	region._configure_restoration()
	check(not region.waykeeper.gear_effect("force_stabilizes") and not region.waykeeper.gear_effect("anchor_clears"),"unequipping removes behaviours rather than stacking them")

func test_behavioural_mastery_nodes_affect_actual_targets_without_farming() -> void:
	await load_region()
	await mend("B1")
	region.waykeeper.learn("force")
	await use("C1","force")
	await mend("C1")
	region.waykeeper.learn("anchor")
	check(region.waykeeper.progress.buy_upgrade("groundwave"),"first meaningful clearing earns Groundwave")
	region.hero.respawn_at(Vector3(39.5,0.02,17.5))
	check(region.waykeeper.use_skill("force"),"one Groundwave reaches two blocked systems in the spillway court")
	await step(30)
	check(region.builder.entities.C3.runtime.ecology.states.cleared and region.builder.entities.B3.runtime.ecology.states.cleared,"area pulse physically clears both sites")
	var earned: int = region.waykeeper.progress.points("force")
	region.waykeeper.use_skill("force")
	await step(30)
	check(region.waykeeper.progress.points("force")==earned,"resolved stones cannot be farmed")
	await use("C3","anchor")
	check(region.waykeeper.progress.buy_upgrade("shared_ground"),"first grounding enables Shared Ground")
	# B3 and C3 are within one root network; B3 grounding can also affect C3
	# in a fresh saved partial state without requiring a separate aimed tap.
	region.builder.entities.C3.runtime.ecology.states.stabilized = false
	await use("B3","anchor")
	check(region.builder.entities.C3.runtime.ecology.states.stabilized,"Shared Ground reaches the nearby foundation")
	await use("B2","anchor")
	await mend("B2")
	check(region.waykeeper.progress.buy_upgrade("living_pulse"),"another restoration level grants a point to choose a Mend node")
	await mend("B3")
	check(region.builder.entities.C3.runtime.progress>0,"completion wave contributes real partial healing to a nearby viable system")

func test_legacy_completed_world_migrates_without_relocking_or_resetting() -> void:
	await load_region()
	region._apply_journey_data({"version":2,"active_region":"R1","worlds":{"R1":{"restored":["B1","C1","C3","B2","C2","B3"]},"R2":{"restored":["M1"],"partial":{"M2":0.3}}},"inventory":{"claimed":["R1/B1"],"equipped":{"tool":"grove_wand"}},"story":{"neri_met":true}})
	region._configure_restoration()
	for id in Region1Manifest.ENTITIES:
		check(region.builder.entities[id].get("restored",false),"completed legacy place stays restored: "+id)
	check(region.waykeeper.progress.unlocked.has("force") and region.waykeeper.progress.unlocked.has("anchor"),"legacy restoration competence credits learned traditions")
	check(region.inventory.equipped.tool=="grove_wand" and region.progression.xp==280,"earned outfit and all region XP survive")
	check(region._worlds.R2.partial.M2==0.3 and region.story_flags.neri_met,"other region partial progress and narrative flags survive")
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data("R2")))
	check(data.version==5,"new persistent schema identifies skills and ecological states")
	region.free()
	await load_region(false,MARSH)
	region._apply_journey_data(data)
	check(region.waykeeper.progress.unlocked.has("anchor") and region.builder.entities.M1.get("restored",false),"skills travel with player across regions")
	check_near(region.builder.entities.M2.runtime.progress,0.3,0.001,"marsh retains older partial healing")

func test_mastery_json_sanitizes_invalid_loadouts_and_preserves_upgrades() -> void:
	var progress := WaykeeperProgression.new()
	progress.set_level(2)
	progress.unlock("force")
	progress.award("force","R1/C1/cleared",2)
	progress.buy_upgrade("groundwave")
	progress.select("force")
	var restored := WaykeeperProgression.new()
	restored.apply_data(JSON.parse_string(JSON.stringify(progress.to_data())),2)
	check(restored.active=="force" and restored.upgrades.has("groundwave") and restored.points("force")==2,"mastery ledger, loadout and behavioural nodes round-trip through JSON")
	check(not restored.award("force","R1/C1/cleared",2),"saved meaningful uses remain duplicate protected")
	restored.apply_data({"unlocked":["unknown","unbuilt"],"active":"anchor","events":{"force/x":999,"junk/y":2},"upgrades":["groundwave",null]})
	check(restored.active=="mend" and restored.unlocked.size()==1 and restored.upgrades.is_empty(),"invalid and unavailable techniques cannot enter the saved loadout")

func test_swiping_a_technique_never_casts_it_and_character_xp_does_not_raise_mastery() -> void:
	await load_region()
	region.builder.restore("B1")
	region.waykeeper.learn("force")
	var target := await approach("C1")
	var button: TouchScreenButton = region.get_node("TouchControls/RestoreButton")
	var at := button.position+button.texture_normal.get_size()*button.scale*0.5
	await touch(at,true)
	var drag := InputEventScreenDrag.new()
	drag.index = 2
	drag.position = at-Vector2(0,38)
	drag.relative = Vector2(0,-38)
	tree.root.push_input(drag,true)
	await step(2)
	await touch(at-Vector2(0,38),false)
	check(region.waykeeper.progress.active=="mend" and not target.ecology.states.cleared,"swipe changes loadout without moving the stone")
	var rank: int = region.waykeeper.progress.rank("force")
	for id in ["R2/M1","R2/M2","R2/M3","R2/M4"]: region.progression.award(id)
	region._configure_restoration()
	check(region.waykeeper.progress.rank("force")==rank,"overall XP never automatically raises Force mastery")

func test_advanced_nodes_change_restoration_behaviour_and_save_as_real_choices() -> void:
	await load_region()
	region.builder.restore("B1")
	region.waykeeper.learn("force")
	region.builder.restore("C1")
	region.builder.restore("B1")
	region.progression.award("R2/M1")
	region._configure_restoration()
	region.waykeeper.learn("anchor")
	# Seed mastery as a unit fixture; the real meaningful-use ledger is verified above.
	for i in 3:
		region.waykeeper.progress.award("force","fixture/discovery%d" % i,2)
		region.waykeeper.progress.award("anchor","fixture/discovery%d" % i,2)
	region.waykeeper.progress.set_level(3)
	region.waykeeper.progress.buy_upgrade("groundwave")
	region.waykeeper.progress.buy_upgrade("shared_ground")
	check(region.waykeeper.progress.buy_upgrade("undertow"),"mastery can choose Undertow")
	check(region.waykeeper.progress.buy_upgrade("root_memory"),"mastery can choose Root Memory")
	await use("C3","force")
	check(region.builder.entities.C3.runtime.ecology.ready_to_restore(),"Undertow lets Force solve water and foundation together without gear")
	await use("B2","anchor")
	check_near(region.builder.entities.B2.runtime.progress,0.25,0.001,"Root Memory contributes actual healing when grounding viable roots")
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.free()
	await load_region()
	region._apply_journey_data(data)
	check(region.waykeeper.progress.upgrades.has("undertow") and region.waykeeper.progress.upgrades.has("root_memory"),"advanced capability choices persist")
