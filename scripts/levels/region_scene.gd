extends Node3D
## Local restoration, anchor rollback and contextual journey guidance.
const CLASSES: Array[HeroClass] = [preload("res://data/classes/warden.tres"), preload("res://data/classes/weaver.tres")]
@onready var builder: RegionBuilder = $Builder
@onready var hero: Hero = $Hero
var checkpoint := {}
var checkpoint_position := Vector3.ZERO
var anchor_inside := false
var departure_reached := false
var recovering := false
var _guidance: Label
var _context: Label
var _objective_panel: PanelContainer
var _objective_hint: Label
var _objective_title := ""
var _objective_feedback := ""
var _objective_expanded := true
var _objective_time_left := 8.0
var _class_button: Button
var journey_map: JourneyMap
var journal := WaykeeperJournal.new()
var _creature_panel: PanelContainer
var _creature_title: Label
var _creature_steps: Label
var _mend_bar: ProgressBar
var _completion_left := 0.0
var _completed_id := ""
var _healing_count: Label
@export var region_id := "R1"
@export var persist_progress := true
var story_flags := {}
var opening: OpeningJourney
var story: StoryDirector
var valley_journey: ValleyJourney
var waykeeper: WaykeeperJourney
var weave_relay: WeaveRelay
var weave_relays := {}
var charge_circuit: ChannelCircuit
var bloom_growth: BloomGrowth
var correspondence: MarshCorrespondence
var _worlds := {}
var _effect_label: Label
@export var save_path := "user://restoration-journey.json"
var progression := RestorationProgression.new()
var inventory := RestorationInventory.new()
var economy := RestorationEconomy.new()
var renewal_world: RenewalWorld
var exchange: SettlementExchange
var equipment_screen: EquipmentScreen
var _gear_label: Label
var _gear_button: TouchScreenButton
var _level_label: Label
var _xp_label: Label
var _xp_bar: ColorRect
var _xp_fill: ColorRect
var _level_toast: Label
var _toast_left := 0.0
var _save_left := 0.0
var _journey_ready := false
var _last_saved_data := ""

func _ready() -> void:
	hero.respawn_at(builder.spawn)
	hero.failed.connect(_on_failed)
	hero.unmoored.connect(_on_unmoored)
	checkpoint_position = builder.spawn
	_make_guidance()
	if builder.restoration_only:
		waykeeper = WaykeeperJourney.new()
		waykeeper.region = self
		add_child(waykeeper)
		_load_journey()
	checkpoint = builder.capture_snapshot()
	_configure_restoration()
	builder.restored.connect(_on_creature_restored)
	_update_level_hud()
	_update_gear_hud()
	_journey_ready = true
	if builder.restoration_only:
		story = StoryDirector.new()
		story.region = self
		add_child(story)
		if region_id == "R2":
			for link in WeaveRelay.LINKS:
				var relay := WeaveRelay.new()
				relay.profile = link
				relay.region = self
				add_child(relay)
				weave_relays[link.id] = relay
			weave_relay = weave_relays.garden_nursery
			charge_circuit = ChannelCircuit.new()
			charge_circuit.region = self
			add_child(charge_circuit)
			bloom_growth = BloomGrowth.new()
			bloom_growth.region = self
			add_child(bloom_growth)
			correspondence = MarshCorrespondence.new()
			correspondence.region = self
			add_child(correspondence)
		renewal_world = RenewalWorld.new()
		renewal_world.region = self
		add_child(renewal_world)
		exchange = SettlementExchange.new()
		exchange.region = self
		add_child(exchange)
		hero.consumable_changed.connect(_configure_restoration)
		if region_id == "R1":
			opening = OpeningJourney.new()
			opening.region = self
			add_child(opening)
		if builder.valley_mode:
			valley_journey = ValleyJourney.new()
			valley_journey.region = self
			add_child(valley_journey)
			var hint := Label.new()
			hint.text = "VALLEY PREVIEW · drag clear world space to look · MAP shows trails"
			hint.position = Vector2(185,72)
			hint.add_theme_font_size_override("font_size",9)
			hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
			get_node("JourneyHUD").add_child(hint)

