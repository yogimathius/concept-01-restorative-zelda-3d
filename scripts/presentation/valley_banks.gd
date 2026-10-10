class_name ValleyBanks
extends Node3D
## Opaque instanced river craft: stone, layered crowns and reeds, plus a
## visible weir-to-landing channel. Presentation reads the restoration ledger.
var valley: Node3D
var water: MeshInstance3D
var basin_water: MeshInstance3D
var boat: Node3D
var landing_life: Node3D
var _batches := {}
var _wet := false
var _bed: MeshInstance3D
var _flow_tween: Tween
const CERAMIC := Color("bdc4af")
const BRONZE := Color("897554")
func _ready() -> void:
	name = "ValleyBanks"
	_banks()
	_woods()
	_trail_edges()
	_channel()
	_landing()
	_build_batches()
	RiverCraft.batch_static(self,[water,basin_water,_bed])
	RiverCraft.batch_static(landing_life)
	sync(valley.builder.entities.C3.get("restored",false),false)
func _instance(mesh: Mesh, color: Color, at: Vector3, scale_by: Vector3, yaw := 0.0, group := "bank") -> void:
	var key := str(mesh.get_instance_id())+str(color)+group
	if not _batches.has(key): _batches[key] = {"mesh":mesh,"color":color,"transforms":[]}
	var basis := Basis(Vector3.UP,yaw).scaled(scale_by)
	_batches[key].transforms.append(Transform3D(basis,at))
func _build_batches() -> void:
	for batch in _batches.values():
		var mesh := MultiMesh.new()
		mesh.transform_format = MultiMesh.TRANSFORM_3D
		mesh.mesh = batch.mesh
		mesh.instance_count = batch.transforms.size()
		for i in mesh.instance_count: mesh.set_instance_transform(i,batch.transforms[i])
		var node := MultiMeshInstance3D.new()
		node.multimesh = mesh
		node.material_override = RiverCraft.material(batch.color)
		add_child(node)
	_batches.clear()
func _banks() -> void:
	var stone := SphereMesh.new()
	stone.radial_segments = 12
	stone.rings = 5
	stone.radius = 1
	stone.height = 2
	var reed := CylinderMesh.new()
	reed.radial_segments = 5
	reed.top_radius = 0.015
	reed.bottom_radius = 0.035
	reed.height = 1
	var random := RandomNumberGenerator.new()
	random.seed = 51109
	for side in [-1,1]:
		for i in 32:
			var z := -38.0+i*1.5
			var x: float = 25.5+side*(1.7+random.randf_range(0.15,0.65))
			var at := Vector2(x,z)
			if absf(z-3.5)<4.5: continue
			_instance(stone,Color("767e77"),ValleyPlaces.point(at)+Vector3.DOWN*0.25,Vector3(random.randf_range(0.4,0.7),0.45,random.randf_range(0.6,1.1)),random.randf_range(0,TAU))
			for j in 4:
				var point := at+Vector2(side*0.55,random.randf_range(-0.4,0.4))
				_instance(reed,Color("788b62"),ValleyPlaces.point(point)+Vector3.UP*0.45,Vector3(1,random.randf_range(0.6,1.5),1))
	# Bank skirts expose stone down to the water instead of a paper-thin mesh.
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in [24.0,27.0]:
		for z in range(-40,12,2):
			var points := [Vector3(x,RiverValley.height_at(Vector2(x,z)),z),Vector3(x,RiverValley.height_at(Vector2(x,z+2)),z+2),Vector3(x,-1.05,z+2),Vector3(x,-1.05,z)]
			for index in ([0,1,2,0,2,3] if x==24 else [0,2,1,0,3,2]): tool.add_vertex(points[index])
	tool.generate_normals()
	RiverCraft.mesh(self,tool.commit(),Vector3.ZERO,Color("6c796e"))
func _woods() -> void:
	var trunk := CylinderMesh.new()
	trunk.height = 1
	trunk.top_radius = 0.07
	trunk.bottom_radius = 0.13
	trunk.radial_segments = 8
	var crown := SphereMesh.new()
	crown.radius = 1
	crown.height = 2
	crown.radial_segments = 16
	crown.rings = 6
	var random := RandomNumberGenerator.new()
	random.seed = 61109
	for grove in [Vector2(-8,-21),Vector2(16,-30),Vector2(51,-30),Vector2(83,-24),Vector2(84,13),Vector2(72,43),Vector2(16,40)]:
		for i in 9:
			var point: Vector2 = grove+Vector2(random.randf_range(-6,6),random.randf_range(-5,5))
			if not valley.walkable(point): continue
			var at := ValleyPlaces.point(point)
			var height := random.randf_range(2.8,4.5)
			var group := str(grove)
			_instance(trunk,Color("766d4d"),at+Vector3.UP*height*0.5,Vector3(1.6,height,1.6),0,group)
			for j in 4:
				var angle := TAU*j/4+i
				var radius := random.randf_range(0.7,1.1)
				_instance(crown,Color("4c8064") if j%2==0 else Color("608d6b"),at+Vector3(cos(angle)*0.65,height+float(j%2)*0.4,sin(angle)*0.65),Vector3(radius,0.7+radius*0.25,radius),angle,group)

