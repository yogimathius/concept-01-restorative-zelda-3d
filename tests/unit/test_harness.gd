extends TestCase

func test_physics_steps_advance() -> void:
	var start := Engine.get_physics_frames()
	await step(3)
	check(Engine.get_physics_frames() >= start + 3, "physics frames should advance by 3")

func test_floor_is_added_to_world() -> void:
	var floor_body := add_floor()
	check(floor_body.is_inside_tree(), "floor should be inside the test world")

func test_check_near_records_failure() -> void:
	check_near(1.0, 2.0, 0.1, "deliberate")
	check(failures.size() == 1, "check_near should record a failure")
	failures.clear()