func _configure_restoration() -> void:
	hero.restoration_only = builder.restoration_only
	hero.touch_only = builder.restoration_only
	if not builder.restoration_only: return
	if waykeeper:
		waykeeper.progress.set_level(progression.get_level())
		hero.learned_nodes = waykeeper.progress.upgrades.duplicate()
		hero.resources.configure(hero.learned_nodes)
	var level := waykeeper.progress.rank("mend") if waykeeper else 1
	hero.restore_verb.reach = minf(8.0, 4.0 + 0.25 * (level - 1) + inventory.bonus("reach") + (1.5 if hero.tea_left > 0 else 0.0))
	hero.restore_verb.aim_dot = -1.0
	hero.restore_verb.rate = minf(1.25, 0.65 + 0.05 * (level - 1) + inventory.bonus("rate"))
	hero.restore_verb.movement = 1.0
	hero.apply_equipment(inventory.equipped, inventory.bonus("speed"))
	$HUD.show_resources()
	if hero.resources.stability <= 0 and not recovering: _on_unmoored()
	_class_button.hide()
	$TouchControls.simplify()

func _make_guidance() -> void:
	var layer := CanvasLayer.new()
	layer.name = "JourneyHUD"
	add_child(layer)
	var panel := PanelContainer.new()
	panel.name = "ObjectivePanel"
	panel.position = Vector2(350, 58) if builder.restoration_only else Vector2(16, 48)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.gui_input.connect(_on_objective_input)
	_objective_panel = panel
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.10, 0.14, 0.86)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	_guidance = Label.new()
	_guidance.add_theme_font_size_override("font_size", 12 if builder.restoration_only else 15)
	_guidance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_guidance.custom_minimum_size.x = 250 if builder.restoration_only else 0
	_guidance.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_guidance.modulate = Color(1, 0.88, 0.60)
	box.add_child(_guidance)
	_context = Label.new()
	_context.add_theme_font_size_override("font_size", 10 if builder.restoration_only else 12)
	_context.custom_minimum_size.x = 250 if builder.restoration_only else 310
	_context.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_context.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_context.modulate = Color(0.80, 0.89, 0.9)
	box.add_child(_context)
	_objective_hint = Label.new()
	_objective_hint.add_theme_font_size_override("font_size", 8)
	_objective_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_objective_hint.modulate = Color(0.70, 0.79, 0.80)
	_objective_hint.visible = builder.restoration_only
	box.add_child(_objective_hint)
	_class_button = Button.new()
	_class_button.position = Vector2(514, 16)
	_class_button.size = Vector2(110, 28)
	_class_button.add_theme_font_size_override("font_size", 13)
	_class_button.pressed.connect(swap_class)
	layer.add_child(_class_button)
	var map_layer := CanvasLayer.new()
	map_layer.layer = 10
	map_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(map_layer)
	journey_map = JourneyMap.new()
	journey_map.builder = builder
	journey_map.hero = hero
	map_layer.add_child(journey_map)
	journey_map.anchor = checkpoint_position
	var map_button := TouchScreenButton.new()
	map_button.name = "MapButton"
	map_button.process_mode = Node.PROCESS_MODE_ALWAYS
	map_button.texture_normal = load("res://assets/ui/map-button.svg")
	var map_label := Label.new()
	map_label.text = "MAP"
	map_label.position = Vector2(29, 7)
	map_label.add_theme_font_size_override("font_size", 10)
	map_label.modulate = Color(1, 0.94, 0.78)
	map_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_button.add_child(map_label)
	map_button.position = Vector2(get_viewport().get_visible_rect().size.x - 80, 16)
	var map_shape := RectangleShape2D.new()
	map_shape.size = Vector2(64, 44)
	map_button.shape = map_shape
	get_viewport().size_changed.connect(func(): map_button.position.x = get_viewport().get_visible_rect().size.x - 80)
	map_button.pressed.connect(func():
		if equipment_screen and equipment_screen.visible: equipment_screen.toggle()
		journey_map.toggle(checkpoint_position))
	layer.add_child(map_button)
	_make_equipment(layer, map_layer)
	var compass := JournalCompass.new()
	compass.region = self
	layer.add_child(compass)
	_healing_count = Label.new()
	_healing_count.position = Vector2(16, 66)
	_healing_count.add_theme_font_size_override("font_size", 14)
	_healing_count.modulate = Color(0.5, 1, 0.8)
	_healing_count.visible = builder.restoration_only
	layer.add_child(_healing_count)
	_level_label = Label.new()
	_level_label.position = Vector2(202, 15)
	_level_label.add_theme_font_size_override("font_size", 12)
	_level_label.modulate = Color(1, 0.9, 0.62)
	_level_label.add_theme_color_override("font_outline_color", Color(0.03, 0.1, 0.12))
	_level_label.add_theme_constant_override("outline_size", 2)
	_level_label.visible = builder.restoration_only
	layer.add_child(_level_label)
	_effect_label = Label.new()
	_effect_label.position = Vector2(202,42)
	_effect_label.add_theme_font_size_override("font_size",9)
	_effect_label.modulate = Color("bdf4b9")
	_effect_label.add_theme_color_override("font_outline_color",Color("102b35"))
	_effect_label.add_theme_constant_override("outline_size",3)
	_effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_effect_label)
	_xp_label = Label.new()
	_xp_label.position = Vector2(337, 17)
	_xp_label.add_theme_font_size_override("font_size", 10)
	_xp_label.modulate = Color(0.82, 0.95, 0.87)
	_xp_label.add_theme_color_override("font_outline_color", Color(0.03, 0.1, 0.12))
	_xp_label.add_theme_constant_override("outline_size", 2)
	_xp_label.visible = builder.restoration_only
	layer.add_child(_xp_label)
	_xp_bar = ColorRect.new()
	_xp_bar.position = Vector2(202, 34)
	_xp_bar.size = Vector2(204, 6)
	_xp_bar.color = Color(0.04, 0.10, 0.12, 0.85)
	_xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xp_fill = ColorRect.new()
	_xp_fill.color = Color(0.95, 0.77, 0.35)
	_xp_fill.size = Vector2(0, 6)
	_xp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xp_bar.add_child(_xp_fill)
	_xp_bar.visible = builder.restoration_only
	layer.add_child(_xp_bar)
	_level_toast = Label.new()
	_level_toast.position = Vector2(116, 153)
	_level_toast.size = Vector2(408, 68)
	_level_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_toast.add_theme_font_size_override("font_size", 13)
	_level_toast.modulate = Color(1, 0.9, 0.62)
	_level_toast.add_theme_color_override("font_outline_color", Color(0.03, 0.1, 0.12))
	_level_toast.add_theme_constant_override("outline_size", 3)
	_level_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_level_toast.hide()
	layer.add_child(_level_toast)
	_creature_panel = PanelContainer.new()
	_creature_panel.position = Vector2(174, 236)
	_creature_panel.custom_minimum_size.x = 266
	_creature_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_creature_panel.add_theme_stylebox_override("panel", style)
	layer.add_child(_creature_panel)
	var creature_box := VBoxContainer.new()
	_creature_panel.add_child(creature_box)
	_creature_title = Label.new()
	_creature_title.add_theme_font_size_override("font_size", 13)
	_creature_title.modulate = Color(1, 0.88, 0.60)
	creature_box.add_child(_creature_title)
	_creature_steps = Label.new()
	_creature_steps.add_theme_font_size_override("font_size", 11)
	_creature_steps.custom_minimum_size.x = 242
	_creature_steps.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	creature_box.add_child(_creature_steps)
	_mend_bar = ProgressBar.new()
	_mend_bar.custom_minimum_size.y = 18
	_mend_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.12, 0.7, 0.50)
	fill.set_corner_radius_all(4)
	_mend_bar.add_theme_stylebox_override("fill", fill)
	creature_box.add_child(_mend_bar)
	if not builder.restoration_only and not OS.has_feature("mobile"):
		var controls := Label.new()
		controls.position = Vector2(16, 338)
		controls.text = "WASD  Move     SHIFT  Dash     J / SPACE  Force     K / E  Mend     M  Map"
		if builder.restoration_only: controls.text = "WASD / ARROWS  Move     Hold SPACE / E / K  Mend     M  Map"
		controls.add_theme_font_size_override("font_size", 10)
		controls.modulate = Color(0.78, 0.9, 0.9, 0.9)
		controls.add_theme_color_override("font_outline_color", Color(0.04, 0.07, 0.10))
		controls.add_theme_constant_override("outline_size", 3)
		layer.add_child(controls)


