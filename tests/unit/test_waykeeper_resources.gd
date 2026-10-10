extends TestCase
const REGION := preload("res://scenes/levels/region1.tscn")
var region: Node3D

func after_each() -> void:
	tree.paused = false
	tree.root.get_node("JourneySession").pending = {}
	await super.after_each()

func load_region() -> void:
	region = REGION.instantiate()
	region.persist_progress = false
	region.get_node("Hero").use_device_input = false
	world.add_child(region)
	await step(4)

func test_stability_grace_weight_and_single_unmoored_recovery() -> void:
	var r := WaykeeperResources.new()
	var events := [0]
	r.unmoored.connect(func(): events[0]+=1)
	check(r.lose_stability(20,1),"Weight reduces environmental Stability loss")
	check_near(r.stability,85,0.001,"grounded Weight absorbs a quarter of loss")
	check(not r.lose_stability(20),"hazard overlap cannot drain repeatedly during protection")
	r.tick(1.1)
	check(r.lose_stability(200),"major instability can become Unmoored")
	check(r.stability==0 and events[0]==1,"zero emits one gentle recovery request")
	r.lose_stability(200)
	r.tick(10,true)
	check(events[0]==1 and r.stability==0,"Unmoored waits for checkpoint recovery")
	r.flow = 0
	r.recover()
	check(r.stability==100 and r.flow==50 and r.protection_left==2,"recovery restores grounding and a usable Flow reserve")

func test_flow_cost_regeneration_water_conditions_and_reward() -> void:
	var r := WaykeeperResources.new()
	check(r.spend(12) and r.flow==88,"Flow pays for active techniques")
	check(not r.spend(100) and r.flow==88,"unaffordable cast cannot overspend")
	check(not r.spend(-1) and not r.spend(NAN),"invalid costs cannot create Flow")
	r.tick(0.2)
	check_near(r.flow,88.8,0.001,"active spending still has gentle regeneration")
	r.tick(1,true,1,1)
	check_near(r.flow,100,0.001,"restored water and Charge increase recovery; Weight reduces it")
	r.lose_stability(20)
	r.flow = 50
	r.restoration_reward()
	check(r.flow==62 and r.stability==90,"first-time restoration returns Flow and grounding")

func test_resource_json_migration_sanitizes_and_never_regenerates_offline() -> void:
	var r := WaykeeperResources.new()
	r.lose_stability(25)
	r.spend(60)
	var restored := WaykeeperResources.new()
	restored.apply_data(JSON.parse_string(JSON.stringify(r.to_data())))
	check(restored.stability==75 and restored.flow==40,"resource depletion survives JSON reload")
	check_near(restored.protection_left,1,0.001,"damage grace survives reload")
	restored.apply_data({"stability":-7,"flow":NAN,"protection":"bad","since_loss":INF})
	check(restored.stability==0 and restored.flow==100 and restored.protection_left==0,"corrupt values stay finite and bounded")
	restored.apply_data({})
	check(restored.stability==100 and restored.flow==100,"older saves receive full starting resources")

func test_actual_mend_charges_only_saved_healing_and_preserves_partial() -> void:
	await load_region()
	region.hero.set_physics_process(false)
	var target: RegionCreature = region.builder.entities.C1.runtime
	region.hero.respawn_at(target.global_position+Vector3.LEFT*2)
	var mend: Verb = region.hero.restore_verb
	mend.on_pressed()
	region.hero.resources.flow = 1.0
	mend.tick(1.0)
	check_near(target.progress,region.hero.restore_verb.rate/8.0,0.001,"low Flow buys the affordable fraction of actual healing")
	check_near(region.hero.resources.flow,0,0.001,"Mend never goes negative")
	var partial: float = target.progress
	mend.tick(1.0)
	check_near(target.progress,partial,0.001,"no Flow pauses while retaining partial healing")
	check(mend.feedback.contains("Flow"),"waiting has explicit resource feedback")
	region.hero.resources.flow = 100
	target.progress = 0.45
	mend.tick(1.0)
	check(region.hero.resources.flow==100,"blocked site at viability cap consumes nothing")
	mend.on_released()
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.free()
	await load_region()
	region.hero.set_physics_process(false)
	region._apply_journey_data(data)
	check_near(region.builder.entities.C1.runtime.progress,0.45,0.001,"resource integration preserves exact partial world progress")

