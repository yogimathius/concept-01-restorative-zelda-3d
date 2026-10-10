class_name JournalScreen
extends Control
## Discovered places, generous touch rows and explicit pin/equip actions.
signal map_requested
signal close_requested
var region: Node3D
var selected := ""
var _mode := "places"
var _rows: VBoxContainer
var _scroll: ScrollContainer
var _details_scroll: ScrollContainer
var _active_scroll: ScrollContainer
var _title: Label
var _body: Label
var _count: Label
var _pin: Button
var _technique: Button
var _cards := {}
var _places_tab: Button
var _care_tab: Button
var _gesture := -1
var _start := Vector2.ZERO
var _scroll_start := 0
var _dragged := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = Vector2(600,330)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var panel := Panel.new()
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel",_style(Color("102b35")))
	add_child(panel)
	_label("WAYKEEPER JOURNAL",Vector2(16,12),Vector2(320,25),16)
	_count = _label("",Vector2(16,38),Vector2(350,20),10)
	_places_tab = _button("PLACES",Vector2(16,60),Vector2(100,34),func(): _show_mode("places"))
	_care_tab = _button("CARE",Vector2(122,60),Vector2(100,34),func(): _show_mode("care"))
	_button("MAP",Vector2(374,8),Vector2(90,44),func(): map_requested.emit())
	_button("CLOSE ×",Vector2(482,8),Vector2(100,44),func(): close_requested.emit())
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(16,102)
	_scroll.size = Vector2(226,212)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_rows = VBoxContainer.new()
	_rows.custom_minimum_size.x = 212
	_rows.add_theme_constant_override("separation",8)
	_scroll.add_child(_rows)
	_title = _label("",Vector2(260,66),Vector2(320,38),15)
	_details_scroll = ScrollContainer.new()
	_details_scroll.position = Vector2(260,110)
	_details_scroll.size = Vector2(320,154)
	_details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_details_scroll)
	_body = Label.new()
	_body.custom_minimum_size.x = 300
	_body.add_theme_font_size_override("font_size",11)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_details_scroll.add_child(_body)
	_pin = _button("PIN PLACE",Vector2(260,272),Vector2(152,44),_toggle_pin)
	_technique = _button("",Vector2(422,272),Vector2(160,44),_ready_technique)
	hide()

func _show_mode(value: String) -> void:
	_mode = value
	selected = ""
	refresh()

func refresh() -> void:
	for child in _rows.get_children(): child.free()
	_cards.clear()
	var entries: Array[Dictionary] = region.journal.care_entries(region) if _mode=="care" else region.journal.entries(region)
	_count.text = "%d %s · tap to inspect" % [entries.size(),"care sites" if _mode=="care" else "places and requests"]
	_places_tab.modulate = Color("f4dda4") if _mode=="places" else Color.WHITE
	_care_tab.modulate = Color("f4dda4") if _mode=="care" else Color.WHITE
	var keys := PackedStringArray()
	for entry in entries: keys.append(entry.id)
	if not keys.has(selected): selected = region.journal.pinned if keys.has(region.journal.pinned) else (entries[0].id if not entries.is_empty() else "")
	for entry in entries:
		var key: String = entry.id
		var card := Button.new()
		card.custom_minimum_size = Vector2(212,68)
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.add_theme_font_size_override("font_size",10)
		card.add_theme_stylebox_override("normal",_style(Color("1d4149")))
		card.text = "%s\n%s\n%s" % [entry.title,entry.status,WaykeeperJournal.region_name(entry.region)] if entry.get("kind","")=="care" else "%s\n%s · %d%%\n%s" % [entry.title,entry.status,roundi(entry.progress*100),WaykeeperJournal.region_name(entry.region)]
		card.mouse_filter = Control.MOUSE_FILTER_PASS
		card.pressed.connect(func(): select_place(key))
		# Commit on release, so a finger scrolling the list cannot select a row.
		card.gui_input.connect(func(event: InputEvent):
			if event is InputEventScreenTouch and not event.pressed and not _dragged: select_place(key); card.accept_event())
		_rows.add_child(card)
		_cards[key] = card
	select_place(selected)

