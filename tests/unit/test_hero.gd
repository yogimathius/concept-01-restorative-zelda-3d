extends TestCase

const HERO_SCENE: PackedScene = preload("res://scenes/hero/hero.tscn")

func spawn_hero(cls: HeroClass = null) -> Hero:
	add_floor()
	var hero: Hero = HERO_SCENE.instantiate()
	hero.use_device_input = false
	hero.hero_class = cls if cls else HeroClass.new()
	world.add_child(hero)
	hero.global_position = Vector3(0, 0.02, 0)
	return hero

func planar_speed(hero: Hero) -> float:
	return Vector2(hero.velocity.x, hero.velocity.z).length()

func add_hazard(pos: Vector3, size: Vector3) -> HazardZone:
	var hz := HazardZone.new()
	hz.size = size
	hz.show_visual = false
	world.add_child(hz)
	hz.global_position = pos
	return hz

# --- movement ---

func test_accelerates_to_top_speed() -> void:
	var hero := spawn_hero()
	await step(2)
	hero.move_input = Vector2(1, 0)
	await step(3)
	check(planar_speed(hero) < 4.0, "still accelerating after 3 frames")
	await step(30)
	check_near(planar_speed(hero), 4.5, 0.1, "reaches base speed")

func test_weight_lowers_top_speed() -> void:
	var hero := spawn_hero()
	await step(2)
	hero.gauge.add(&"weight", 99.0)
	hero.move_input = Vector2(1, 0)
	await step(40)
	check_near(planar_speed(hero), 4.5 * lerpf(1.0, 0.55, 0.99), 0.1, "weighted top speed")

func test_friction_stops_hero_when_input_released() -> void:
	var hero := spawn_hero()
	await step(2)
	hero.move_input = Vector2(1, 0)
	await step(30)
	hero.move_input = Vector2.ZERO
	await step(12)
	check(planar_speed(hero) < 0.05, "stopped within 0.2 s")

func test_charge_lowers_friction_so_hero_overshoots() -> void:
	var hero := spawn_hero()
	await step(2)
	hero.gauge.add(&"charge", 99.0)
	hero.move_input = Vector2(1, 0)
	await step(30)
	hero.move_input = Vector2.ZERO
	await step(12)
	check(planar_speed(hero) > 1.0, "charged hero is still sliding after 0.2 s")

func test_turn_rate_is_capped() -> void:
	var hero := spawn_hero()
	await step(2)
	hero.move_input = Vector2(0, -1)   # opposite of initial facing (DOWN = +z)
	await step(6)
	check_near(absf(hero.facing.angle_to(Vector2.DOWN)), 14.0 * 6.0 / 60.0, 0.12, "turned 14 rad/s for 6 frames")

# --- dash ---

func test_dash_travels_dash_distance() -> void:
	var hero := spawn_hero()
	await step(2)
	var start_z := hero.global_position.z
	hero.request_dash()
	await step(30)
	check_near(hero.global_position.z - start_z, 3.8, 0.35, "dash distance + exit drift along facing")

func test_weight_shortens_dash() -> void:
	var hero := spawn_hero()
	await step(2)
	hero.gauge.add(&"weight", 99.0)
	var start_z := hero.global_position.z
	hero.request_dash()
	await step(30)
	check(hero.global_position.z - start_z < 2.3, "weighted dash is roughly half length")

func test_dash_has_cooldown() -> void:
	var hero := spawn_hero()
	await step(2)
	var count := [0]
	hero.dashed.connect(func() -> void: count[0] += 1)
	hero.request_dash()
	hero.request_dash()
	check(count[0] == 1, "second dash ignored during dash")
	await step(40)
	hero.request_dash()
	check(count[0] == 2, "dash available again after cooldown")

func test_dash_iframes_block_state_and_force() -> void:
	var hero := spawn_hero()
	await step(2)
	hero.request_dash()
	hero.receive_influence(Influence.state(null, &"weight", 50.0))
	check_near(hero.gauge.value(&"weight"), 0.0, 0.001, "state blocked during dash")
	await step(15)
	hero.receive_influence(Influence.state(null, &"weight", 50.0))
	check_near(hero.gauge.value(&"weight"), 50.0, 0.001, "state applies after dash")

# --- hearts and overload ---

func test_weight_overload_costs_heart_and_roots() -> void:
	var hero := spawn_hero()
	await step(2)
	hero.gauge.add(&"weight", 100.0)
	check(hero.hearts == 4, "overload costs a heart")
	check(hero.rooted_left > 0.0, "weight overload roots")
	var start := hero.global_position
	hero.move_input = Vector2(1, 0)
	await step(30)
	check(hero.global_position.distance_to(start) < 0.05, "rooted hero can't move")

func test_charge_overload_surges_in_heading() -> void:
	var hero := spawn_hero()
	await step(2)
	hero.move_input = Vector2(1, 0)
	await step(30)
	var start_x := hero.global_position.x
	hero.gauge.add(&"charge", 100.0)
	hero.move_input = Vector2(-1, 0)   # surge ignores input
	await step(30)
	check(hero.hearts == 4, "overload costs a heart")
	check(hero.global_position.x - start_x > 3.5, "surged forward despite opposite input")

func test_invulnerability_blocks_second_heart_loss() -> void:
	var hero := spawn_hero()
	await step(2)
	hero.gauge.add(&"weight", 100.0)
	hero.gauge.add(&"weight", 100.0)
	check(hero.hearts == 4, "second overload inside invulnerability costs no heart")

func test_overload_and_hazard_same_frame_costs_one_heart() -> void:
	var hero := spawn_hero()
	await step(2)
	hero.gauge.add(&"weight", 100.0)
	hero.receive_influence(Influence.hazard(null))
	check(hero.hearts == 4, "only one heart lost")

func test_losing_last_heart_emits_failed_once() -> void:
	var hero := spawn_hero()
	await step(2)
	var count := [0]
	hero.failed.connect(func() -> void: count[0] += 1)
	for i in 6:
		hero.invulnerable_left = 0.0
		hero.lose_heart(&"test")
	check(hero.hearts == 0, "hearts floor at zero")
	check(count[0] == 1, "failed emitted exactly once")

func test_restore_hearts_refills_and_clears_states() -> void:
	var hero := spawn_hero()
	await step(2)
	hero.lose_heart(&"test")
	hero.gauge.add(&"charge", 40.0)
	hero.restore_hearts()
	check(hero.hearts == 5, "hearts refilled")
	check_near(hero.gauge.value(&"charge"), 0.0, 0.001, "states cleared")

# --- knockback ---

func test_force_knocks_hero_back() -> void:
	var hero := spawn_hero()
	await step(2)
	var start_x := hero.global_position.x
	hero.receive_influence(Influence.force(null, 2.0, Vector3.RIGHT))
	await step(30)
	check(hero.global_position.x - start_x > 0.25, "knocked back along force")

func test_weight_resists_knockback() -> void:
	var hero := spawn_hero()
	await step(2)
	hero.gauge.add(&"weight", 99.0)
	var start_x := hero.global_position.x
	hero.receive_influence(Influence.force(null, 2.0, Vector3.RIGHT))
	await step(30)
	check(hero.global_position.x - start_x < 0.1, "heavy hero barely moves")

# --- hazards ---

func test_hazard_costs_heart_and_respawns_at_safe_position() -> void:
	var hero := spawn_hero()
	add_hazard(Vector3(4, 0, 0), Vector3(2, 1, 2))
	await step(2)
	hero.move_input = Vector2(1, 0)
	for i in 120:
		await step()
		if hero.hearts < 5:
			break
	hero.move_input = Vector2.ZERO
	await step(2)
	check(hero.hearts == 4, "hazard costs a heart")
	check(hero.global_position.x < 2.25, "respawned outside the hazard margin")

func test_dash_into_hazard_still_costs_heart() -> void:
	var hero := spawn_hero()
	add_hazard(Vector3(0, 0, 3), Vector3(2, 1, 2))
	await step(5)
	hero.request_dash()   # facing +z, straight into the hazard
	await step(20)
	check(hero.hearts == 4, "dash i-frames don't cover hazards")
	check(hero.global_position.z < 2.0, "respawned before the hazard")
