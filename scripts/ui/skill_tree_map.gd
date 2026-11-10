class_name SkillTreeMap
extends Control
## Ceramic waterways connect disciplines; scroll container handles touch panning.
func _draw() -> void:
	var root_at := Vector2(335,28)
	for id in WaykeeperTree.NODES:
		var node: Dictionary = WaykeeperTree.NODES[id]
		var to: Vector2 = node.pos + Vector2(56,0)
		var sources: Array = node.parents
		if sources.is_empty():
			draw_polyline(PackedVector2Array([root_at,Vector2(to.x,65),to]),Color("537e78"),4,true)
		else:
			for parent in sources:
				var from: Vector2 = WaykeeperTree.NODES[parent].pos + Vector2(56,54)
				draw_polyline(PackedVector2Array([from,Vector2(from.x,to.y-18),Vector2(to.x,to.y-18),to]),WaykeeperTree.COLORS[node.branch].darkened(0.4),3,true)
	draw_circle(root_at,16,Color("d9bc7d"))
	draw_circle(root_at,10,Color("173b3b"))
