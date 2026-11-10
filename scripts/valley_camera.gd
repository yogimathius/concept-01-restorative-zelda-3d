class_name ValleyCamera
extends Node3D
## Perspective follow camera. A drag in clear world space never owns a stick,
## medallion or HUD finger. The rendering camera is a direct SpringArm child.
@export var target_path := NodePath("../Hero")
var yaw := -PI/2
var pitch := deg_to_rad(-24)
var drag_index := -1
var target: Hero
var pivot: Node3D
var arm: SpringArm3D
var camera: Camera3D
var _restoration_left := 0.0
var _restoration_at := Vector3.ZERO

func _ready() -> void:
	target = get_node(target_path)
	pivot = Node3D.new()
	add_child(pivot)
	arm = SpringArm3D.new()
	arm.spring_length = 8
	arm.margin = 0.25
	arm.add_excluded_object(target.get_rid())
	var shape := SphereShape3D.new()
	shape.radius = 0.3
	arm.shape = shape
	pivot.add_child(arm)
	camera = Camera3D.new()
	camera.fov = 62
	camera.far = 240
	camera.current = true
	arm.add_child(camera)
	pivot.global_position = target.global_position+Vector3.UP*1.4
	_pose()

func world_input(input: Vector2) -> Vector2:
	var right := Vector3(cos(yaw),0,-sin(yaw))
	var back := Vector3(sin(yaw),0,cos(yaw))
	var world := right*input.x+back*input.y
	return Vector2(world.x,world.z)

func screen_direction(world: Vector2) -> Vector2:
	return Vector2(world.dot(world_input(Vector2.RIGHT)),world.dot(world_input(Vector2.DOWN)))

func gesture_allowed(at: Vector2) -> bool:
	if get_tree().paused or not target.is_controllable(): return false
	var region := target.get_parent()
	if region.recovering or (region.story and region.story.dialogue.visible): return false
	if region.opening and region.opening._card.visible and region.opening._card.get_global_rect().has_point(at): return false
	var controls := region.get_node("TouchControls")
	for name in ["ContextButton","RestoreButton","DashButton"]:
		var button: TouchScreenButton = controls.get_node(name)
		var center := button.position+button.texture_normal.get_size()*button.scale*0.5
		if at.distance_to(center) < button.texture_normal.get_width()*button.scale.x*0.5+12: return false
	var size := get_viewport().get_visible_rect().size
	return Rect2(Vector2(185,100),Vector2(maxf(0,size.x-335),maxf(0,size.y-225))).has_point(at)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and drag_index < 0 and gesture_allowed(event.position): drag_index = event.index
		elif not event.pressed and event.index == drag_index: drag_index = -1
	elif event is InputEventScreenDrag and event.index == drag_index:
		if not gesture_allowed(event.position): drag_index = -1; return
		yaw -= event.relative.x*0.006
		pitch = clampf(pitch-event.relative.y*0.004,deg_to_rad(-48),deg_to_rad(-12))
		_pose()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_PAUSED: drag_index = -1

func _pose() -> void:
	pivot.rotation = Vector3(pitch,yaw,0)

func _process(delta: float) -> void:
	_restoration_left = maxf(0,_restoration_left-delta)
	var goal := target.global_position+Vector3.UP*1.4
	if _restoration_left>0: goal = goal.lerp(_restoration_at+Vector3.UP*1.8,0.25)
	pivot.global_position = pivot.global_position.lerp(goal,1-exp(-8*delta))

func frame_restoration(at: Vector3) -> void:
	_restoration_at = at
	_restoration_left = 4.5
