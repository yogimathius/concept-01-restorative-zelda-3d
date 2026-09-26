extends CharacterBody3D

@export var patrol_distance: float = 1.5
@export var speed: float = 1.0
@export var max_hp: int = 3
@export var contact_damage: int = 1
@export var stagger_time: float = 0.25

var start_x: float
var dir := 1.0
var hp: int
var stagger_timer := 0.0
var dead := false

@onready var mesh_root: Node = $enemy
@onready var damage_zone: Area3D = $DamageZone

func _ready() -> void:
	start_x = position.x
	hp = max_hp
	add_to_group("enemies")
	damage_zone.body_entered.connect(_on_damage_zone_body_entered)

func _physics_process(delta: float) -> void:
	if dead:
		return
	if stagger_timer > 0.0:
		stagger_timer -= delta
		return
	position.x += dir * speed * delta
	if position.x > start_x + patrol_distance:
		dir = -1.0
	elif position.x < start_x - patrol_distance:
		dir = 1.0
	rotation.y = 0.0 if dir > 0 else PI

func _on_damage_zone_body_entered(body: Node3D) -> void:
	if dead:
		return
	if body.has_method("take_damage"):
		body.take_damage(contact_damage)

func take_damage(amount: int) -> void:
	if dead:
		return
	hp -= amount
	stagger_timer = stagger_time
	flash(Color(1.0, 1.0, 1.0))
	if hp <= 0:
		die()

func die() -> void:
	dead = true
	$CollisionShape3D.disabled = true
	damage_zone.monitoring = false
	flash(Color(1.0, 1.0, 1.0))
	GameEvents.enemy_defeated.emit()
	var t := create_tween()
	t.tween_property(mesh_root, "scale", Vector3.ZERO, 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await t.finished
	queue_free()

func flash(color: Color, duration: float = 0.12) -> void:
	var meshes := ToonUtil.get_mesh_instances(mesh_root)
	var originals := {}
	for m in meshes:
		for i in range(m.mesh.get_surface_count()):
			var mat: Material = m.get_active_material(i)
			if mat is ShaderMaterial:
				originals[mat] = mat.get_shader_parameter("base_color")
				mat.set_shader_parameter("base_color", color)
	var t := create_tween()
	t.tween_interval(duration)
	t.tween_callback(func():
		for mat in originals:
			if is_instance_valid(mat):
				mat.set_shader_parameter("base_color", originals[mat])
	)
