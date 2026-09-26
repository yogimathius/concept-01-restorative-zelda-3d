extends TestCase

func test_ambient_motes_emit_over_their_area() -> void:
	var m := AmbientMotes.new()
	m.size = Vector3(6, 1, 4)
	m.color = Color(0.7, 0.4, 0.9)
	m.amount = 24
	world.add_child(m)
	var p := m.particles
	check(p is CPUParticles3D and p.emitting, "emitting CPU particles (phone-safe)")
	check(p.amount == 24, "amount applied")
	check(p.emission_shape == CPUParticles3D.EMISSION_SHAPE_BOX and p.emission_box_extents == Vector3(3, 0.5, 2),
		"box emission matches area")

func test_hero_actions_leave_bursts() -> void:
	add_floor()
	var hero: Hero = preload("res://scenes/hero/hero.tscn").instantiate()
	hero.use_device_input = false
	hero.hero_class = HeroClass.new()
	world.add_child(hero)
	await step(2)
	var before := tree.root.get_child_count()
	hero.request_dash()
	hero.gauge.add(&"weight", 100.0)
	check(tree.root.get_child_count() >= before + 2, "dash puff and overload burst spawned")
