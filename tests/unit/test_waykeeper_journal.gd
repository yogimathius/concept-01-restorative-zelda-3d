extends TestCase
const REGION := preload("res://scenes/levels/region1.tscn")
var region: Node3D

func load_region() -> void:
	region = REGION.instantiate()
	region.persist_progress = false
	region.get_node("Hero").use_device_input = false
	world.add_child(region)
	await step(3)

func test_journal_remembers_partial_conditions_without_revealing_unvisited_places() -> void:
	await load_region()
	check(region.journal.entries(region).size()==1,"opening remembers only the known grove")
	check(not region.journal.pin(region,"R1/B3"),"unvisited late grove cannot be pinned")
	var target: RegionCreature = region.builder.entities.B2.runtime
	target.ecology.states.seen = true
	target.progress = 0.55
	var entry: Dictionary = region.journal.observe(region,"R1/B2")
	check(entry.skill=="anchor" and not entry.unlocked,"partial refuge identifies the missing tradition")
	check(entry.steps.contains("55%"),"exact retained recovery is shown")
	check(region.journal.pin(region,"R1/B2"),"discovered refuge can be remembered for a return")
	var before: Dictionary = region._journey_data()
	region.waykeeper.progress.unlock("anchor")
	target.ecology.states.stabilized = true
	entry = region.journal.observe(region,"R1/B2")
	check(entry.skill=="mend" and entry.unlocked,"real grounding changes the next technique")
	check(before.progression == region.progression.to_data(),"reading/pinning grants no XP")
	check(before.skills.events == region.waykeeper.progress.events,"reading/pinning grants no mastery")

func test_pin_and_observations_survive_json_and_other_region_snapshots() -> void:
	await load_region()
	region.builder.entities.B2.runtime.ecology.states.seen = true
	region.builder.entities.B2.runtime.progress = 0.43
	region.journal.pin(region,"R1/B2")
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.journal.pinned = ""
	region._apply_journey_data(data)
	check(region.journal.pinned=="R1/B2","chosen destination survives JSON reload")
	check_near(region.journal.observe(region,"R1/B2").progress,0.43,0.001,"observations use restored partial world state")
	region._worlds.R2 = {"partial":{"M3":0.6},"ecology":{"M3":{"seen":true,"stabilized":false}}}
	check(region.journal.pin(region,"R2/M3"),"remembered marsh destination can be pinned from Ford")
	var navigation: Dictionary = region.journal.navigation(region)
	check(navigation.direction==Vector2.ZERO and navigation.caption.contains("Reedglass"),"other-region pin gives region name, not misleading direction")
	region.journal.apply_data(region,{"pinned":"R2/M6"})
	check(region.journal.pinned.is_empty(),"forged unseen destination rejected")
	region.journal.apply_data(region,{"pinned":null})
	check(region.journal.pinned.is_empty(),"malformed pin is safe")

func test_completed_place_stops_navigation_and_optional_irrigation_remains_useful() -> void:
	await load_region()
	region.journal.pin(region,"R1/B1")
	region.builder.restore("B1")
	check(region.journal.navigation(region).is_empty(),"completion removes navigation clutter")
	check(not region.journal.pin(region,"R1/B1"),"completed place is not an active objective")
	region._worlds.R2 = {"restored":["M1"],"ecology":{"M1":{"cultivated":false}}}
	var entry: Dictionary = region.journal.observe(region,"R2/M1")
	check(entry.restored and not entry.done and entry.skill=="anchor","optional garden irrigation remains a reason to return")
	region._worlds.R2.ecology.M1.cultivated = true
	check(region.journal.observe(region,"R2/M1").done,"cultivated garden settles the optional objective")

func test_actual_region_round_trip_preserves_pin_and_legacy_saves_start_unpinned() -> void:
	await load_region()
	region.builder.entities.B2.runtime.ecology.states.seen = true
	region.builder.entities.B2.runtime.progress = 0.37
	region.journal.pin(region,"R1/B2")
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data("R2")))
	var marsh: Node3D = load("res://scenes/levels/region2.tscn").instantiate()
	marsh.persist_progress = false
	marsh.get_node("Hero").use_device_input = false
	world.add_child(marsh)
	await step(3)
	marsh._apply_journey_data(data)
	check(marsh.journal.pinned=="R1/B2","marsh retains the remembered Ford return")
	check(marsh.journal.navigation(marsh).caption.contains("Broken Ford"),"marsh guidance names the other region")
	var back: Dictionary = JSON.parse_string(JSON.stringify(marsh._journey_data("R1")))
	region._apply_journey_data(back)
	check(region.journal.pinned=="R1/B2","returning to Ford keeps the chosen destination")
	check_near(region.journal.observe(region,"R1/B2").progress,0.37,0.001,"round trip keeps partial healing")
	back.erase("journal")
	back.version = 4
	region._apply_journey_data(back)
	check(region.journal.pinned.is_empty(),"legacy save has no automatically chosen pin")
	check_near(region.builder.entities.B2.runtime.progress,0.37,0.001,"legacy save retains restoration progress")

func test_touch_journal_scroll_pin_and_ready_never_cast_or_buy_skills() -> void:
	await load_region()
	for id in region.builder.manifest.ENTITIES: region.builder.entities[id].runtime.ecology.states.seen = true
	region.waykeeper.progress.unlock("force")
	region.journey_map.toggle(region.checkpoint_position)
	await tap(region.journey_map._journal_button)
	var screen: JournalScreen = region.journey_map.journal_screen
	check(screen.visible and tree.paused,"journal opens with touch and pauses the world")
	screen.select_place("R1/C1")
	await tap(screen._pin)
	check(region.journal.pinned=="R1/C1","explicit touch pins the place")
	var selected := screen.selected
	var at: Vector2 = screen._scroll.global_position+Vector2(100,190)
	await touch(at,true)
	var drag := InputEventScreenDrag.new()
	drag.index = 7
	drag.position = at-Vector2(0,100)
	drag.relative = Vector2(0,-100)
	tree.root.push_input(drag,true)
	await touch(drag.position,false)
	check(screen.selected==selected and screen._scroll.scroll_vertical>0,"scroll cannot choose a row")
	at = screen._details_scroll.global_position+Vector2(100,120)
	await touch(at,true)
	drag.position = at-Vector2(0,85)
	drag.relative = Vector2(0,-85)
	tree.root.push_input(drag,true)
	await touch(drag.position,false)
	check(screen._details_scroll.scroll_vertical>0,"long restoration notes scroll with touch")
	var flow: float = region.hero.resources.flow
	await tap(screen._technique)
	check(not tree.paused and not region.journey_map.visible,"ready closes journal and resumes touch controls")
	check(region.waykeeper.progress.active=="force","ready selects the necessary learned technique")
	check_near(region.hero.resources.flow,flow,0.001,"technique choice never spends Flow")
	check(not region.builder.entities.C1.runtime.ecology.states.cleared,"technique choice never casts")
	check(region.waykeeper.progress.purchased.is_empty(),"journal never spends skill points")

func touch(at: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 7
	event.position = at
	event.pressed = pressed
	tree.root.push_input(event,true)
	await tree.process_frame

func tap(control: Control) -> void:
	var at := control.get_global_rect().get_center()
	await touch(at,true)
	await touch(at,false)
