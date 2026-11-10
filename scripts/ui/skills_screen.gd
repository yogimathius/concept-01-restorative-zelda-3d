class_name SkillsScreen
extends Control
## A connected touch-pannable watershed, plus compact technique loadouts.
var journey: WaykeeperJourney
var selected := "mend"
var selected_node := "living_pulse"
var _title: Label
var _body: Label
var _mastery: Label
var _select: Button
var _skills := {}
var _tree_buttons := {}
var _points: Label
var _node_title: Label
var _node_body: Label
var _node_requirements: Label
var _buy: Button
var _tree_view: Control
var _tech_view: Control
var _scroll: ScrollContainer
var _host: Control
var _tree_tab: Button
var _pan_index := -1
var _pan_at := Vector2.ZERO
var _panning := false
var _tech_tab: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = Vector2(600,330)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_host = self
	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("102b35")
	style.border_color = Color("cfb477")
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel",style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	_label("WAYKEEPER",Vector2(16,12),16,Color("f4dda4"))
	_points = _label("",Vector2(16,36),10,Color("b8e7cd"))
	_tree_tab = _button("TREE",Vector2(210,8),Vector2(82,40),show_tree)
	_tech_tab = _button("TECHNIQUES",Vector2(298,8),Vector2(150,40),show_techniques)
	_button("CLOSE ×",Vector2(482,8),Vector2(100,40),toggle)
	_label("Drag waterways · tap a node",Vector2(16,51),8,Color("b9daca"))
	_tree_view = Control.new()
	add_child(_tree_view)
	_host = _tree_view
	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(16,62)
	_scroll.size = Vector2(338,250)
	_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	_scroll.follow_focus = true
	_tree_view.add_child(_scroll)
	var map := SkillTreeMap.new()
	map.custom_minimum_size = Vector2(675,650)
	_scroll.add_child(map)
	_host = map
	for id in WaykeeperTree.NODES:
		var key: String = id
		_tree_buttons[id] = _button("",WaykeeperTree.NODES[id].pos,Vector2(112,54),func(): view_node(key))
	_label("WEAVER · connected water",Vector2(16,440),10,Color("87cde7"))
	_host = _tree_view
	_node_title = _label("",Vector2(369,62),15,Color("f4dda4"))
	_node_title.size = Vector2(212,40)
	_node_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_node_body = _label("",Vector2(369,104),12,Color("d4e8df"))
	_node_body.size = Vector2(212,92)
	_node_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_node_requirements = _label("",Vector2(369,201),10,Color("b9daca"))
	_node_requirements.size = Vector2(198,65)
	var requirements_scroll := ScrollContainer.new()
	requirements_scroll.position = Vector2(369,201)
	requirements_scroll.size = Vector2(213,65)
	requirements_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tree_view.add_child(requirements_scroll)
	_node_requirements.reparent(requirements_scroll)
	_node_requirements.position = Vector2.ZERO
	_node_requirements.custom_minimum_size.x = 198
	_node_requirements.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_buy = _button("",Vector2(369,274),Vector2(213,40),func():
		journey.buy_node(selected_node)
		refresh())
	_tech_view = Control.new()
	add_child(_tech_view)
	_host = _tech_view
	var i := 0
	for id in WaykeeperDefinitions.SKILLS:
		var key: String = id
		_skills[id] = _button("",Vector2(18,62+i*41),Vector2(178,38),func(): selected=key; refresh())
		i += 1
	_title = _label("",Vector2(215,66),17,Color("f4dda4"))
	_mastery = _label("",Vector2(215,97),11,Color("b9daca"))
	_body = _label("",Vector2(215,127),12,Color("d4e8df"))
	_body.size = Vector2(360,135)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_select = _button("",Vector2(215,274),Vector2(367,40),func(): journey.select(selected); refresh())
	journey.changed.connect(refresh)
	get_viewport().size_changed.connect(_layout)
	_layout()
	show_tree()
	hide()

func _layout() -> void:
	position = (get_viewport().get_visible_rect().size-size)*0.5

func show_tree() -> void:
	_pan_index = -1
	_tree_view.show()
	_tech_view.hide()
	_tree_tab.modulate = Color("ffe0a1")
	_tech_tab.modulate = Color.WHITE
	refresh()

func show_techniques() -> void:
	_pan_index = -1
	_tree_view.hide()
	_tech_view.show()
	_tree_tab.modulate = Color.WHITE
	_tech_tab.modulate = Color("ffe0a1")
	refresh()

func view_node(id: String) -> void:
	selected_node = id
	refresh()

func toggle() -> void:
	if visible:
		hide()
		get_tree().paused = false
		journey.region.get_node("TouchControls").show()
		journey.region.get_node("JourneyHUD").show()
		journey.region._save_journey()
		return
	var region := journey.region
	if region.equipment_screen.visible: region.equipment_screen.toggle()
	if region.journey_map.visible: region.journey_map.toggle(region.checkpoint_position)
	region.get_node("TouchControls").cancel_touch()
	region.get_node("TouchControls").hide()
	region.get_node("JourneyHUD").hide()
	get_tree().paused = true
	selected = journey.progress.active
	show_tree()
	_scroll.scroll_horizontal = 190
	refresh()
	show()

