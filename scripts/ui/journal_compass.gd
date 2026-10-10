class_name JournalCompass
extends Control
## One optional direction hint. A bearing is not an automatically computed route.
var region: Node3D
var _label: Label
var _direction := Vector2.ZERO
var _style := StyleBoxFlat.new()
var _refresh_left := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(182,38)
	_style.bg_color = Color(0.06,0.16,0.20,0.9)
	_style.set_corner_radius_all(8)
	_label = Label.new()
	_label.position = Vector2(28,4)
	_label.size = Vector2(149,32)
	_label.add_theme_font_size_override("font_size",9)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	hide()

func _process(delta: float) -> void:
	_refresh_left -= delta
	if _refresh_left > 0: return
	_refresh_left = 0.1
	position = Vector2(region.get_viewport().get_visible_rect().size.x-198,66)
	var navigation: Dictionary = region.journal.navigation(region)
	visible = not navigation.is_empty() and not get_tree().paused and not region.recovering and (region.story == null or not region.story.dialogue.visible)
	if not visible: return
	_label.text = navigation.title + "\n" + navigation.caption
	_direction = navigation.direction
	if region.builder.valley_mode:
		_direction = region.get_node("Camera3D").screen_direction(_direction)
	queue_redraw()

func _draw() -> void:
	draw_style_box(_style,Rect2(Vector2.ZERO,size))
	var center := Vector2(14,19)
	if _direction == Vector2.ZERO:
		draw_circle(center,4,Color("f4dda4"))
	else:
		var side := _direction.orthogonal()
		draw_colored_polygon(PackedVector2Array([center+_direction*10,center-_direction*6+side*5,center-_direction*6-side*5]),Color("f4dda4"))
