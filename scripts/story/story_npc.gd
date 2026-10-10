class_name StoryNPC
extends Node3D
## Inhabitants with readable clothing, names and a contextual touch interaction.
var npc_id := ""
var display_name := ""
var role := ""
var cloth := Color("9d7770")
var hero: Hero
var _visuals: Node3D
var _name: Label3D
var _ring: MeshInstance3D
var _time := 0.0
var _animation: AnimationPlayer
var _was_near := false
var workplace := Vector3.ZERO
var _route := []
var surface_height: Callable
static var _surface_materials := {}

func _ready() -> void:
	workplace = global_position
	add_to_group("story_npc")
	_visuals = Node3D.new()
	add_child(_visuals)
	var model := make_model(npc_id)
	_visuals.add_child(model)
	_animation = model.find_child("AnimationPlayer",true,false) as AnimationPlayer
	_play("idle")
	_name = Label3D.new()
	_name.text = display_name
	_name.font_size = 30
	_name.pixel_size = 0.012
	_name.outline_size = 3
	_name.position.y = 1.85
	_name.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name.modulate = Color("fff0b9")
	add_child(_name)
	_ring = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.40
	ring.outer_radius = 0.46
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("f1d68e")
	ring.material = mat
	_ring.mesh = ring
	_ring.position.y = 0.035
	add_child(_ring)

func _process(delta: float) -> void:
	_time += delta
	_visuals.position.y = 0.0
	if not is_instance_valid(hero): return
	var near := global_position.distance_to(hero.global_position) < 2.8
	_ring.visible = near
	if not _route.is_empty() and global_position.distance_to(_route[0])<0.08: _route.pop_front()
	var destination: Vector3 = _route[0] if not _route.is_empty() else workplace
	if not near and global_position.distance_to(destination)>0.08:
		_play("walk")
		var direction := destination-global_position
		global_position = global_position.move_toward(destination,delta*1.1)
		if surface_height.is_valid(): global_position.y = surface_height.call(Vector2(global_position.x,global_position.z))
		_visuals.rotation.y = lerp_angle(_visuals.rotation.y,atan2(direction.x,direction.z),minf(1,delta*4))
	else:
		if not _animation or _animation.current_animation != "greeting" or not _animation.is_playing(): _play("idle")
	if near and not _was_near: _play("greeting")
	_was_near = near
	if near:
		var direction := hero.global_position-global_position
		_visuals.rotation.y = lerp_angle(_visuals.rotation.y,atan2(direction.x,direction.z),minf(1,delta*4))

static func make_model(id: String) -> Node3D:
	var asset_id := "daro" if id=="tavi" else "mara" if id=="edda" else "neri" if id=="sela" else "iona" if id=="bryn" else id
	var model := (load("res://assets/characters/npcs/"+asset_id+".glb") as PackedScene).instantiate() as Node3D
	# Set the portrait/world material before binding it to any mesh. Removing
	# an already-bound outline pass leaves stale GLES material dependencies.
	var material := ShaderMaterial.new()
	material.shader = Hero.TOON_MATERIAL.shader
	# Inhabitants use immutable palettes. Share their surfaces between world
	# and portrait instances instead of destroying/recreating shader materials
	# whenever a conversation closes (GLES can retain those dependencies).
	for mesh in ToonUtil.get_mesh_instances(model):
		for surface in mesh.mesh.get_surface_count():
			var key := id+"/"+str(mesh.name)+"/"+str(surface)
			if not _surface_materials.has(key):
				var original: Material = mesh.get_active_material(surface)
				var ink := ToonUtil.toon_material(original,material)
				var palette := {"tavi":Color("547969"),"edda":Color("a17362"),"sela":Color("806e9a"),"bryn":Color("5b8b94")}
				if palette.has(id) and original is BaseMaterial3D and original.resource_name.begins_with("cloth_"):
					var base: Color = ink.get_shader_parameter("base_color")
					ink.set_shader_parameter("base_color",base.lerp(palette[id],0.68))
				_surface_materials[key] = ink
			mesh.set_surface_override_material(surface,_surface_materials[key])
	return model
func _play(animation: String) -> void:
	if not _animation: return
	var clip := animation if _animation.has_animation(animation) else animation+"-loop"
	if _animation.has_animation(clip) and _animation.current_animation!=clip: _animation.play(clip,0.2)

func work_at(at: Vector3, waypoints: Array = []) -> void:
	if workplace==at: return
	workplace = at
	_route = waypoints.duplicate()
