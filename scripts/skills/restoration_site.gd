class_name RestorationSite
extends Node3D
## Independent ecological requirements, persistent state and readable world cues.
var target: RegionCreature
var journey: WaykeeperJourney
var profile := {}
var states := {"cleared":false,"stabilized":false,"seen":false,"flourishing":false,"cultivated":false,"linked":false,"charged":false,"bloomed":false}
var _stones: Node3D
var _braces: Node3D
var _irrigation: Node3D
var _water: MeshInstance3D
var _time := 0.0
var _last_progress := -1.0

func setup(p_target: RegionCreature, p_journey: WaykeeperJourney, p_profile: Dictionary) -> void:
	target = p_target
	journey = p_journey
	profile = p_profile
	name = "Ecology"
	target.add_child(self)

func _ready() -> void:
	_stones = Node3D.new()
	_stones.name = "StoneObstruction"
	add_child(_stones)
	if requires("cleared"):
		for i in 4:
			var stone := BoxMesh.new()
			stone.size = Vector3(0.42,0.4+i*0.09,0.48)
			var piece := _mesh(stone,Vector3((i-1.5)*0.38,0.3,0.8),Color("796783"))
			piece.rotation_degrees = Vector3(i*7,i*24,12-i*6)
			remove_child(piece)
			_stones.add_child(piece)
	_braces = Node3D.new()
	_braces.name = "GroundedRoots"
	add_child(_braces)
	for side in [-1,1]:
		var rod := CylinderMesh.new()
		rod.height = 1.3
		rod.top_radius = 0.035
		rod.bottom_radius = 0.06
		rod.radial_segments = 6
		var piece := _mesh(rod,Vector3(side*0.44,0.48,0),Color("d5bbff"),0.4)
		piece.rotation.z = side * 0.56
		remove_child(piece)
		_braces.add_child(piece)
	var water := CylinderMesh.new()
	water.height = 0.045
	water.top_radius = 1.05
	water.bottom_radius = 1.05
	_water = _mesh(water,Vector3(0,0.045,0),Color("66aebc"),0.1)
	if profile.get("optional_anchor",false):
		_irrigation = Node3D.new()
		_irrigation.name = "LivingIrrigation"
		add_child(_irrigation)
		for side in [-1,1]:
			var channel := BoxMesh.new()
			channel.size = Vector3(0.08,0.04,2.7)
			var piece := _mesh(channel,Vector3(side*1.1,0.08,0),Color("67e0c7"),0.25)
			remove_child(piece)
			_irrigation.add_child(piece)
			var basket := CylinderMesh.new()
			basket.top_radius = 0.22
			basket.bottom_radius = 0.18
			basket.height = 0.26
			var harvest := _mesh(basket,Vector3(side*1.1,0.20,1.4),Color("dabb79"))
			remove_child(harvest)
			_irrigation.add_child(harvest)
	_sync()

func optional_available() -> bool:
	return target.restored and profile.get("optional_anchor",false) and not states.cultivated

func requires(condition: String) -> bool:
	return profile.get("requirements",[]).has(condition)

func ready_to_restore() -> bool:
	for condition in profile.get("requirements",[]):
		if not states.get(condition,false): return false
	return true

func mend_limit() -> float:
	return 1.0 if ready_to_restore() else float(profile.get("cap",0.45))

func pending() -> Array:
	var out := []
	for condition in profile.get("requirements",[]):
		if not states.get(condition,false): out.append(condition)
	return out

