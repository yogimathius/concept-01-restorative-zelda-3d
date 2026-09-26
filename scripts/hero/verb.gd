class_name Verb
extends Node
## Base for hero abilities. The hero forwards input edges (pressed / held /
## released) and ticks the verb every physics frame; the verb owns its own
## timing, hit queries, feedback and animation.

@export var cooldown: float = 0.3

var hero: Hero
var active := false
var _cooldown_left := 0.0

func setup(p_hero: Hero) -> void:
	hero = p_hero

func ready_to_use() -> bool:
	return _cooldown_left <= 0.0 and not active

func start_cooldown() -> void:
	_cooldown_left = cooldown

func tick(delta: float) -> void:
	_cooldown_left = maxf(0.0, _cooldown_left - delta)
	_update(delta)

func on_pressed() -> void:
	pass

func on_held(_delta: float) -> void:
	pass

func on_released() -> void:
	pass

func _update(_delta: float) -> void:
	pass

## Movement multiplier applied to the hero while this verb wants it (e.g. a
## wind-up or channel slowing the hero down).
func move_multiplier() -> float:
	return 1.0
