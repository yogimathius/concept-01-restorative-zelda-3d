extends TestCase
var region: Node3D
func load_valley() -> void:
	region = load("res://scenes/levels/river_valley.tscn").instantiate()
	region.persist_progress = false
	region.get_node("Hero").use_device_input = false
	world.add_child(region)
	await step(4)

func test_authored_places_preserve_ids_and_move_later_restorations_out_of_courts() -> void:
	await load_valley()
	check(region.builder.entities.B1.runtime.position.is_equal_approx(Vector3(23.5,0,5.5)),"opening grove remains familiar")
	check(region.builder.entities.C1.runtime.position.is_equal_approx(Vector3(36.5,0,6.5)),"Force opening remains familiar")
	for id in ValleyPlaces.POSITIONS:
		check(region.builder.entities[id].runtime.position.is_equal_approx(ValleyPlaces.point(ValleyPlaces.POSITIONS[id])),"stable ID uses authored place "+id)
	check(region.builder.entities.C3.runtime.position.y==10,"weir is on a walkable plateau")
	check(region.builder.entities.C3.runtime.ecology.profile.title=="Upper ford weir","site explains the actual landmark")
	for npc in tree.get_nodes_in_group("story_npc"):
		if npc.get_parent()==region and npc.npc_id=="oren": check(npc.position.is_equal_approx(ValleyPlaces.point(ValleyPlaces.LANDING)),"Oren inhabits the downstream landing")
	for route in [ValleyPlaces.SOUTH_ROUTE,ValleyPlaces.SUNLEAF_ROUTE,RiverValley.UPPER_ROUTE]:
		for i in range(route.size()-1):
			for j in 20:
				var at: Vector2 = route[i].lerp(route[i+1],float(j)/20)
				check(region.builder.valley.walkable(at),"authored approach is walkable")

func test_orens_story_clue_marks_the_real_weir_without_granting_rewards() -> void:
	await load_valley()
	var target: RegionCreature = region.builder.entities.C3.runtime
	check(not target.ecology.states.seen,"distant weir is not automatically discovered")
	region.hero.respawn_at(ValleyPlaces.point(ValleyPlaces.LANDING)+Vector3.LEFT)
	await step(3)
	region.story.talk("oren")
	check(region.story.dialogue.visible,"landing supports Oren's touch interaction")
	var before: Dictionary = region.inventory.to_data()
	region.story._act("valley_weir")
	check(not tree.paused and target.ecology.states.seen,"story clue remembers a learned destination")
	check(region.journal.pinned=="R1/C3","player chooses the real return pin")
	var entry: Dictionary = region.journal.observe(region,"R1/C3")
	check(entry.title=="Upper ford weir" and entry.benefit.contains("landing"),"journal knows the actual restoration benefit")
	check(region.progression.xp==0 and region.inventory.to_data()==before,"clue grants no repeatable loot or XP")

func test_weir_requires_techniques_and_changes_water_and_npc_life() -> void:
	await load_valley()
	var target: RegionCreature = region.builder.entities.C3.runtime
	var banks: ValleyBanks = region.builder.valley.banks
	check(not banks.water.visible and not banks.landing_life.visible,"landing begins dry")
	Influence.send(target,Influence.restore(region.hero,1.0))
	check_near(target.progress,0.4,0.001,"Mend keeps partial recovery without bypassing conditions")
	check(not target.restored,"weir does not become Mend-only")
	region.waykeeper.progress.unlock("force")
	region.waykeeper.progress.unlock("anchor")
	region.hero.respawn_at(target.position+Vector3.LEFT*2+Vector3.UP*0.02)
	await step(3)
	check(region.waykeeper.use_skill("force"),"generous Force reaches the plateau intake")
	check(target.ecology.states.cleared and not target.restored,"Force opens the intake, preserving partial work")
	await step(30)
	check(region.waykeeper.use_skill("anchor"),"Anchor settles the weir")
	check(target.ecology.ready_to_restore(),"foundation and intake conditions are understood")
	Influence.send(target,Influence.restore(region.hero,1.0))
	check(target.restored and banks.water.visible,"Mend releases the visible channel")
	await step(180)
	check(banks.basin_water.visible and banks.landing_life.visible,"water arrives at the inhabited basin")
	check_near(banks.water.material_override.get_shader_parameter("fill"),1,0.001,"staged flow settles into persistent water")
	var oren: StoryNPC
	for npc in tree.get_nodes_in_group("story_npc"):
		if npc.get_parent()==region and npc.npc_id=="oren": oren = npc
	check(oren.workplace.is_equal_approx(ValleyPlaces.point(ValleyPlaces.BASIN+Vector2(-1,0))),"Oren has actual work beside returned water")
	check(oren.position.distance_to(ValleyPlaces.point(ValleyPlaces.LANDING))>0.5,"Oren moves along the landing instead of only thanking the player")
	check(StoryChapters.conversation(region,"oren").pages[0].contains("boat"),"dialogue recognizes his changed life")
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region._apply_journey_data(data)
	check(banks.water.visible and region.progression.xp==40,"reload retains water and unique XP")
	check(not region.builder.restore("C3"),"settled weir cannot farm rewards")

func test_v1_partial_and_completed_saves_keep_progress_in_new_geography() -> void:
	await load_valley()
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	data.worlds.R1.partial.C3 = 0.31
	data.worlds.R1.position = [42.5,0.02,15.5]
	data.worlds.R1.ecology.C3.seen = true
	data.journal.pinned = "R1/C3"
	region._apply_journey_data(data)
	check_near(region.builder.entities.C3.runtime.progress,0.31,0.001,"V1 partial restoration remains")
	check(region.journal.pinned=="R1/C3","remembered place moves with stable ID")
	check(region.builder.entities.C3.runtime.position.is_equal_approx(ValleyPlaces.point(ValleyPlaces.POSITIONS.C3)),"legacy target cell does not replace new geography")
	data.worlds.R1.restored = ["C3"]
	data.progression.healed_places = ["R1/C3"]
	region._apply_journey_data(data)
	check(region.builder.entities.C3.runtime.restored and region.builder.valley.banks.water.visible,"completed V1 weir stays restored")
	check_near(region.builder.valley.banks.water.material_override.get_shader_parameter("fill"),1,0.001,"completed save settles flow without replaying completion")
	check(region.progression.xp==40,"earned progression is not reset or duplicated")

func test_npc_route_tracks_terrain_height_instead_of_floating_between_waypoints() -> void:
	await load_valley()
	var npc := StoryNPC.new()
	npc.npc_id = "oren"
	npc.hero = region.hero
	npc.surface_height = region.builder.surface_height
	npc.position = ValleyPlaces.point(Vector2(4,-12))
	region.add_child(npc)
	npc.work_at(ValleyPlaces.point(RiverValley.OVERLOOK))
	for i in 30:
		npc._process(0.1)
		check_near(npc.position.y,RiverValley.height_at(Vector2(npc.position.x,npc.position.z)),0.001,"inhabitant stays on real terrain")
