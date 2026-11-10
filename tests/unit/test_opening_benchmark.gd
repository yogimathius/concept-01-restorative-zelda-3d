extends TestCase
const FORD := preload("res://scenes/levels/region1.tscn")
var region: Node3D
func after_each() -> void:
	tree.paused = false
	tree.root.get_node("JourneySession").pending = {}
	await super.after_each()
func load_ford() -> void:
	region = FORD.instantiate()
	region.persist_progress = false
	region.get_node("Hero").use_device_input = false
	world.add_child(region)
	await step(5)
func test_first_restoration_presentation_never_delays_rewards_or_movement() -> void:
	await load_ford()
	var grove: RegionCreature = region.builder.entities.B1.runtime
	region.hero.respawn_at(grove.global_position+Vector3.LEFT*2)
	region.hero.set_verb_held(Hero.SLOT_RESTORE,true)
	await step(30)
	check(grove.progress>0 and region.opening.presentations.B1.stage!="wounded","partial Mend physically establishes a connection")
	region.hero.set_verb_held(Hero.SLOT_RESTORE,false)
	var partial: float = grove.progress
	await step(10)
	check_near(grove.progress,partial,0.001,"presentation never drains retained partial work")
	region.hero.set_verb_held(Hero.SLOT_RESTORE,true)
	await step(100)
	region.hero.set_verb_held(Hero.SLOT_RESTORE,false)
	check(grove.restored and region.progression.xp==40 and region.inventory.owned.has("grove_wand"),"real restoration immediately grants original XP and visible gear")
	check(region.opening.presentations.B1.completing and not tree.paused,"signature recovery plays while gameplay remains free")
	check(region.builder.can_walk(Vector2i(25,5)),"bridge is safe immediately, during physical recovery")
	region.opening.presentations.B1._process(5.0)
	check(region.opening.presentations.B1.settled,"staged recovery settles without blocking progression")
func test_first_growth_is_a_player_choice_and_survives_reload() -> void:
	await load_ford()
	region.builder.restore("B1")
	await step(5)
	check(region.waykeeper.progress.skill_points()==2,"first restoration provides the normal two chosen points")
	check(region.waykeeper.progress.purchased.is_empty(),"the first reward never auto-purchases nodes")
	region.opening._acknowledge()
	check(region.story_flags.has("opening_reward_seen"),"optional prompt acknowledgement is remembered")
	check(region.waykeeper.buy_node("steady_vessel"),"first reward supports an actual chosen tree capability")
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.free()
	await load_ford()
	region._apply_journey_data(data)
	region._configure_restoration()
	await step(5)
	check(region.story_flags.has("opening_reward_seen") and region.waykeeper.progress.purchased.has("steady_vessel"),"reload retains prompt acknowledgement and paid node")
	check(region.progression.xp==40,"revisiting never duplicates restoration XP")
func test_spring_return_changes_inhabited_space_and_story_once() -> void:
	await load_ford()
	region.builder.restore("B1")
	check(region.waykeeper.learn("force"),"first restoration enables Iona's learned technique")
	var spring: RegionCreature = region.builder.entities.C1.runtime
	region.hero.respawn_at(spring.global_position+Vector3.LEFT*2)
	check(region.waykeeper.use_skill("force"),"Force clears the physical spring condition")
	await step(30)
	region.hero.set_verb_held(Hero.SLOT_RESTORE,true)
	await step(110)
	region.hero.set_verb_held(Hero.SLOT_RESTORE,false)
	check(spring.restored and region.opening.landscape.gathering.visible,"spring recovery enables the actual public gathering")
	for water in region.opening.landscape.water_channels: check(water.visible,"restored spring fills local water")
	var mara: StoryNPC
	for npc in tree.get_nodes_in_group("story_npc"):
		if npc.get_parent()==region and npc.npc_id=="mara": mara=npc
	await step(20)
	check(mara.workplace==Vector3(10.8,0,9.1),"Mara returns to the restored basin")
	var content := StoryChapters.conversation(region,"mara")
	check(content.options[0].action=="mara_return" and " ".join(content.pages).contains("downstream"),"return conversation connects restoration to people")
	var xp: int = region.progression.xp
	region.story._act("mara_return")
	region.story.dialogue.dismiss()
	region.story._act("mara_return")
	region.story.dialogue.dismiss()
	check(region.progression.xp==xp and region.story_flags.has("opening_return_seen"),"social return is remembered without reward farming")
func test_older_complete_save_gets_settled_world_without_replaying_reward() -> void:
	await load_ford()
	region._apply_journey_data({"version":5,"skills":{"unlocked":["force","anchor"]},"worlds":{"R1":{"restored":["B1","C1"]}},"story":{"mara_met":true}})
	region._configure_restoration()
	region.opening.landscape.sync(false)
	await step(5)
	check(region.opening.landscape.first_grove.visible and region.opening.landscape.gathering.visible,"completed legacy places derive their new living presentation")
	check(not region.opening._card.visible,"experienced visitor does not replay the introductory reward card")
	check(not region.opening.presentations.B1.completing,"replay never launches a completion spectacle")
	check(region.progression.xp==80 and region.inventory.owned.has("spring_cloak"),"existing earned XP and equipment stay intact")
func test_inhabitants_have_human_rigs_and_bounded_geometry() -> void:
	for id in ["mara","iona","oren","neri","daro"]:
		var model := StoryNPC.make_model(id)
		var rigs := model.find_children("*","Skeleton3D",true,false)
		check(rigs.size()==1,"civilian retains articulated human rig: "+id)
		var animations: AnimationPlayer = model.find_child("AnimationPlayer",true,false)
		check(animations.has_animation("idle") and animations.has_animation("walk") and animations.has_animation("greeting"),"civilian has actual routine and greeting clips: "+id)
		var triangles := 0
		for mesh in ToonUtil.get_mesh_instances(model):
			for surface in mesh.mesh.get_surface_count(): triangles += mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_INDEX].size()/3
		check(triangles>8000 and triangles<=24000,"human model stays within body budget: "+id)
		model.free()