func _trail_edges() -> void:
	# Ground-hugging stones and dry reeds pick out the route without fencing it.
	var stone := SphereMesh.new()
	stone.radial_segments = 10
	stone.rings = 5
	stone.radius = 1.0
	stone.height = 2.0
	var reed := CylinderMesh.new()
	reed.radial_segments = 5
	reed.top_radius = 0.012
	reed.bottom_radius = 0.04
	reed.height = 1.0
	var random := RandomNumberGenerator.new()
	random.seed = 52027
	for route in [
		[RiverValley.HIGH_ROUTE, 1.2],
		[RiverValley.UPPER_ROUTE, 1.3], [ValleyPlaces.SOUTH_ROUTE, 1.25],
		[ValleyPlaces.SUNLEAF_ROUTE, 1.2],
	]:
		var points: Array = route[0]
		for i in range(points.size() - 1):
			var steps := maxi(1, ceili(points[i].distance_to(points[i+1]) / 3.0))
			for step in steps:
				var t := (step + 0.5) / steps
				var center: Vector2 = valley._trail_curve(points, i, t)
				var before: Vector2 = valley._trail_curve(points, i, maxf(0.0, t - 0.02))
				var after: Vector2 = valley._trail_curve(points, i, minf(1.0, t + 0.02))
				var tangent := (after - before).normalized()
				if tangent.length_squared() < 0.1: continue
				for side in [-1, 1]:
					if random.randf() < 0.55: continue
					var at: Vector2 = center + tangent.orthogonal() * side * (float(route[1]) + random.randf_range(1.0, 1.9))
					if not valley.walkable(at) or valley.trail_strength(at) > 0.24: continue
					if absf(at.x-25.5) < 3.8 and at.y < 12: continue
					if at.distance_to(Vector2(5.5,4)) < 5.0 or at.distance_to(RiverValley.LANDMARK) < 6.5 or at.distance_to(ValleyPlaces.LANDING) < 6.5: continue
					var ground := ValleyPlaces.point(at)
					_instance(stone,Color("70766d"),ground+Vector3.DOWN*0.025,Vector3(random.randf_range(0.17,0.28),0.045,random.randf_range(0.21,0.35)),random.randf_range(0,TAU),"trail")
					if random.randf() < 0.52:
						var tuft: Vector2 = at+tangent.orthogonal()*side*0.25
						_instance(reed,Color("68785e"),ValleyPlaces.point(tuft)+Vector3.UP*0.20,Vector3(1,random.randf_range(0.28,0.50),1),random.randf_range(0,TAU),"trail")

func _ribbon(points: Array, width: float, lift: float) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var samples: Array[Vector2] = []
	for i in range(points.size()-1):
		var steps := maxi(1,ceili(points[i].distance_to(points[i+1])*2.0))
		for step in steps:
			samples.append(valley._trail_curve(points,i,float(step)/steps))
	samples.append(points[-1])
	var lengths := PackedFloat32Array([0.0])
	for i in range(samples.size()-1): lengths.append(lengths[-1]+samples[i].distance_to(samples[i+1]))
	var total := maxf(0.001,lengths[-1])
	for i in range(samples.size()-1):
		var a := samples[i]
		var b := samples[i+1]
		var across_a := (b-samples[maxi(0,i-1)]).normalized().orthogonal()*width
		var across_b := (samples[mini(samples.size()-1,i+2)]-a).normalized().orthogonal()*width
		var quad := [a-across_a,a+across_a,b+across_b,b-across_b]
		var uv := [Vector2(0,lengths[i]/total),Vector2(1,lengths[i]/total),Vector2(1,lengths[i+1]/total),Vector2(0,lengths[i+1]/total)]
		for index in [0,1,2,0,2,3]:
			tool.set_uv(uv[index])
			tool.add_vertex(ValleyPlaces.point(quad[index])+Vector3.UP*lift)
	tool.generate_normals()
	return tool.commit()

