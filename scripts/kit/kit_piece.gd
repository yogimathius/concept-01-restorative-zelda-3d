class_name KitPiece
extends Node3D
## One swappable kit piece: shows <shape>_corrupted or <shape>_restored.
## Gates, conduits, landmarks and props that transform use this; static
## floors go through KitDresser instead.

@export var family: String
@export var shape: String
@export var restored := false:
	set(value):
		restored = value
		_sync()
## Give this instance its own materials (needed for ToonUtil.flash).
@export var unique_materials := false

var corrupted_node: MeshInstance3D
var restored_node: MeshInstance3D

func _ready() -> void:
	corrupted_node = _make("%s_corrupted" % shape)
	restored_node = _make("%s_restored" % shape)
	_sync()

func set_restored(value: bool, animate := false) -> void:
	restored = value
	if animate and is_inside_tree():
		var shown := restored_node if restored else corrupted_node
		shown.scale = Vector3(1.15, 0.8, 1.15)
		create_tween().tween_property(shown, "scale", Vector3.ONE, 0.35) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _make(node_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = KitLibrary.mesh(family, node_name)
	if unique_materials and mi.mesh:
		for i in mi.mesh.get_surface_count():
			var mat: Material = mi.mesh.surface_get_material(i).duplicate()
			if mat is ShaderMaterial and mat.next_pass:
				mat.next_pass = mat.next_pass.duplicate()
			mi.set_surface_override_material(i, mat)
	add_child(mi)
	return mi

func _sync() -> void:
	if corrupted_node:
		corrupted_node.visible = not restored
		restored_node.visible = restored
