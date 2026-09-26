extends Node3D

@export var corrupted_tile_scene: PackedScene
@export var corrupted_tiles_root: NodePath
@export var grid_size: int = 5
@export var tile_spacing: float = 1.0
@export var toon_material: Material

func _ready() -> void:
	if toon_material:
		ToonUtil.apply_toon(self, toon_material)
	var root := get_node(corrupted_tiles_root)
	var half := grid_size / 2
	for i in range(grid_size):
		for j in range(grid_size):
			var t: Node3D = corrupted_tile_scene.instantiate()
			t.position = Vector3((i - half) * tile_spacing, 0, (j - half) * tile_spacing)
			root.add_child(t)
			if toon_material:
				ToonUtil.apply_toon(t, toon_material)
