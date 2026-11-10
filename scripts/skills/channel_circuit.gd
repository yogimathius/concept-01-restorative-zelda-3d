class_name ChannelCircuit
extends Node3D
## Two authored receivers teach safe Charge transfer without precise aim or timers.
## The bell is a renewable source, but each receiver's world reward is unique.
const SOURCE_AT := Vector3(25.5,0,19.0)
const RECEIVERS := [
	{"id":"lantern_beds","title":"lantern beds","at":Vector3(20.5,0,22.5),"label":"LANTERN BED","color":Color("e9d48a")},
	{"id":"exchange_lamp","title":"exchange lamp","at":Vector3(12.5,0,16.5),"label":"EXCHANGE LAMP","color":Color("a4e6dc")},
]
var region: Node3D
var _source: Node3D
var _source_globe: MeshInstance3D
var _receivers := {}
var _carried: MeshInstance3D
var _last_state := ""
var _time := 0.0

func _ready() -> void:
	name = "ChannelCircuit"
	_source = _post(SOURCE_AT,"BELL CAPACITOR",Color("8dcce2"))
	_source_globe = _source.get_node("Globe")
	for definition in RECEIVERS:
		_receivers[definition.id] = _post(definition.at,definition.label,definition.color)
	_carried = MeshInstance3D.new()
	_carried.name = "CarriedCharge"
	var orb := SphereMesh.new()
	orb.radius = 0.18
	orb.height = 0.36
	_carried.mesh = orb
	_carried.material_override = _material(Color("bdf4e4"),1.4)
	add_child(_carried)
	if completed("lantern_beds") and completed("exchange_lamp"):
		region.waykeeper.channel_carry = false
	_sync()

func _post(at: Vector3, title: String, tint: Color) -> Node3D:
	var post := Node3D.new()
	post.name = title.replace(" ","")
	post.position = at + Vector3.UP*region.builder.surface_height(Vector2(at.x,at.z))
	add_child(post)
	var base := CylinderMesh.new()
	base.top_radius = 0.30
	base.bottom_radius = 0.42
	base.height = 0.44
	base.radial_segments = 12
	_piece(post,"Ceramic",base,Vector3(0,0.22,0),_material(Color("d9cab3")))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.27
	ring.outer_radius = 0.39
	_piece(post,"Bronze",ring,Vector3(0,0.47,0),_material(Color("bda472"),0.2))
	var glass := SphereMesh.new()
	glass.radius = 0.22
	glass.height = 0.34
	_piece(post,"Globe",glass,Vector3(0,0.63,0),_material(tint.darkened(0.6)))
	var label := Label3D.new()
	label.name = "Caption"
	label.text = title
	label.position.y = 1.34
	label.font_size = 27
	label.pixel_size = 0.009
	label.outline_size = 4
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color("efe4b9")
	post.add_child(label)
	return post

func _piece(parent: Node3D, title: String, mesh: Mesh, at: Vector3, material: Material) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.name = title
	piece.mesh = mesh
	piece.position = at
	piece.material_override = material
	parent.add_child(piece)
	return piece

