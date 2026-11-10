class_name WeaveRelay
extends Node3D
## An authored pair in the marsh's shared water network. The same forgiving
## gesture and ecological save rule serve different social and resource outcomes.
const LINKS := [
	{"id":"garden_nursery","source_site":"M2","sink_site":"M1","source_at":Vector3(8.5,0,10.0),"sink_at":Vector3(13.5,0,10.0),"source_label":"NURSERY FEED","sink_label":"GARDEN INLET","title":"garden and nursery","hint":"Restore Neri's garden and the reed nursery before linking their relays","complete":"Water reaches both beds · Neri can tend them together"},
	{"id":"spring_refuge","source_site":"M5","sink_site":"M4","source_at":Vector3(6.5,0,19.0),"sink_at":Vector3(11.5,0,19.0),"source_label":"SPRING OUTLET","sink_label":"WILLOW ROOTS","title":"spring and willow refuge","hint":"Restore Daro's spring and the willow refuge before linking their relays","complete":"Clear spring water reaches the willow roots · Daro's mint can grow"},
]
var region: Node3D
var profile: Dictionary = LINKS[0]
var _posts: Array[Node3D] = []
var _labels: Array[Label3D] = []
var _water: MeshInstance3D
var _herb_bed: Node3D
var _current: Array[MeshInstance3D] = []
var _line: Line2D
var _hint: Label
var _source_halo: Sprite2D
var _sink_halo: Sprite2D
var _gesture := false
var _source := 0
var _candidate := false
var _linked_visual := false
var _time := 0.0

func _ready() -> void:
	name = "Weave_"+str(profile.id)
	var a: Vector3 = profile.source_at
	var b: Vector3 = profile.sink_at
	var middle: Vector3 = (a+b)*0.5
	var span: float = a.distance_to(b)
	for i in 2:
		var position_3d: Vector3 = a if i == 0 else b
		var post := Node3D.new()
		post.name = "SourceRelay" if i == 0 else "SinkRelay"
		post.position = position_3d + Vector3.UP * region.builder.surface_height(Vector2(position_3d.x,position_3d.z))
		add_child(post)
		_posts.append(post)
		var pedestal := CylinderMesh.new()
		pedestal.top_radius = 0.32
		pedestal.bottom_radius = 0.40
		pedestal.height = 0.35
		pedestal.radial_segments = 12
		_mesh(post,pedestal,Vector3(0,0.18,0),Color("d8cab1"))
		var ring := TorusMesh.new()
		ring.inner_radius = 0.30
		ring.outer_radius = 0.43
		_mesh(post,ring,Vector3(0,0.38,0),Color("74c9cd"),0.5)
		var marker := Label3D.new()
		marker.name = "RelayLabel"
		marker.text = profile.source_label if i == 0 else profile.sink_label
		marker.font_size = 28
		marker.pixel_size = 0.011
		marker.outline_size = 3
		marker.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		marker.position.y = 1.2
		marker.modulate = Color("e8e0b5")
		post.add_child(marker)
		_labels.append(marker)
	for i in 2:
		var broken := BoxMesh.new()
		broken.size = Vector3(1.55,0.12,0.32)
		_mesh(self,broken,Vector3(a.x+0.9 if i==0 else b.x-0.9,0.10,middle.z),Color("ae9c86"))
	var stream := BoxMesh.new()
	stream.size = Vector3(span-1.6,0.045,0.19)
	_water = _mesh(self,stream,Vector3(middle.x,0.20,middle.z),Color("71e2d4"),0.65)
	for i in 4:
		var glint := SphereMesh.new()
		glint.radius = 0.08
		glint.height = 0.16
		_current.append(_mesh(self,glint,Vector3(a.x+0.9+i*0.8,0.27,middle.z),Color("d5fff0"),0.85))
	if profile.id == "spring_refuge": _make_herb_bed()
	var layer := CanvasLayer.new()
	layer.layer = 13
	region.add_child(layer)
	var halo_texture: Texture2D = load("res://assets/ui/weave-target.svg")
	_source_halo = Sprite2D.new()
	_source_halo.texture = halo_texture
	_source_halo.scale = Vector2.ONE*0.47
	layer.add_child(_source_halo)
	_sink_halo = Sprite2D.new()
	_sink_halo.texture = halo_texture
	_sink_halo.scale = Vector2.ONE*0.68
	layer.add_child(_sink_halo)
	_line = Line2D.new()
	_line.width = 7.0
	_line.default_color = Color("87cde7")
	_line.antialiased = true
	layer.add_child(_line)
	_hint = Label.new()
	_hint.add_theme_font_size_override("font_size",14)
	_hint.add_theme_color_override("font_color",Color("f4e6b9"))
	_hint.add_theme_color_override("font_outline_color",Color("112c34"))
	_hint.add_theme_constant_override("outline_size",5)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_hint)
	_sync()