func _make_equipment(layer: CanvasLayer, overlay: CanvasLayer) -> void:
	equipment_screen = EquipmentScreen.new()
	equipment_screen.hero = hero
	equipment_screen.inventory = inventory
	overlay.add_child(equipment_screen)
	equipment_screen.equipped.connect(func(_id: String):
		_configure_restoration()
		_update_gear_hud()
		_save_journey()
		Juice.sfx("anchor"))
	_gear_button = TouchScreenButton.new()
	_gear_button.name = "GearButton"
	_gear_button.process_mode = Node.PROCESS_MODE_ALWAYS
	_gear_button.texture_normal = load("res://assets/ui/gear-button.svg")
	var shape := RectangleShape2D.new()
	shape.size = Vector2(64,44)
	_gear_button.shape = shape
	_gear_label = Label.new()
	_gear_label.position = Vector2(27,7)
	_gear_label.add_theme_font_size_override("font_size", 9)
	_gear_label.modulate = Color("f4dda4")
	_gear_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gear_button.add_child(_gear_label)
	layer.add_child(_gear_button)
	_gear_button.position = Vector2(get_viewport().get_visible_rect().size.x-153,16)
	get_viewport().size_changed.connect(func(): _gear_button.position.x = get_viewport().get_visible_rect().size.x-153)
	_gear_button.pressed.connect(func(): equipment_screen.toggle.call_deferred())
	_gear_button.visible = builder.restoration_only

