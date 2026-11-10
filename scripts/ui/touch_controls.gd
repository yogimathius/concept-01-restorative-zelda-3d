extends CanvasLayer
## Permanent finger controls; desktop mouse emulates one touch for previews.
signal context_pressed
var _context_button: TouchScreenButton
var _context_caption := ""
var journey: WaykeeperJourney
var _gesture_index := -1
var _gesture_start := Vector2.ZERO
var _swiped := false
var _gesture_skill := ""
var _weave_gesture_relay: WeaveRelay
var _hero: Hero
var _labels := {}

func _ready() -> void:
	_hero = get_parent().get_node("Hero")
	visible = true
	$RestoreButton.pressed.connect(func():
		if journey == null or journey.progress.active == "mend": _hero.set_verb_held(Hero.SLOT_RESTORE, true)
		$RestoreButton.modulate = Color(1.2, 1.2, 1.2))
	$RestoreButton.released.connect(func():
		_hero.set_verb_held(Hero.SLOT_RESTORE, false)
		$RestoreButton.modulate = Color.WHITE)
	$DashButton.pressed.connect(func(): _hero.request_dash())
	$ForceButton.pressed.connect(func(): _hero.set_verb_held(Hero.SLOT_FORCE, true))
	$ForceButton.released.connect(func(): _hero.set_verb_held(Hero.SLOT_FORCE, false))
	_context_button = TouchScreenButton.new()
	_context_button.name = "ContextButton"
	_context_button.texture_normal = load("res://assets/ui/pack-medallion.svg")
	_context_button.pressed.connect(func(): context_pressed.emit())
	add_child(_context_button)
	for entry in [["ContextButton","PACK","Travelling cups"], ["RestoreButton", "MEND", "Hold to heal"], ["DashButton", "GLIDE", "Tap to travel"], ["ForceButton", "FORCE", ""]]:
		var title := Label.new()
		title.text = entry[1]
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 11)
		title.add_theme_color_override("font_color", Color(1, 0.94, 0.77))
		title.add_theme_color_override("font_outline_color", Color(0.03, 0.10, 0.12))
		title.add_theme_constant_override("outline_size", 4)
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(title)
		var caption := Label.new()
		caption.text = entry[2]
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", 8)
		caption.add_theme_color_override("font_outline_color", Color(0.03, 0.10, 0.12))
		caption.add_theme_constant_override("outline_size", 3)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(caption)
		_labels[entry[0]] = [title, caption]
	get_viewport().size_changed.connect(_layout_controls)
	_layout_controls()

func simplify() -> void:
	$ForceButton.hide()
	$ForceButton.set_process_input(false)
	$"Virtual Joystick".use_input_actions = false
	for label in _labels.get("ForceButton", []): label.hide()
	$RestoreButton.show()
	$DashButton.show()

func _layout_controls() -> void:
	var screen := get_viewport().get_visible_rect().size
	_place_action(_context_button,Vector2(screen.x-153,screen.y-155),52)
	_place_action($RestoreButton, Vector2(screen.x - 70, screen.y - 104), 88)
	_place_action($DashButton, Vector2(screen.x - 151, screen.y - 75), 64)
	_place_action($ForceButton, Vector2(screen.x - 150, screen.y - 145), 56)

func _place_action(button: TouchScreenButton, center: Vector2, diameter: float) -> void:
	var texture_size := button.texture_normal.get_size()
	button.scale = Vector2(diameter, diameter) / texture_size
	button.position = center - Vector2.ONE * diameter * 0.5
	var shape := CircleShape2D.new()
	shape.radius = texture_size.x * 0.5
	button.shape = shape
	var labels: Array = _labels[button.name]
	labels[0].position = center + Vector2(-48, diameter * 0.5 - 3)
	labels[0].size = Vector2(96, 16)
	labels[1].position = labels[0].position + Vector2(0, 15)
	labels[1].size = Vector2(96, 12)

