extends SceneTree
## Separate persistent valley sandbox. Never opens the production save.
func _init() -> void: call_deferred("run")
func run() -> void:
	DisplayServer.window_set_title("Broken Waterway — river valley prototype (separate save)")
	var region: Node3D = load("res://scenes/levels/river_valley.tscn").instantiate()
	root.add_child(region)
	current_scene = region