func _update_gear_hud() -> void:
	_gear_label.text = "GEAR" if inventory.unseen.is_empty() else "GEAR\n+%d" % inventory.unseen.size()

func swap_class() -> void:
	hero.apply_class(CLASSES[(CLASSES.find(hero.hero_class) + 1) % CLASSES.size()])
	_configure_restoration()

func _unhandled_input(event: InputEvent) -> void:
	if builder.restoration_only: return
	if event.is_action_pressed("debug_swap_class"): swap_class()
	elif event.is_action_pressed("debug_switch_scene"):
		get_tree().change_scene_to_file("res://scenes/test/feel_lab.tscn")

func _physics_process(delta: float) -> void:
	if recovering: return
	_completion_left = maxf(0, _completion_left - delta)
	_toast_left = maxf(0, _toast_left - delta)
	_level_toast.visible = _toast_left > 0
	_save_left -= delta
	if persist_progress and builder.restoration_only and _save_left <= 0:
		_save_journey()
		_save_left = 2.0
	_effect_label.text = "  ".join((["Scrip %d" % economy.scrip] if builder.restoration_only else []) + (["Tea %ds" % ceili(hero.tea_left)] if hero.tea_left>0 else []) + (["Cordial %ds" % ceili(hero.cordial_left)] if hero.cordial_left>0 else []))
	if region_id == "R1" and builder.entities["B1"].get("restored", false):
		var at: Vector3 = builder._center(builder.entities["A1"].cell)
		var inside := hero.global_position.distance_to(at) <= 1.1
		if inside and not anchor_inside:
			checkpoint_position = at + Vector3.UP * 0.02
			checkpoint = builder.capture_snapshot()
			Juice.wave(at + Vector3.UP * 0.06, 1.5, Color(1, 0.82, 0.4), 0.8)
			Juice.sfx("anchor")
		anchor_inside = inside
	if region_id == "R1" and not departure_reached and builder.entities["G2"].get("powered", false) and hero.global_position.x > 47.4:
		departure_reached = true
		checkpoint = builder.capture_snapshot()
		Juice.sfx("restore")
	_update_guidance()
	_update_objective_card(delta)
	_update_creature_panel()

func _on_objective_input(event: InputEvent) -> void:
	if not builder.restoration_only: return
	var tapped: bool = event is InputEventScreenTouch and event.pressed
	if event is InputEventMouseButton and not OS.has_feature("mobile"):
		tapped = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
	if not tapped: return
	_objective_expanded = not _objective_expanded
	_objective_time_left = 0.0
	_context.visible = _objective_expanded
	_objective_hint.text = "TAP TO HIDE" if _objective_expanded else "TAP FOR HINT"
	_objective_panel.accept_event()

func _update_objective_card(delta: float) -> void:
	if not builder.restoration_only: return
	var feedback: String = hero.restore_verb.feedback if hero.restore_verb else ""
	if _guidance.text != _objective_title or (not feedback.is_empty() and feedback != _objective_feedback):
		_objective_title = _guidance.text
		_objective_expanded = true
		_objective_time_left = 8.0
	elif _objective_expanded and _objective_time_left > 0.0:
		_objective_time_left -= delta
		if _objective_time_left <= 0.0: _objective_expanded = false
	_objective_feedback = feedback
	_context.visible = _objective_expanded
	_objective_hint.text = "TAP TO HIDE" if _objective_expanded else "TAP FOR HINT"

func _on_creature_restored(id: String) -> void:
	if builder._replaying: return
	_completed_id = id
	_completion_left = 3.0
	if not builder.restoration_only: return
	var discovery := inventory.discover(region_id + "/" + id)
	_update_gear_hud()
	var reward := progression.award(region_id + "/" + id)
	if reward.earned > 0:
		_toast_left = 3.0
		if reward.level > reward.before:
			_level_toast.text = "WAYKEEPER LEVEL %d\n+2 Skill Points · tap SKILLS to choose your path" % reward.level
			Juice.wave(hero.global_position + Vector3.UP * 0.2, 2.0, Color(1, 0.83, 0.35), 0.8)
			Juice.sfx("anchor")
		else:
			_level_toast.text = "+%d RESTORATION XP" % reward.earned
		_configure_restoration()
		_update_level_hud()
	if not discovery.is_empty():
		_level_toast.text += "\nFound " + RestorationInventory.ITEMS[discovery].name + " · tap GEAR"
		_toast_left = 4.5
	var loot := RestorationLoot.new()
	loot.item_id = discovery
	loot.hero = hero
	loot.position = builder.entities[id].runtime.global_position
	add_child(loot)
	if discovery.is_empty():
		_level_toast.text += "\nFound supplies + a travelling cup · tap PACK"
		_toast_left = 4.5
	if persist_progress: _save_journey()