func cancel_touch() -> void:
	_gesture_index = -1
	_gesture_skill = ""
	_swiped = false
	if _weave_gesture_relay: _weave_gesture_relay.cancel()
	_weave_gesture_relay = null
	if not is_instance_valid(_hero): return
	_hero.set_verb_held(Hero.SLOT_RESTORE, false)
	_hero.set_verb_held(Hero.SLOT_FORCE, false)
	_hero.move_input = Vector2.ZERO
	$"Virtual Joystick"._reset()
	for button in [$RestoreButton, $DashButton, $ForceButton,_context_button]:
		var was_visible: bool = button.visible
		button.hide()
		button.visible = was_visible

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: cancel_touch()

func set_context(title: String, caption: String) -> void:
	if _labels.ContextButton[0].text != title:
		_labels.ContextButton[0].text = title
		_context_button.texture_normal = load("res://assets/ui/talk-medallion.svg" if title == "TALK" else "res://assets/ui/pack-medallion.svg")
	if _context_caption != caption:
		_context_caption = caption
		_labels.ContextButton[1].text = caption

func set_technique(p_journey: WaykeeperJourney) -> void:
	journey = p_journey
	var id := journey.progress.active
	$RestoreButton.texture_normal = load(WaykeeperDefinitions.SKILLS[id].icon)
	_labels.RestoreButton[0].text = WaykeeperDefinitions.SKILLS[id].name.to_upper()
	_labels.RestoreButton[1].text = ("Hold · swipe to switch" if id=="mend" else "Drag to link · swipe up" if id=="weave" else "Tap to carry · swipe up" if id=="channel" else "Tap to grow · swipe up" if id=="bloom" else "Tap · swipe to switch") if journey.progress.unlocked.size()>1 else "Hold to heal"
	_layout_controls()

func _nearest_weave_relay() -> WeaveRelay:
	var chosen: WeaveRelay
	var nearest := INF
	for value in journey.region.weave_relays.values():
		var relay: WeaveRelay = value
		var distance: float = relay.distance_to_hero()
		if relay.ready() and not relay.linked() and distance <= 7.0 and distance < nearest:
			chosen = relay
			nearest = distance
	if chosen: return chosen
	for value in journey.region.weave_relays.values():
		var relay: WeaveRelay = value
		var distance: float = relay.distance_to_hero()
		if distance < nearest:
			chosen = relay
			nearest = distance
	return chosen

func _input(event: InputEvent) -> void:
	if not visible or journey == null or get_tree().paused: return
	var center: Vector2 = $RestoreButton.position+$RestoreButton.texture_normal.get_size()*$RestoreButton.scale*0.5
	if event is InputEventScreenTouch:
		if event.pressed and event.position.distance_to(center)<44:
			_gesture_index = event.index
			_gesture_start = event.position
			_swiped = false
			_gesture_skill = journey.progress.active
			if _gesture_skill == "weave":
				_weave_gesture_relay = _nearest_weave_relay()
				if _weave_gesture_relay: _weave_gesture_relay.begin()
		elif not event.pressed and event.index == _gesture_index:
			if _gesture_skill == "weave":
				var relay: WeaveRelay = _weave_gesture_relay
				var short_up: bool = event.position.y < _gesture_start.y-30 and event.position.distance_to(_gesture_start)<85
				if relay != null: short_up = short_up and not relay._candidate
				if short_up:
					if relay: relay.cancel()
					journey.cycle()
				elif relay: relay.end(event.position)
				else: journey.use_skill("weave")
				_weave_gesture_relay = null
			elif not _swiped and _gesture_skill != "mend" and event.position.distance_to(center)<60: journey.use_skill(_gesture_skill)
			_gesture_index = -1
	elif event is InputEventScreenDrag and event.index == _gesture_index and _gesture_skill == "weave":
		if _weave_gesture_relay: _weave_gesture_relay.drag(event.position)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _gesture_index and not _swiped:
		if event.position.y < _gesture_start.y-30:
			_swiped = true
			journey.cycle()
			get_viewport().set_input_as_handled()
