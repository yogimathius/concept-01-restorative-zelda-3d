class_name ReedSkipper
extends Node3D
## A small non-combat inhabitant of a restored refuge. It gathers near care,
## and remains part of the world after the temporary strain is tended.
var region: Node3D
var site_id := ""
var home := Vector3.ZERO
var _age := 0.0
var _body: MeshInstance3D
var _was_bloomed := false

func _ready() -> void:
	visible = false
	home = position
	_body = _piece(_sphere(0.19,0.28),Vector3(0,0.21,0),Color("7abfb5"))
	for side in [-1,1]:
		_piece(_sphere(0.045,0.07),Vector3(float(side)*0.095,0.31,-0.12),Color("f4e4b4"))
		var foot := _piece(_sphere(0.085,0.065),Vector3(float(side)*0.18,0.06,0.07),Color("d2bc89"))
		foot.rotation.y = float(side)*0.35
	var tail := CylinderMesh.new()
	tail.height = 0.42
	tail.top_radius = 0.018
	tail.bottom_radius = 0.06
	tail.radial_segments = 6
	var tail_piece := _piece(tail,Vector3(0,0.27,0.25),Color("8bd1b5"))
	tail_piece.rotation.x = 0.65

func _sphere(radius: float, height: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 8
	mesh.rings = 4
	return mesh

func _piece(mesh: Mesh, at: Vector3, color: Color) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.65
	piece.material_override = material
	add_child(piece)
	return piece

func _physics_process(delta: float) -> void:
	if not is_instance_valid(region): return
	visible = region.builder.entities.get(site_id,{}).get("restored",false)
	if not visible: return
	_age += delta
	var responding: bool = region.hero.restore_verb.active and region.hero.global_position.distance_to(global_position)<4.5
	var pace := 4.5 if responding else 2.3
	var arc := maxf(0.0,sin(_age*pace))
	position = home+Vector3(sin(_age*0.9)*0.40,arc*0.15,cos(_age*0.9)*0.30)
	rotation.y = _age*0.9+PI*0.5
	var bloomed: bool = site_id == "M4" and region.builder.entities.M4.runtime.ecology.states.bloomed
	if bloomed != _was_bloomed:
		_was_bloomed = bloomed
		(_body.material_override as StandardMaterial3D).albedo_color = Color("9cddad") if bloomed else Color("7abfb5")
