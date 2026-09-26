extends Node3D
## Step-1 feel lab: shove dummies, feel Weight/Charge on the pads, lose
## hearts to overload and the hazard, fail and retry. Failure handling here
## is a stand-in for CheckpointDirector (build step 6).

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