func select_place(key: String) -> void:
	var entry: Dictionary = region.journal.observe(region,key)
	if entry.is_empty():
		_title.text = "Living care" if _mode=="care" else "No places discovered"
		_body.text = "Restore a place to reveal the small care it may need later." if _mode=="care" else "Explore and speak with the people here to discover places."
		_pin.disabled = true
		_technique.disabled = true
		_pin.text = "PIN PLACE"
		_technique.text = "READY MEND"
		return
	selected = key
	_details_scroll.scroll_vertical = 0
	for id in _cards: _cards[id].modulate = Color("f4dda4") if id == selected else Color.WHITE
	_title.text = entry.title
	var reward: String = entry.get("reward_text","") if entry.get("kind","") in ["quest","care"] else RestorationInventory.ITEMS[entry.reward].name if not entry.reward.is_empty() else "Travelling supplies"
	var reward_label := "Yield" if entry.get("kind","")=="care" else "Reward" if entry.get("kind","")=="quest" else "Found" if entry.restored else "Discovery"
	var lesson: String = "" if entry.done or entry.unlocked else "\n" + region.waykeeper.teacher_hint(entry.skill)
	_body.text = "%s\n\n%s%s\n\n%s\n\n%s: %s" % [entry.status,entry.steps,lesson,entry.benefit,reward_label,reward]
	_pin.text = "UNPIN" if region.journal.pinned == selected else "PIN PLACE"
	_pin.disabled = entry.done and region.journal.pinned != selected
	_technique.text = "RECOVERING" if entry.get("kind","")=="care" and not entry.actionable else "QUEST COMPLETE" if entry.done and entry.get("kind","")=="quest" else "RESTORED" if entry.done else "RETURN TO " + str(entry.get("return_to","NPC")).to_upper() if not entry.get("actionable",true) else ("READY " + WaykeeperDefinitions.SKILLS[entry.skill].name.to_upper() if entry.unlocked else "LEARN " + WaykeeperDefinitions.SKILLS[entry.skill].name.to_upper())
	_technique.disabled = entry.done or not entry.unlocked or not entry.local or not entry.get("actionable",true)

func _toggle_pin() -> void:
	if region.journal.pinned == selected: region.journal.pinned = ""
	else: region.journal.pin(region,selected)
	region._save_journey()
	select_place(selected)

func _ready_technique() -> void:
	var entry: Dictionary = region.journal.observe(region,selected)
	if entry.is_empty() or entry.done or not entry.local or not entry.unlocked or not entry.get("actionable",true): return
	region.waykeeper.select(entry.skill)
	close_requested.emit()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree(): return
	if event is InputEventScreenTouch:
		if event.pressed:
			for container in [_scroll,_details_scroll]:
				if not container.get_global_rect().has_point(event.position): continue
				_active_scroll = container
				_gesture = event.index
				_start = event.position
				_scroll_start = container.scroll_vertical
				_dragged = false
		elif not event.pressed and event.index == _gesture:
			_gesture = -1
			if _dragged: get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _gesture:
		if absf(event.position.y-_start.y)>8: _dragged = true
		if _dragged:
			_active_scroll.scroll_vertical = _scroll_start+roundi(_start.y-event.position.y)
			get_viewport().set_input_as_handled()

func _button(text: String, at: Vector2, dimensions: Vector2, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = dimensions
	button.add_theme_font_size_override("font_size",11)
	button.add_theme_stylebox_override("normal",_style(Color("1d4149")))
	button.pressed.connect(action)
	button.gui_input.connect(func(event: InputEvent):
		if event is InputEventScreenTouch and not event.pressed:
			if not button.disabled: action.call()
			button.accept_event())
	add_child(button)
	return button

func _label(text: String, at: Vector2, dimensions: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size = dimensions
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size)
	label.modulate = Color("f4dda4")
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("7caa9c")
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	return style
