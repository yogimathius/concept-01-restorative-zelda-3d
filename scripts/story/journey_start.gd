extends Node
func _ready() -> void:
	if OS.has_feature("river_valley"):
		get_tree().change_scene_to_file.call_deferred("res://scenes/levels/river_valley.tscn")
		return
	var region := "R1"
	var path := "user://restoration-journey.json"
	if FileAccess.file_exists(path):
		var data = JSON.parse_string(FileAccess.get_file_as_string(path))
		if data is Dictionary and (data.get("version",0)==2 or data.get("version",0)==3 or data.get("version",0)==4 or data.get("version",0)==5) and data.get("active_region","")=="R2": region = "R2"
	get_tree().change_scene_to_file.call_deferred("res://scenes/levels/region%s.tscn" % region.trim_prefix("R"))
