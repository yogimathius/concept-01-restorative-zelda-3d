class_name JourneyMap
extends Control
## The map reports actual bridges, local color and gate state. Borrowed
## fire can open a gold route inside a still-corrupted area.

var builder: RegionBuilder
var hero: Hero
var anchor := Vector3.ZERO
var journal_screen: JournalScreen
var _journal_button: Button
const ORIGIN := Vector2(18, 62)
const TILE := 6.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	position = Vector2(110, 38)
	size = Vector2(420, 284)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_journal_button = Button.new()
	_journal_button.text = "JOURNAL"
	_journal_button.position = Vector2(290,238)
	_journal_button.size = Vector2(112,40)
	_journal_button.add_theme_font_size_override("font_size",11)
	_journal_button.pressed.connect(show_journal)
	_journal_button.gui_input.connect(func(event: InputEvent):
		if event is InputEventScreenTouch and not event.pressed: show_journal(); _journal_button.accept_event())
	add_child(_journal_button)
	journal_screen = JournalScreen.new()
	journal_screen.region = hero.get_parent()
	journal_screen.map_requested.connect(show_map)
	journal_screen.close_requested.connect(func(): toggle(anchor))
	add_child(journal_screen)
	get_viewport().size_changed.connect(_layout)
	_layout()
	hide()

func _layout() -> void:
	size = Vector2(600,330) if journal_screen.visible else Vector2(420,284)
	position = (get_viewport().get_visible_rect().size-size)*0.5
	queue_redraw()

func show_journal() -> void:
	journal_screen.show()
	_journal_button.hide()
	journal_screen.refresh()
	_layout()

func show_map() -> void:
	journal_screen.hide()
	_journal_button.visible = builder.restoration_only
	_layout()

func toggle(checkpoint: Vector3) -> void:
	anchor = checkpoint
	visible = not visible
	get_tree().paused = visible
	var gear := hero.get_parent().get_node_or_null("JourneyHUD/GearButton")
	if gear: gear.visible = not visible
	var skills := hero.get_parent().get_node_or_null("JourneyHUD/SkillsButton")
	if skills: skills.visible = not visible
	if visible:
		show_map()
		var controls := hero.get_parent().get_node_or_null("TouchControls")
		if controls:
			controls.cancel_touch()
			controls.hide()
		hero._interrupt_verbs()
		hero.move_input = Vector2.ZERO
		for action in ["move_left", "move_right", "move_up", "move_down", "force", "restore"]:
			Input.action_release(action)
		var stick := hero.get_parent().get_node_or_null("TouchControls/Virtual Joystick")
		if stick: stick._reset()
		queue_redraw()
	else:
		var controls := hero.get_parent().get_node_or_null("TouchControls")
		if controls: controls.show()

func _input(event: InputEvent) -> void:
	if hero.touch_only: return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_M:
		var checkpoint: Vector3 = hero.get_parent().checkpoint_position
		toggle(checkpoint)
		get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if journal_screen.visible: return
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		if event.position.x > 372 and event.position.y < 40:
			toggle(anchor)

func _dot(at: Vector3, color: Color, radius := 3.0) -> void:
	draw_circle(_map_point(Vector2(at.x,at.z)), radius, color)

func _map_point(at: Vector2) -> Vector2:
	if builder.valley_mode: return Vector2(18,62)+(at-RiverValley.BOUNDS.position)*Vector2(370,154)/RiverValley.BOUNDS.size
	return ORIGIN+at*TILE

func _draw_valley() -> void:
	for x in range(-18,94,2):
		for z in range(-40,52,2):
			var at := Vector2(x,z)
			var color: Color = builder.valley._color(at).lightened(RiverValley.height_at(at)*0.025)
			if x>=24 and x<27 and z<12: color = Color("73cfb8") if builder.valley.walkable(at) else Color("3b8991")
			draw_rect(Rect2(_map_point(at),Vector2(7,4)),color)
	for route in [RiverValley.LOW_ROUTE,RiverValley.HIGH_ROUTE,RiverValley.UPPER_ROUTE,ValleyPlaces.SOUTH_ROUTE,ValleyPlaces.SUNLEAF_ROUTE]:
		for i in range(route.size()-1): draw_line(_map_point(route[i]),_map_point(route[i+1]),Color("c3b38a"),2)
	for i in range(ValleyPlaces.WATER_ROUTE.size()-1): draw_line(_map_point(ValleyPlaces.WATER_ROUTE[i]),_map_point(ValleyPlaces.WATER_ROUTE[i+1]),Color("70c9b5") if builder.entities.C3.get("restored",false) else Color("a5a895"),2)
	var font := ThemeDB.fallback_font
	draw_string(font,_map_point(ValleyPlaces.LANDING)+Vector2(-8,12),"Landing",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("f4dda4"))
	draw_string(font,_map_point(RiverValley.OVERLOOK)+Vector2(-20,-5),"Overlook",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("f4dda4"))
	draw_string(font,_map_point(RiverValley.LANDMARK)+Vector2(-20,-5),"Upper weir",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("8ce1de"))