func _on_care_reward(material_id: String, previous_level: int, seed_kind := "") -> void:
	_on_economy_changed(previous_level)
	_level_toast.text = "+2 %s · +1 scrip · +3 XP%s" % [material_id.replace("_"," ")," · +1 "+seed_kind if not seed_kind.is_empty() else ""]
	if progression.get_level()>previous_level: _level_toast.text += "\nWAYKEEPER LEVEL %d · new Skill Points" % progression.get_level()
	_toast_left = 3.5
	_save_journey()

func _on_economy_changed(previous_level: int) -> void:
	if progression.get_level()!=previous_level: _configure_restoration()
	_update_level_hud()
	if progression.get_level()>previous_level:
		_level_toast.text = "WAYKEEPER LEVEL %d · new Skill Points" % progression.get_level()
		_toast_left = 3.5

func _update_level_hud() -> void:
	var level := progression.get_level()
	_level_label.text = "LEVEL %d" % level
	_xp_label.text = "%d / %d XP" % [progression.xp - RestorationProgression.threshold(level), RestorationProgression.threshold(level + 1) - RestorationProgression.threshold(level)]
	_xp_fill.size.x = _xp_bar.size.x * progression.level_progress()

func _journey_data(active := "") -> Dictionary:
	var restored := []
	var partial := {}
	for id in builder.manifest.ENTITIES:
		var entry: Dictionary = builder.entities[id]
		if entry.get("restored",false): restored.append(id)
		elif entry.runtime.progress>0: partial[id] = entry.runtime.progress
	var at := hero.global_position
	_worlds[region_id] = {"restored":restored,"partial":partial,"position":[snappedf(at.x,0.001),0.02,snappedf(at.z,0.001)],"ecology":waykeeper.site_data() if waykeeper else {}}
	return {"version":5,"journal":journal.to_data(),"resources":hero.resources.to_data(),"skills":waykeeper.to_data() if waykeeper else {},"active_region":region_id if active.is_empty() else active,"worlds":_worlds.duplicate(true),"progression":progression.to_data(),"inventory":inventory.to_data(),"economy":economy.to_data(),"story":story_flags.duplicate(),"effects":{"tea":hero.tea_left,"cordial":hero.cordial_left}}

func _save_journey(active := "") -> void:
	if not persist_progress or not builder.restoration_only: return
	var serialized := JSON.stringify(_journey_data(active))
	if serialized == _last_saved_data: return
	var file := FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if file == null: return
	file.store_string(serialized)
	file.flush()
	file.close()
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(save_path+".tmp"),ProjectSettings.globalize_path(save_path))==OK: _last_saved_data = serialized

func _load_journey() -> void:
	var session := get_node_or_null("/root/JourneySession")
	if not builder.valley_mode and session and not session.pending.is_empty() and session.pending.active_region == region_id:
		var data: Dictionary = session.pending
		session.pending = {}
		persist_progress = session.persist
		save_path = session.save_path
		_apply_journey_data(data)
	elif persist_progress and FileAccess.file_exists(save_path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(save_path))
		if data is Dictionary: _apply_journey_data(data)

