extends Camera3D
## Orthographic follow camera: smoothed follow with a little look-ahead, and
## trauma-based shake driven by Juice.shake().

@export var target_path: NodePath
@export var offset: Vector3 = Vector3(0, 8, 8)
@export var follow_lag: float = 0.15
@export var look_ahead_time: float = 0.12
@export var max_shake_offset: float = 0.35
@export var max_shake_roll_deg: float = 2.0
@export var trauma_decay: float = 1.8

var target: Node3D
var trauma := 0.0
var _focus := Vector3.ZERO
var _time := 0.0

func _ready() -> void:
	target = get_node_or_null(target_path)
	Juice.shake_requested.connect(add_trauma)
	if target:
		_focus = target.global_position
		global_position = _focus + offset
		look_at(_focus, Vector3.UP)

func add_trauma(amount: float) -> void:
	trauma = minf(1.0, trauma + amount)

func _process(delta: float) -> void:
	if target == null:
		return
	var goal := target.global_position
	if target is CharacterBody3D:
		var v: Vector3 = (target as CharacterBody3D).velocity
		goal += Vector3(v.x, 0.0, v.z) * look_ahead_time
	_focus = _focus.lerp(goal, 1.0 - exp(-delta / follow_lag))
	global_position = _focus + offset
	look_at(_focus, Vector3.UP)
	_time += delta
	if trauma > 0.0:
		var s := trauma * trauma
		var basis := global_transform.basis
		global_position += (basis.x * _noise(1.0) + basis.y * _noise(2.0)) * max_shake_offset * s
		rotate_object_local(Vector3.FORWARD, deg_to_rad(max_shake_roll_deg) * s * _noise(3.0))
		trauma = maxf(0.0, trauma - trauma_decay * delta)

func _noise(seed: float) -> float:
	return sin(_time * 37.0 + seed * 11.3) * cos(_time * 23.0 + seed * 5.1)
