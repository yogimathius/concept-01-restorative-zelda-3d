class_name ToonUtil
extends RefCounted

static func apply_toon(node: Node, template: ShaderMaterial) -> void:
	if node is MeshInstance3D and node.mesh:
		for i in range(node.mesh.get_surface_count()):
			var color := Color(0.6, 0.6, 0.6)
			var original: Material = node.get_active_material(i)
			if original is BaseMaterial3D:
				color = original.albedo_color
			var mat: ShaderMaterial = template.duplicate()
			mat.set_shader_parameter("base_color", color)
			if mat.next_pass:
				mat.next_pass = mat.next_pass.duplicate()
			node.set_surface_override_material(i, mat)
	for child in node.get_children():
		apply_toon(child, template)

static func get_mesh_instances(node: Node, out: Array = []) -> Array:
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		get_mesh_instances(child, out)
	return out
