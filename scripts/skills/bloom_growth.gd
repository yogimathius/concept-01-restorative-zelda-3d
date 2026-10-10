class_name BloomGrowth
extends Node3D
## Bloom asks an already restored, connected living place to grow further.
## These authored outcomes change repeatable care and safe rest, not main gates.
const GROVES := [
	{"id":"M1","title":"kitchen garden","at":Vector3(11.5,0,7.5),"color":Color("aee5a3")},
	{"id":"M4","title":"willow refuge","at":Vector3(10.5,0,17.5),"color":Color("9bdcbb")},
]
var region: Node3D
var _growth := {}
var _labels := {}
var _visual_state := {}
var _shared_shelter: MeshInstance3D

func _ready() -> void:
	name = "BloomGrowth"
	for definition in GROVES:
		var id: String = definition.id
		var group := Node3D.new()
		group.name = "Growth_"+id
		var at: Vector3 = definition.at
		group.position = at+Vector3.UP*region.builder.surface_height(Vector2(at.x,at.z))
		add_child(group)
		_growth[id] = group
		if id == "M1": _garden(group)
		else: _refuge(group)
		var label := Label3D.new()
		label.text = "BLOOM · "+definition.title.to_upper()
		label.position = Vector3(0,1.5,0)
		label.font_size = 26
		label.pixel_size = 0.008
		label.outline_size = 4
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color("f2e9b7")
		add_child(label)
		label.position += group.position
		_labels[id] = label
		_visual_state[id] = false
		group.visible = false
	_shared_shelter = MeshInstance3D.new()
	_shared_shelter.name = "SharedSpringShelter"
	var ring := TorusMesh.new()
	ring.inner_radius = 0.82
	ring.outer_radius = 0.98
	_shared_shelter.mesh = ring
	_shared_shelter.position = region.builder.entities.M5.runtime.global_position+Vector3.UP*0.08
	_shared_shelter.material_override = _material(Color("8bdcba"),0.45)
	add_child(_shared_shelter)
	_sync(false)