func _channel() -> void:
	RiverCraft.mesh(self,_ribbon(ValleyPlaces.WATER_ROUTE,0.95,0.065),Vector3.ZERO,CERAMIC)
	_bed = RiverCraft.mesh(self,_ribbon(ValleyPlaces.WATER_ROUTE,0.62,0.072),Vector3.ZERO,Color("66645d"))
	water = RiverCraft.mesh(self,_ribbon(ValleyPlaces.WATER_ROUTE,0.61,0.084),Vector3.ZERO,Color("58ada7"))
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/watershed_channel.gdshader")
	material.set_shader_parameter("fill",1.0)
	water.material_override = material
	for at in [Vector2(48,-10),Vector2(33,17),Vector2(45,35)]:
		var pos := ValleyPlaces.point(at)
		RiverCraft.cylinder(self,pos+Vector3.UP*0.45,0.15,0.9,CERAMIC)
		RiverCraft.ring(self,pos+Vector3.UP*0.8,0.19,Color("58afa9"),0.035)
func _landing() -> void:
	var at := ValleyPlaces.point(ValleyPlaces.LANDING)
	# River-order boathouse: bronze-banded piers, ceramic deck, indigo canopy.
	RiverCraft.box(self,at+Vector3(0,-0.03,2),Vector3(8,0.06,6),CERAMIC)
	for x in [-3,3]:
		for z in [2.6,4.6]:
			RiverCraft.cylinder(self,at+Vector3(x,1.2,z),0.18,2.4,CERAMIC,0.13)
			for y in [0.25,1.8,2.2]: RiverCraft.ring(self,at+Vector3(x,y,z),0.21,BRONZE)
	# Shelter the boat side, keeping Oren's meeting area open to the camera.
	var canopy_at := at+Vector3(0,2.5,3.6)
	RiverCraft.box(self,canopy_at,Vector3(7.3,0.12,2),Color("344c68"))
	var shelter := StaticBody3D.new()
	shelter.name = "CanopyCollision"
	add_child(shelter)
	shelter.position = canopy_at
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(7.3,0.12,2)
	collision.shape = box
	shelter.add_child(collision)
	var basin := ValleyPlaces.point(ValleyPlaces.BASIN)
	RiverCraft.cylinder(self,basin+Vector3.UP*0.12,1.35,0.24,CERAMIC)
	RiverCraft.ring(self,basin+Vector3.UP*0.27,1.34,BRONZE,0.05)
	basin_water = RiverCraft.cylinder(self,basin+Vector3.UP*0.255,1.22,0.035,Color("55b6a7"))
	boat = Node3D.new()
	boat.position = basin+Vector3(0,0.25,2.4)
	add_child(boat)
	var hull := SphereMesh.new()
	hull.radius = 0.7
	hull.height = 1.4
	hull.radial_segments = 16
	hull.rings = 6
	RiverCraft.mesh(boat,hull,Vector3.ZERO,Color("647973")).scale = Vector3(0.75,0.35,2)
	RiverCraft.box(boat,Vector3(0,0.1,0),Vector3(0.8,0.12,1.7),CERAMIC)
	RiverCraft.box(self,boat.position+Vector3.DOWN*0.22,Vector3(1,0.1,2),BRONZE)
	landing_life = Node3D.new()
	landing_life.name = "LandingLife"
	add_child(landing_life)
	for i in 9:
		var point := basin+Vector3(cos(i*2.4)*2.1,0,sin(i*2.4)*2.1)
		RiverCraft.pot(landing_life,point,CERAMIC,0.2)
		for j in 3: RiverCraft.cylinder(landing_life,point+Vector3((j-1)*0.10,0.7,0),0.025,0.8,Color("709568"),0.007)
	var sign := Label3D.new()
	sign.text = "OREN'S LANDING"
	sign.position = at+Vector3(0,2.7,-1)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.font_size = 22
	sign.pixel_size = 0.007
	add_child(sign)
func sync(wet: bool, animate: bool) -> void:
	if water==null: return
	var changed := wet!=_wet
	_wet = wet
	water.visible = wet
	basin_water.visible = wet
	landing_life.visible = wet
	if _flow_tween and _flow_tween.is_valid(): _flow_tween.kill()
	var material: ShaderMaterial = water.material_override
	if wet and animate and changed:
		material.set_shader_parameter("fill",0.0)
		basin_water.hide()
		_flow_tween = create_tween()
		_flow_tween.tween_method(func(value: float): material.set_shader_parameter("fill",value),0.0,1.0,2.4)
		_flow_tween.tween_callback(basin_water.show)
		landing_life.scale = Vector3(1,0.05,1)
		create_tween().tween_property(landing_life,"scale",Vector3.ONE,2.4)
		create_tween().tween_property(boat,"position",ValleyPlaces.point(ValleyPlaces.BASIN)+Vector3(0,0.33,1.8),2.4)
	else:
		material.set_shader_parameter("fill",1.0 if wet else 0.0)
		landing_life.scale = Vector3.ONE
		boat.position = ValleyPlaces.point(ValleyPlaces.BASIN)+Vector3(0,0.33 if wet else 0.25,1.8 if wet else 2.4)
