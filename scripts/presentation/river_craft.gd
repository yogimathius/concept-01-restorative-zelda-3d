class_name RiverCraft
extends RefCounted
## Shared ceramic, bronze and living-water construction; cached opaque materials.
static var _materials := {}
static func material(color: Color, metal := 0.0, glow := 0.0) -> StandardMaterial3D:
	var key := str(color)+str(metal)+str(glow)
	if not _materials.has(key):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.metallic = metal
		mat.roughness = 0.45 if metal>0 else 0.85
		mat.emission_enabled = glow>0
		mat.emission = color
		mat.emission_energy_multiplier = glow
		_materials[key] = mat
	return _materials[key]
static func mesh(parent: Node3D, shape: Mesh, at: Vector3, color: Color, metal := 0.0, glow := 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = shape
	node.material_override = material(color,metal,glow)
	parent.add_child(node)
	node.position = at
	return node
static func box(parent: Node3D, at: Vector3, size: Vector3, color: Color, metal := 0.0) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return mesh(parent,shape,at,color,metal)
static func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: Color, top := -1.0) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.bottom_radius = radius
	shape.top_radius = radius if top<0 else top
	shape.height = height
	shape.radial_segments = 16
	return mesh(parent,shape,at,color)
static func ring(parent: Node3D, at: Vector3, radius: float, color: Color, thickness := 0.025) -> MeshInstance3D:
	var shape := TorusMesh.new()
	shape.inner_radius = radius-thickness
	shape.outer_radius = radius
	shape.rings = 24
	shape.ring_segments = 6
	return mesh(parent,shape,at,color,0.5)
static func pot(parent: Node3D, at: Vector3, color: Color, radius := 0.25) -> void:
	cylinder(parent,at+Vector3.UP*0.22,radius,0.44,color,radius*0.85)
	ring(parent,at+Vector3.UP*0.45,radius*0.88,Color("8b7854"),0.018)
	cylinder(parent,at+Vector3.UP*0.44,radius*0.73,0.01,Color("343d32"))
static func channel(parent: Node3D, at: Vector3, length: float, along_x := true) -> MeshInstance3D:
	for side in [-1,1]:
		box(parent,at+Vector3(0,0.05,side*0.20) if along_x else at+Vector3(side*0.20,0.05,0),Vector3(length,0.12,0.07) if along_x else Vector3(0.07,0.12,length),Color("c1c3ae"))
	var water := box(parent,at+Vector3.UP*0.025,Vector3(length,0.045,0.32) if along_x else Vector3(0.32,0.045,length),Color("449b9b"))
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/river.gdshader")
	mat.set_shader_parameter("restored",1.0)
	water.material_override = mat
	return water

static func batch_static(parent: Node3D, excluded: Array = []) -> void:
	var batches := {}
	for node in parent.get_children():
		if not node is MeshInstance3D or excluded.has(node): continue
		var key := str(hash(node.mesh.get_faces()))+str(node.material_override.get_instance_id())
		if not batches.has(key): batches[key] = {"mesh":node.mesh,"material":node.material_override,"transforms":[]}
		batches[key].transforms.append(node.transform)
		parent.remove_child(node)
		node.queue_free()
	for batch in batches.values():
		var mesh := MultiMesh.new()
		mesh.transform_format = MultiMesh.TRANSFORM_3D
		mesh.mesh = batch.mesh
		mesh.instance_count = batch.transforms.size()
		for i in mesh.instance_count: mesh.set_instance_transform(i,batch.transforms[i])
		var node := MultiMeshInstance3D.new()
		node.multimesh = mesh
		node.material_override = batch.material
		parent.add_child(node)
