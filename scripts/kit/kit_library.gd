class_name KitLibrary
extends RefCounted
## Loads Broken Ford kit meshes (assets/kit/<family>.glb) once, converted to
## the toon shader, and caches them. Meshes are shared: use KitPiece with
## unique_materials when something needs to flash on its own.

const KIT_DIR := "res://assets/kit/"
const TOON: ShaderMaterial = preload("res://shaders/toon_outline_material.tres")

static var _meshes: Dictionary = {}

static func mesh(family: String, node_name: String) -> Mesh:
	var key := family + "/" + node_name
	if _meshes.has(key):
		return _meshes[key]
	var path := KIT_DIR + family + ".glb"
	if not ResourceLoader.exists(path):
		return null
	var root: Node = (load(path) as PackedScene).instantiate()
	var src := root.find_child(node_name, true, false) as MeshInstance3D
	var out: Mesh = null
	if src and src.mesh:
		out = src.mesh.duplicate()
		for i in out.get_surface_count():
			out.surface_set_material(i, ToonUtil.toon_material(src.get_active_material(i), TOON))
	root.free()
	_meshes[key] = out
	return out
