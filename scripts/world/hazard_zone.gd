class_name HazardZone
extends Area3D
## Anything with receive_influence that enters gets a HAZARD influence (the
## hero loses a heart and respawns at its last safe position). Box-shaped so
## the hero can ask whether a point is near it when recording safe spots.

@export var size := Vector3(2.0, 1.0, 2.0)
@export var show_visual := true
## Shift the volume vertically (chasms reach below ground to catch falls).
@export var y_offset := 0.0
@export var color := Color(0.28, 0.08, 0.34)

func _ready() -> void:
	add_to_group("hazard")
	var box := BoxShape3D.new()
	box.size = size
	var shape := CollisionShape3D.new()
	shape.shape = box
	shape.position.y = size.y * 0.5 + y_offset
	add_child(shape)
	if show_visual:
		var plane := PlaneMesh.new()
		plane.size = Vector2(size.x, size.z)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = color
		plane.material = mat
		var mi := MeshInstance3D.new()
		mi.mesh = plane
		mi.position.y = 0.02
		add_child(mi)
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	Influence.send(body, Influence.hazard(self))

func contains_point(point: Vector3, margin := 0.0) -> bool:
	var local := to_local(point)
	var half := size * 0.5
	var in_height := local.y >= y_offset - 0.1 and local.y <= y_offset + size.y + 0.1
	return in_height and absf(local.x) <= half.x + margin and absf(local.z) <= half.z + margin
