class_name WaterwaySoundscape
extends Node
## Sparse original motif plus adaptive water/bird layers. One loop per layer.
var region: Node3D
var layers := {}
var _refresh := 0.0
func _ready() -> void:
	name = "WaterwaySoundscape"
	process_mode = Node.PROCESS_MODE_ALWAYS
	for id in ["motif","water","birds"]:
		var player := AudioStreamPlayer.new()
		player.stream = load("res://assets/audio/"+id+".wav").duplicate()
		player.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		player.stream.loop_end = player.stream.data.size()/2
		player.volume_db = -22 if id=="motif" else -48
		add_child(player)
		layers[id] = player
		player.play()
func _process(delta: float) -> void:
	_refresh -= delta
	if _refresh>0: return
	_refresh = 0.20
	var healthy: bool = region.hero._near_healthy_water
	var count := 0
	for entry in region.builder.entities.values():
		if entry.get("restored",false): count += 1
	var water := -23.0 if healthy else -34.0 if count>0 else -48.0
	var birds := -30.0 if count>0 else -48.0
	layers.water.volume_db = lerpf(layers.water.volume_db,water,0.16)
	layers.birds.volume_db = lerpf(layers.birds.volume_db,birds,0.12)
func _exit_tree() -> void:
	for player in layers.values(): player.stop()
