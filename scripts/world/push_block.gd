class_name PushBlock
extends StaticBody3D

var builder: Node3D
var cell := Vector2i.ZERO
var restored := false
var piece: KitPiece

func _ready() -> void:
	add_to_group("influenceable")
	add_to_group("push_block")
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.7, 0.7, 0.7)
	collision.shape = box
	collision.position.y = 0.35
	add_child(collision)
	piece = KitPiece.new()
	piece.family = "stone_chunk"
	piece.shape = "stone_chunk"
	piece.restored = restored
	add_child(piece)

func receive_influence(inf: Influence) -> void:
	if inf.kind != Influence.Kind.FORCE or inf.amount < 3: return
	var dir := Vector2i(signf(inf.direction.x), 0) if absf(inf.direction.x) > absf(inf.direction.z) else Vector2i(0, signf(inf.direction.z))
	var next := cell + dir
	if builder.level.char_at(next) == "_" and not builder._bridged(next):
		queue_free()
		return
	if not builder.can_walk(next): return
	for block in get_tree().get_nodes_in_group("push_block"):
		if block != self and block.cell == next and not block.is_queued_for_deletion(): return
	for creature in get_tree().get_nodes_in_group("creature"):
		if not creature.restored and Vector2(creature.global_position.x, creature.global_position.z).distance_to(Vector2(next) + Vector2.ONE * 0.5) < 0.85: return
	cell = next
	global_position = Vector3(cell.x + 0.5, 0, cell.y + 0.5)
	Juice.sfx("pulse_hit")
