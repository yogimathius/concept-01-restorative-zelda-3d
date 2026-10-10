class_name RegionCreature
extends CharacterBody3D
## Creature grammar: force changes configuration, mend changes role.
## No health, damage, or hidden depletion meter.

var id := ""
var kind := ""
var builder: Node3D
var hero: Hero
var model: Node3D
var home := Rect2()
var spawn := Vector3.ZERO
var ecology: RestorationSite
var restored := false
var growths := 3
var progress := 0.0
var stagger_left := 0.0
var windup_left := -1.0
var recovery_left := 0.8
var _cracks := 0
var _crack_left := 0.0
var _regrow_left := 8.0
var _mending_left := 0.0
var _refuse_left := 0.0
var _last_glow := -1.0
var _growth_nodes: Array[Node] = []
var _target_ring: MeshInstance3D

func _ready() -> void:
	add_to_group("creature")
	add_to_group("influenceable")
	spawn = global_position
	for n in model.find_children("growth*", "", true, false):
		_growth_nodes.append(n)
	_target_ring = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.53
	ring.outer_radius = 0.60
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.25, 0.92, 0.75)
	ring.material = mat
	_target_ring.mesh = ring
	_target_ring.position.y = 0.04
	add_child(_target_ring)

func has_line_to(target: Node3D) -> bool:
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.65, target.global_position + Vector3.UP * 0.65)
	query.exclude = [get_rid()]
	query.collision_mask = 1
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.collider == target

func socket_choice() -> Dictionary:
	var e: Dictionary = builder.entities[id]
	var best := {}
	var distance := 2.01
	var spec: Dictionary = e.spec
	for socket in spec.get("sockets", [spec.get("socket", Vector2i.ZERO)]):
		var at: Vector3 = builder._center(builder._world_cell(spec.area, socket))
		var d := global_position.distance_to(at)
		if d < distance:
			distance = d
			best = {"at": socket}
	return best

func can_mend() -> bool:
	if restored: return false
	if builder.restoration_only: return progress < ecology.mend_limit() if ecology else true
	return growths == 0 and not socket_choice().is_empty() if kind == "bearer" else stagger_left > 0

func mend_status() -> String:
	if restored: return "Restored"
	if builder.restoration_only and ecology: return ecology.status()
	if builder.restoration_only: return "Hold Mend to bring this grove back" if kind == "bearer" else "Hold Mend to wake this spring"
	if kind == "bearer":
		if growths > 0: return "Use Force to shed its stone · %d growths" % growths
		if socket_choice().is_empty(): return "Lead it beside a bridge notch"
		return "Bare stone · hold Mend to make a crossing"
	return "Off balance · hold Mend" if stagger_left > 0 else "Interrupt its glow, or return its spark"

func receive_influence(inf: Influence) -> void:
	if restored: return
	if inf.kind == Influence.Kind.FORCE:
		if builder.restoration_only:
			if ecology and ecology.accepts("force"): ecology.journey.apply_force(ecology)
			return
		if kind == "bearer":
			if inf.tags.has("returned_spark"):
				while growths > 0: _shed(inf.direction)
			elif inf.amount >= 4:
				_shed(inf.direction)
			elif inf.amount >= 3:
				_cracks += 1
				_crack_left = 3
				if _cracks >= 2:
					_shed(inf.direction)
					_cracks = 0
			stagger_left = 0.75
		elif inf.amount >= 5 or inf.tags.has("returned_spark"):
			stagger_left = 2
			_play("stagger")
			Juice.wave(global_position + Vector3.UP * 0.1, 0.8, Color(1, 0.8, 0.3), 0.35)
		windup_left = -1
		recovery_left = 0.8
	elif inf.kind == Influence.Kind.RESTORE:
		if not can_mend():
			if builder.restoration_only: return
			if kind == "bearer" and growths > 0 and growths < 3 and _refuse_left <= 0:
				growths += 1
				_sync_growths()
				_refuse_left = 1.5
				Juice.burst(global_position + Vector3.UP * 0.7, Color(0.55, 0.4, 0.65), 8)
			return
		_mending_left = 0.15
		progress = minf(ecology.mend_limit() if ecology else 1.0, progress + inf.amount)
		if progress >= 1:
			var e: Dictionary = builder.entities[id]
			e.cell = Vector2i(floori(global_position.x), floori(global_position.z))
			if kind == "bearer" and not builder.restoration_only: e.spec.socket = socket_choice().at
			builder.restore(id)

func _shed(direction: Vector3) -> void:
	if growths <= 0: return
	growths -= 1
	_regrow_left = 8
	_sync_growths()
	builder.drop_chunk(global_position, direction)
	Juice.burst(global_position + Vector3.UP * 0.75, Color(0.55, 0.48, 0.6), 10)

func _sync_growths() -> void:
	for i in _growth_nodes.size():
		if is_instance_valid(_growth_nodes[i]): _growth_nodes[i].visible = i < growths

