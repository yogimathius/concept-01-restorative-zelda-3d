class_name KitDresser
extends Node3D
## Batches static kit dressing into one MultiMeshInstance3D per distinct mesh,
## so a whole floor costs a handful of draw calls on a phone.

var _batches: Dictionary = {}   # "family/node" -> Array[Transform3D]

func place(family: String, node_name: String, at: Vector3, yaw_deg := 0.0, scale := 1.0) -> void:
	var key := family + "/" + node_name
	if not _batches.has(key):
		_batches[key] = []
	var basis := Basis(Vector3.UP, deg_to_rad(yaw_deg)).scaled(Vector3.ONE * scale)
	_batches[key].append(Transform3D(basis, at))

func place_xform(family: String, node_name: String, xform: Transform3D) -> void:
	var key := family + "/" + node_name
	if not _batches.has(key):
		_batches[key] = []
	_batches[key].append(xform)

func build() -> void:
	for child in get_children():
		if child is MultiMeshInstance3D:
			child.free()
	for key in _batches:
		var parts: PackedStringArray = key.split("/")
		var m := KitLibrary.mesh(parts[0], parts[1])
		if m == null:
			push_warning("KitDresser: missing kit mesh %s" % key)
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = m
		var transforms: Array = _batches[key]
		mm.instance_count = transforms.size()
		for i in transforms.size():
			mm.set_instance_transform(i, transforms[i])
		var inst := MultiMeshInstance3D.new()
		inst.name = key.replace("/", "__")
		inst.multimesh = mm
		add_child(inst)
