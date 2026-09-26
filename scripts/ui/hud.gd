extends CanvasLayer
## Hearts in the top-left, plus an F3 debug readout of state values for
## tuning (the shipped HUD shows no numbers; the body shows state).

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
		var heart := ColorRect.new()
		heart.custom_minimum_size = Vector2(20, 20)
		hearts_row.add_child(heart)
	for i in hearts_row.get_child_count():
		var heart := hearts_row.get_child(i) as ColorRect
		heart.color = Color(0.85, 0.15, 0.2) if i < hearts else Color(0.25, 0.22, 0.25, 0.6)

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
