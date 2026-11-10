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
func test_points_are_player_choices_with_independent_mastery_and_prerequisites() -> void:
	var p := WaykeeperProgression.new()
	check(p.skill_points()==0 and not p.buy_upgrade("deep_reserve"),"fresh keeper cannot spend unearned points")
	p.set_level(2)
	check(p.skill_points()==2,"each level grants two points")
	p.unlock("force")
	check(not p.buy_upgrade("groundwave"),"points do not bypass technique experience")
	p.award("force","spring/clear",2)
	check(p.upgrades.is_empty(),"mastery never automatically learns a node")
	check(p.buy_upgrade("groundwave") and p.skill_points()==1,"choosing a node spends a point")
	check(not p.buy_upgrade("groundwave") and p.skill_points()==1,"duplicate purchase cannot spend twice")
	check(p.buy_upgrade("deep_reserve") and p.skill_points()==0,"player chooses where to invest remaining point")
	p.set_level(3)
	check(p.skill_points()==2,"leveling adds points without refunding previous investment")
	check(not p.buy_upgrade("undertow"),"advanced node needs deeper mastery")
	p.award("force","second/clear",2)
	p.award("force","third/clear",2)
	check(p.buy_upgrade("undertow"),"parent plus meaningful mastery permit deep behaviour")
	check(not p.award("force","third/clear",2),"saved event ledger prevents mastery farming")
func test_purchases_and_legacy_upgrade_migration_preserve_choice_without_refilling_points() -> void:
	var p := WaykeeperProgression.new()
	p.apply_data({"unlocked":["mend","force"],"events":{"force/a":3,"force/b":3},"upgrades":["undertow"]},3)
	check(p.upgrades.has("undertow") and p.upgrades.has("groundwave"),"existing behaviour and its connecting path migrate")
	check(p.skill_points()==4 and p.inherited.has("undertow"),"old earned upgrades cost none of the new choice budget")
	check(p.buy_upgrade("deep_reserve"),"migrated keeper can make a new choice")
	var data: Dictionary = JSON.parse_string(JSON.stringify(p.to_data()))
	var restored := WaykeeperProgression.new()
	restored.apply_data(data,3)
	check(restored.skill_points()==3 and restored.purchased.has("deep_reserve"),"JSON reload retains spending exactly")
	check(restored.upgrades.has("undertow") and not restored.award("force","a",3),"migration retains learned behaviours and event protection")
	restored.apply_data({"tree_version":1,"purchased":["unknown","undertow","deep_reserve","deep_reserve","steady_vessel","spring_attunement"],"inherited":["deep_reserve"]},2)
	check(restored.skill_points()==0 and restored.purchased.size()==2,"corrupt saves cannot invent points or bypass requirements")
	check(restored.inherited.is_empty(),"stat nodes cannot claim free legacy status")
func test_real_resource_caps_and_save_reload_do_not_refill_depleted_reserves() -> void:
	await load_region()
	region.builder.restore("B1")
	region.hero.resources.flow = 32
	region.hero.resources.stability = 61
	check(region.waykeeper.buy_node("deep_reserve") and region.waykeeper.buy_node("steady_vessel"),"real level reward funds two choices")
	check(region.hero.resources.max_flow==110 and region.hero.resources.max_stability==108,"chosen nodes alter actual resource caps")
	check(region.hero.resources.flow==32 and region.hero.resources.stability==61,"buying capacity never refills depletion")
	region.hero.resources.flow = 107
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.free()
	await load_region()
	region.hero.set_physics_process(false)
	region._apply_journey_data(data)
	region._configure_restoration()
	check(region.hero.resources.max_flow==110 and region.hero.resources.flow==107,"tree loads before resource sanitizer so extended Flow survives")
	check(region.waykeeper.progress.skill_points()==0,"loading never refunds spent points")
