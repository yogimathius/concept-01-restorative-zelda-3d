class_name EquipmentScreen
extends Control
## A touch wardrobe with a live rigged character preview and explicit equip.
signal equipped(id: String)
signal pack_requested
var _page := 0
var _page_label: Label
var _prev: Button
var _next: Button
var hero: Hero
var inventory: RestorationInventory
var selected_slot := "tool"
var selected_id := "wayfarer_wand"
var _title: Label
var _supplies: Label
var _details: Label
var _equip: Button
var _cards: Array[Button] = []
var _tabs: Array[Button] = []
var _preview: SubViewport
var _model: Node3D
var _angle := 0.0
var _target_angle := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	var background := Panel.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.add_theme_stylebox_override("panel", _style(Color("102b35"), Color("7caa9c")))
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	_title = _label("YOUR RESTORATION GEAR", Vector2(22,14), 17, Color("f4dda4"))
	_supplies = _label("", Vector2(22,38), 11, Color("b7dccc"))
	var close := _button("CLOSE ×", Vector2(485,10), Vector2(96,44))
	close.pressed.connect(toggle)
	var pack := _button("PACK",Vector2(381,10),Vector2(92,44))
	pack.pressed.connect(func(): pack_requested.emit())
	var view := SubViewportContainer.new()
	view.position = Vector2(18,70)
	view.size = Vector2(420,392)
	view.scale = Vector2(0.5,0.5)
	view.stretch = false
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(view)
	_preview = SubViewport.new()
	_preview.size = Vector2i(420,392)
	_preview.own_world_3d = true
	_preview.msaa_3d = Viewport.MSAA_4X
	_preview.transparent_bg = true
	_preview.render_target_update_mode = SubViewport.UPDATE_DISABLED
	view.add_child(_preview)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.82
	camera.position = Vector3(0,1.0,2.4)
	_preview.add_child(camera)
	camera.look_at(Vector3(0,0.83,0))
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b3d9df")
	environment.environment.ambient_light_energy = 0.42
	_preview.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35,-25,0)
	light.light_energy = 1.1
	_preview.add_child(light)
	var turn := _button("TURN HERO ↻", Vector2(38,271), Vector2(172,40))
	turn.pressed.connect(func(): _target_angle += PI)
	for i in RestorationInventory.SLOTS.size():
		var slot: String = RestorationInventory.SLOTS[i]
		var tab := _button(slot.to_upper(), Vector2(246+i*113,64), Vector2(105,42))
		tab.pressed.connect(func(): select_slot(slot))
		_tabs.append(tab)
	for i in 3:
		var card := _button("", Vector2(246,110+i*46), Vector2(331,42))
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.add_theme_font_size_override("font_size", 12)
		card.add_theme_constant_override("outline_size", 0)
		_cards.append(card)
	_prev = _button("‹",Vector2(246,249),Vector2(40,24))
	_next = _button("›",Vector2(537,249),Vector2(40,24))
	_page_label = _label("",Vector2(299,254),10,Color("b7dccc"))
	_prev.pressed.connect(func(): _page -= 1; refresh())
	_next.pressed.connect(func(): _page += 1; refresh())
	_details = _label("", Vector2(246,274), 11, Color("b7dccc"))
	_details.size = Vector2(190,38)
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_equip = _button("EQUIP", Vector2(450,274), Vector2(127,44))
	_equip.pressed.connect(func():
		if inventory.equip(selected_id):
			equipped.emit(selected_id)
			refresh())
	get_viewport().size_changed.connect(_layout)
	_layout()
	hide()

func _layout() -> void:
	size = Vector2(600,330)
	position = (get_viewport().get_visible_rect().size-size)*0.5

func toggle() -> void:
	var opening := not visible
	if opening:
		if hero.get_parent().waykeeper and hero.get_parent().waykeeper.screen.visible: hero.get_parent().waykeeper.screen.toggle()
		var map = hero.get_parent().journey_map
		if map.visible: map.toggle(map.anchor)
		var controls := hero.get_parent().get_node("TouchControls")
		controls.cancel_touch()
		controls.hide()
		hero._interrupt_verbs()
		hero.move_input = Vector2.ZERO
		get_tree().paused = true
		for name in ["GearButton", "MapButton", "SkillsButton"]: hero.get_parent().get_node("JourneyHUD/"+name).hide()
		show()
		_preview.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		var newest := inventory.unseen
		select_slot(RestorationInventory.ITEMS[newest[-1]].slot if not newest.is_empty() else selected_slot)
		if not newest.is_empty(): select_item(newest[-1])
	else:
		hide()
		_preview.render_target_update_mode = SubViewport.UPDATE_DISABLED
		get_tree().paused = false
		for name in ["GearButton", "MapButton", "SkillsButton"]: hero.get_parent().get_node("JourneyHUD/"+name).show()
		hero.get_parent().get_node("TouchControls").show()

