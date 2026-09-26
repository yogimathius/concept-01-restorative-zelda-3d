class_name HeroClass
extends Resource
## A playable hero: tuning, model, and the two verb scenes that fill the
## Force and Restore slots. state_overrides replace the base Weight/Charge
## definitions with the same id (class affinity).

@export var display_name: String = "Hero"
@export var model: PackedScene
@export var base_speed: float = 4.5
@export var base_accel: float = 30.0
@export var base_turn_rate: float = 14.0
@export var dash_distance: float = 3.5
@export var force_verb: PackedScene
@export var restore_verb: PackedScene
@export var state_overrides: Array = []
