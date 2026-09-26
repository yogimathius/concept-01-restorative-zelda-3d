extends CharacterBody3D

@export var speed: float = 4.0
@export var gravity: float = 20.0
@export var max_hp: int = 3
@export var invincibility_time: float = 0.6
@export var attack_range: float = 1.1
@export var attack_damage: int = 1

var facing := Vector2.DOWN
var attacking := false
var hp: int
var invincible := false
var start_position: Vector3

@onready var visuals: Node3D = $Visuals
@onready var anim_player: AnimationPlayer = $Visuals/hero/AnimationPlayer

const TOON_MATERIAL: ShaderMaterial = preload("res://shaders/toon_outline_material.tres")

func _ready() -> void:
	ToonUtil.apply_toon(visuals, TOON_MATERIAL)
	hp = max_hp
	start_position = global_position
	GameEvents.player_hp_changed.emit(hp, max_hp)

func _physics_process(delta: float) -> void:
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if input_dir.length() > 0.01:
		facing = input_dir.normalized()
		visuals.rotation.y = atan2(facing.x, facing.y)

	velocity.x = input_dir.x * speed
	velocity.z = input_dir.y * speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	move_and_slide()

	if Input.is_action_just_pressed("attack"):
		attack()

	if anim_player:
		var moving := input_dir.length() > 0.01
		if not attacking:
			if moving and anim_player.current_animation != "walk":
				anim_player.play("walk")
			elif not moving and anim_player.current_animation != "idle":
				anim_player.play("idle")

func attack() -> void:
	if attacking:
		return
	attacking = true
	if anim_player and anim_player.has_animation("attack"):
		anim_player.play("attack")
		await get_tree().create_timer(0.15).timeout
		_try_hit_enemies()
		await anim_player.animation_finished
	else:
		_try_hit_enemies()
	attacking = false

func _try_hit_enemies() -> void:
	var facing3 := Vector3(facing.x, 0.0, facing.y).normalized()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var to_enemy: Vector3 = enemy.global_position - global_position
		to_enemy.y = 0.0
		var dist := to_enemy.length()
		if dist > attack_range:
			continue
		if dist > 0.05 and facing3.dot(to_enemy.normalized()) < 0.3:
			continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(attack_damage)

func take_damage(amount: int) -> void:
	if invincible or hp <= 0:
		return
	hp -= amount
	GameEvents.player_hp_changed.emit(hp, max_hp)
	flash(Color(1.0, 0.3, 0.3))
	if hp <= 0:
		await get_tree().create_timer(0.3).timeout
		respawn()
		return
	invincible = true
	await get_tree().create_timer(invincibility_time).timeout
	invincible = false

func respawn() -> void:
	hp = max_hp
	global_position = start_position
	velocity = Vector3.ZERO
	GameEvents.player_hp_changed.emit(hp, max_hp)

func flash(color: Color, duration: float = 0.15) -> void:
	var meshes := ToonUtil.get_mesh_instances(visuals)
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
