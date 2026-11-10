class_name DialogueScreen
extends Control
signal choice(action: String)
signal closed
var _portrait: ConversationPortrait
var _body_width := 544.0
var _heading: Label
var _body: Label
var _page: Label
var _buttons: Array[Button] = []
var _pages: Array = []
var _options: Array = []
var _index := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = Vector2(590,264)
	position = (get_viewport().get_visible_rect().size-size)*0.5
	mouse_filter = Control.MOUSE_FILTER_STOP
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
	_heading = _label(Vector2(22,16),18,Color("f4dda4"))
	_body = _label(Vector2(22,53),15,Color("d4e8df"))
	_body.size = Vector2(544,130)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_page = _label(Vector2(22,190),10,Color("8fbdac"))
	for i in 3:
		var button := Button.new()
		button.position = Vector2(22+i*277,212)
		button.size = Vector2(268,40)
		if i == 2:
			button.position = Vector2(530,10)
			button.size = Vector2(44,40)
		button.add_theme_font_size_override("font_size",13)
		button.add_theme_color_override("font_color",Color("f4dda4"))
		var button_style := StyleBoxFlat.new()
		button_style.bg_color = Color("27534f")
		button_style.border_color = Color("87b69b")
		button_style.set_border_width_all(1)
		button_style.set_corner_radius_all(8)
		button.add_theme_stylebox_override("normal",button_style)
		button.gui_input.connect(func(event: InputEvent):
			if event is InputEventScreenTouch and event.pressed:
				if not button.disabled: button.pressed.emit()
				button.accept_event())
		button.pressed.connect(func(): _choose(i))
		add_child(button)
		_buttons.append(button)
	_portrait = ConversationPortrait.new()
	_portrait.position = Vector2(16,43)
	_portrait.size = Vector2(142,145)
	add_child(_portrait)
	get_viewport().size_changed.connect(func(): position = (get_viewport().get_visible_rect().size-size)*0.5)
	hide()

func show_conversation(name: String, role: String, pages: Array, options: Array) -> void:
	_heading.text = name + "  ·  " + role
	var id := name.to_lower()
	var has_portrait := id in ["mara","iona","oren","neri","daro","tavi","edda","sela","bryn"]
	_portrait.show_subject(id if has_portrait else "")
	_body_width = 396.0 if has_portrait else 544.0
	_body.position.x = 172.0 if has_portrait else 22.0
	_body.size.x = _body_width
	_pages = _paginate(pages)
	_options = options
	_index = 0
	show()
	_refresh()

func dismiss() -> void:
	_portrait.stop()
	hide()
	closed.emit()

func _choose(index: int) -> void:
	if index == 2: dismiss(); return
	if index == 1 and _index < _pages.size()-1: dismiss(); return
	if _index < _pages.size()-1:
		_index += 1
		_refresh()
		return
	var action: String = _options[index].get("action","close")
	if action == "close": dismiss()
	else: choice.emit(action)

func _refresh() -> void:
	_body.text = _pages[_index]
	_page.text = "%d / %d" % [_index+1,_pages.size()]
	var last := _index == _pages.size()-1
	for i in 3:
		if i == 2:
			_buttons[i].text = "×"
			_buttons[i].show()
			continue
		_buttons[i].visible = not last or i < _options.size()
		if not _buttons[i].visible: continue
		_buttons[i].disabled = last and _options[i].get("disabled",false)
		_buttons[i].text = _options[i].text if last else ("Continue" if i == 0 else "Leave for now")

func _label(at: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size",font_size)
	label.modulate = color
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label

func _paginate(pages: Array) -> Array:
	var result := []
	var font := _body.get_theme_font("font")
	for page_text in pages:
		var chunk := ""
		for word in String(page_text).replace("\n\n","\n").split(" ",false):
			var candidate := chunk + (" " if not chunk.is_empty() else "") + word
			if not chunk.is_empty() and font.get_multiline_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,_body_width,15).y > 126:
				result.append(chunk)
				chunk = word
			else: chunk = candidate
		if not chunk.is_empty(): result.append(chunk)
	return result if not result.is_empty() else [""]