func _draw() -> void:
	if journal_screen != null and journal_screen.visible: return
	var font := ThemeDB.fallback_font
	draw_style_box(_background(), Rect2(Vector2.ZERO, size))
	draw_string(font, Vector2(18, 28), "THE BROKEN WATERWAY", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(0.95, 0.85, 0.64))
	draw_string(font, Vector2(389, 28), "×", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.85, 0.9, 0.9))
	draw_string(font, Vector2(18, 48), ("RIVER VALLEY · PROTOTYPE" if builder.valley_mode else ("REEDGLASS MARSH" if builder.region_id == "R2" else "BROKEN FORD")), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.7, 0.84, 0.83))
	if builder.valley_mode: _draw_valley()
	for c in ([] if builder.valley_mode else builder.level.cells()):
		var color := Color(0.30, 0.31, 0.38)
		if c.ch == "," or builder._restored_cells.has(c.cell): color = Color(0.31, 0.65, 0.53)
		if c.ch == "#": color = Color(0.13, 0.19, 0.23)
		if c.ch == "_": color = Color(0.08, 0.13, 0.18) if not builder._bridged(c.cell) else Color(0.45, 0.91, 0.8)
		if c.ch == "~" and not builder._restored_cells.has(c.cell): color = Color(0.64, 0.35, 0.63)
		draw_rect(Rect2(ORIGIN + Vector2(c.cell) * TILE, Vector2.ONE * TILE), color)
	for id in ([] if builder.valley_mode else builder.manifest.GATES.keys()):
		var gate: Dictionary = builder.entities[id]
		for cell in gate.cells:
			draw_rect(Rect2(ORIGIN + Vector2(cell) * TILE, Vector2.ONE * TILE), Color(0.97, 0.81, 0.42) if gate.get("powered", false) else Color(0.52, 0.39, 0.31))
	for id in builder.manifest.ENTITIES:
		var e: Dictionary = builder.entities[id]
		if builder.valley_mode and not e.get("restored",false) and e.runtime.ecology and not e.runtime.ecology.states.seen: continue
		if e.get("restored",false) and e.runtime.ecology and e.runtime.ecology.optional_available():
			_dot(e.runtime.global_position,Color("81e5bd"),4)
		if not e.get("restored", false):
			var ecological: RestorationSite = e.runtime.ecology
			_dot(e.runtime.global_position, Color("c8b5ff") if ecological and ecological.states.seen and not ecological.ready_to_restore() else Color(0.9, 0.51, 0.4), 3)
		elif builder.restoration_only and hero.get_parent().renewal_world and hero.get_parent().economy.patches.get(id,{}).get("cooldown",0.0)<=0:
			var care: Node3D = hero.get_parent().renewal_world.get_node_or_null("Care_"+id)
			if care: _dot(care.global_position,Color("a9dfaa"),2)
	_dot(anchor, Color(1, 0.81, 0.4), 4)
	_dot(hero.global_position, Color(0.93, 1, 1), 3)
	var pinned: Dictionary = hero.get_parent().journal.observe(hero.get_parent(),hero.get_parent().journal.pinned)
	if not pinned.is_empty() and pinned.local and not pinned.done:
		var at: Vector2 = _map_point(Vector2(pinned.at.x,pinned.at.z))
		draw_arc(at,7,0,TAU,24,Color("f4dda4"),2)
	draw_string(font, Vector2(18, 232), "You  ·  white       Anchor  ·  gold       Bridge  ·  teal", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.72, 0.86, 0.87))
	draw_string(font, Vector2(18, 252), "Warm: wounded · violet: return later · green: care" if builder.restoration_only else "Grey terrain can contain an open route.", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.72, 0.86, 0.87))
	for npc in get_tree().get_nodes_in_group("story_npc"):
		if npc.get_parent() == hero.get_parent(): _dot(npc.global_position,Color("ffe0a4"),3)
	if builder.region_id == "R2":
		draw_string(font,Vector2(232,90),"NERI · west garden",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffe0a4"))
		draw_string(font,Vector2(232,110),"DARO · southwest",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffe0a4"))
		draw_string(font,Vector2(232,130),"OREN · southeast bell",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffe0a4"))
		draw_string(font,Vector2(232,152),"NURSERY · Force + Mend",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("ffc781"))
		draw_string(font,Vector2(232,172),"BELL · Anchor + Mend",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("c8b5ff"))
		draw_string(font,Vector2(232,192),"Mint dot · optional irrigation",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("81e5bd"))
		return
	if builder.valley_mode: return
	# Later regions are outlined: they are not part of the current build.
	var points := [Vector2(358, 82), Vector2(338, 126), Vector2(383, 163), Vector2(359, 203)]
	draw_line(Vector2(307, 160), points[0], Color(0.37, 0.51, 0.53), 1)
	for pair in [[0, 1], [0, 2], [1, 3], [2, 3]]:
		draw_line(points[pair[0]], points[pair[1]], Color(0.37, 0.51, 0.53), 1)
	for i in points.size():
		draw_arc(points[i], 9, 0, TAU, 24, Color(0.48, 0.6, 0.59), 1)
		draw_string(font, points[i] + Vector2(-3, 4), "2" if i == 0 else "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.7, 0.8, 0.78))
	draw_string(font, Vector2(327, 61), "MARSH", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.65, 0.75, 0.76))

func _background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.095, 0.13, 0.97)
	style.set_corner_radius_all(12)
	style.set_border_width_all(1)
	style.border_color = Color(0.37, 0.52, 0.53)
	return style
