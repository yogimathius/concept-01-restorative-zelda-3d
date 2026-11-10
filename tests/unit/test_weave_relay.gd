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
	await step(4)

func touch(at: Vector2, down: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 3
	event.position = at
	event.pressed = down
	tree.root.push_input(event,true)
	await step(2)

func test_neri_teaches_weave_and_touch_link_changes_persistent_world() -> void:
	await load_marsh()
	check(not region.waykeeper.learn("weave"),"Weave requires both living places")
	region.builder.restore("M1")
	region.builder.restore("M2")
	var conversation: Dictionary = StoryChapters.conversation(region,"neri")
	check(conversation.options.any(func(item: Dictionary): return item.action=="learn_weave"),"Neri offers a story-led Weave lesson")
	region.story._act("learn_weave")
	check(region.waykeeper.progress.unlocked.has("weave") and region.waykeeper.progress.active=="weave","lesson equips one medallion technique")
	region.story.dialogue.dismiss()
	region.hero.respawn_at(Vector3(8.5,0.02,9.0))
	region.hero.set_physics_process(false)
	await step(3)
	var relay: WeaveRelay = region.weave_relay
	var button: TouchScreenButton = region.get_node("TouchControls/RestoreButton")
	var center: Vector2 = button.position+button.texture_normal.get_size()*button.scale*0.5
	var destination: Vector2 = relay._screen(1)
	var initial_flow: float = region.hero.resources.flow
	var initial_xp: int = region.progression.xp
	await touch(center,true)
	var drag := InputEventScreenDrag.new()
	drag.index = 3
	drag.position = destination
	drag.relative = destination-center
	tree.root.push_input(drag,true)
	await step(2)
	check(relay._candidate and relay._line.visible,"drag previews and magnetizes the partner relay")
	await touch(destination,false)
	check(relay.linked() and relay._water.visible,"touch release physically reconnects the ceramic feed")
	check_near(region.hero.resources.flow,initial_flow-16.0,0.01,"successful Link spends Flow once")
	check(region.waykeeper.progress.points("weave")==3 and region.progression.xp==initial_xp+20,"unique link awards mastery and quest XP")
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	check(data.worlds.R2.ecology.M1.linked and data.worlds.R2.ecology.M2.linked,"connection lives in both ecological save states")
	region.free()
	await load_marsh()
	region._apply_journey_data(data)
	region._configure_restoration()
	await step(2)
	check(region.weave_relay.linked() and region.weave_relay._water.visible,"older world reload keeps the visible water link")
	check(region.waykeeper.progress.unlocked.has("weave") and region.waykeeper.progress.points("weave")==3,"Weave learning and mastery persist")
	check(not region.weave_relay.begin() and region.progression.xp==initial_xp+20,"a completed link cannot be farmed")

func test_link_refuses_without_flow_and_weaver_node_is_chosen() -> void:
	await load_marsh()
	region.builder.restore("M1")
	region.builder.restore("M2")
	region.waykeeper.learn("weave")
	region.hero.respawn_at(Vector3(8.5,0.02,9.0))
	region.hero.set_physics_process(false)
	await step(2)
	var relay: WeaveRelay = region.weave_relay
	region.hero.resources.flow = 5.0
	check(relay.begin(),"nearby restored relays accept Weave gesture")
	check(not relay.end(relay._screen(1)) and not relay.linked(),"insufficient Flow cannot create a free link")
	check(region.progression.xp==80 and region.waykeeper.progress.points("weave")==0,"failed cast awards nothing")
	region.hero.resources.flow = 100.0
	check(relay.begin() and relay.end(relay._screen(1)),"same connection succeeds with enough Flow")
	var p: WaykeeperProgression = region.waykeeper.progress
	check(not p.upgrades.has("living_conduit"),"mastery never auto-purchases Weaver node")
	region.progression.award_activity(20)
	region._configure_restoration()
	check(region.waykeeper.buy_node("deep_reserve") and region.waykeeper.buy_node("spring_attunement"),"player invests through connected Waykeeper tree")
	check(region.waykeeper.buy_node("living_conduit") and region.hero.resources.linked_bonus==4.0,"purchased Weaver node changes Flow near linked water")
	region.hero.resources.flow = 50.0
	region.hero.resources.spending_left = 0.0
	region.hero.resources.tick(1.0,true,0.0,0.0,true)
	check_near(region.hero.resources.flow,72.0,0.01,"connected water grants the purchased Flow recovery in active play")

func test_equipped_weave_remains_safe_after_travel_to_ford() -> void:
	region = FORD.instantiate()
	region.persist_progress = false
	region.get_node("Hero").use_device_input = false
	world.add_child(region)
	await step(4)
	region._apply_journey_data({"version":5,"skills":{"unlocked":["mend","weave"],"active":"weave"},"worlds":{"R1":{"restored":[]}}})
	check(region.waykeeper.progress.active=="weave" and region.weave_relay==null,"learned Weave travels without creating a false Ford relay")
	var button: TouchScreenButton = region.get_node("TouchControls/RestoreButton")
	var center: Vector2 = button.position+button.texture_normal.get_size()*button.scale*0.5
	await touch(center,true)
	await touch(center,false)
	check(region.waykeeper.feedback.contains("Neri"),"touching Weave away from a relay gives a useful hint")
	await touch(center,true)
	var drag := InputEventScreenDrag.new()
	drag.index = 3
	drag.position = center-Vector2(0,40)
	drag.relative = Vector2(0,-40)
	tree.root.push_input(drag,true)
	await step(2)
	await touch(center-Vector2(0,40),false)
	check(region.waykeeper.progress.active=="mend","short upward gesture cycles away from Weave in Ford")

func test_second_link_becomes_daros_trackable_quest_and_renewable_herb_route() -> void:
	await load_marsh()
	for id in ["M1","M2","M4","M5"]: region.builder.restore(id)
	check(region.waykeeper.learn("weave"),"garden lesson opens Weave for the wider marsh")
	var second: WeaveRelay = region.weave_relays.spring_refuge
	check(second.ready() and not second.linked() and not second._herb_bed.visible,"Daro's severed feed is visible before linking")
	var offered: Dictionary = StoryChapters.conversation(region,"daro")
	check(offered.options.any(func(item: Dictionary): return item.action=="daro_link_quest"),"Daro offers a distinct living route request")
	region.story._act("daro_link_quest")
	check(region.story_flags.has("daro_link_started"),"request becomes an active story objective")
	region.story.dialogue.dismiss()
	var quest: Dictionary = region.journal.observe(region,"quest/R2/daro_water_route")
	check(quest.status.contains("Weave") and region.journal.pin(region,quest.id),"touch journal can track and pin the link request")
	region.hero.respawn_at(Vector3(6.5,0.02,18.0))
	region.hero.set_physics_process(false)
	await step(30)
	var button: TouchScreenButton = region.get_node("TouchControls/RestoreButton")
	var center: Vector2 = button.position+button.texture_normal.get_size()*button.scale*0.5
	var xp_before: int = region.progression.xp
	await touch(center,true)
	var destination: Vector2 = second._screen(1-second._source)
	var drag := InputEventScreenDrag.new()
	drag.index = 3
	drag.position = destination
	drag.relative = destination-center
	tree.root.push_input(drag,true)
	await step(2)
	check(second._candidate and second._line.visible,"touch targets the nearby spring pair rather than the garden")
	await touch(destination,false)
	check(second.linked() and second._herb_bed.visible and not region.weave_relay.linked(),"second Link grows mint without silently solving the first")
	check(region.progression.xp==xp_before+20 and region.waykeeper.progress.points("weave")==3,"second unique connection earns its own bounded progression")
	quest = region.journal.observe(region,"quest/R2/daro_water_route")
	check(quest.status.contains("Return to Daro") and not quest.actionable and region.journal.navigation(region).title==quest.title,"journal changes from technique objective to return visit")
	var scrip_before: int = region.economy.scrip
	var seeds_before: int = region.inventory.seeds
	region.story._act("daro_link_reward")
	check(region.story_flags.has("daro_link_reward") and region.economy.scrip==scrip_before+6 and region.inventory.seeds==seeds_before+3,"Daro gives concrete quest rewards once")
	check(region.progression.xp==xp_before+35 and region.journal.observe(region,quest.id).done,"return conversation closes the journal request and earns XP")
	region.story.dialogue.dismiss()
	region.story._act("daro_link_reward")
	check(region.economy.scrip==scrip_before+6 and region.progression.xp==xp_before+35,"repeating dialogue cannot farm the quest")
	var patch: RenewalPatch = region.renewal_world.get_node("Care_M5")
	var state: Dictionary = region.economy.patch("M5")
	state.progress = 0.95
	patch._physics_process(0.01)
	var care_seeds: int = region.inventory.seeds
	patch.receive_influence(Influence.restore(region.hero,0.1))
	check(region.inventory.seeds==care_seeds+1 and region.economy.patch("M5").cooldown>0,"later spring care yields a renewable herb seed")
	patch.receive_influence(Influence.restore(region.hero,0.1))
	check(region.inventory.seeds==care_seeds+1,"care cooldown prevents duplicate seed farming")
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.free()
	await load_marsh()
	region._apply_journey_data(data)
	region._configure_restoration()
	await step(2)
	check(region.weave_relays.spring_refuge.linked() and region.weave_relays.spring_refuge._herb_bed.visible,"second link and herb bed survive reload")
	check(region.story_flags.has("daro_link_reward") and region.journal.observe(region,quest.id).done and region.inventory.seeds==care_seeds+1,"request, reward and resources survive reload")

func test_living_echo_is_a_chosen_cross_skill_care_interaction() -> void:
	await load_marsh()
	for id in ["M1","M2","M4","M5"]: region.builder.restore(id)
	region.waykeeper.learn("weave")
	region.hero.set_physics_process(false)
	region.waykeeper.progress.award("mend","fixture/meaningful_restore",3)
	check(not region.waykeeper.buy_node("living_echo"),"hybrid care is not granted automatically")
	var first: WeaveRelay = region.weave_relay
	region.hero.respawn_at(Vector3(8.5,0.02,9.0))
	await step(20)
	check(first.begin() and first.end(first._screen(1-first._source)),"first authored link earns the first Weave mastery")
	check(region.waykeeper.progress.points("weave")==3 and not region.waykeeper.buy_node("living_echo"),"one link does not satisfy the deeper node")
	var second: WeaveRelay = region.weave_relays.spring_refuge
	region.hero.respawn_at(Vector3(6.5,0.02,18.0))
	await step(20)
	check(second.begin() and second.end(second._screen(1-second._source)),"second authored link earns distinct mastery")
	region.progression.award_activity(100)
	check(region.waykeeper.buy_node("living_pulse") and region.waykeeper.buy_node("deep_reserve") and region.waykeeper.buy_node("spring_attunement") and region.waykeeper.buy_node("living_conduit"),"player invests across Mend and Weaver branches")
	check(region.waykeeper.buy_node("living_echo"),"two learned disciplines and two links unlock chosen Living Echo")
	var source: RenewalPatch = region.renewal_world.get_node("Care_M5")
	var partner: RenewalPatch = region.renewal_world.get_node("Care_M4")
	source._physics_process(0.01)
	partner._physics_process(0.01)
	check_near(region.economy.patch("M4").progress,0.0,0.001,"linked care begins untouched")
	source.receive_influence(Influence.restore(region.hero,0.4))
	check_near(region.economy.patch("M4").progress,0.2,0.001,"useful Mend carries half its care across the link")
	check(region.economy.patch("M4").cycles==0 and region.economy.patch("M4").cooldown==0,"echo cannot auto-complete or farm partner rewards")
	source.receive_influence(Influence.restore(region.hero,0.6))
	check_near(region.economy.patch("M4").progress,0.5,0.001,"completing source care still leaves partner for player choice")
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.free()
	await load_marsh()
	region._apply_journey_data(data)
	region._configure_restoration()
	check(region.waykeeper.effective_node("living_echo") and region.economy.patch("M4").progress>=0.5,"chosen node and partial echoed care survive reload")
