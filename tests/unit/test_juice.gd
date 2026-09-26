extends TestCase

const TOON: ShaderMaterial = preload("res://shaders/toon_outline_material.tres")
const CameraRig := preload("res://scripts/camera_rig.gd")

func test_hitstop_slows_time_then_restores() -> void:
	Juice.hitstop_enabled = true
	Juice.hitstop(50)
	check_near(Engine.time_scale, 0.05, 0.0001, "time slowed during hitstop")
	await wait_ms(200)
	check_near(Engine.time_scale, 1.0, 0.0001, "time restored after hitstop")

func test_overlapping_hitstops_restore_once_after_longest() -> void:
	Juice.hitstop_enabled = true
	Juice.hitstop(40)
	Juice.hitstop(250)
	await wait_ms(120)
	check_near(Engine.time_scale, 0.05, 0.0001, "short hitstop must not end the long one")
	await wait_ms(300)
	check_near(Engine.time_scale, 1.0, 0.0001, "time restored after the longest hitstop")

func test_disabled_hitstop_does_nothing() -> void:
	Juice.hitstop_enabled = false
	Juice.hitstop(100)
	check_near(Engine.time_scale, 1.0, 0.0001, "disabled hitstop leaves time alone")

func test_shake_clamps_and_emits() -> void:
	var got := [-1.0]
	var cb := func(t: float) -> void: got[0] = t
	Juice.shake_requested.connect(cb)
	Juice.shake(3.0)
	Juice.shake_requested.disconnect(cb)
	check_near(got[0], 1.0, 0.0001, "trauma clamped to 1")

func test_sfx_synth_builds_and_caches_presets() -> void:
	var s := SfxSynth.get_stream("pulse_hit")
	check(s != null, "known preset builds")
	check(s.data.size() == int(0.18 * SfxSynth.MIX_RATE) * 2, "16-bit mono sample count matches duration")
	check(SfxSynth.get_stream("pulse_hit") == s, "stream cached")
	check(SfxSynth.get_stream("nope") == null, "unknown preset is null")

func test_overlapping_flashes_restore_original_color() -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = BoxMesh.new()
	world.add_child(mi)
	ToonUtil.apply_toon(mi, TOON)
	var mat: ShaderMaterial = mi.get_surface_override_material(0)
	var original: Color = mat.get_shader_parameter("base_color")
	ToonUtil.flash(mi, mi, Color.WHITE, 0.05)
	ToonUtil.flash(mi, mi, Color.RED, 0.05)
	check(mat.get_shader_parameter("base_color") == Color.RED, "latest flash colour shows")
	await wait_ms(200)
	check(mat.get_shader_parameter("base_color") == original, "original colour restored, not the first flash colour")

func test_camera_follows_target_and_shake_decays() -> void:
	var target := Node3D.new()
	target.name = "Target"
	world.add_child(target)
	var cam = CameraRig.new()   # untyped: trauma/target_path live on the script, not Camera3D
	cam.target_path = NodePath("../Target")
	world.add_child(cam)
	await wait_ms(50)
	target.global_position = Vector3(4, 0, 0)
	await wait_ms(1000)
	check_near(cam.global_position.x, 4.0, 0.1, "camera converges on target x")
	Juice.shake(0.5)
	check_near(cam.trauma, 0.5, 0.001, "camera receives shake trauma")
	await wait_ms(600)
	check(cam.trauma < 0.1, "trauma decays")

func test_wave_spawns_expanding_ring_that_cleans_up() -> void:
	var before := tree.root.get_child_count()
	Juice.wave(Vector3(1, 0, 2), 1.5, Color(0.4, 1.0, 0.9), 0.15)
	var ring: MeshInstance3D = tree.root.get_child(tree.root.get_child_count() - 1)
	check(tree.root.get_child_count() == before + 1, "wave adds one ring")
	check_near(ring.global_position.x, 1.0, 0.001, "ring centred on emitter")
	var start_scale := ring.scale.x
	await wait_ms(80)
	check(is_instance_valid(ring) and ring.scale.x > start_scale, "ring expands")
	await wait_ms(400)
	check(not is_instance_valid(ring), "ring frees itself after the wave")