func refresh() -> void:
	if not is_instance_valid(_body): return
	var progress := journey.progress
	_points.text = "LEVEL %d · %d SKILL POINTS" % [progress.level,progress.skill_points()]
	for id in _tree_buttons:
		var node: Dictionary = WaykeeperTree.NODES[id]
		var learned: bool = progress.upgrades.has(id)
		var available: bool = progress.requirements(id).is_empty()
		var button: Button = _tree_buttons[id]
		button.text = node.name.replace(" ","\n")+"\n"+("LEARNED" if learned else ("%d POINTS" % node.cost if available else "LOCKED"))
		button.modulate = WaykeeperTree.COLORS[node.branch] if learned or available else Color("809a98")
		var frame := StyleBoxFlat.new()
		frame.bg_color = Color("23554e") if learned else Color("173b3b")
		frame.border_color = Color("f4dda4") if selected_node==id else (WaykeeperTree.COLORS[node.branch] if available or learned else Color("385854"))
		frame.set_border_width_all(2)
		frame.set_corner_radius_all(9)
		button.add_theme_stylebox_override("normal",frame)
	var info: Dictionary = WaykeeperTree.NODES[selected_node]
	_node_title.text = info.name
	_node_title.modulate = WaykeeperTree.COLORS[info.branch]
	_node_body.text = info.branch + "\n" + info.effect
	if selected_node=="undertow" and journey.gear_effect("force_stabilizes"):
		_node_body.text += "\nFerryman staff grants this while worn."
	var eligibility := progress.requirements(selected_node)
	var mastery_text := PackedStringArray()
	for skill in info.mastery: mastery_text.append("%s %d/%d" % [WaykeeperDefinitions.SKILLS[skill].name,progress.points(skill),info.mastery[skill]])
	_node_requirements.text = "%d Skill Points · %s\n%s" % [info.cost,"Mastery: "+" · ".join(mastery_text) if not mastery_text.is_empty() else "No mastery required","Ready to learn" if eligibility.is_empty() else "\n".join(eligibility)]
	_buy.disabled = not eligibility.is_empty()
	_buy.text = "LEARNED" if progress.upgrades.has(selected_node) else "LEARN · %d POINTS" % info.cost
	for id in _skills:
		_skills[id].text = "%s %s" % [WaykeeperDefinitions.SKILLS[id].name,"· %d" % progress.rank(id) if progress.unlocked.has(id) else "· seek teacher"]
		_skills[id].modulate = WaykeeperDefinitions.SKILLS[id].color if selected==id else Color.WHITE
	_title.text = WaykeeperDefinitions.SKILLS[selected].name + " · " + WaykeeperDefinitions.SKILLS[selected].verb
	_body.text = WaykeeperDefinitions.SKILLS[selected].description
	var definition: Dictionary = WaykeeperDefinitions.SKILLS[selected]
	if definition.has("flow_per_second"): _title.text += " · %d Flow/s" % definition.flow_per_second
	elif definition.has("flow_cost"): _title.text += " · %d Flow" % definition.flow_cost
	var known: bool = progress.unlocked.has(selected)
	_mastery.size = Vector2(360,28)
	_mastery.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_mastery.text = "Mastery %d · rank %d" % [progress.points(selected),progress.rank(selected)] if known else journey.teacher_hint(selected) if selected in ["force","anchor","weave","channel","bloom"] else "Future branch · not yet learnable"
	_body.text += "\n\nWarden and Weaver are traditions you can combine. Chosen capabilities live in the TREE."
	_select.disabled = not known or progress.active==selected
	_select.text = "ON YOUR MEDALLION" if progress.active==selected else ("EQUIP TECHNIQUE" if known else "TRADITION NOT YET LEARNED")

func _label(text: String, at: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size",font_size)
	label.modulate = color
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_host.add_child(label)
	return label

func _button(text: String, at: Vector2, dimensions: Vector2, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = dimensions
	button.add_theme_font_size_override("font_size",10)
	button.add_theme_color_override("font_color",Color("f4dda4"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("27534f")
	style.set_corner_radius_all(8)
	button.add_theme_stylebox_override("normal",style)
	button.pressed.connect(action)
	button.gui_input.connect(func(event: InputEvent):
		if event is InputEventScreenTouch and event.pressed:
			if not button.disabled: button.pressed.emit()
			button.accept_event())
	_host.add_child(button)
	return button

func _input(event: InputEvent) -> void:
	if not visible or not _tree_view.visible: return
	if event is InputEventScreenTouch:
		if event.pressed and Rect2(position+_scroll.position,_scroll.size-Vector2(14,14)).has_point(event.position):
			_pan_index = event.index
			_pan_at = event.position
			_panning = false
		elif not event.pressed and event.index == _pan_index:
			_pan_index = -1
			if _panning: get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _pan_index:
		var movement: Vector2 = event.position-_pan_at
		if _panning or movement.length()>6:
			_panning = true
			_scroll.scroll_horizontal -= roundi(movement.x)
			_scroll.scroll_vertical -= roundi(movement.y)
			_pan_at = event.position
			get_viewport().set_input_as_handled()
