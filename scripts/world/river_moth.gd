class_name RiverMoth
extends Node3D
## A small living consequence of restored water. It answers nearby Mend light.
var region: Node3D
var site_id := ""
var home := Vector3.ZERO
var _age := 0.0
var _body: MeshInstance3D
var _wings: Array[MeshInstance3D] = []

func _ready() -> void:
	home = position
	_body = MeshInstance3D.new()
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.085
	body_mesh.height = 0.22
	body_mesh.radial_segments = 8
	body_mesh.rings = 4
	_body.mesh = body_mesh
	_body.material_override = _material(Color("c3ad68"))
	add_child(_body)
	for side in [-1.0,1.0]:
		var wing := MeshInstance3D.new()
		var wing_mesh := SphereMesh.new()
		wing_mesh.radius = 0.12
		wing_mesh.height = 0.12
		wing_mesh.radial_segments = 8
		wing_mesh.rings = 4
		wing.mesh = wing_mesh
		wing.scale = Vector3(0.9,0.12,1.55)
		wing.position = Vector3(side*0.12,0,0)
		wing.material_override = _material(Color("80d3cf"))
		add_child(wing)
		_wings.append(wing)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(region): return
	visible = region.builder.entities.get(site_id,{}).get("restored",false)
	if not visible: return
	_age += delta
	var responding: bool = region.hero.restore_verb.active and region.hero.global_position.distance_to(global_position)<4.5
	var distance := 0.35 if responding else 0.7
	var center: Vector3 = region.hero.global_position if responding else home
	position = center + Vector3(cos(_age*1.4)*distance,1.35+sin(_age*3.1)*0.16,sin(_age*1.4)*distance)
	rotation.y = _age*1.4
	for i in _wings.size():
		_wings[i].rotation.z = sin(_age*19.0)*0.65*(1 if i==0 else -1)

func _material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color*0.45
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat
