class_name RenewalPatch
extends Node3D
## Small, repeatable acts of care around places the Waykeeper has restored.
var region: Node3D
var site_id := ""
var material_id := "reed_fiber"
var profile := {}
var ecology = null
var kind := "care"
var restored := true
var progress := 0.0
var _stem: MeshInstance3D
var _halo: MeshInstance3D
var _label: Label3D
var _strain: Node3D
var _response: Node3D
var _renewed: Node3D
var _last_visible := false
var _last_stage := -1
var _last_percent := -1

func _ready() -> void:
	add_to_group("influenceable")
	_stem = MeshInstance3D.new()
	_stem.mesh = KitLibrary.mesh(_family(),_family()+"_corrupted")
	_stem.scale = Vector3.ONE*(0.67 if profile.kind == "habitat" else 0.76)
	add_child(_stem)
	_strain = Node3D.new()
	_strain.name = "Strain"
	add_child(_strain)
	_response = Node3D.new()
	_response.name = "WaterResponding"
	add_child(_response)
	_renewed = Node3D.new()
	_renewed.name = "NearlyTended"
	add_child(_renewed)
	_build_condition()
	for group in [_strain,_response,_renewed]: group.scale = Vector3.ONE*1.35
	_halo = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.61
	ring.outer_radius = 0.69
	_halo.mesh = ring
	_halo.position.y = 0.04
	var halo_mat := StandardMaterial3D.new()
	halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo_mat.albedo_color = _tint()
	_halo.material_override = halo_mat
	add_child(_halo)
	_label = Label3D.new()
	_label.text = profile.title
	_label.position.y = 0.9
	_label.font_size = 23
	_label.pixel_size = 0.008
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.outline_size = 4
	_label.modulate = Color("f4e5bd")
	add_child(_label)
	_sync()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(region): return
	region.economy.tick_patch(site_id,delta)
	var source: Dictionary = region.builder.entities.get(site_id,{})
	var available: bool = source.get("restored",false) and region.economy.patch(site_id).cooldown <= 0
	restored = not available
	progress = region.economy.patch(site_id).progress
	_sync()
	_label.visible = not restored and region.hero.global_position.distance_to(global_position) <= 5.5

func can_mend() -> bool:
	return not restored

func mend_status() -> String:
	return "%s · %d%% tended\n%s" % [profile.title,roundi(progress*100),profile.cue]

func completion_feedback() -> String:
	return "%s tended · materials, scrip and XP earned" % profile.title

func receive_influence(inf: Influence) -> void:
	if restored or inf.kind != Influence.Kind.RESTORE: return
	var state: Dictionary = region.economy.patch(site_id)
	var old_progress: float = state.progress
	state.progress = minf(1.0,old_progress+inf.amount)
	progress = state.progress
	var echoed: bool = region.renewal_world.echo_care(site_id,progress-old_progress)
	if progress >= 1.0:
		var previous_level: int = region.progression.get_level()
		if region.economy.tend(site_id,material_id,region.progression):
			restored = true
			var seed_kind := ""
			if site_id == "M1" and region.builder.entities.M1.runtime.ecology.states.bloomed: seed_kind = "garden seed"
			if site_id == "M5" and region.builder.entities.M5.runtime.ecology.states.linked: seed_kind = "mint seed"
			if site_id == "M6" and region.builder.entities.M6.runtime.ecology.states.charged: seed_kind = "lantern seed"
			if not seed_kind.is_empty(): region.inventory.grant_seeds(1)
			region._on_care_reward(material_id,previous_level,seed_kind)
			if echoed: region._level_toast.text += " · care echoed"
			var loot := CareLoot.new()
			loot.material_id = material_id
			loot.kind = profile.kind
			loot.bonus_seeds = 1 if not seed_kind.is_empty() else 0
			loot.hero = region.hero
			loot.position = region.to_local(global_position+Vector3.UP*0.3)
			region.add_child(loot)
			Juice.wave(global_position+Vector3.UP*0.2,1.35,Color("aaf5cf"),0.65)
	_sync()