func status() -> String:
	if target.restored:
		if states.bloomed: return "Garden in bloom · new seed grows here" + ("\nAnchor can still steady the irrigation" if optional_available() else "") if target.id == "M1" else "Willow canopy grown · safe shelter renews Stability"
		if states.charged: return "Lantern beds lit · Charge reaches the living reeds"
		if optional_available():
			return "Garden restored · Anchor secures irrigation\n" + (journey.teacher_hint("anchor") if not journey.progress.unlocked.has("anchor") else "Optional · clear irrigation renews Flow")
		return "Garden connected · water reaches both beds" if states.linked else "Irrigation thriving · Neri can tend the beds; water renews Flow" if states.cultivated else ("Flourishing" if states.flourishing else "Restored")
	var remaining := pending()
	if remaining.is_empty(): return "Ready to Mend · hold to complete recovery"
	var condition: String = remaining[0]
	var skill: String = WaykeeperDefinitions.REQUIREMENT_SKILLS[condition]
	var reason: String = profile.get("reasons",{}).get(condition,"Stone blocks the water · Force clears it" if condition == "cleared" else "Roots are shifting · Anchor steadies them")
	if not journey.progress.unlocked.has(skill): reason += "\n" + journey.teacher_hint(skill)
	elif target.progress >= mend_limit()-0.001: reason += "\nSwipe the medallion up, or choose %s in SKILLS" % WaykeeperDefinitions.SKILLS[skill].name
	else: reason += "\nMend can help partially; your progress stays"
	return reason

func accepts(skill: String) -> bool:
	if target.restored: return skill == "anchor" and optional_available()
	return (skill == "force" and requires("cleared") and not states.cleared) or (skill == "anchor" and requires("stabilized") and not states.stabilized)

func resolve(condition: String, skill: String) -> bool:
	if condition == "cultivated":
		if skill != "anchor" or not optional_available(): return false
		states.cultivated = true
		states.flourishing = true
		journey.meaningful("anchor",journey.region.region_id+"/"+target.id+"/irrigation",2)
		Juice.wave(global_position+Vector3.UP*0.1,2.7,Color("89ebc3"),0.9)
		_sync()
		return true
	if not requires(condition) or states.get(condition,false) or target.restored: return false
	states[condition] = true
	states.seen = true
	journey.meaningful(skill,journey.region.region_id+"/"+target.id+"/"+condition,2)
	if condition == "cleared":
		for stone in _stones.get_children():
			var direction: Vector3 = (stone.position + Vector3(0.1,0,0.2)).normalized()
			create_tween().tween_property(stone,"position",stone.position+direction*1.7+Vector3.UP*0.2,0.5)
			create_tween().tween_property(stone,"scale",Vector3.ONE*0.01,0.65)
		Juice.burst(global_position+Vector3.UP*0.3,Color("efc896"),14)
	else:
		Juice.wave(global_position+Vector3.UP*0.08,1.4,Color("c8b5ff"),0.8)
	_sync(condition == "cleared")
	return true

func to_data() -> Dictionary:
	return states.duplicate()

func apply_data(data: Dictionary) -> void:
	for key in states: states[key] = data.get(key,false) == true
	if target.restored:
		states.cleared = true
		states.stabilized = true
	_sync()

func _sync(animate_stones := false) -> void:
	if not is_instance_valid(_stones): return
	if not animate_stones: _stones.visible = requires("cleared") and not states.cleared and not target.restored
	if is_instance_valid(_irrigation): _irrigation.visible = states.cultivated
	_braces.visible = requires("stabilized") and states.stabilized
	_water.visible = requires("cleared") and (states.cleared or target.progress>0.1)
	var material := _water.get_active_material(0) as StandardMaterial3D
	material.albedo_color = Color("63dcc0") if states.cleared else Color("7d7990")

func _physics_process(delta: float) -> void:
	_time += delta
	if target.restored:
		target.model.rotation.z = 0
		_sync()
		return
	if requires("stabilized"):
		target.model.rotation.z = sin(_time*1.8)*0.10 if not states.stabilized else 0.0
	if absf(target.progress-_last_progress)>0.005:
		_last_progress = target.progress
		_sync()
	if target.global_position.distance_to(journey.region.hero.global_position)<6:
		states.seen = true
	if target.progress >= float(profile.get("cap",1.0))-0.001 and target.progress>0:
		journey.meaningful("mend",journey.region.region_id+"/"+target.id+"/viable",1)

func _mesh(mesh: Mesh, at: Vector3, color: Color, glow := 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = glow>0
	material.emission = color
	material.emission_energy_multiplier = glow
	mesh.surface_set_material(0,material)
	add_child(node)
	return node
