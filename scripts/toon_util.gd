class_name ToonUtil
extends RefCounted

static func apply_toon(node: Node, template: ShaderMaterial) -> void:
	if node is MeshInstance3D and node.mesh:
		for i in range(node.mesh.get_surface_count()):
			var original: Material = node.get_active_material(i)
			if original is ShaderMaterial:
				continue  # already toon (e.g. a KitLibrary mesh)
			node.set_surface_override_material(i, toon_material(original, template))
	for child in node.get_children():
		apply_toon(child, template)

## Toon ShaderMaterial carrying an imported material's albedo and emission.
static func toon_material(original: Material, template: ShaderMaterial) -> ShaderMaterial:
	var color := Color(0.6, 0.6, 0.6)
	var glow := Color.BLACK
	var glow_energy := 0.0
	if original is BaseMaterial3D:
		color = original.albedo_color
		if original.emission_enabled:
			glow = original.emission
			glow_energy = original.emission_energy_multiplier
	var mat: ShaderMaterial = template.duplicate()
	mat.set_shader_parameter("base_color", color)
	mat.set_shader_parameter("emission_color", glow)
	mat.set_shader_parameter("emission_energy", glow_energy)
	if mat.next_pass:
		mat.next_pass = mat.next_pass.duplicate()
	return mat

static func get_mesh_instances(node: Node, out: Array = []) -> Array:
	if node is MeshInstance3D:
		out.append(node)
	for child in node.get_children():
		get_mesh_instances(child, out)
	return out

## Briefly tints every toon surface under root. Safe to overlap: the true
## base colour is remembered in material meta, so a second flash can't
## capture the first flash's colour as "original".
static func flash(owner: Node, root: Node, color: Color, duration: float = 0.12) -> void:
	var touched: Array[ShaderMaterial] = []
	for m in get_mesh_instances(root):
		for i in range(m.mesh.get_surface_count()):
			var mat: Material = m.get_active_material(i)
			if mat is ShaderMaterial and not touched.has(mat):
				if not mat.has_meta("toon_base_color"):
					mat.set_meta("toon_base_color", mat.get_shader_parameter("base_color"))
				mat.set_shader_parameter("base_color", color)
				touched.append(mat)
	owner.get_tree().create_timer(duration, true, false, true).timeout.connect(func() -> void:
		for mat in touched:
			if is_instance_valid(mat):
				mat.set_shader_parameter("base_color", mat.get_meta("toon_base_color")))
