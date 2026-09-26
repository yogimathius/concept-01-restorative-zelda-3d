extends SceneTree

var player: CharacterBody3D
var enemy: Node
var main: Node
var enemy_defeated_seen := false
var frame := 0

func _init() -> void:
	call_deferred("_setup")

func _setup() -> void:
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	main = main_scene.instantiate()
	get_root().add_child(main)
	player = main.get_node("Player")
	var game_events := get_root().get_node("GameEvents")
	game_events.enemy_defeated.connect(func():
		enemy_defeated_seen = true
		print("TEST: enemy_defeated signal received")
	)
	physics_frame.connect(_on_frame)

func _on_frame() -> void:
	frame += 1

	if frame == 5:
		enemy = main.get_node("Room/Enemy")
		print("Initial: player hp=", player.hp, "/", player.max_hp, " enemy hp=", enemy.hp, "/", enemy.max_hp)
		# real Area3D physics overlap, not a mock: teleport player onto the enemy's DamageZone
		player.global_position = enemy.global_position + Vector3(0, 0, 0.15)

	if frame == 15:
		# physics has had 10 frames to register the overlap and fire body_entered by now
		print("After real contact-zone overlap: player hp=", player.hp, " invincible=", player.invincible)
		assert(player.hp == player.max_hp - enemy.contact_damage, "contact damage did not apply via real Area3D overlap")
		assert(player.invincible, "player did not become invincible after taking damage")
		player.global_position = Vector3(20, 0.5, 20)
		player.invincible = false

	if frame == 20:
		# enemy.take_damage() is fully synchronous up to its death tween (only queue_free is deferred
		# behind an idle-based Tween, which this headless-no-window run can't tick -- see report)
		enemy.take_damage(1)
		print("after hit 1: hp=", enemy.hp, " dead=", enemy.dead)
		assert(enemy.hp == enemy.max_hp - 1)
		enemy.take_damage(1)
		print("after hit 2: hp=", enemy.hp, " dead=", enemy.dead)
		assert(enemy.hp == enemy.max_hp - 2)
		enemy.take_damage(1)
		print("after hit 3 (lethal): hp=", enemy.hp, " dead=", enemy.dead, " enemy_defeated_seen=", enemy_defeated_seen)
		assert(enemy.hp <= 0, "enemy hp did not reach 0")
		assert(enemy.dead, "enemy.dead was not set")
		assert(enemy_defeated_seen, "enemy_defeated signal never fired")

	if frame == 25:
		# confirm the real input path actually reaches attack() (the mid-swing hit-detection
		# delay inside attack() is idle-based and can't be driven to completion here -- see report)
		player.facing = Vector2.DOWN
		Input.action_press("attack")

	if frame == 27:
		Input.action_release("attack")
		print("player.attacking after simulated input = ", player.attacking)
		assert(player.attacking, "attack() was not triggered by simulated Input.action_press")

	if frame == 35:
		# respawn() logic tested directly and synchronously (it's normally scheduled behind
		# an idle-based timer in take_damage(); this exercises the method's own correctness)
		player.hp = 0
		player.global_position = Vector3(20, 0.5, 20)
		player.respawn()
		print("After respawn(): hp=", player.hp, "/", player.max_hp,
			" pos=", player.global_position, " start_pos=", player.start_position)
		assert(player.hp == player.max_hp, "respawn() did not restore full hp")
		assert(player.global_position.distance_to(player.start_position) < 0.01, "respawn() did not restore start position")

	if frame == 40:
		print("ALL COMBAT ASSERTIONS PASSED")
		quit()
