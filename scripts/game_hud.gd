extends CanvasLayer

@onready var hearts_row: HBoxContainer = $HeartsRow
@onready var status_label: Label = $StatusLabel

func _ready() -> void:
	GameEvents.player_hp_changed.connect(_on_hp_changed)
	GameEvents.enemy_defeated.connect(_on_enemy_defeated)
	status_label.modulate.a = 0.0

func _on_hp_changed(hp: int, _max_hp: int) -> void:
	var hearts := hearts_row.get_children()
	for i in range(hearts.size()):
		hearts[i].visible = i < hp

func _on_enemy_defeated() -> void:
	status_label.text = "Enemy defeated!"
	status_label.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(1.5)
	t.tween_property(status_label, "modulate:a", 0.0, 0.5)