func _apply_journey_data(data: Dictionary) -> void:
	var version = data.get("version",0)
	if version != 1 and version != 2 and version != 3 and version != 4 and version != 5: return
	var saved_resources = data.get("resources",{})

	_worlds = data.get("worlds",{}).duplicate(true) if data.get("worlds",{}) is Dictionary else {}
	if data.version == 1: _worlds = {"R1":{"restored":data.get("restored",[]),"partial":data.get("partial",{}),"position":data.get("position",[])}}
	if data.get("progression",{}) is Dictionary: progression.apply_data(data.get("progression",{}))
	if data.get("inventory",{}) is Dictionary: inventory.apply_data(data.get("inventory",{}))
	if data.get("economy",{}) is Dictionary: economy.apply_data(data.get("economy",{}))
	var saved_story = data.get("story",{})
	if saved_story is Dictionary:
		for flag in ["mara_met","neri_met","daro_met","daro_link_started","daro_link_reward","bryn_channel_started","bryn_channel_reward","exchange_powered","neri_bloom_started","neri_bloom_reward","marsh_message","neri_letter","neri_reply_ready","neri_reply_sent","opening_reward_seen","opening_return_seen"]:
			if saved_story.get(flag,false) == true: story_flags[flag] = true
	# Old saves receive all previously earned gear exactly once, across both regions.
	for world_id in ["R1","R2"]:
		var spec: GDScript = Region1Manifest if world_id == "R1" else Region2Manifest
		var world_data = _worlds.get(world_id,{})
		if not world_data is Dictionary: continue
		var places = world_data.get("restored",[])
		if places is Array:
			for id in places:
				if id is String and spec.ENTITIES.has(id):
					progression.award(world_id+"/"+id)
					inventory.discover(world_id+"/"+id)
	var current = _worlds.get(region_id,{})
	if not current is Dictionary: return
	var saved_places = current.get("restored",[])
	if saved_places is Array:
		builder._replaying = true
		for id in saved_places:
			if id is String and builder.manifest.ENTITIES.has(id): builder.restore(id)
		builder._place_scenery()
		builder._replaying = false
	var partial = current.get("partial",{})
	if partial is Dictionary:
		for id in partial:
			if builder.manifest.ENTITIES.has(id) and not builder.entities[id].get("restored",false) and (partial[id] is float or partial[id] is int): builder.entities[id].runtime.progress = clampf(partial[id],0,1)
	var position = current.get("position",[])
	if position is Array and position.size()==3 and (position[0] is float or position[0] is int) and (position[2] is float or position[2] is int):
		var at := Vector3(position[0],builder.surface_height(Vector2(position[0],position[2]))+0.02,position[2])
		if builder.can_walk(Vector2i(floori(at.x),floori(at.z))): hero.respawn_at(at)
	if waykeeper:
		waykeeper.load_data(data,_worlds)
		hero.resources.configure(waykeeper.progress.upgrades)
	journal.apply_data(self,data.get("journal",{}))
	hero.resources.apply_data(saved_resources if saved_resources is Dictionary else {})
	var effects = data.get("effects",{})
	if effects is Dictionary:
		if effects.get("tea",0) is float or effects.get("tea",0) is int: hero.tea_left = clampf(effects.get("tea",0),0,30)
		if effects.get("cordial",0) is float or effects.get("cordial",0) is int: hero.cordial_left = clampf(effects.get("cordial",0),0,30)

	if valley_journey: valley_journey.sync(false)

func travel_to(destination: String) -> void:
	if builder.valley_mode:
		_context.text = "Valley prototype boundary. Reedglass remains in the main journey."
		return
	if destination not in ["R1","R2"] or destination == region_id: return
	if destination == "R2" and not builder.entities.get("C3",{}).get("restored",false): return
	var session := get_node("/root/JourneySession")
	session.pending = _journey_data(destination)
	session.persist = persist_progress
	session.save_path = save_path
	_save_journey(destination)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/levels/region%s.tscn" % destination.trim_prefix("R"))

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and _journey_ready: _save_journey()

