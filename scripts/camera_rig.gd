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

@export var constrain_region := false
@export var region_min := Vector2(6.5, 4.0)
@export var region_max := Vector2(45.0, 19.0)

var target: Node3D
var trauma := 0.0
var _focus := Vector3.ZERO
var _time := 0.0
var _restoration_left := 0.0
var _restoration_at := Vector3.ZERO
var _resting_size := 8.0

func _ready() -> void:
	_resting_size = size
	target = get_node_or_null(target_path)
	Juice.shake_requested.connect(add_trauma)
	if target:
		_focus = target.global_position
		if constrain_region:
			_focus.x = clampf(_focus.x, region_min.x, region_max.x)
			_focus.z = clampf(_focus.z, region_min.y, region_max.y)
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
	_restoration_left = maxf(0,_restoration_left-delta)
	if _restoration_left>0:
		goal = goal.lerp(_restoration_at,0.3*minf(1,_restoration_left))
	size = lerpf(size,_resting_size+(1.2 if _restoration_left>0 else 0.0),minf(1,delta*2))
	if constrain_region:
		goal.x = clampf(goal.x, region_min.x, region_max.x)
		goal.z = clampf(goal.z, region_min.y, region_max.y)
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

func frame_restoration(at: Vector3) -> void:
	_restoration_at = at
	_restoration_left = 4.5
