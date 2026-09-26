extends Node3D
## Region 1 slice: built from the world-design grids. Debug keys:
## F1 swap Warden/Weaver, F2 play the next authored restoration (preview
## until creature AI lands), F4 back to the feel lab.

const CLASSES: Array[HeroClass] = [
	preload("res://data/classes/warden.tres"),
	preload("res://data/classes/weaver.tres"),
]

@onready var builder: RegionBuilder = $Builder
@onready var hero: Hero = $Hero

func _ready() -> void:
	hero.respawn_at(builder.spawn)
	hero.failed.connect(_on_failed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_swap_class"):
		hero.apply_class(CLASSES[(CLASSES.find(hero.hero_class) + 1) % CLASSES.size()])
	elif event.is_action_pressed("debug_restore_next"):
		builder.restore_next()
	elif event.is_action_pressed("debug_switch_scene"):
		get_tree().change_scene_to_file("res://scenes/test/feel_lab.tscn")

func _on_failed() -> void:
	await get_tree().create_timer(0.6, true, false, true).timeout
	hero.restore_hearts()
	hero.respawn_at(builder.spawn)