func _play(animation: String) -> void:
	var ap := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap and ap.has_animation(animation) and ap.current_animation != animation: ap.play(animation)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(hero) or hero.hearts <= 0: return
	_refuse_left = maxf(0, _refuse_left - delta)
	_mending_left = maxf(0, _mending_left - delta)
	if not builder.restoration_only and _mending_left <= 0: progress = maxf(0, progress - delta * 0.5)
	_target_ring.visible = not restored and (can_mend() or progress > 0)
	_target_ring.scale = Vector3.ONE * (1.0 + progress * 0.2)
	if restored:
		if kind == "charger" and not builder.restoration_only: _tick_turret(delta)
		return
	if absf(progress - _last_glow) > 0.001:
		_last_glow = progress
		for mesh in ToonUtil.get_mesh_instances(model):
			for surface in mesh.mesh.get_surface_count():
				var material: Material = mesh.get_active_material(surface)
				if material is ShaderMaterial: material.set_shader_parameter("mend_amount", progress)
	if builder.restoration_only:
		velocity = Vector3.ZERO
		return
	if kind == "bearer":
		_crack_left -= delta
		if _crack_left <= 0: _cracks = 0
		_regrow_left -= delta
		if _regrow_left <= 0 and growths < 3 and _mending_left <= 0:
			growths += 1
			_regrow_left = 8
			_sync_growths()
		if global_position.distance_to(hero.global_position) < 2.5 and has_line_to(hero):
			Influence.send(hero, Influence.state(self, &"weight", 12 * delta))
	# Once a valid channel starts, keep its opening until the player stops.
	# Otherwise the stagger can expire a frame before the last Mend tick.
	if _mending_left <= 0: stagger_left = maxf(0, stagger_left - delta)
	if stagger_left > 0 or _mending_left > 0: return
	var offset := hero.global_position - global_position
	offset.y = 0
	var distance := offset.length()
	var in_anchor_shelter := id == "C1" and hero.global_position.x < 36 and hero.global_position.z < 4
	if distance > 7 or in_anchor_shelter or not has_line_to(hero):
		windup_left = -1
		return
	model.rotation.y = atan2(offset.x, offset.z)
	if windup_left >= 0:
		windup_left -= delta
		if windup_left <= 0:
			windup_left = -1
			recovery_left = 1.3 if kind == "charger" else 1.0
			if kind == "charger":
				_fire(offset.normalized(), false)
			else:
				_play("slam")
				Juice.wave(global_position + Vector3.UP * 0.08, 1.5, Color(0.7, 0.5, 0.85), 0.3)
				if distance < 1.8:
					Influence.send(hero, Influence.state(self, &"weight", 30))
					Influence.send(hero, Influence.force(self, 6, offset.normalized()))
		return
	recovery_left -= delta
	if recovery_left <= 0 and (kind == "charger" or distance < 1.8):
		windup_left = 0.8 if kind == "charger" else 0.9
		_play("aim" if kind == "charger" else "slam")
		Juice.wave(global_position + Vector3.UP * 0.05, 0.6, Color(0.45, 0.75, 1) if kind == "charger" else Color(0.7, 0.4, 0.8), windup_left)
		return
	var direction := offset.normalized()
	var speed := 1.2 if kind == "bearer" else 1.6
	if kind == "charger":
		if distance >= 3.0: return
		direction = -direction
	elif distance < 1.25: return
	var next := global_position + direction * speed * delta
	var planar := Vector2(next.x, next.z)
	if not home.has_point(planar): return
	if not builder.can_walk(Vector2i(floori(next.x + direction.x * 0.4), floori(next.z + direction.z * 0.4))): return
	velocity = direction * speed
	velocity.y = -1
	move_and_slide()
	_play("walk-loop")

func _tick_turret(delta: float) -> void:
	recovery_left -= delta
	var spec: Dictionary = builder.entities[id].spec
	if not spec.has("conduit") or builder.entities[spec.conduit].get("powered", false): return
	var at: Vector3 = builder._center(builder.entities[spec.conduit].cell)
	if recovery_left <= 0:
		recovery_left = 1
		_fire((at - global_position).normalized(), true)

func _fire(direction: Vector3, friendly: bool) -> void:
	var spark := ChargeSpark.new()
	spark.builder = builder
	spark.hero = hero
	spark.source_id = id
	spark.direction = direction
	spark.friendly = friendly
	builder.add_child(spark)
	spark.global_position = global_position + direction * 0.8 + Vector3.UP * 0.65
	_play("fire")
	Juice.sfx("spark")

func snapshot() -> Dictionary:
	return {"position": global_position, "growths": growths, "restored": restored, "progress": progress, "stagger": stagger_left, "regrow": _regrow_left, "ecology":ecology.to_data() if ecology else {}}

func apply_snapshot(data: Dictionary) -> void:
	global_position = data.position
	growths = data.growths
	restored = data.restored
	progress = data.progress
	stagger_left = data.stagger
	_regrow_left = data.regrow
	if ecology: ecology.apply_data(data.get("ecology",{}))
	_sync_growths()