func test_force_anchor_cost_refusal_and_completion_replay() -> void:
	await load_region()
	region.hero.set_physics_process(false)
	region.builder.restore("B1")
	region.waykeeper.learn("force")
	var spring: RegionCreature = region.builder.entities.C1.runtime
	region.hero.respawn_at(spring.global_position+Vector3.LEFT*2)
	region.hero.resources.flow = 11
	check(not region.waykeeper.use_skill("force") and not spring.ecology.states.cleared,"insufficient Flow cannot clear or earn mastery")
	check(region.hero.resources.flow==11 and region.waykeeper.progress.points("force")==0,"refusal costs no Flow and awards nothing")
	await step(30)
	region.hero.resources.flow = 100
	check(region.waykeeper.use_skill("force"),"affordable Force works")
	check_near(region.hero.resources.flow,88,0.001,"one useful pulse costs 12 Flow")
	await step(30)
	check(not region.waykeeper.use_skill("force") and region.hero.resources.flow==88,"resolved target and empty casts are free")
	region.builder.restore("C1")
	region.waykeeper.learn("anchor")
	region.hero.respawn_at(region.builder.entities.B2.runtime.global_position+Vector3.LEFT*2)
	await step(30)
	region.hero.resources.flow = 50
	check(region.waykeeper.use_skill("anchor"),"Anchor can steady a site")
	check_near(region.hero.resources.flow,36,0.001,"one useful grounding costs 14 Flow")
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.free()
	await load_region()
	region.hero.set_physics_process(false)
	region._apply_journey_data(data)
	check_near(region.hero.resources.flow,36,0.001,"restored-site replay does not grant completion Flow again")
	check(region.builder.entities.B1.get("restored",false) and region.builder.entities.B2.runtime.ecology.states.stabilized,"resources travel alongside existing world conditions")

func test_unmoored_returns_to_checkpoint_without_rollback_and_cancels_touch() -> void:
	await load_region()
	region.builder.restore("B1")
	region.builder.entities.C1.runtime.progress = 0.30
	region.hero.respawn_at(Vector3(49,0.02,18.5))
	await step(2)
	region.hero.resources.protection_left = 0
	region.hero.set_verb_held(Hero.SLOT_RESTORE,true)
	check(region.hero.lose_stability(200),"main RPG hazard uses Stability")
	check(region.recovering and not region.hero.is_controllable(),"Unmoored stops interaction")
	check(not region.hero.restore_verb.active,"held Mend is released during recovery")
	await step(2)
	check(region.get_node("JourneyHUD/ObjectivePanel").visible and region._guidance.text.contains("Unmoored"),"recovery guidance stays visible even beside an NPC")
	await step(60)
	check(not region.recovering and region.hero.is_controllable(),"checkpoint recovery returns control")
	check(region.hero.global_position.distance_to(region.checkpoint_position)<0.2,"recovery returns to the safe marker")
	check(region.builder.entities.B1.get("restored",false),"completed crossing survives without checkpoint rollback")
	check_near(region.builder.entities.C1.runtime.progress,0.30,0.001,"partial healing survives Unmoored")
	check(region.hero.hearts==5,"main RPG never mutates legacy fixture hearts")

func test_paused_menus_stop_resource_time_and_main_hud_replaces_hearts() -> void:
	await load_region()
	region.hero.resources.spend(40)
	region.hero.resources.lose_stability(20)
	region.equipment_screen.toggle()
	var before: Dictionary = region.hero.resources.to_data()
	await step(20)
	check(region.hero.resources.to_data()==before,"gear menu does not advance Flow, Stability or grace")
	check(not region.get_node("HUD/HeartsRow").visible,"main game has no five-heart presentation")
	check(region.get_node("HUD/Resources").visible,"Stability and Flow have a visible bar HUD")
	region.equipment_screen.toggle()
	await step(10)
	check(region.hero.resources.flow>before.flow,"regeneration resumes during active play")