func _make_herb_bed() -> void:
	_herb_bed = Node3D.new()
	_herb_bed.name = "LivingMint"
	_herb_bed.position = Vector3(8.3,0,17.7)
	add_child(_herb_bed)
	var earth := BoxMesh.new()
	earth.size = Vector3(2.65,0.10,1.10)
	_mesh(_herb_bed,earth,Vector3(0,0.08,0),Color("35534b"))
	for side in [-1,1]:
		var lip := BoxMesh.new()
		lip.size = Vector3(2.7,0.16,0.09)
		_mesh(_herb_bed,lip,Vector3(0,0.17,float(side)*0.57),Color("d8c9ae"))
	for i in 7:
		var stem := CylinderMesh.new()
		stem.height = 0.48+float(i%3)*0.07
		stem.top_radius = 0.025
		stem.bottom_radius = 0.045
		stem.radial_segments = 6
		var x := (float(i)-3.0)*0.35
		var z := sin(float(i)*2.3)*0.26
		var height: float = stem.height
		_mesh(_herb_bed,stem,Vector3(x,0.16+height*0.5,z),Color("347c61"))
		for j in 2:
			var leaf := SphereMesh.new()
			leaf.radius = 0.14
			leaf.height = 0.075
			var side: float = -1.0 if j==0 else 1.0
			var blade := _mesh(_herb_bed,leaf,Vector3(x+side*0.11,0.36+float(j)*0.09,z+side*0.07),Color("4faf72") if i%2==0 else Color("6abf78"))
			blade.scale = Vector3(1.45,1,0.85)
			blade.rotation.y = side*0.46
		var crown := SphereMesh.new()
		crown.radius = 0.085
		crown.height = 0.12
		_mesh(_herb_bed,crown,Vector3(x,0.19+height,z),Color("a9d482"))

func _mesh(parent: Node3D, mesh: Mesh, at: Vector3, color: Color, glow := 0.0) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = glow > 0
	material.emission = color
	material.emission_energy_multiplier = glow
	piece.material_override = material
	parent.add_child(piece)
	return piece

func linked() -> bool:
	return ready() and region.builder.entities[profile.source_site].runtime.ecology.states.linked and region.builder.entities[profile.sink_site].runtime.ecology.states.linked

func ready() -> bool:
	return region.builder.entities[profile.source_site].get("restored",false) and region.builder.entities[profile.sink_site].get("restored",false)

func distance_to_hero() -> float:
	return minf(region.hero.global_position.distance_to(_posts[0].global_position),region.hero.global_position.distance_to(_posts[1].global_position))

func near_hero() -> bool:
	return distance_to_hero() <= 7.0

func _sync() -> void:
	_linked_visual = linked()
	_water.visible = _linked_visual
	for glint in _current: glint.visible = _linked_visual
	if _herb_bed: _herb_bed.visible = _linked_visual
	_hint.visible = _gesture
	_line.visible = _gesture
	_source_halo.visible = _gesture
	_sink_halo.visible = _gesture

