extends TestCase
const MARSH := preload("res://scenes/levels/region2.tscn")
const FORD := preload("res://scenes/levels/region1.tscn")
var region: Node3D

func after_each() -> void:
	tree.paused = false
	tree.root.get_node("JourneySession").pending = {}
	await super.after_each()

func load_marsh() -> void:
	region = MARSH.instantiate()
	region.persist_progress = false
	region.get_node("Hero").use_device_input = false
	world.add_child(region)
	await step(5)

func touch(at: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 7
	event.position = at
	event.pressed = true
	tree.root.push_input(event,true)
	await step(2)
	event.pressed = false
	tree.root.push_input(event,true)
	await step(2)

func bloom_tap() -> void:
	var button: TouchScreenButton = region.get_node("TouchControls/RestoreButton")
	await touch(button.position+button.texture_normal.get_size()*button.scale*0.5)

func link(id: String, at: Vector3) -> void:
	var relay: WeaveRelay = region.weave_relays[id]
	region.hero.respawn_at(at)
	await step(20)
	check(relay.begin() and relay.end(relay._screen(1-relay._source)),"the restored water route links before Bloom")

func test_neri_teaches_touch_bloom_and_two_living_places_change() -> void:
	await load_marsh()
	check(not region.waykeeper.learn("bloom"),"Bloom cannot be learned before the garden has connected water")
	for id in ["M1","M2","M4","M5"]: region.builder.restore(id)
	check(region.waykeeper.learn("weave"),"Weave is available after the first two restorations")
	await link("garden_nursery",Vector3(8.5,0.02,9.0))
	var neri: StoryNPC
	for npc in tree.get_nodes_in_group("story_npc"):
		if npc.get_parent()==region and npc.npc_id=="neri": neri=npc
	region.hero.set_physics_process(false)
	region.hero.respawn_at(neri.global_position+Vector3(0,0,1))
	await step(1)
	region.story.talk("neri")
	for i in 8:
		if region.story.dialogue._buttons[1].text.contains("Bloom"): break
		var continue_button: Button = region.story.dialogue._buttons[0]
		await touch(region.story.dialogue.position+continue_button.position+continue_button.size*0.5)
	check(region.story.dialogue.visible and region.story.dialogue._buttons[1].text.contains("Bloom"),"Neri offers Bloom after the linked garden is visible")
	var option: Button = region.story.dialogue._buttons[1]
	await touch(region.story.dialogue.position+option.position+option.size*0.5)
	check(region.waykeeper.progress.unlocked.has("bloom") and region.waykeeper.progress.active=="bloom" and region.story_flags.has("neri_bloom_started"),"touch dialogue learns Bloom and starts the journal request")
	region.story.dialogue.dismiss()
	region.hero.set_physics_process(false)
	region.hero.respawn_at(Vector3(11.5,0.02,7.5))
	await step(40)
	var xp_before: int = region.progression.xp
	var flow_before: float = region.hero.resources.flow
	await bloom_tap()
	check(region.bloom_growth.completed("M1") and region.bloom_growth._growth.M1.visible,"touch Bloom grows a persistent garden bed")
	check_near(region.hero.resources.flow,flow_before-18.0,0.01,"useful Bloom spends its listed Flow cost")
	check(region.progression.xp==xp_before+20 and region.waykeeper.progress.points("bloom")==3,"first growth earns unique XP and mastery")
	var patch: RenewalPatch = region.renewal_world.get_node("Care_M1")
	region.economy.patch("M1").progress = 0.95
	patch._physics_process(0.01)
	var seeds_before: int = region.inventory.seeds
	patch.receive_influence(Influence.restore(region.hero,0.1))
	check(region.inventory.seeds==seeds_before+1 and region.economy.patch("M1").cooldown>0,"bloomed garden yields seed on later care under the existing cooldown")
	await step(40)
	flow_before = region.hero.resources.flow
	await bloom_tap()
	check(region.hero.resources.flow==flow_before and region.progression.xp==xp_before+23,"repeat Bloom cannot spend Flow or farm its first reward")
	region.hero.respawn_at(Vector3(10.5,0.02,17.5))
	await step(40)
	flow_before = region.hero.resources.flow
	await bloom_tap()
	check(not region.bloom_growth.completed("M4") and region.hero.resources.flow==flow_before,"refuge refuses Bloom while its water link is severed")
	await link("spring_refuge",Vector3(6.5,0.02,18.0))
	region.waykeeper.select("bloom")
	region.hero.respawn_at(Vector3(10.5,0.02,17.5))
	await step(40)
	await bloom_tap()
	check(region.bloom_growth.completed("M4") and region.bloom_growth.sheltered(),"second growth creates the willow shelter")
	var reserves := WaykeeperResources.new()
	reserves.stability = 50
	reserves.tick(1.0,false,0,0,false,true)
	check_near(reserves.stability,53.0,0.01,"the living shelter increases Stability recovery without another resource bar")
	region.hero.resources.stability = 50.0
	region.hero.resources.since_loss = WaykeeperResources.LOSS_GRACE
	region.hero._physics_process(1.0)
	check(region.hero.resources.stability >= 54.9,"the actual hero receives shelter recovery beside the Bloomed refuge")
	check(region.waykeeper.progress.points("bloom")==6,"two distinct growths create meaningful Bloom mastery")
	region.hero.respawn_at(region.builder.entities.M5.runtime.global_position)
	await step(4)
	check(not region.bloom_growth.sheltered(),"the spring has no canopy before a chosen network node")
	region.progression.award_activity(100)
	region._configure_restoration()
	check(region.waykeeper.buy_node("deep_reserve") and region.waykeeper.buy_node("spring_attunement") and region.waykeeper.buy_node("living_conduit"),"the player invests through the connected Weaver branch")
	check(region.waykeeper.buy_node("living_network") and region.bloom_growth.sheltered(),"chosen Living Network carries shelter to the linked spring")
	await step(2)
	check(region.bloom_growth._shared_shelter.visible,"the spring visibly marks its new shelter after tree purchase")
	var request: Dictionary = region.journal.observe(region,"quest/R2/neri_new_season")
	check(not request.is_empty() and request.get("status","").contains("Return to Neri") and not request.get("actionable",true),"journal now points back to the person using the changed garden")
	var scrip_before: int = region.economy.scrip
	seeds_before = region.inventory.seeds
	var reward_xp: int = region.progression.xp
	region.story._act("bloom_reward")
	check(region.story_flags.has("neri_bloom_reward") and region.economy.scrip==scrip_before+5 and region.inventory.seeds==seeds_before+3 and region.progression.xp==reward_xp+20,"Neri's seed, scrip and XP reward can be claimed once")
	region.story.dialogue.dismiss()
	region.story._act("bloom_reward")
	check(region.economy.scrip==scrip_before+5 and region.progression.xp==reward_xp+20,"repeating return dialogue cannot farm reward")
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.free()
	await load_marsh()
	region._apply_journey_data(data)
	region._configure_restoration()
	await step(3)
	check(region.bloom_growth.completed("M1") and region.bloom_growth.completed("M4") and region.journal.observe(region,request.id).done,"growth, ecology and quest completion survive save/load")
	check(region.waykeeper.progress.points("bloom")==6 and region.inventory.seeds==seeds_before+3,"mastery and earned seeds survive save/load")
	check(region.waykeeper.effective_node("living_network") and region.bloom_growth._shared_shelter.visible,"the chosen cross-skill shelter survives save/load")

func test_legacy_marsh_keeps_optional_growth_unlearned() -> void:
	await load_marsh()
	region._apply_journey_data({"version":5,"worlds":{"R2":{"restored":["M1","M2","M4","M5"],"ecology":{}}},"skills":{"active":"bloom","unlocked":["mend"]}})
	check(not region.waykeeper.progress.unlocked.has("bloom") and not region.bloom_growth.completed("M1") and not region.bloom_growth.completed("M4"),"existing restored sites stay restored without inventing future growth")
	check(region.builder.entities.M1.get("restored",false) and region.builder.entities.M4.get("restored",false),"older completed world is preserved")
