class_name ChargeSpark
extends Node3D
## Swept projectiles cannot tunnel through a gate, wall, or chasm lane.

var source_id := ""
var builder: Node3D
var hero: Hero
var direction := Vector3.FORWARD
var speed := 6.0
var friendly := false
var captured := false
var life := 6.0

func _ready() -> void:
	add_to_group("spark")
	add_to_group("influenceable")
	var visual := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.13
	mesh.height = 0.26
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.35, 0.9, 1.0)
	mesh.material = material
	visual.mesh = mesh
	add_child(visual)

func _physics_process(delta: float) -> void:
	if captured: return
	life -= delta
	if life <= 0:
		queue_free()
		return
	var travel := speed * delta
	# Substeps also detect logical receivers, which deliberately have no
	# blocking collision in their ground tile.
	while travel > 0:
		var step := minf(travel, 0.12)
		var next := global_position + direction * step
		var query := PhysicsRayQueryParameters3D.create(global_position, next)
		query.collision_mask = 1
		if friendly: query.exclude = [hero.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			var body: Node = hit.collider
			if body is Hero:
				_hit_hero(body)
			elif body.has_method("receive_influence"):
				if body.get("id") != source_id or friendly:
					Influence.send(body, Influence.force(self, 8.0 if friendly else 2.0, direction, PackedStringArray(["returned_spark"]) if friendly else PackedStringArray()))
				queue_free()
			else:
				queue_free()
			return
		global_position = next
		if friendly and builder.try_power_near(global_position, 0.42):
			Juice.burst(global_position, Color(0.4, 1.0, 0.85), 10)
			queue_free()
			return
		if not friendly and is_instance_valid(hero) and _distance_to(hero.global_position) < 0.43:
			_hit_hero(hero)
			return
		travel -= step

func _distance_to(at: Vector3) -> float:
	var offset := global_position - at
	offset.y = 0
	return offset.length()

func _hit_hero(target: Hero) -> void:
	Influence.send(target, Influence.force(self, 2.0, direction))
	Influence.send(target, Influence.state(self, &"charge", 25.0))
	queue_free()

func receive_influence(inf: Influence) -> void:
	if inf.kind == Influence.Kind.FORCE:
		release(inf.direction)

func release(heading: Vector3) -> void:
	captured = false
	friendly = true
	direction = heading.normalized()
	speed = 7.8
	life = 6
