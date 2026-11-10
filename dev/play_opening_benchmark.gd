extends SceneTree
## Persistent playtest sandbox; normal production progress is never read or written.
func _init() -> void: call_deferred("run")
func run() -> void:
	DisplayServer.window_set_title("Broken Waterway — opening playtest (separate save)")
	var region: Node3D = load("res://scenes/levels/region1.tscn").instantiate()
	region.save_path = "user://opening-benchmark-preview.json"
	root.add_child(region)
	current_scene = region
