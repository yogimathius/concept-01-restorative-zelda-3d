class_name CareLoot
extends Node3D
## A tangible reward burst; the ledger is credited on completion, so travel
## and interruption cannot lose or duplicate a care reward.
var material_id := "reed_fiber"
var kind := "glass"
var bonus_seeds := 0
var hero: Hero
var _age := 0.0
var _start := Vector3.ZERO
var _gem: Node3D

func _ready() -> void:
	_start = global_position
	_gem = Node3D.new()
	add_child(_gem)
	match kind:
		"reeds":
			for i in 3:
				var stem := CylinderMesh.new()
				stem.height = 0.38+0.06*float(i)
				stem.top_radius = 0.018
				stem.bottom_radius = 0.038
				stem.radial_segments = 6
				_piece(stem,Vector3((float(i)-1.0)*0.08,0,0),Color("a7e2b2"))
		"silt":
			var clay := CylinderMesh.new()
			clay.height = 0.16
			clay.top_radius = 0.19
			clay.bottom_radius = 0.22
			clay.radial_segments = 8
			_piece(clay,Vector3.ZERO,Color("cba98c"))
		"habitat":
			var seed := SphereMesh.new()
			seed.radius = 0.15
			seed.height = 0.26
			_piece(seed,Vector3.ZERO,Color("e1d5a1"))
		_:
			GearVisuals._gem(_gem,Vector3.ZERO,0.16,Color("a8e9f2"),0.65)
	var label := Label3D.new()
	label.text = "+2 %s · +1 scrip%s" % [material_id.replace("_"," ")," · +1 seed" if bonus_seeds>0 else ""]
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 0.6
	label.font_size = 25
	label.pixel_size = 0.007
	label.outline_size = 6
	label.modulate = Color("ffe6af")
	add_child(label)

func _piece(mesh: Mesh, at: Vector3, tint: Color) -> void:
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 0.24
	piece.material_override = material
	_gem.add_child(piece)

func _process(delta: float) -> void:
	_age += delta
	_gem.rotation.y += delta*3.0
	if _age<0.9:
		global_position = _start+Vector3.UP*(0.25+sin(_age/0.9*PI)*0.5)
	elif is_instance_valid(hero):
		var t := minf(1.0,(_age-0.9)/0.65)
		global_position = (_start+Vector3.UP*0.4).lerp(hero.global_position+Vector3.UP*0.85,t)
		_gem.scale = Vector3.ONE*(1.0-t)
	if _age>=1.6: queue_free()
