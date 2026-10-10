class_name RestorationLoot
extends Node3D
## A visible discovery lifts out of its restored place and travels to the bag.
var item_id := ""
var hero: Hero
var _age := 0.0
var _start := Vector3.ZERO
var _piece: Node3D
func _ready() -> void:
	_start = global_position
	_piece = GearVisuals.make_piece(item_id) if not item_id.is_empty() else Node3D.new()
	if item_id.is_empty(): GearVisuals._gem(_piece,Vector3(0,0.5,0),0.2,Color("9fe5b9"),0.5)
	add_child(_piece)
	_piece.scale = Vector3.ONE*0.65
	var label := Label3D.new()
	label.text = RestorationInventory.ITEMS[item_id].name if not item_id.is_empty() else "Supplies + a travelling cup"
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position.y = 1.5
	label.font_size = 28
	label.pixel_size = 0.006
	label.outline_size = 7
	label.modulate = Color("ffe0a4")
	add_child(label)
func _process(delta: float) -> void:
	_age += delta
	_piece.rotation.y += delta*2.8
	if _age < 1.0: global_position = _start+Vector3.UP*(0.5+sin(_age*PI)*0.55)
	elif is_instance_valid(hero):
		var t := minf(1,(_age-1.0)/0.65)
		global_position = (_start+Vector3.UP*0.5).lerp(hero.global_position+Vector3.UP*0.7,t)
		_piece.scale = Vector3.ONE*(0.65*(1-t))
	if _age >= 1.7: queue_free()
