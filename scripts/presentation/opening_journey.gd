class_name OpeningJourney
extends Node
## Opening presentation orchestrator; reusable systems own resources/skills/saves.
var region: Node3D
var landscape: OpeningWaterway
var presentations := {}
var _card: PanelContainer
var _title: Label
var _text: Label
var _gear: Button
var _skills: Button
var _dismiss: Button
var _delay := 0.0
var _reward_delay := 0.0
var _pending_toast := ""
var beat := "homecoming"
func _ready() -> void:
	name = "OpeningJourney"
	landscape = OpeningWaterway.new()
	landscape.region = region
	region.add_child(landscape)
	for id in region.builder.manifest.ENTITIES:
		var target: RegionCreature = region.builder.entities[id].runtime
		var presentation := RestorationPresentation.new()
		presentation.target = target
		target.add_child(presentation)
		presentations[id] = presentation
	region.builder.restored.connect(_restored)
	_make_card()
	var sound := WaterwaySoundscape.new()
	sound.region = region
	region.add_child(sound)
func _restored(id: String) -> void:
	if region.builder._replaying: return
	presentations[id].complete()
	if id in ["B1","C1"] and region.hero.global_position.distance_to(region.builder.entities[id].runtime.global_position)<8:
		region.get_node("Camera3D").frame_restoration(region.builder.entities[id].runtime.global_position)
	if id in ["B1","C1"]:
		region._toast_left = 0.0
		region._mend_bar.value = 100.0
	if id=="B1":
		_delay = 4.6
	if id=="C1":
		_pending_toast = region._level_toast.text
		_reward_delay = 4.6
func _make_card() -> void:
	_card = PanelContainer.new()
	_card.name = "OpeningReward"
	_card.position = Vector2(20,80)
	_card.custom_minimum_size = Vector2(290,106)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("102d36")
	style.border_color = Color("b9a774")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_card.add_theme_stylebox_override("panel",style)
	region.get_node("JourneyHUD").add_child(_card)
	var column := VBoxContainer.new()
	_card.add_child(column)
	_title = Label.new()
	_title.text = "THE FIRST WATER RETURNS"
	_title.add_theme_font_size_override("font_size",13)
	_title.modulate = Color("ecd59e")
	column.add_child(_title)
	_text = Label.new()
	_text.text = "Level 2 · two Skill Points to choose your path.\nA Bloomkeeper's wand is waiting in your gear."
	_text.add_theme_font_size_override("font_size",11)
	_text.modulate = Color("c2dfd0")
	column.add_child(_text)
	var row := HBoxContainer.new()
	column.add_child(row)
	_gear = _button(row,"See my wand",func():
		_acknowledge()
		region.equipment_screen.toggle()
		region.equipment_screen.select_item("grove_wand"))
	_skills = _button(row,"Choose my path",func():
		_acknowledge()
		region.waykeeper.screen.toggle())
	_dismiss = _button(row,"Later",_acknowledge)
	_card.hide()
func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 32
	button.add_theme_font_size_override("font_size",11)
	button.pressed.connect(action)
	button.gui_input.connect(func(event):
		if event is InputEventScreenTouch and event.pressed:
			button.pressed.emit()
			button.accept_event())
	parent.add_child(button)
	return button
func _acknowledge() -> void:
	region.story_flags.opening_reward_seen = true
	_card.hide()
	region._save_journey()
func _process(delta: float) -> void:
	_delay = maxf(0,_delay-delta)
	if _reward_delay>0:
		_reward_delay = maxf(0,_reward_delay-delta)
		if _reward_delay==0:
			region._level_toast.text = _pending_toast
			region._toast_left = 4.0
	var grove: bool = region.builder.entities.B1.get("restored",false)
	var spring: bool = region.builder.entities.C1.get("restored",false)
	beat = "homecoming" if not region.story_flags.has("mara_met") and not grove else "first_mend" if not grove else "first_growth" if not region.story_flags.has("opening_reward_seen") and not region.waykeeper.progress.unlocked.has("force") else "force_lesson" if not region.waykeeper.progress.unlocked.has("force") else "spring" if not spring else "return" if not region.story_flags.has("opening_return_seen") else "journey_continues"
	_card.visible = beat=="first_growth" and _delay<=0 and not region.equipment_screen.visible and not region.waykeeper.screen.visible and not region.journey_map.visible and not region.recovering and region.hero.global_position.distance_to(region.builder.entities.B1.runtime.global_position)<6.0
	var showcasing := false
	for id in ["B1","C1"]:
		if presentations[id].completing and region.hero.global_position.distance_to(region.builder.entities[id].runtime.global_position)<8: showcasing=true
	region.get_node("JourneyHUD/ObjectivePanel").visible = region.recovering or (not _card.visible and not showcasing and region.story.nearest==null)
	region._creature_steps.visible = not showcasing
	region._mend_bar.visible = not showcasing
	region._creature_panel.position.x = 20.0 if showcasing else 174.0
	if showcasing:
		region._creature_panel.position.y = 84.0
		region._creature_panel.size.y = region._creature_panel.get_combined_minimum_size().y
	# Free movement and optional menu choice; no forced pause, purchase or rerouting.
	if spring:
		for npc in get_tree().get_nodes_in_group("story_npc"):
			if npc.get_parent()==region and npc.npc_id=="mara": npc.work_at(Vector3(10.8,0,9.1),[Vector3(8.7,0,9.1)])