func _update_creature_panel() -> void:
	_creature_panel.position.y = clampf(get_viewport().get_visible_rect().size.y - 14 - _creature_panel.size.y,100,236)
	if builder.restoration_only and waykeeper:
		if waykeeper.progress.active in ["channel","bloom"]:
			_creature_panel.hide()
			return
		if waykeeper.progress.active=="weave":
			for relay in weave_relays.values():
				if relay.ready() and relay.near_hero():
					_creature_panel.hide()
					return
	if _completion_left > 0 and hero.global_position.distance_to(builder.entities[_completed_id].runtime.global_position)<=6:
		_creature_panel.show()
		_creature_title.text = "RESTORED · 100%"
		_creature_steps.text = "Crossing created · the world is healing" if builder.entities[_completed_id].kind == "bearer" else "Friendly sparks now power the way forward"
		_mend_bar.value = 100
		if builder.restoration_only:
			_creature_steps.text = "Grove healed · a broad crossing has returned" if builder.entities[_completed_id].kind == "bearer" else "Spring healed · the waterway is opening"
		if region_id == "R2": _creature_steps.text = builder.entities[_completed_id].spec.title + " · life has returned"
		return
	var creature: RegionCreature
	var nearest := 6.0
	for n in hero.find_influenceables(nearest):
		if not n is RegionCreature: continue
		if n.restored and (n.ecology == null or not n.ecology.optional_available()): continue
		var distance := hero.global_position.distance_to(n.global_position)
		if distance < nearest:
			creature = n
			nearest = distance
	if hero.restore_verb.active and is_instance_valid(hero.restore_verb.target) and not hero.restore_verb.target.restored:
		creature = hero.restore_verb.target
	_creature_panel.visible = creature != null
	if creature == null: return
	var force_key := "J / SPACE" if not OS.has_feature("mobile") else "FORCE"
	var mend_key := "K / E" if not OS.has_feature("mobile") else "MEND"
	if builder.restoration_only:
		_creature_title.text = builder.entities[creature.id].spec.get("title","Withered grove" if creature.kind == "bearer" else "Silent spring")
		var remaining: float = (1.0 - creature.progress) / hero.restore_verb.rate
		_creature_steps.text = creature.ecology.status() if creature.ecology and (not creature.ecology.ready_to_restore() or creature.restored) else "Hold MEND to heal · %.1fs left\nYour progress stays if you let go" % remaining
		if creature.ecology: _creature_title.text = creature.ecology.profile.title
		if builder.valley_mode and (creature.ecology == null or creature.ecology.ready_to_restore()) and hero.global_position.distance_to(creature.global_position)>hero.restore_verb.reach:
			_creature_steps.text = "Move a little closer to connect\nYour restoration progress stays"
		_mend_bar.value = creature.progress * 100
		return
	_creature_title.text = "Stone Bearer · %d / 3 growths removed" % (3 - creature.growths) if creature.kind == "bearer" else "Spark Charger"
	if creature.kind == "bearer" and creature.growths > 0:
		var taps := creature.growths if hero.hero_class.display_name == "Warden" else creature.growths * 2 - creature._cracks
		_creature_steps.text = "1. Tap %s · %d more hits\nMend now would regrow stone" % [force_key, taps]
	elif creature.kind == "bearer" and creature.socket_choice().is_empty():
		_creature_steps.text = "2. Lead bare stone to an amber bridge notch"
	elif not creature.can_mend():
		_creature_steps.text = "1. Tap %s to interrupt, then hold %s" % [force_key, mend_key]
	else:
		var remaining: float = (1.0 - creature.progress) / hero.restore_verb.rate
		_creature_steps.text = "Hold %s continuously · %.1fs left\nStay in the green circle; release loses progress" % [mend_key, remaining]
	_mend_bar.value = creature.progress * 100

func _update_guidance() -> void:
	if recovering: return
	if builder.restoration_only:
		_update_healing_guidance()
		if waykeeper: waykeeper.update_guidance()
		return
	_class_button.text = hero.hero_class.display_name + " ↔"
	var keyboard := not OS.has_feature("mobile")
	var mend := "hold K / E to Mend" if keyboard else "hold MEND"
	_context.text = "WASD move · Shift dash · J / Space Force · " + mend if keyboard else "Move with the stick · Force breaks stone · Hold Mend to restore"
	if departure_reached:
		_guidance.text = "Broken Ford crossed · Reedglass Marsh lies ahead"
		_context.text = "The optional reed pocket remains yours to explore."
	elif not builder.entities["B1"].get("restored", false):
		_guidance.text = "Cross the broken ford"
		if hero.global_position.x < 16:
			_context.text = "Follow the path east. Force moves the practice stone."
		else:
			var bearer: RegionCreature = builder.entities["B1"].runtime
			_context.text = bearer.mend_status()
			if bearer.can_mend(): _context.text += " · " + mend
	elif checkpoint_position.x < 32:
		_guidance.text = "Follow the new bridge to the river marker"
		_context.text = "The golden ring beyond the ford secures your progress."
	elif not builder.entities["G1"].get("powered", false):
		_guidance.text = "Wake the signal court"
		_context.text = "Interrupt the Charger, then Mend." if hero.hero_class.display_name == "Warden" else "Hold Force to catch a spark; face the teal eye and release."
	elif not builder.entities["G2"].get("powered", false):
		_guidance.text = "Open the east spillway"
		_context.text = "Go south. The next Charger's restored fire powers the gate." if hero.hero_class.display_name == "Warden" else "Go south. Feed the east receiver with a caught spark."
	else:
		_guidance.text = "The spillway is open · head east"
		_context.text = "Restoring a creature brings color back and clears its nearby pool."
	if hero.restore_verb and not hero.restore_verb.feedback.is_empty():
		_context.text = hero.restore_verb.feedback

