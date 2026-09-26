extends Node3D
## Step-1 feel lab: pulse dummies, feel Weight/Charge on the pads, lose
## hearts to overload and the hazard, fail and retry. Failure handling here
## is a stand-in for CheckpointDirector (build step 6).

const CLASSES: Array[HeroClass] = [
	preload("res://data/classes/warden.tres"),
	preload("res://data/classes/weaver.tres"),
]

@onready var hero: Hero = $Hero
@onready var dummies_root: Node3D = $Dummies

var _hero_start: Vector3
var _dummy_starts := {}

func _ready() -> void:
	_hero_start = hero.global_position
	for dummy in dummies_root.get_children():
		_dummy_starts[dummy] = dummy.global_position
	hero.failed.connect(_on_failed)

func _on_failed() -> void:
	await get_tree().create_timer(0.6, true, false, true).timeout
	hero.restore_hearts()
	hero.respawn_at(_hero_start)
	for dummy in _dummy_starts:
		dummy.global_position = _dummy_starts[dummy]
		dummy.stop()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_swap_class"):
		swap_class()

## F1: flip between the Warden and the Weaver (debug; class select comes later).
func swap_class() -> void:
	var next := CLASSES[(CLASSES.find(hero.hero_class) + 1) % CLASSES.size()]
	hero.apply_class(next)
