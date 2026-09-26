extends Camera3D

@export var target_path: NodePath
@export var offset: Vector3 = Vector3(0, 8, 8)

var target: Node3D

func _ready() -> void:
	target = get_node_or_null(target_path)

func _process(_delta: float) -> void:
	if target:
		global_position = target.global_position + offset
		look_at(target.global_position, Vector3.UP)
