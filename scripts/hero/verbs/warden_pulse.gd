extends Verb
## Warden Force verb: a short wind-up, then an emitted pulse of restorative
## energy across an arc in front of the hero. It knocks corruption back and
## staggers it; it does not restore anything by itself (that's Mend).
## Strength scales with force_output, so Weight (the Warden's affinity)
## makes it hit much harder.

signal pulsed(hit_count: int)

const TARGET_RADIUS := 0.4
const PULSE_COLOR := Color(0.45, 1.0, 0.85)

@export var windup: float = 0.12
@export var reach: float = 1.3
@export var arc_dot: float = 0.35
@export var strength: float = 8.0
@export var hitstop_ms: int = 80

var _windup_left := -1.0

func on_pressed() -> void:
	if not ready_to_use():
		return
	active = true
	_windup_left = windup
	hero.play_anim(&"attack")

func _update(delta: float) -> void:
	if _windup_left < 0.0:
		return
	_windup_left -= delta
	if _windup_left <= 0.0:
		_windup_left = -1.0
		_release_pulse()
		active = false
		start_cooldown()

func move_multiplier() -> float:
	return 0.35 if active else 1.0

func _release_pulse() -> void:
	var facing := hero.facing_3d()
	var power := strength * hero.gauge.modifier(StateDefinition.MOD_FORCE_OUTPUT)
	var hits := 0
	for target in hero.find_influenceables(reach + TARGET_RADIUS):
		var to := target.global_position - hero.global_position
		to.y = 0.0
		var dist := to.length()
		if dist > 0.05 and facing.dot(to / dist) < arc_dot:
			continue
		if Influence.send(target, Influence.force(hero, power, facing)):
			hits += 1
	Juice.sfx("pulse_emit")
	Juice.wave(hero.global_position + facing * 0.4 + Vector3.UP * 0.35, reach + TARGET_RADIUS, PULSE_COLOR)
	if hits > 0:
		Juice.hitstop(hitstop_ms)
		Juice.shake(0.35)
		Juice.haptic(40)
		Juice.sfx("pulse_hit")
		Juice.burst(hero.global_position + facing * reach * 0.8 + Vector3.UP * 0.5, PULSE_COLOR)
	pulsed.emit(hits)