func _update_healing_guidance() -> void:
	if region_id == "R2":
		_update_marsh_guidance()
		return
	var count := 0
	for id in builder.manifest.ENTITIES:
		if builder.entities[id].get("restored", false): count += 1
	_healing_count.text = "%d / 6 places healed" % count
	var hold := "hold the MEND button"
	if not builder.entities["B1"].get("restored", false):
		_guidance.text = "Bring life back to the grove"
		_context.text = "Use the left stick to follow the path east. Near the withered tree, " + hold + "."
	elif not builder.entities["C1"].get("restored", false):
		_guidance.text = "Wake the quiet spring"
		_context.text = "Cross the new bridge, follow the path east, and Mend the dark spring."
	elif not builder.entities["C3"].get("restored", false):
		_guidance.text = "Let the water flow again"
		_context.text = "The passage is open. Head south, then east, to heal the next spring."
	elif count < 6:
		_guidance.text = "The waterway is healing"
		_context.text = "Explore south and west for three more places to heal, or follow the open path east."
	else:
		_guidance.text = "Life has returned to Broken Ford"
		_context.text = "All six places are healed. Enjoy the grove, then follow the waterway east."
	if not story_flags.has("mara_met") and not builder.entities["B1"].get("restored",false):
		_guidance.text = "A way home · meet Mara"
		_context.text = "Mara is beside the river marker. Walk near her and tap TALK, or follow the path east to start restoring."
	elif builder.entities["C3"].get("restored",false):
		_context.text = "Oren waits at the east landing. Tap TALK near him to travel into Reedglass Marsh."
	if hero.restore_verb and not hero.restore_verb.feedback.is_empty(): _context.text = hero.restore_verb.feedback

func _update_marsh_guidance() -> void:
	var count := 0
	for id in builder.manifest.ENTITIES:
		if builder.entities[id].get("restored",false): count += 1
	_healing_count.text = "%d / 6 places healed" % count
	if story_flags.has("marsh_message"):
		_guidance.text = "Lio's letter · a living waterway"
		_context.text = "Return to Neri in the western garden and share the letter. Explore for the remaining discoveries." if not story_flags.has("neri_letter") else "Neri has heard from Lio. Explore the marsh, brew with Daro, or return to the ford. Counterweight Orchard is the next chapter."
	elif not story_flags.has("neri_met"):
		_guidance.text = "When the marsh sings · meet Neri"
		_context.text = "Neri tends the western kitchen garden. Walk near her and tap TALK."
	elif not builder.entities.M1.get("restored",false):
		_guidance.text = "Bring back Neri's kitchen garden"
		_context.text = "Follow the path east from Neri. Hold MEND near the dark garden bed."
	elif not builder.entities.M2.get("restored",false):
		_guidance.text = "Let the reed nursery sing"
		_context.text = "Cross the northern path east. Force opens the nursery feed; then Mend the reeds. Partial healing stays."
	elif not builder.entities.M3.get("restored",false):
		_guidance.text = "Wake the silent sluice bell"
		_context.text = "Follow the eastern path south. Anchor steadies the bell foundation; then Mend it to bring back its tone."
	else:
		_guidance.text = "The bell answers · find Oren"
		_context.text = "Speak to Oren by the southeast bell. A message has arrived in the reopened waterway."
	if builder.entities.M1.get("restored",false) and not builder.entities.M2.get("restored",false) and not waykeeper.progress.unlocked.has("force"):
		_guidance.text = "Neri knows the nursery feed · learn Force"
		_context.text = "Return to Neri by the western garden. Tap TALK to learn how to open the nursery channel."
	elif builder.entities.M2.get("restored",false) and not builder.entities.M3.get("restored",false) and not waykeeper.progress.unlocked.has("anchor"):
		_guidance.text = "Oren knows the bell · learn Anchor"
		_context.text = "Find Oren in the southeast court. Tap TALK to learn how to give the bell a steady foundation."
	if builder.entities.M1.get("restored",false) and builder.entities.M2.get("restored",false) and not builder.entities.M1.runtime.ecology.states.linked:
		_context.text += " Neri can also teach Weave to link her garden relays."
	if hero.restore_verb and not hero.restore_verb.feedback.is_empty(): _context.text = hero.restore_verb.feedback

func _on_failed() -> void:
	if recovering: return
	recovering = true
	_completion_left = 0
	_guidance.text = "Return to the river marker"
	await get_tree().create_timer(0.8, true, false, true).timeout
	builder.rollback(checkpoint)
	hero.restore_hearts()
	hero.respawn_at(checkpoint_position)
	anchor_inside = true
	recovering = false

func _on_unmoored() -> void:
	if recovering or not builder.restoration_only: return
	recovering = true
	$TouchControls.cancel_touch()
	$TouchControls.hide()
	_guidance.text = "Unmoored · the waterway holds you"
	_context.text = "Returning to the river marker. Everything you restored stays."
	_objective_expanded = true
	_objective_time_left = 8.0
	_context.show()
	await get_tree().create_timer(0.8, false).timeout
	hero.respawn_at(checkpoint_position)
	hero.gauge.clear_all()
	hero.resources.recover()
	$TouchControls.show()
	anchor_inside = true
	recovering = false
	if waykeeper: waykeeper._message("Grounded again · your restoration and discoveries remain")
	_save_journey()
