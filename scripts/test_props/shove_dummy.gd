class_name ShoveDummy
extends CharacterBody3D
## Feel-lab target: slides when shoved, bounces off walls, and squashes and
## flashes on hit, so the shove can be judged on its own.

signal shoved(inf: Influence)

const TOON_MATERIAL: ShaderMaterial = preload("res://shaders/toon_outline_material.tres")

@export var knockback_per_force: float = 1.1
@export var friction: float = 9.0
@export var gravity: float = 20.0

var _slide := Vector3.ZERO

@onready var body_mesh: Node3D = $Mesh

func _ready() -> void:
	add_to_group("influenceable")
	ToonUtil.apply_toon(body_mesh, TOON_MATERIAL)

func receive_influence(inf: Influence) -> void:
	if inf.kind != Influence.Kind.FORCE:
		return
	_slide += inf.direction * inf.amount * knockback_per_force
	shoved.emit(inf)
	ToonUtil.flash(self, body_mesh, Color.WHITE, 0.1)
	body_mesh.scale = Vector3(1.3, 0.7, 1.3)
	var t := create_tween()
	t.tween_property(body_mesh, "scale", Vector3.ONE, 0.25) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func stop() -> void:
	_slide = Vector3.ZERO
	velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	velocity.x = _slide.x
	velocity.z = _slide.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - gravity * delta
	move_and_slide()
	for i in get_slide_collision_count():
		var n := get_slide_collision(i).get_normal()
		n.y = 0.0
		if n.length() > 0.5 and _slide.dot(n) < 0.0:
			_slide = _slide.bounce(n.normalized()) * 0.6
	_slide = _slide.move_toward(Vector3.ZERO, friction * delta)
