extends Verb
## Hold to mend an eligible creature; the beam makes target and refusal
## visible in the world, rather than hiding an unfinished Restore slot.

@export var reach := 1.8
@export var rate := 1.0
@export var movement := 0.3
@export var aim_dot := -1.0
var target: Node3D
var _beam: MeshInstance3D
var _sound_left := 0.0
var _reach_ring: MeshInstance3D
var feedback := ""
var _feedback_left := 0.0
var _completed_left := 0.0

func on_pressed() -> void:
	active = true
	_completed_left = 0.0
	feedback = "Mend ready · move close to a corrupted creature"
	if hero.restoration_only: feedback = "Mend ready · approach a dark grove or spring"
	if not is_instance_valid(_reach_ring):
		_reach_ring = MeshInstance3D.new()
		var ring := TorusMesh.new()
		ring.inner_radius = reach - 0.035
		ring.outer_radius = reach
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(0.35, 1.0, 0.8)
		ring.material = material
		_reach_ring.mesh = ring
		hero.add_child(_reach_ring)
		_reach_ring.position.y = 0.06
	_reach_ring.visible = true
	(_reach_ring.mesh as TorusMesh).inner_radius = reach - 0.035
	(_reach_ring.mesh as TorusMesh).outer_radius = reach
	Juice.wave(hero.global_position + Vector3.UP * 0.08, reach, Color(0.35, 1.0, 0.8), 0.45)

func on_released() -> void:
	active = false
	if is_instance_valid(target) and not target.restored and target.progress > 0:
		feedback = "Healing saved · hold Mend again to continue" if hero.restoration_only else "Mend interrupted · hold again to continue; progress fades"
	target = null
	if is_instance_valid(_beam):
		_beam.visible = false
	if is_instance_valid(_reach_ring):
		_reach_ring.visible = false
	_feedback_left = 4.0

func move_multiplier() -> float:
	return movement if active else 1.0

func _update(delta: float) -> void:
	if not active:
		_feedback_left = maxf(0, _feedback_left - delta)
		if _feedback_left <= 0: feedback = ""
		return
	if hero.is_dashing() or not hero.is_controllable():
		on_released()
		return
	if _completed_left > 0:
		_completed_left = maxf(0, _completed_left - delta)
		return
	target = null
	var story_target: Node3D
	var care_target: Node3D
	var blocked_story: Node3D
	var nearest_story := INF
	var nearest_care := INF
	var nearest_blocked := INF
	for n in hero.find_influenceables(reach):
		if not n.has_method("mend_status") or n.restored:
			continue
		var offset: Vector3 = n.global_position - hero.global_position
		offset.y = 0
		if offset.length() > 0.1 and hero.facing_3d().dot(offset.normalized()) < aim_dot:
			continue
		if n.has_method("has_line_to") and not n.has_line_to(hero):
			continue
		var distance := offset.length()
		if hero.restoration_only and n is RegionCreature:
			if n.can_mend() and distance < nearest_story:
				nearest_story = distance
				story_target = n
			elif not n.can_mend() and distance < nearest_blocked:
				nearest_blocked = distance
				blocked_story = n
		elif distance < nearest_care:
			nearest_care = distance
			care_target = n
	target = story_target if story_target else care_target if care_target else blocked_story
	if target == null:
		if is_instance_valid(_beam): _beam.visible = false
		feedback = _missing_target_feedback()
		return
	var eligible: bool = target.can_mend()
	var amount := rate * delta
	if hero.restoration_only and eligible:
		var limit: float = target.ecology.mend_limit() if target.ecology else 1.0
		var per_second: float = WaykeeperDefinitions.SKILLS.mend.flow_per_second
		if hero.learned_nodes.has("gentle_current") and hero._near_healthy_water: per_second *= 0.75
		if hero.learned_nodes.has("gentle_foundation") and target.ecology and target.ecology.states.stabilized:
			per_second *= 0.75
			hero.resources.protection_left = maxf(hero.resources.protection_left,0.1)
		amount = minf(amount, maxf(0, limit - target.progress))
		amount = minf(amount, hero.resources.flow * rate / per_second)
		if amount <= 0.0:
			feedback = "Flow returning · your healing stays; healthy springs help recovery"
			if is_instance_valid(_beam): _beam.visible = false
			return
		hero.resources.spend(amount / rate * per_second)
	Influence.send(target, Influence.restore(hero, amount))
	if target.restored:
		feedback = "Restored · crossing made" if target.kind == "bearer" else "Restored · its sparks now help you"
		if hero.restoration_only: feedback = "Grove restored · life and a crossing have returned" if target.kind == "bearer" else "Spring restored · clear water is flowing again"
		if target.has_method("completion_feedback"): feedback = target.completion_feedback()
		_completed_left = 3.0
		if is_instance_valid(_beam): _beam.visible = false
		return
	feedback = target.mend_status()
	if eligible and (target.ecology == null or target.ecology.ready_to_restore()): feedback = "Mending · keep holding · %d%%" % roundi(target.progress * 100)
	_draw_beam(target.global_position, eligible)
	_sound_left -= delta
	if _sound_left <= 0:
		_sound_left = 0.8
		Juice.sfx("mend" if eligible else "refuse")

func _missing_target_feedback() -> String:
	var closest: Node3D
	var distance := INF
	for n in hero.find_influenceables(12.0):
		if not n.has_method("mend_status") or n.restored: continue
		var offset: Vector3 = n.global_position - hero.global_position
		offset.y = 0
		if offset.length() < distance:
			distance = offset.length()
			closest = n
	if closest == null: return "Mend ready · explore for a dark grove or spring" if hero.restoration_only else "Mend ready · find a corrupted creature; ordinary stones need Force"
	if distance > reach: return "Move a little closer to the grove or spring to heal it" if hero.restoration_only else "Mend ready · move closer to the creature, inside the green circle"
	var direction: Vector3 = closest.global_position - hero.global_position
	direction.y = 0
	if direction.length() > 0.1 and hero.facing_3d().dot(direction.normalized()) < aim_dot:
		return "Mend ready · face the creature"
	return "Mend blocked · move around the stone or wall"

func _exit_tree() -> void:
	if is_instance_valid(_beam): _beam.queue_free()
	if is_instance_valid(_reach_ring): _reach_ring.queue_free()

func _draw_beam(at: Vector3, eligible: bool) -> void:
	if not is_instance_valid(_beam):
		_beam = MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 0.035
		cylinder.bottom_radius = 0.08
		cylinder.height = 1.0
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		cylinder.material = material
		_beam.mesh = cylinder
		hero.add_child(_beam)
	var from := hero.global_position + Vector3.UP * 0.65
	var to := at + Vector3.UP * 0.55
	var direction := to - from
	_beam.visible = true
	_beam.global_position = (from + to) * 0.5
	var up := direction.normalized()
	var right := up.cross(Vector3.FORWARD).normalized()
	if right.length() < 0.1: right = Vector3.RIGHT
	_beam.global_basis = Basis(right, up, right.cross(up)).scaled(Vector3(1, direction.length(), 1))
	(_beam.mesh.material as StandardMaterial3D).albedo_color = Color(0.35, 1.0, 0.8) if eligible else Color(0.75, 0.45, 0.7)
