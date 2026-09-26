class_name StatePad
extends Area3D
## Feel-lab pad: while something that receives influences stands on it, it
## builds `state_id` at `rate` per second. Lets Weight/Charge be felt in
## isolation before creatures exist.

@export var state_id: StringName = &"weight"
@export var rate: float = 35.0
@export var size := Vector2(2.0, 2.0)
@export var color := Color(0.6, 0.5, 0.4)

var _bodies: Array[Node3D] = []

func _ready() -> void:
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 1.0, size.y)
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = 0.5
	add_child(shape)
	var plane := PlaneMesh.new()
	plane.size = size
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	plane.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	mi.position.y = 0.02
	add_child(mi)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("receive_influence"):
		_bodies.append(body)

func _on_body_exited(body: Node3D) -> void:
	_bodies.erase(body)

func _physics_process(delta: float) -> void:
	for body in _bodies:
		if is_instance_valid(body):
			Influence.send(body, Influence.state(self, state_id, rate * delta))