func _material(color: Color, glow := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = glow > 0
	material.emission = color
	material.emission_energy_multiplier = glow
	return material

func _piece(parent: Node3D, mesh: Mesh, at: Vector3, color: Color, glow := 0.0) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.position = at
	piece.material_override = _material(color,glow)
	parent.add_child(piece)
	return piece

func _garden(group: Node3D) -> void:
	for row in 3:
		var earth := BoxMesh.new()
		earth.size = Vector3(2.8,0.12,0.48)
		_piece(group,earth,Vector3(0,0.07,(row-1)*0.72),Color("526b54"))
		for i in 5:
			var x := (float(i)-2.0)*0.49
			var stem := CylinderMesh.new()
			stem.height = 0.35+0.12*float((row+i)%3)
			stem.top_radius = 0.022
			stem.bottom_radius = 0.035
			stem.radial_segments = 6
			_piece(group,stem,Vector3(x,0.28,(row-1)*0.72),Color("7fc695"))
			var blossom := SphereMesh.new()
			blossom.radius = 0.13
			blossom.height = 0.16
			_piece(group,blossom,Vector3(x,0.52+0.12*float((row+i)%3),(row-1)*0.72),Color("f0d9a1") if i%2==0 else Color("b2e9d2"),0.35)
	for side in [-1,1]:
		var rim := BoxMesh.new()
		rim.size = Vector3(0.10,0.22,2.25)
		_piece(group,rim,Vector3(float(side)*1.52,0.12,0),Color("d5c9ab"))

func _refuge(group: Node3D) -> void:
	for side in [-1,1]:
		var trunk := CylinderMesh.new()
		trunk.height = 2.7
		trunk.top_radius = 0.10
		trunk.bottom_radius = 0.18
		trunk.radial_segments = 8
		_piece(group,trunk,Vector3(float(side)*1.6,1.35,0),Color("b4aa8d"))
		for i in 5:
			var leaf := SphereMesh.new()
			leaf.radius = 0.48+0.06*float(i%2)
			leaf.height = 0.40+0.05*float(i%3)
			var angle := float(i)*TAU/5.0
			var leaf_at := Vector3(float(side)*1.38+cos(angle)*0.42,2.54+0.13*float(i%3),-0.42+sin(angle)*0.47)
			_piece(group,leaf,leaf_at,Color("4b9b82") if i%2==0 else Color("79c3a1"),0.12)
			var glint := SphereMesh.new()
			glint.radius = 0.045
			glint.height = 0.08
			_piece(group,glint,leaf_at+Vector3(0,0.22,0),Color("e2dfa1"),0.45)
		for i in 3:
			var reed := CylinderMesh.new()
			reed.height = 1.4+float(i)*0.18
			reed.top_radius = 0.018
			reed.bottom_radius = 0.035
			reed.radial_segments = 6
			_piece(group,reed,Vector3(float(side)*(0.55+float(i)*0.38),1.8,0.55),Color("b0e1bd"))
	var shade := CylinderMesh.new()
	shade.height = 0.045
	shade.top_radius = 1.55
	shade.bottom_radius = 1.55
	_piece(group,shade,Vector3(0,0.04,0),Color("47877d"),0.15)

func ready(id: String) -> bool:
	if region.region_id != "R2" or not region.builder.entities[id].get("restored",false): return false
	return region.builder.entities[id].runtime.ecology.states.linked

func completed(id: String) -> bool:
	return region.builder.entities[id].runtime.ecology.states.bloomed

func remaining() -> int:
	var count := 0
	for definition in GROVES:
		if not completed(definition.id): count += 1
	return count

func sheltered() -> bool:
	if not completed("M4"): return false
	if region.hero.global_position.distance_to(_growth.M4.global_position) <= 5.5: return true
	return region.waykeeper.effective_node("living_network") and region.weave_relays.spring_refuge.linked() and region.hero.global_position.distance_to(region.builder.entities.M5.runtime.global_position) <= 5.5

func use() -> bool:
	if region.region_id != "R2": return false
	var nearest: Dictionary = {}
	var best := 6.0
	for definition in GROVES:
		var offset: Vector3 = definition.at-region.hero.global_position
		offset.y = 0
		if offset.length() < best:
			best = offset.length()
			nearest = definition
	if nearest.is_empty():
		region.waykeeper._message("Bloom answers living places · approach Neri's garden or the willow refuge")
		return false
	var id: String = nearest.id
	if completed(id):
		region.waykeeper._message("The %s is already flourishing" % nearest.title)
		return false
	if not ready(id):
		region.waykeeper._message("Restore the %s and link its water with Weave before Bloom" % nearest.title)
		return false
	if not region.waykeeper._spend_flow("bloom"): return false
	var ecology: RestorationSite = region.builder.entities[id].runtime.ecology
	ecology.states.bloomed = true
	ecology.states.flourishing = true
	region.waykeeper.meaningful("bloom","R2/"+id+"/bloomed",3)
	var reward: Dictionary = region.progression.award_activity(20)
	region._configure_restoration()
	region._update_level_hud()
	region._level_toast.text = "+%d XP · %s blooms" % [reward.earned,nearest.title]
	region._toast_left = 4.0
	region.hero.play_anim(&"attack")
	_sync(true)
	Juice.wave(_growth[id].global_position+Vector3.UP*0.4,3.7,nearest.color,1.25)
	Juice.burst(_growth[id].global_position+Vector3.UP*0.8,nearest.color,24)
	region.waykeeper._message("The %s grows into its new season" % nearest.title)
	region._save_journey()
	return true

func _sync(animate: bool) -> void:
	_shared_shelter.visible = completed("M4") and region.waykeeper.effective_node("living_network") and region.weave_relays.spring_refuge.linked()
	for definition in GROVES:
		var id: String = definition.id
		var bloomed: bool = completed(id)
		var group: Node3D = _growth[id]
		if bloomed and not _visual_state[id]:
			group.visible = true
			group.scale = Vector3(0.65,0.02,0.65) if animate else Vector3.ONE
			if animate: group.create_tween().tween_property(group,"scale",Vector3.ONE,0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		elif not bloomed and _visual_state[id]: group.visible = false
		_visual_state[id] = bloomed

func _process(_delta: float) -> void:
	_sync(false)
	for definition in GROVES:
		var id: String = definition.id
		var offset: Vector3 = definition.at-region.hero.global_position
		offset.y = 0
		_labels[id].visible = region.waykeeper.progress.active == "bloom" and ready(id) and not completed(id) and offset.length() <= 6.0