func select_slot(slot: String) -> void:
	_page = 0
	selected_slot = slot
	selected_id = inventory.equipped[slot]
	_target_angle = PI + 0.3 if slot == "cloak" else 0.3
	refresh()

func select_item(id: String) -> void:
	if not RestorationInventory.ITEMS.has(id): return
	if RestorationInventory.ITEMS[id].slot != selected_slot: select_slot(RestorationInventory.ITEMS[id].slot)
	selected_id = id
	var ids: Array = []
	for key in RestorationInventory.ITEMS:
		if RestorationInventory.ITEMS[key].slot == selected_slot: ids.append(key)
	_page = ids.find(id) / 3
	refresh()

func refresh() -> void:
	_supplies.text = "%d seeds   ·   %d river crystals   ·   %d / %d pieces found" % [inventory.seeds, inventory.crystals, inventory.owned.size(), RestorationInventory.ITEMS.size()]
	for i in _tabs.size(): _tabs[i].modulate = Color("f4dda4") if RestorationInventory.SLOTS[i] == selected_slot else Color.WHITE
	var ids: Array[String] = []
	for id in RestorationInventory.ITEMS:
		if RestorationInventory.ITEMS[id].slot == selected_slot: ids.append(id)
	_page = clampi(_page,0,(ids.size()-1)/3)
	_prev.disabled = _page == 0
	_next.disabled = (_page+1)*3 >= ids.size()
	_prev.visible = ids.size() > 3
	_next.visible = ids.size() > 3
	_page_label.text = "Page %d / %d" % [_page+1,ceili(float(ids.size())/3)] if ids.size()>3 else ""
	for i in _cards.size():
		_cards[i].visible = _page*3+i < ids.size()
		if not _cards[i].visible: continue
		var id := ids[_page*3+i]
		var item: Dictionary = RestorationInventory.ITEMS[id]
		var card := _cards[i]
		for connection in card.pressed.get_connections(): card.pressed.disconnect(connection.callable)
		var is_owned := inventory.owned.has(id)
		var tag := "WORN" if inventory.equipped[selected_slot] == id else ("NEW" if inventory.unseen.has(id) else "")
		card.text = "  %s %s\n  %s" % [item.name, "· " + tag if tag != "" else "", item.effect if is_owned else item.source]
		card.disabled = not is_owned
		card.modulate = Color("f4dda4") if id == selected_id else Color.WHITE
		card.pressed.connect(func(): select_item(id))
	var worn: bool = inventory.equipped[selected_slot] == selected_id
	_equip.disabled = worn
	_equip.text = "EQUIPPED" if worn else "EQUIP"
	_details.text = "Wearing this piece" if worn else "Preview · replaces your\n" + RestorationInventory.ITEMS[inventory.equipped[selected_slot]].name
	_rebuild_preview()

func _rebuild_preview() -> void:
	if is_instance_valid(_model): _model.free()
	_model = hero.hero_class.model.instantiate()
	_preview.add_child(_model)
	ToonUtil.apply_toon(_model, Hero.TOON_MATERIAL)
	var choices := inventory.equipped.duplicate()
	choices[selected_slot] = selected_id
	GearVisuals.apply(_model, choices)
	_model.rotation.y = _angle
	var animation := _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if animation: animation.play("idle")

func _process(delta: float) -> void:
	if not visible or not is_instance_valid(_model): return
	_angle = lerp_angle(_angle, _target_angle, minf(1, delta*8))
	_model.rotation.y = _angle

func _button(text: String, at: Vector2, dimensions: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = dimensions
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color("edf3dc"))
	button.add_theme_color_override("font_disabled_color", Color("82968f"))
	button.add_theme_stylebox_override("normal", _style(Color("1d4149"), Color("47756f")))
	button.add_theme_stylebox_override("hover", _style(Color("29565b"), Color("ddbf76")))
	button.add_theme_stylebox_override("pressed", _style(Color("397168"), Color("f4dda4")))
	button.add_theme_stylebox_override("disabled", _style(Color("182f38"), Color("304c51")))
	button.gui_input.connect(func(event: InputEvent):
		if event is InputEventScreenTouch and event.pressed:
			if not button.disabled: button.pressed.emit()
			button.accept_event())
	add_child(button)
	return button

func _label(text: String, at: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.modulate = color
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _style(color: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	return style
