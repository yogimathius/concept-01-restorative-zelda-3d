extends Node
## Game-feel toolkit (autoload "Juice"). Every verb connection, overload,
## heart loss and restore calls through here so feel is tuned in one place.

signal shake_requested(trauma: float)

const HITSTOP_SCALE := 0.05
const PLAYER_POOL_SIZE := 8

var hitstop_enabled := true
var _hitstop_until_ms := 0
var _players: Array[AudioStreamPlayer] = []
var _next_player := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in PLAYER_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

func hitstop(ms: int) -> void:
	if not hitstop_enabled or ms <= 0:
		return
	_hitstop_until_ms = maxi(_hitstop_until_ms, Time.get_ticks_msec() + ms)
	Engine.time_scale = HITSTOP_SCALE

func _process(_delta: float) -> void:
	# Ended by the wall clock, not a SceneTreeTimer: timers count smoothed frame
	# deltas, which drift from real time, and an early fire could never tell it
	# was early, leaving the game stuck in slow motion.
	if _hitstop_until_ms > 0 and Time.get_ticks_msec() >= _hitstop_until_ms:
		_hitstop_until_ms = 0
		Engine.time_scale = 1.0

func is_hitstopped() -> bool:
	return Engine.time_scale < 1.0

func shake(trauma: float) -> void:
	shake_requested.emit(clampf(trauma, 0.0, 1.0))

func haptic(ms: int) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)

func sfx(name: String, pitch_jitter := 0.08) -> void:
	var stream := SfxSynth.get_stream(name)
	if stream == null:
		push_warning("Juice.sfx: unknown sound '%s'" % name)
		return
	var player := _players[_next_player]
	_next_player = (_next_player + 1) % _players.size()
	player.stream = stream
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.play()

func burst(at: Vector3, color: Color, amount := 14) -> void:
	var parent: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	var particles := CPUParticles3D.new()
	particles.one_shot = true
	particles.emitting = false
	particles.amount = amount
	particles.lifetime = 0.35
	particles.explosiveness = 1.0
	particles.direction = Vector3.UP
	particles.spread = 70.0
	particles.initial_velocity_min = 2.5
	particles.initial_velocity_max = 5.0
	particles.gravity = Vector3(0, -12, 0)
	var mesh := SphereMesh.new()
	mesh.radius = 0.06
	mesh.height = 0.12
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mesh.material = mat
	particles.mesh = mesh
	parent.add_child(particles)
	particles.global_position = at
	particles.emitting = true
	get_tree().create_timer(1.0, true, false, true).timeout.connect(particles.queue_free)

## Expanding flat energy ring (the Pulse's visible emission). Cosmetic only:
## driven by a tween, frees itself when done.
func wave(at: Vector3, radius: float, color: Color, duration := 0.2) -> void:
	var parent: Node = get_tree().current_scene if get_tree().current_scene else get_tree().root
	var torus := TorusMesh.new()
	torus.inner_radius = 0.85
	torus.outer_radius = 1.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	torus.material = mat
	var ring := MeshInstance3D.new()
	ring.mesh = torus
	parent.add_child(ring)
	ring.global_position = at
	ring.scale = Vector3(0.2, 0.1, 0.2)
	var t := ring.create_tween().set_parallel(true).set_ignore_time_scale(true)
	t.tween_property(ring, "scale", Vector3(radius, 0.1, radius), duration) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	t.tween_property(mat, "albedo_color:a", 0.0, duration)
	t.chain().tween_callback(ring.queue_free)
