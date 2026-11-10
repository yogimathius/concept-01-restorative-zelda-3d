extends CanvasLayer
## Main RPG: Stability and Flow. Hearts remain only in legacy combat fixtures.
## F3 provides a development readout of Weight/Charge.

@export var hero_path: NodePath

var _hero: Hero

@onready var hearts_row: HBoxContainer = $HeartsRow
@onready var debug_label: Label = $DebugLabel

func _ready() -> void:
	_hero = get_node(hero_path)
	_hero.hearts_changed.connect(_on_hearts_changed)
	_on_hearts_changed(_hero.hearts, _hero.max_hearts)

func _on_hearts_changed(hearts: int, max_hearts: int) -> void:
	while hearts_row.get_child_count() < max_hearts:
		var heart := Label.new()
		heart.text = "♥"
		heart.add_theme_font_size_override("font_size", 22)
		heart.custom_minimum_size = Vector2(20, 24)
		hearts_row.add_child(heart)
	for i in hearts_row.get_child_count():
		var heart := hearts_row.get_child(i) as Label
		heart.modulate = Color(1.0, 0.50, 0.42) if i < hearts else Color(0.38, 0.45, 0.49, 0.8)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_overlay"):
		debug_label.visible = not debug_label.visible
	if debug_label.visible:
		var status := ""
		if _hero.rooted_left > 0.0:
			status = "  ROOTED"
		elif _hero.surge_left > 0.0:
			status = "  SURGE"
		debug_label.text = "weight %3d   charge %3d%s   %d fps" % [
			_hero.gauge.value(&"weight"), _hero.gauge.value(&"charge"), status, Engine.get_frames_per_second()]

var resource_panel: PanelContainer
var _stability_label: Label
var _flow_label: Label
var _stability_bar: ProgressBar
var _flow_bar: ProgressBar

func show_resources() -> void:
	hearts_row.hide()
	debug_label.hide()
	show()
	if resource_panel: return
	resource_panel = PanelContainer.new()
	resource_panel.name = "Resources"
	resource_panel.position = Vector2(16, 12)
	resource_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("102b35ed")
	frame.border_color = Color("a58d64")
	frame.set_border_width_all(1)
	frame.set_corner_radius_all(8)
	frame.content_margin_left = 9
	frame.content_margin_right = 9
	frame.content_margin_top = 5
	frame.content_margin_bottom = 5
	resource_panel.add_theme_stylebox_override("panel",frame)
	add_child(resource_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation",2)
	resource_panel.add_child(box)
	_stability_label = _resource_label(box,Color("edcf96"))
	_stability_bar = _resource_bar(box,Color("d7b675"))
	_flow_label = _resource_label(box,Color("a9ecdf"))
	_flow_bar = _resource_bar(box,Color("60c9bf"))
	_hero.resources.changed.connect(_refresh_resources)
	_refresh_resources()

func _resource_label(parent: Node, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size",10)
	label.modulate = color
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func _resource_bar(parent: Node, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(160,5)
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color("071c26")
	background.set_corner_radius_all(3)
	var fill := background.duplicate() as StyleBoxFlat
	fill.bg_color = color
	bar.add_theme_stylebox_override("background",background)
	bar.add_theme_stylebox_override("fill",fill)
	parent.add_child(bar)
	return bar

func _refresh_resources() -> void:
	_stability_label.text = "STABILITY  %d / %d" % [ceili(_hero.resources.stability),int(_hero.resources.max_stability)]
	_flow_label.text = "FLOW  %d / %d" % [floori(_hero.resources.flow),int(_hero.resources.max_flow)]
	_stability_bar.max_value = _hero.resources.max_stability
	_flow_bar.max_value = _hero.resources.max_flow
	_stability_bar.value = _hero.resources.stability
	_flow_bar.value = _hero.resources.flow