func _material(tint: Color, glow := 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.emission_enabled = glow>0
	material.emission = tint
	material.emission_energy_multiplier = glow
	return material

func source_ready() -> bool:
	return region.builder.entities.M3.get("restored",false)

func receiver_ready(id: String) -> bool:
	if not source_ready(): return false
	return id != "lantern_beds" or region.builder.entities.M6.get("restored",false)

func completed(id: String) -> bool:
	if id == "lantern_beds": return region.builder.entities.M6.runtime.ecology.states.charged
	if id == "exchange_lamp": return region.story_flags.has("exchange_powered")
	return false

func remaining() -> int:
	var count := 0
	for definition in RECEIVERS:
		if receiver_ready(definition.id) and not completed(definition.id): count += 1
	return count

func _distance_to(post: Node3D) -> float:
	var offset: Vector3 = post.global_position-region.hero.global_position
	offset.y = 0
	return offset.length()

func use() -> bool:
	if region.region_id != "R2": return false
	if not source_ready():
		region.waykeeper._message("The sluice bell must be restored before it can carry Charge")
		return false
	var nearest: Dictionary = {}
	var best := 5.5
	for definition in RECEIVERS:
		var distance: float = _distance_to(_receivers[definition.id])
		if distance < best:
			best = distance
			nearest = definition
	if region.waykeeper.channel_carry:
		if not nearest.is_empty(): return _deliver(nearest)
		region.waykeeper._message("Charge held · tap Channel beside an unlit ceramic receiver")
		return false
	if _distance_to(_source) <= 5.5:
		if remaining() == 0:
			region.waykeeper._message("Both receivers carry the bell's Charge now")
			return false
		if not region.waykeeper._spend_flow("channel"): return false
		region.waykeeper.channel_carry = true
		region.hero.play_anim(&"attack")
		Juice.wave(_source.global_position+Vector3.UP*0.6,2.1,Color("8ce6dd"),0.75)
		region.waykeeper._message("Charge held safely · carry it to a dark ceramic receiver")
		_sync()
		region._save_journey()
		return true
	if not nearest.is_empty():
		region.waykeeper._message("That receiver needs Charge from the restored bell capacitor")
	else:
		region.waykeeper._message("Approach the bell capacitor, then tap Channel to carry Charge")
	return false

func _deliver(definition: Dictionary) -> bool:
	var id: String = definition.id
	if completed(id):
		region.waykeeper._message("The %s already carries Charge" % definition.title)
		return false
	if not receiver_ready(id):
		region.waykeeper._message("Restore the lantern beds before sending Charge into their roots")
		return false
	region.waykeeper.channel_carry = false
	if id == "lantern_beds":
		var ecology: RestorationSite = region.builder.entities.M6.runtime.ecology
		ecology.states.charged = true
		ecology.states.flourishing = true
	else:
		region.story_flags.exchange_powered = true
	region.waykeeper.meaningful("channel","R2/"+id+"/charged",3)
	var reward: Dictionary = region.progression.award_activity(20)
	region._configure_restoration()
	region._update_level_hud()
	region._level_toast.text = "+%d XP · %s lit" % [reward.earned,definition.title]
	region._toast_left = 4.0
	region.hero.play_anim(&"attack")
	Juice.wave(_receivers[id].global_position+Vector3.UP*0.6,3.0,definition.color,1.0)
	Juice.burst(_receivers[id].global_position+Vector3.UP*0.6,definition.color,20)
	region.waykeeper._message("Charge reaches the %s · the place can work again" % definition.title)
	_sync()
	region._save_journey()
	return true

func _sync() -> void:
	var signature := "%s/%s/%s/%s" % [source_ready(),completed("lantern_beds"),completed("exchange_lamp"),region.waykeeper.channel_carry]
	if signature == _last_state: return
	_last_state = signature
	_source_globe.material_override = _material(Color("8ce6dd") if source_ready() else Color("586a72"),0.9 if source_ready() else 0.0)
	for definition in RECEIVERS:
		var lit: bool = completed(definition.id)
		var globe: MeshInstance3D = _receivers[definition.id].get_node("Globe")
		globe.material_override = _material(definition.color if lit else Color("606b73"),1.1 if lit else 0.0)
		_receivers[definition.id].get_node("Caption").text = definition.label + (" · LIT" if lit else " · DARK")
	_carried.visible = region.waykeeper.channel_carry

func _process(delta: float) -> void:
	_time += delta
	_sync()
	var guiding: bool = region.waykeeper.progress.active == "channel"
	_source.get_node("Caption").visible = guiding and source_ready() and remaining() > 0 and _distance_to(_source) <= 5.5
	for definition in RECEIVERS:
		_receivers[definition.id].get_node("Caption").visible = guiding and receiver_ready(definition.id) and not completed(definition.id) and _distance_to(_receivers[definition.id]) <= 5.5
	if region.waykeeper.channel_carry:
		_carried.global_position = region.hero.global_position+Vector3(0.55,1.2+sin(_time*3.0)*0.08,0)
		_carried.rotate_y(delta*2.0)
