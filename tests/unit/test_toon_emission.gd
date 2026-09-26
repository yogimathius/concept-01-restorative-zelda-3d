extends TestCase
## Glowing accents (turquoise/gold insets) must survive the toon conversion.

const TOON: ShaderMaterial = preload("res://shaders/toon_outline_material.tres")

func test_apply_toon_carries_emission() -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	var src := StandardMaterial3D.new()
	src.albedo_color = Color(0.2, 0.7, 0.68)
	src.emission_enabled = true
	src.emission = Color(0.2, 0.7, 0.68)
	src.emission_energy_multiplier = 1.8
	mi.set_surface_override_material(0, src)
	world.add_child(mi)
	ToonUtil.apply_toon(mi, TOON)
	var mat: ShaderMaterial = mi.get_surface_override_material(0)
	check(mat.get_shader_parameter("emission_color") == src.emission, "emission colour copied")
	check_near(float(mat.get_shader_parameter("emission_energy")), 1.8, 0.001, "emission energy copied")

func test_non_emissive_material_has_no_glow() -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	mi.set_surface_override_material(0, StandardMaterial3D.new())
	world.add_child(mi)
	ToonUtil.apply_toon(mi, TOON)
	var mat: ShaderMaterial = mi.get_surface_override_material(0)
	check_near(float(mat.get_shader_parameter("emission_energy")), 0.0, 0.001, "no glow by default")

func test_kit_glow_survives_import_and_toon() -> void:
	var root: Node3D = (load("res://assets/kit/signal_groove.glb") as PackedScene).instantiate()
	world.add_child(root)
	var mi := root.find_child("signal_groove_restored", true, false) as MeshInstance3D
	ToonUtil.apply_toon(mi, TOON)
	var mat: ShaderMaterial = mi.get_surface_override_material(0)
	check(float(mat.get_shader_parameter("emission_energy")) > 0.5, "gold stroke glows after import")
