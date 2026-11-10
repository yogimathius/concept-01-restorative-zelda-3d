extends TestCase
const MARSH := preload("res://scenes/levels/region2.tscn")
var region: Node3D
func after_each() -> void:
	tree.paused = false
	tree.root.get_node("JourneySession").pending = {}
	await super.after_each()
func load_region() -> void:
	region = MARSH.instantiate()
	region.persist_progress = false
	region.get_node("Hero").use_device_input = false
	world.add_child(region)
	await step(4)
func approach(id: String) -> RegionCreature:
	var target: RegionCreature = region.builder.entities[id].runtime
	region.hero.respawn_at(target.global_position+Vector3.LEFT*2+Vector3.UP*0.02)
	await step(2)
	return target
func mend(id: String) -> void:
	await approach(id)
	region.hero.set_verb_held(Hero.SLOT_RESTORE,true)
	await step(110)
	region.hero.set_verb_held(Hero.SLOT_RESTORE,false)
	await step(2)
func action(id: String, skill: String) -> bool:
	await approach(id)
	var used: bool = region.waykeeper.use_skill(skill)
	await step(30)
	return used
func choose_lesson(npc: String, skill: String) -> void:
	for character in tree.get_nodes_in_group("story_npc"):
		if character.get_parent()==region and character.npc_id==npc:
			region.hero.respawn_at(character.global_position+Vector3.BACK*1.6)
	await step(3)
	region.story.talk(npc)
	var screen: DialogueScreen = region.story.dialogue
	while screen._index<screen._pages.size()-1: screen._choose(0)
	var choice := -1
	for i in screen._options.size():
		if screen._options[i].action=="learn_"+skill: choice=i
	check(choice>=0,"local conversation offers missing "+skill)
	if choice>=0: region.story._act(screen._options[choice].action)
	check(region.waykeeper.progress.unlocked.has(skill),"NPC teaches "+skill+" through chapter progress")
	region.story.dialogue.dismiss()
func test_main_sites_teach_readable_force_anchor_and_mend_with_local_catchup() -> void:
	await load_region()
	check(not region.waykeeper.learn("force") and not region.waykeeper.learn("anchor"),"marsh cannot grant techniques before meaningful world milestones")
	await mend("M2")
	check_near(region.builder.entities.M2.runtime.progress,0.5,0.001,"nursery retains approachable partial healing")
	check(not region.builder.entities.M2.get("restored",false),"Mend cannot repair a blocked feed alone")
	check(region.builder.entities.M2.runtime.ecology.status().contains("Neri"),"world condition names the local teacher")
	await mend("M1")
	check(region.builder.entities.M1.get("restored",false),"garden stays a straightforward Mend moment")
	await choose_lesson("neri","force")
	check(await action("M2","force"),"learned Force opens the nursery water")
	await mend("M2")
	await mend("M3")
	check_near(region.builder.entities.M3.runtime.progress,0.6,0.001,"bell retains partial recovery without a timing puzzle")
	check(region.builder.entities.M3.runtime.ecology.status().contains("Oren"),"bell guidance offers local Anchor learning")
	await choose_lesson("oren","anchor")
	check(await action("M3","anchor"),"Anchor grounds the bell")
	await mend("M3")
	check(region.progression.xp==120 and region.builder.entities.M3.get("restored",false),"all three main restorations pay the original unique rewards")
	region.story._act("marsh_message")
	check(region.story_flags.has("marsh_message"),"existing Lio story still completes")
	region.story.dialogue.dismiss()
func test_new_conditions_preserve_older_partial_and_completed_worlds() -> void:
	await load_region()
	region._apply_journey_data({"version":5,"skills":{"unlocked":["force","anchor"]},"worlds":{"R2":{"restored":["M1","M3"],"partial":{"M2":0.85}}},"story":{"marsh_message":true}})
	region._configure_restoration()
	check(region.builder.entities.M3.get("restored",false) and region.builder.entities.M3.runtime.ecology.ready_to_restore(),"previously completed bell stays complete without new gates")
	check_near(region.builder.entities.M2.runtime.progress,0.85,0.001,"older partial above the new cap is never reduced")
	check(await action("M2","force"),"one readable clearing allows saved partial work to continue")
	await mend("M2")
	check(region.builder.entities.M2.get("restored",false),"preserved partial finishes after the actual condition is addressed")
	check(region.story_flags.has("marsh_message"),"earned narrative reveal remains")
	check(region.builder.entities.M1.runtime.ecology.optional_available(),"legacy garden offers an optional deeper return without being unhealed")
func test_irrigation_revisit_changes_world_npc_flow_and_persists_without_reward_farming() -> void:
	await load_region()
	await mend("M1")
	region.waykeeper.progress.unlock("anchor")
	check(await action("M1","anchor"),"Anchor can improve an already restored garden")
	var site: RestorationSite = region.builder.entities.M1.runtime.ecology
	check(site.states.cultivated and site.get_node("LivingIrrigation").visible,"persistent clear irrigation and harvest become visible")
	check(region.progression.xp==40 and region.waykeeper.progress.points("anchor")==2,"optional work grants technique knowledge without duplicating site XP")
	region.hero.respawn_at(Vector3(23.5,0.02,5.5))
	await step(100)
	var neri: StoryNPC
	for npc in tree.get_nodes_in_group("story_npc"):
		if npc.npc_id=="neri" and npc.get_parent()==region: neri=npc
	check(neri.global_position.distance_to(Vector3(5.5,0,3.5))>1,"restoration changes Neri's actual routine")
	check(" ".join(StoryChapters.conversation(region,"neri").pages).contains("harvest"),"Neri recognizes the changed living system")
	await approach("M1")
	region.hero.resources.flow = 20
	await step(20)
	check(region.hero._near_healthy_water,"irrigated garden becomes a Flow recovery place")
	var mastery: int = region.waykeeper.progress.points("anchor")
	check(not await action("M1","anchor") and region.waykeeper.progress.points("anchor")==mastery,"resolved irrigation cannot be farmed")
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.free()
	await load_region()
	region._apply_journey_data(data)
	region._configure_restoration()
	await step(5)
	check(region.builder.entities.M1.runtime.ecology.states.cultivated and region.builder.entities.M1.runtime.ecology.get_node("LivingIrrigation").visible,"irrigation survives save reload")
	check(not await action("M1","anchor") and region.waykeeper.progress.points("anchor")==mastery,"reload cannot restore rewards or reset optional work")
func test_partial_story_site_remembers_exact_conditions_and_requires_no_repeat_cast() -> void:
	await load_region()
	region.waykeeper.progress.unlock("force")
	region.waykeeper.progress.unlock("anchor")
	await mend("M2")
	await action("M2","force")
	await mend("M3")
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.free()
	await load_region()
	region._apply_journey_data(data)
	region._configure_restoration()
	check(region.builder.entities.M2.runtime.ecology.states.cleared,"cleared nursery stays open across reload")
	check_near(region.builder.entities.M3.runtime.progress,0.6,0.001,"bell partial healing stays exact")
	check(not region.builder.entities.M3.runtime.ecology.states.stabilized,"unperformed grounding is not fabricated")
	await mend("M2")
	await action("M3","anchor")
	await mend("M3")
	check(region.builder.entities.M2.get("restored",false) and region.builder.entities.M3.get("restored",false),"return resumes meaningful work without reclearing or losing progress")
