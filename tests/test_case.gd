class_name TestCase
extends RefCounted
## Base for headless tests. tests/run_all.gd runs every test_* method on a
## fresh instance, calling before_each/after_each around it. Tests may await
## step()/wait_ms() to let physics and timers advance.

var tree: SceneTree
var world: Node3D
var failures: PackedStringArray = PackedStringArray()

func before_each() -> void:
	world = Node3D.new()
	world.name = "TestWorld"
	tree.root.add_child(world)
	# global time scaling would skew physics timing in tests. Looked up at
	# runtime: autoload names aren't resolvable when run_all.gd compiles this.
	tree.root.get_node("Juice").hitstop_enabled = false

func after_each() -> void:
	if is_instance_valid(world):
		world.queue_free()
	tree.root.get_node("Juice").hitstop_enabled = true
	Engine.time_scale = 1.0
	await tree.process_frame

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func check_near(actual: float, expected: float, tolerance: float, message: String) -> void:
	check(absf(actual - expected) <= tolerance,
		"%s (expected %.3f ± %.3f, got %.3f)" % [message, expected, tolerance, actual])

func step(frames: int = 1) -> void:
	for i in frames:
		await tree.physics_frame

func wait_ms(ms: int) -> void:
	var end := Time.get_ticks_msec() + ms
	while Time.get_ticks_msec() < end:
		await tree.process_frame

## Adds a static floor whose top surface sits at y = 0.
func add_floor(size: float = 40.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size, 0.2, size)
	shape.shape = box
	body.add_child(shape)
	body.position = Vector3(0, -0.1, 0)
	world.add_child(body)
	return body
