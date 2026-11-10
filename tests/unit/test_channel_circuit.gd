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

func tap(at: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 5
	event.position = at
	event.pressed = true
	tree.root.push_input(event,true)
	await step(2)
	event.pressed = false
	tree.root.push_input(event,true)
	await step(2)

func channel_tap() -> void:
	var button: TouchScreenButton = region.get_node("TouchControls/RestoreButton")
	await tap(button.position+button.texture_normal.get_size()*button.scale*0.5)

func test_bryn_teaches_touch_channel_and_two_receivers_persist() -> void:
	await load_marsh()
	check(not region.waykeeper.learn("channel"),"Channel cannot be taken before the bell and beds recover")
	for id in ["M3","M6"]: region.builder.restore(id)
	region.hero.respawn_at(Vector3(11.5,0.02,15.5))
	await step(10)
	region.story.talk("bryn")
	check(region.story.dialogue.visible and tree.paused,"Bryn offers a touch dialogue after both places recover")
	var option: Button = region.story.dialogue._buttons[0]
	await tap(region.story.dialogue.position+option.position+option.size*0.5)
	check(region.waykeeper.progress.unlocked.has("channel") and region.waykeeper.progress.active=="channel","touch lesson unlocks and equips Channel")
	check(region.story_flags.has("bryn_channel_started") and not region.journal.observe(region,"quest/R2/bryn_charge_route").is_empty(),"lesson creates a trackable journey request")
	region.story.dialogue.dismiss()
	region.hero.set_physics_process(false)
	region.hero.respawn_at(Vector3(25.5,0.02,18.0))
	await step(40)
	var flow_before: float = region.hero.resources.flow
	var xp_before: int = region.progression.xp
	await channel_tap()
	check(region.waykeeper.channel_carry and region.charge_circuit._carried.visible,"one tap safely carries a visible Charge")
	check_near(region.hero.resources.flow,flow_before-12.0,0.01,"only useful capture spends Flow")
	check(region.progression.xp==xp_before and region.waykeeper.progress.points("channel")==0,"capture alone never farms progression")
	await step(40)
	await channel_tap()
	check(region.waykeeper.channel_carry and not region.charge_circuit.completed("lantern_beds"),"the player carries Charge toward the beds rather than delivering from the source")
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.free()
	await load_marsh()
	region._apply_journey_data(data)
	region._configure_restoration()
	await step(2)
	check(region.waykeeper.channel_carry and region.waykeeper.progress.active=="channel","carried Charge and loadout survive region reload")
	region.hero.set_physics_process(false)
	region.hero.respawn_at(Vector3(22.5,0.02,20.0))
	await step(40)
	await channel_tap()
	check(region.charge_circuit.completed("lantern_beds") and region.builder.entities.M6.runtime.ecology.status().contains("lit"),"Channel physically lights the restored living beds")
	check(not region.waykeeper.channel_carry and region.progression.xp==xp_before+20 and region.waykeeper.progress.points("channel")==3,"first unique receiver earns bounded XP and mastery")
	region.hero.respawn_at(Vector3(25.5,0.02,18.0))
	await step(40)
	await channel_tap()
	check(region.waykeeper.channel_carry and region.waykeeper.progress.points("channel")==3,"the bell gives another charge without repeat mastery")
	region.hero.respawn_at(Vector3(12.5,0.02,15.5))
	await step(40)
	await channel_tap()
	check(region.charge_circuit.completed("exchange_lamp") and region.story_flags.has("exchange_powered"),"second receiver lights the inhabited exchange")
	check(region.progression.xp==xp_before+40 and region.waykeeper.progress.points("channel")==6,"distinct receiver earns its own one-time progression")
	var quest: Dictionary = region.journal.observe(region,"quest/R2/bryn_charge_route")
	check(quest.status.contains("Return to Bryn") and not quest.actionable,"journal advances to a return conversation")
	var scrip_before: int = region.economy.scrip
	var glass_before: int = region.economy.materials.riverglass
	region.exchange.handle("exchange_channel_reward")
	check(region.story_flags.has("bryn_channel_reward") and region.economy.scrip==scrip_before+8 and region.economy.materials.riverglass==glass_before+2,"Bryn gives material and currency rewards once")
	check(region.progression.xp==xp_before+60 and region.journal.observe(region,quest.id).done,"return XP and journal completion are real")
	region.story.dialogue.dismiss()
	region.exchange.handle("exchange_channel_reward")
	check(region.economy.scrip==scrip_before+8 and region.progression.xp==xp_before+60,"repeated dialogue cannot farm the reward")
	var patch: RenewalPatch = region.renewal_world.get_node("Care_M6")
	var care_state: Dictionary = region.economy.patch("M6")
	care_state.progress = 0.95
	patch._physics_process(0.01)
	var seeds_before: int = region.inventory.seeds
	patch.receive_influence(Influence.restore(region.hero,0.1))
	check(region.inventory.seeds==seeds_before+1 and care_state.cooldown>0,"lit lantern beds produce a renewable seed through useful care")
	patch.receive_influence(Influence.restore(region.hero,0.1))
	check(region.inventory.seeds==seeds_before+1,"care cooldown prevents duplicate lantern seeds")
	data = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.free()
	await load_marsh()
	region._apply_journey_data(data)
	region._configure_restoration()
	await step(2)
	check(region.charge_circuit.completed("lantern_beds") and region.charge_circuit.completed("exchange_lamp") and region.journal.observe(region,quest.id).done,"both permanent lights and the quest survive save/load")
	check(region.waykeeper.progress.points("channel")==6 and region.economy.scrip==scrip_before+9,"mastery, quest payment and later care income survive save/load")
	check(region.inventory.seeds==seeds_before+1 and region.economy.patch("M6").cooldown>0,"renewable seed and cooldown survive save/load")

func test_channel_refuses_empty_casts_and_legacy_save_stays_unlocked_only_by_story() -> void:
	await load_marsh()
	region._apply_journey_data({"version":5,"skills":{"active":"channel","channel_carry":true,"unlocked":["mend"]},"worlds":{"R2":{"restored":[]}}})
	check(not region.waykeeper.progress.unlocked.has("channel") and not region.waykeeper.channel_carry,"malformed or older save cannot invent Channel")
	for id in ["M3","M6"]: region.builder.restore(id)
	region.waykeeper.learn("channel")
	region.hero.set_physics_process(false)
	region.hero.respawn_at(Vector3(12.5,0.02,15.5))
	await step(40)
	var flow_before: float = region.hero.resources.flow
	var xp_before: int = region.progression.xp
	await channel_tap()
	check(not region.waykeeper.channel_carry and region.hero.resources.flow==flow_before,"tapping a dark receiver without Charge spends nothing")
	region.hero.respawn_at(Vector3(25.5,0.02,18.0))
	await step(40)
	await channel_tap()
	region.hero.respawn_at(Vector3(22.5,0.02,20.0))
	await step(40)
	await channel_tap()
	check(region.charge_circuit.completed("lantern_beds"),"first receiver takes the held charge")
	region.hero.respawn_at(Vector3(25.5,0.02,18.0))
	await step(40)
	await channel_tap()
	region.hero.respawn_at(Vector3(22.5,0.02,20.0))
	await step(40)
	await channel_tap()
	check(region.waykeeper.channel_carry and region.progression.xp==xp_before+20,"a completed receiver cannot consume another charge or repeat XP")
