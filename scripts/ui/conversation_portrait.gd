class_name ConversationPortrait
extends TextureRect
## A close, lit view of the actual inhabitant; only renders during conversation.
var viewport: SubViewport
var subject: Node3D
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	viewport = SubViewport.new()
	viewport.size = Vector2i(568,580)
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(viewport)
	texture = viewport.get_texture()
	if DisplayServer.get_name()=="headless":
		viewport.disable_3d = true
		return
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 0.73
	viewport.add_child(camera)
	camera.position = Vector3(0.16,1.58,2.2)
	camera.look_at(Vector3(0,1.35,0))
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-35,-25,0)
	light.light_color = Color("ffead1")
	light.light_energy = 1.5
	viewport.add_child(light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15,155,0)
	fill.light_color = Color("a4d4d5")
	fill.light_energy = 0.7
	viewport.add_child(fill)
func show_subject(id: String) -> void:
	if subject:
		viewport.remove_child(subject)
		subject.queue_free()
		subject = null
	if id.is_empty():
		hide()
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	if DisplayServer.get_name()=="headless":
		show()
		return
	subject = StoryNPC.make_model(id)
	viewport.add_child(subject)
	subject.rotation.y = -0.18
	var animation := subject.find_child("AnimationPlayer",true,false) as AnimationPlayer
	if animation:
		var clip := "idle" if animation.has_animation("idle") else "idle-loop"
		if animation.has_animation(clip): animation.play(clip)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	show()
func stop() -> void:
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if subject:
		viewport.remove_child(subject)
		subject.queue_free()
		subject = null
