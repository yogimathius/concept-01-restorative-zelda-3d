extends Area3D

@export var corrupted_tiles_root: NodePath
@export var restored_tiles_root: NodePath
@export var restored_tile_scene: PackedScene
@export var grid_size: int = 5
@export var tile_spacing: float = 1.0
@export var toon_material: Material

var healed := false
var player_in_range := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		player_in_range = true

func _on_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		player_in_range = false

func _process(_delta: float) -> void:
	if player_in_range and not healed and Input.is_action_just_pressed("interact"):
		_heal()

func _heal() -> void:
	healed = true
	var corrupted := get_node(corrupted_tiles_root)
	for tile in corrupted.get_children():
		tile.queue_free()
	var restored := get_node(restored_tiles_root)
	var half := grid_size / 2
	for i in range(grid_size):
		for j in range(grid_size):
			var t: Node3D = restored_tile_scene.instantiate()
			t.position = Vector3((i - half) * tile_spacing, 0, (j - half) * tile_spacing)
			restored.add_child(t)
			if toon_material:
				ToonUtil.apply_toon(t, toon_material)
