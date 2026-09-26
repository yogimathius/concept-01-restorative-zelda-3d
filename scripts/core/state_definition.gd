class_name StateDefinition
extends Resource
## Tuning for one player/creature state (Weight, Charge). Each modifier is a
## multiplier that runs linearly from 1.0 at empty to its at-max value at full.

enum Overload { ROOT, SURGE }

const MOD_MOVE_SPEED := "move_speed"
const MOD_ACCEL := "accel"
const MOD_FRICTION := "friction"
const MOD_TURN_RATE := "turn_rate"
const MOD_DASH_DISTANCE := "dash_distance"
const MOD_KNOCKBACK_TAKEN := "knockback_taken"
const MOD_FORCE_OUTPUT := "force_output"

@export var id: StringName
@export var max_value: float = 100.0
@export var decay_delay: float = 1.0
@export var decay_rate: float = 20.0
@export var overload: Overload = Overload.ROOT
@export var overload_duration: float = 1.0
## modifier name (String) -> multiplier at max value
@export var modifiers_at_max: Dictionary = {}

func modifier(name: String, normalized: float) -> float:
	if not modifiers_at_max.has(name):
		return 1.0
	return lerpf(1.0, float(modifiers_at_max[name]), clampf(normalized, 0.0, 1.0))