func _sync() -> void:
	if not _stem: return
	if _last_visible != restored:
		_last_visible = restored
		visible = not restored
	if restored: return
	var percent := roundi(progress*100)
	if percent != _last_percent:
		_last_percent = percent
		_label.text = "%s · %d%%" % [profile.title,percent]
	var stage := 2 if progress>=0.70 else 1 if progress>=0.32 else 0
	if stage == _last_stage: return
	_last_stage = stage
	_stem.mesh = KitLibrary.mesh(_family(),_family()+("_restored" if stage==2 else "_corrupted"))
	_strain.visible = stage==0
	_response.visible = stage>=1
	_renewed.visible = stage>=2
	(_halo.material_override as StandardMaterial3D).albedo_color = _tint().darkened(0.35) if stage==0 else _tint()

func _family() -> String:
	return "stone_chunk" if profile.kind=="silt" else "signal_groove" if profile.kind=="glass" else "reed"

func _tint() -> Color:
	return Color("b2e39b") if profile.kind=="reeds" else Color("a7e1c0") if profile.kind=="habitat" else Color("d8bd91") if profile.kind=="silt" else Color("8bdde6")

func _piece(parent: Node3D, mesh: Mesh, at: Vector3, tint: Color, glow := 0.0) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.emission_enabled = glow>0
	material.emission = tint
	material.emission_energy_multiplier = glow
	piece.material_override = material
	parent.add_child(piece)
	return piece

func _build_condition() -> void:
	match profile.kind:
		"silt":
			for i in 3:
				var crust := BoxMesh.new()
				crust.size = Vector3(0.38,0.12,0.32)
				var plate := _piece(_strain,crust,Vector3((float(i)-1.0)*0.31,0.16,0.20*float(i%2)),Color("827779"))
				plate.rotation.y = float(i)*0.4
			var trickle := BoxMesh.new()
			trickle.size = Vector3(1.2,0.035,0.17)
			_piece(_response,trickle,Vector3(0,0.11,0),Color("73c7c6"),0.25)
			for side in [-1,1]:
				var sprout := CylinderMesh.new()
				sprout.height = 0.34
				sprout.top_radius = 0.025
				sprout.bottom_radius = 0.045
				sprout.radial_segments = 6
				_piece(_renewed,sprout,Vector3(float(side)*0.38,0.20,0.32),Color("91cea0"))
		"glass":
			for i in 3:
				var shard := CylinderMesh.new()
				shard.height = 0.32+float(i)*0.08
				shard.top_radius = 0.035
				shard.bottom_radius = 0.16
				shard.radial_segments = 6
				_piece(_strain,shard,Vector3((float(i)-1.0)*0.32,0.22,0.13*float(i%2)),Color("7e8695"))
				_piece(_response,shard,Vector3((float(i)-1.0)*0.32,0.22,0.13*float(i%2)),Color("7ab8c5"),0.25)
			var core := SphereMesh.new()
			core.radius = 0.20
			core.height = 0.22
			_piece(_renewed,core,Vector3(0,0.34,0),Color("c6f4e9"),0.7)
		"habitat":
			var nest := TorusMesh.new()
			nest.inner_radius = 0.32
			nest.outer_radius = 0.44
			_piece(_response,nest,Vector3(0,0.16,0),Color("adbb82"))
			for side in [-1,1]:
				var twig := BoxMesh.new()
				twig.size = Vector3(0.05,0.45,0.05)
				var bent := _piece(_strain,twig,Vector3(float(side)*0.31,0.24,0.1),Color("826b73"))
				bent.rotation.z = float(side)*0.55
				var leaf := SphereMesh.new()
				leaf.radius = 0.12
				leaf.height = 0.15
				_piece(_renewed,leaf,Vector3(float(side)*0.35,0.42,0),Color("a5deaa"),0.15)
		_:
			for side in [-1,0,1]:
				var bent_reed := CylinderMesh.new()
				bent_reed.height = 0.52
				bent_reed.top_radius = 0.02
				bent_reed.bottom_radius = 0.045
				bent_reed.radial_segments = 6
				var droop := _piece(_strain,bent_reed,Vector3(float(side)*0.28,0.20,0),Color("8b7b77"))
				droop.rotation.z = -0.65+float(side)*0.14
				_piece(_response,bent_reed,Vector3(float(side)*0.28,0.28,0),Color("82bb92"))
				var bud := SphereMesh.new()
				bud.radius = 0.08
				bud.height = 0.12
				_piece(_renewed,bud,Vector3(float(side)*0.28,0.57,0),Color("e5d79f"),0.22)
