class_name MarshCorrespondence
extends Node3D
## Physical continuity for Lio's recovered letter and Neri's reply. Story flags
## remain the only save authority; these inexpensive props are derived from them.
var region: Node3D
var _found: Node3D
var _received: Node3D
var _carried: Node3D
var _outgoing: Node3D
var _writing_tray: Node3D
var _last_stage := ""

func _ready() -> void:
	_found = _letter(self,Color("a8d5c4"))
	_found.position = region.builder.entities.M3.runtime.global_position+Vector3(0.8,0.26,0.6)
	_caption(_found,"LIO'S LETTER")
	_writing_tray = _tray()
	_writing_tray.position = Vector3(6.9,region.builder.surface_height(Vector2(6.9,5.1)),5.1)
	_received = _letter(self,Color("d4b8c7"))
	_received.position = Vector3(6.9,region.builder.surface_height(Vector2(6.9,5.1))+0.32,5.1)
	_caption(_received,"NERI'S WRITING")
	_carried = _letter(region.hero,Color("d4b8c7"))
	_carried.position = Vector3(0.32,0.70,-0.24)
	_carried.scale = Vector3.ONE*0.65
	_outgoing = _letter(self,Color("d4b8c7"))
	_outgoing.position = Vector3(24.6,region.builder.surface_height(Vector2(24.6,16.6))+0.28,16.6)
	_caption(_outgoing,"REPLY FOR LIO")
	region.builder.restored.connect(_on_restored)
	_sync()

func _process(_delta: float) -> void:
	_sync()
	for letter in [_found,_received,_outgoing]:
		if letter.visible:
			letter.get_node("Caption").visible = letter.global_position.distance_to(region.hero.global_position)<5.0

func _main_done() -> bool:
	return region.builder.entities.M1.get("restored",false) and region.builder.entities.M2.get("restored",false) and region.builder.entities.M3.get("restored",false)

func _on_restored(_id: String) -> void:
	if _main_done() and not region.builder._replaying:
		Juice.wave(_found.global_position,1.8,Color("b8eddf"),0.7)

func _sync() -> void:
	var stage := "sent" if region.story_flags.has("neri_reply_sent") else "carrying" if region.story_flags.has("neri_reply_ready") else "received" if region.story_flags.has("neri_letter") else "with_oren" if region.story_flags.has("marsh_message") else "found" if _main_done() else "hidden"
	if stage==_last_stage: return
	_last_stage=stage
	_found.visible = stage=="found"
	_writing_tray.visible = stage in ["received","carrying","sent"]
	_received.visible = stage in ["received","carrying","sent"]
	_carried.visible = stage=="carrying"
	_outgoing.visible = stage=="sent"

func _letter(parent: Node3D, seal: Color) -> Node3D:
	var letter := Node3D.new()
	parent.add_child(letter)
	var roll := CylinderMesh.new()
	roll.height = 0.62
	roll.top_radius = 0.09
	roll.bottom_radius = 0.09
	roll.radial_segments = 8
	var reed := MeshInstance3D.new()
	reed.mesh = roll
	reed.rotation.z = PI*0.5
	reed.material_override = _material(Color("e5d5ad"))
	letter.add_child(reed)
	var band := CylinderMesh.new()
	band.height = 0.13
	band.top_radius = 0.115
	band.bottom_radius = 0.115
	band.radial_segments = 8
	var binding := MeshInstance3D.new()
	binding.mesh = band
	binding.rotation.z = PI*0.5
	binding.material_override = _material(Color("9c794f"))
	letter.add_child(binding)
	var mark := SphereMesh.new()
	mark.radius = 0.09
	mark.height = 0.055
	mark.radial_segments = 8
	mark.rings = 4
	var glass := MeshInstance3D.new()
	glass.mesh = mark
	glass.position = Vector3(0,0.10,0)
	var glass_mat := _material(seal)
	glass_mat.emission_enabled = true
	glass_mat.emission = seal
	glass_mat.emission_energy_multiplier = 0.35
	glass.material_override = glass_mat
	letter.add_child(glass)
	return letter

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.65
	return material

func _caption(letter: Node3D, title: String) -> void:
	var label := Label3D.new()
	label.name = "Caption"
	label.text = title
	label.position.y = 0.46
	label.font_size = 23
	label.pixel_size = 0.012
	label.outline_size = 4
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("f2dfb1")
	label.visible = false
	letter.add_child(label)

func _tray() -> Node3D:
	var tray := Node3D.new()
	add_child(tray)
	var top := BoxMesh.new()
	top.size = Vector3(0.9,0.08,0.55)
	var ceramic := MeshInstance3D.new()
	ceramic.mesh = top
	ceramic.position.y = 0.27
	ceramic.material_override = _material(Color("d7d2b5"))
	tray.add_child(ceramic)
	for side in [-1,1]:
		var leg_mesh := BoxMesh.new()
		leg_mesh.size = Vector3(0.08,0.25,0.08)
		var leg := MeshInstance3D.new()
		leg.mesh = leg_mesh
		leg.position = Vector3(float(side)*0.34,0.12,0.18)
		leg.material_override = _material(Color("8d755d"))
		tray.add_child(leg)
	return tray