func test_mend_anchor_hybrid_changes_actual_channel_cost_and_grounding() -> void:
	await load_region()
	region.hero.set_physics_process(false)
	region.builder.restore("B1")
	region.waykeeper.learn("force")
	region.builder.restore("C1")
	region.waykeeper.learn("anchor")
	region.progression.award("R2/M1")
	region.progression.award("R2/M2")
	region.progression.award("R2/M3")
	region._configure_restoration()
	var p: WaykeeperProgression = region.waykeeper.progress
	p.award("anchor","fixture/roots",2)
	check(region.waykeeper.buy_node("living_pulse") and region.waykeeper.buy_node("shared_ground"),"both disciplines invest in connecting branches")
	check(region.waykeeper.buy_node("gentle_foundation"),"cross-discipline node requires both learned parents and mastery")
	var target: RegionCreature = region.builder.entities.B2.runtime
	target.ecology.states.stabilized = true
	region.hero.respawn_at(target.global_position+Vector3.LEFT*2)
	region.hero.resources.flow = 80
	region.hero.resources.protection_left = 0
	region.hero.restore_verb.on_pressed()
	region.hero.restore_verb.tick(0.5)
	check_near(region.hero.resources.flow,77,0.001,"Anchored Mend spends six Flow/second instead of eight")
	check(not region.hero.lose_stability(20),"hybrid grounds Stability while meaningful Mend channels")
	region.hero.restore_verb.on_released()
func test_spring_attunement_completion_return_and_current_rider_change_play() -> void:
	var r := WaykeeperResources.new()
	r.configure(PackedStringArray(["deep_reserve","spring_attunement","restoration_return"]))
	r.flow = 0
	r.tick(1,true)
	check_near(r.flow,18,0.001,"spring node improves real Flow regeneration")
	r.restoration_reward()
	check_near(r.flow,38,0.001,"completion node adds eight Flow to refund")
	await load_region()
	region.builder.restore("C1")
	region.hero.respawn_at(region.builder.entities.C1.runtime.global_position+Vector3.LEFT*2)
	await step(20)
	check(region.hero._near_healthy_water,"restored spring is detected by real hero")
	region.hero.learned_nodes.append("current_rider")
	region.hero.request_dash()
	check(region.hero.is_dashing() and region.hero._dash_flow_bonus==1.25,"Current Rider increases actual Glide travel at a healthy spring")
	var full: float = region.hero.resources.flow
	await step(15)
	check(region.hero.resources.flow==full,"Glide never consumes Flow")

func test_gear_can_supply_a_node_without_spending_or_erasing_tree_investment() -> void:
	await load_region()
	region.builder.restore("B1")
	region.waykeeper.learn("force")
	region.inventory.equip("ferryman_staff")
	var points: int = region.waykeeper.progress.skill_points()
	check(region.waykeeper.effective_node("undertow"),"behavioural staff temporarily grants Undertow interaction")
	check(not region.waykeeper.progress.upgrades.has("undertow") and region.waykeeper.progress.skill_points()==points,"gear does not fabricate learned nodes or spend points")
	region.inventory.equip("wayfarer_wand")
	check(not region.waykeeper.effective_node("undertow"),"temporary node disappears when gear is replaced")
	region.waykeeper.progress.apply_data({"unlocked":["force"],"events":{"force/a":3,"force/b":3},"upgrades":["undertow"]},2)
	check(region.waykeeper.effective_node("undertow"),"permanently learned Undertow works independently of the staff")

func test_connected_tree_touch_pan_does_not_purchase_or_cast() -> void:
	await load_region()
	region.builder.restore("B1")
	region.waykeeper.screen.toggle()
	var screen: SkillsScreen = region.waykeeper.screen
	var at: Vector2 = screen.position+screen._scroll.position+Vector2(220,95)
	var down := InputEventScreenTouch.new()
	down.index = 4
	down.position = at
	down.pressed = true
	tree.root.push_input(down,true)
	await step(2)
	var drag := InputEventScreenDrag.new()
	drag.index = 4
	drag.position = at-Vector2(100,0)
	drag.relative = Vector2(-100,0)
	tree.root.push_input(drag,true)
	await step(2)
	down.position = drag.position
	down.pressed = false
	tree.root.push_input(down,true)
	await step(2)
	check(screen._scroll.scroll_horizontal>190,"actual screen drag pans the connected watershed")
	check(region.waykeeper.progress.skill_points()==2 and region.waykeeper.progress.upgrades.is_empty(),"panning cannot spend points or learn a capability")
	check(not region.hero.restore_verb.active,"tree gestures cannot leak into held Mend")
	screen.toggle()