func _process(delta: float) -> void:
	_time += delta
	if linked() != _linked_visual: _sync()
	if _linked_visual:
		for i in _current.size(): _current[i].position.x = float(profile.source_at.x)+0.9 + fposmod(_time*1.15+i*0.85,3.2)
	for marker in _labels:
		marker.visible = ready() and region.waykeeper.progress.unlocked.has("weave") and not linked()
	if _gesture:
		var destination := _screen(1-_source)
		_source_halo.position = _screen(_source)
		_sink_halo.position = destination
		_sink_halo.modulate = Color("c7fff1") if _candidate else Color("d0e9df",0.75)
		var screen: Vector2 = region.get_viewport().get_visible_rect().size
		_hint.position = Vector2(clampf(destination.x+15,10,screen.x-170),clampf(destination.y-58,58,screen.y-42))
		_hint.text = "RELEASE TO LINK" if _candidate else "DRAG TO THE OTHER RELAY"
		_line.default_color = Color("9ff2db") if _candidate else Color("87cde7")

func _screen(index: int) -> Vector2:
	return region.get_node("Camera3D").unproject_position(_posts[index].global_position + Vector3.UP*0.6)

func begin() -> bool:
	if not region.hero.is_controllable() or region.hero.is_dashing(): return false
	if linked():
		region.waykeeper._message("The %s already share water" % profile.title)
		return false
	if not ready():
		region.waykeeper._message(profile.hint)
		return false
	if not region.waykeeper.progress.unlocked.has("weave"): return false
	var first: float = region.hero.global_position.distance_to(_posts[0].global_position)
	var second: float = region.hero.global_position.distance_to(_posts[1].global_position)
	if not near_hero():
		region.waykeeper._message("Move toward the ceramic relays by the %s" % profile.title)
		return false
	_source = 0 if first <= second else 1
	_gesture = true
	_candidate = false
	_line.points = PackedVector2Array([_screen(_source),_screen(_source)])
	_sync()
	return true

func drag(at: Vector2) -> void:
	if not _gesture: return
	_candidate = at.distance_to(_screen(1-_source)) <= 105.0
	_line.points = PackedVector2Array([_screen(_source),_screen(1-_source) if _candidate else at])

func end(at: Vector2) -> bool:
	if not _gesture: return false
	drag(at)
	var commit := _candidate and ready() and not linked()
	_gesture = false
	_sync()
	if not commit:
		region.waykeeper._message("Drag toward the other glowing relay, then release")
		return false
	if not region.waykeeper._spend_flow("weave"): return false
	var source: RestorationSite = region.builder.entities[profile.source_site].runtime.ecology
	var sink: RestorationSite = region.builder.entities[profile.sink_site].runtime.ecology
	source.states.linked = true
	sink.states.linked = true
	sink.states.flourishing = true
	_sync()
	_water.scale = Vector3(0.03,1,1)
	create_tween().tween_property(_water,"scale",Vector3.ONE,0.8).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	region.waykeeper.meaningful("weave","R2/"+str(profile.id)+"/link",3)
	var reward: Dictionary = region.progression.award_activity(20)
	region.waykeeper.progress.set_level(region.progression.get_level())
	region._configure_restoration()
	region._update_level_hud()
	region._level_toast.text = "+%d XP · %s connected" % [reward.earned,profile.title]
	region._toast_left = 4.0
	var center: Vector3 = (profile.source_at+profile.sink_at)*0.5
	Juice.wave(center+Vector3.UP*0.3,5.0,Color("8cf0d8"),1.7)
	Juice.burst(center+Vector3.UP*0.4,Color("a7ead1"),24)
	region.waykeeper._message(profile.complete)
	region._save_journey()
	return true

func cancel() -> void:
	_gesture = false
	_candidate = false
	if is_instance_valid(_line): _sync()
