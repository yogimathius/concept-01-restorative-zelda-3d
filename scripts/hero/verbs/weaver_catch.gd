extends "res://scripts/hero/verbs/warden_pulse.gd"
## Tap for weak Force; hold to capture a shot, release along current facing.

var held_spark: ChargeSpark
var _holding := false
var _held_time := 0.0
var _caught_time := 0.0

func on_pressed() -> void:
	if not ready_to_use(): return
	_holding = true
	_held_time = 0
	active = true

func on_released() -> void:
	if not _holding: return
	_holding = false
	active = false
	if is_instance_valid(held_spark):
		held_spark.release(hero.facing_3d())
		held_spark = null
		Juice.sfx("pulse_emit")
	elif _held_time < 0.25 and hero.is_controllable():
		hero.play_anim(&"attack")
		_release_pulse()
	start_cooldown()

func _update(delta: float) -> void:
	if not _holding: return
	_held_time += delta
	if is_instance_valid(held_spark):
		_caught_time += delta
		held_spark.global_position = hero.global_position + hero.facing_3d() * 0.65 + Vector3.UP * 0.65
		if _caught_time > 2:
			held_spark.queue_free()
			held_spark = null
			hero.gauge.add(&"charge", 25)
			Juice.sfx("overload_surge")
		return
	for spark in hero.get_tree().get_nodes_in_group("spark"):
		if spark.captured or spark.friendly or spark.is_queued_for_deletion(): continue
		var offset: Vector3 = spark.global_position - hero.global_position
		offset.y = 0
		if offset.length() <= 1.5 and hero.facing_3d().dot(offset.normalized()) > 0.25:
			held_spark = spark
			spark.captured = true
			_caught_time = 0
			Juice.sfx("catch")
			Juice.wave(hero.global_position + Vector3.UP * 0.3, 0.9, PULSE_COLOR)
			break

func move_multiplier() -> float:
	return 0.8 if _holding else 1.0

func _exit_tree() -> void:
	if is_instance_valid(held_spark): held_spark.queue_free()
