class_name RiverValley
extends Node3D
## Bounded opening prototype. Height and walkability are shared by terrain,
## checkpoints, maps and save loading; no second authored coordinate system.
const BOUNDS := Rect2(-18, -40, 112, 92)
const OVERLOOK := Vector2(9, -18)
const LANDMARK := Vector2(65, -25)
const LOW_ROUTE := [Vector2(5.5,4), Vector2(12,5), Vector2(18,6), Vector2(23,5.5)]
const HIGH_ROUTE := [Vector2(5.5,4), Vector2(1,-4), Vector2(4,-12), OVERLOOK, Vector2(18,-12), Vector2(21,-4), Vector2(23,5.5)]
const EAST_ROUTE := [Vector2(23,5.5), Vector2(27.5,5.5), Vector2(30,6)]
const UPPER_ROUTE := [Vector2(30,6),Vector2(39,2),Vector2(48,-10),LANDMARK]
const TRAIL_PIXELS_PER_UNIT := 4
const TRAIL_FEATHER := 0.85
var builder: Node3D
var chunks: Array[MeshInstance3D] = []
var banks: ValleyBanks
var trail_mask: Image
var _trail_texture: ImageTexture

static func height_at(at: Vector2) -> float:
	# Preserve the inhabited opening's coordinates. Broad cosine ramps are
	# deliberately gentle: climbing never requires jumping or precise input.
	var west := maxf(0, 1.0-at.distance_to(OVERLOOK)/23.0)
	var east := maxf(0, 1.0-maxf(0,at.distance_to(LANDMARK)-8.0)/19.0)
	var opening_flat := smoothstep(1.0, 9.0, maxf(0, -at.y))
	var bank_flat := smoothstep(0.0, 7.0, absf(at.x-25.5))
	return (6.5 * (1.0-cos(west*PI))*0.5 + 10.0 * (1.0-cos(east*PI))*0.5) * opening_flat * bank_flat

func walkable(at: Vector2) -> bool:
	if not BOUNDS.grow(-0.6).has_point(at): return false
	if at.x >= 24 and at.x < 27 and at.y < 12:
		return builder.entities.get("B1",{}).get("restored",false) and at.y >= 0 and at.y <= 7
	return true

func _ready() -> void:
	_build_trail_mask()
	for x in range(-18,94,14):
		for z in range(-40,52,14):
			_make_chunk(Vector2(x,z), Vector2(mini(x+14,94),mini(z+14,52)))
	_landmark()
	_planting()
	banks = ValleyBanks.new()
	banks.valley = self
	add_child(banks)
	for point in [Vector2(1,-4),OVERLOOK,Vector2(21,-4),Vector2(48,-10)]:
		var pos := Vector3(point.x,height_at(point),point.y)
		RiverCraft.cylinder(self,pos+Vector3.UP*0.5,0.14,1.0,Color("c1c6b3"))
		RiverCraft.ring(self,pos+Vector3.UP*0.9,0.18,Color("54c4c0"),0.045)
	var sign := Label3D.new()
	sign.text = "RIVER OVERLOOK\nA gentle trail returns to the grove"
	sign.position = Vector3(OVERLOOK.x,height_at(OVERLOOK)+1.8,OVERLOOK.y)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.font_size = 30
	sign.pixel_size = 0.008
	add_child(sign)

func _color(at: Vector2) -> Color:
	var healthy := at.distance_to(Vector2(7,5)) < 12
	for id in builder.manifest.ENTITIES:
		var entity: Dictionary = builder.entities.get(id,{})
		if entity.get("restored",false) and at.distance_to(Vector2(entity.runtime.position.x,entity.runtime.position.z)) < 11: healthy = true
	if builder.entities.get("C3",{}).get("restored",false):
		for i in range(ValleyPlaces.WATER_ROUTE.size()-1):
			if Geometry2D.get_closest_point_to_segment(at,ValleyPlaces.WATER_ROUTE[i],ValleyPlaces.WATER_ROUTE[i+1]).distance_to(at)<5: healthy = true
	var noise := sin(at.x*0.42)*cos(at.y*0.35)*0.025
	return Color(0.24+noise,0.39+noise,0.31+noise) if healthy else Color(0.36+noise,0.33+noise,0.32+noise)

func _make_chunk(lo: Vector2, hi: Vector2) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for x in range(int(lo.x),int(hi.x),2):
		for z in range(int(lo.y),int(hi.y),2):
			var right := minf(x+2,hi.x)
			# Split precisely at the river bank; the bank remains a real gap.
			if x < 24 and right > 24: right = 24
			var left := float(x)
			if left >= 24 and left < 27 and z < 12: left = 27
			if right <= left: continue
			var points := [Vector2(left,z),Vector2(right,z),Vector2(right,minf(z+2,hi.y)),Vector2(left,minf(z+2,hi.y))]
			for i in [0,1,2,0,2,3]:
				var at: Vector2 = points[i]
				tool.set_color(_color(at))
				tool.add_vertex(Vector3(at.x,height_at(at),at.y))
	tool.generate_normals()
	var mesh := tool.commit()
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/watershed_ground.gdshader")
	material.set_shader_parameter("trail_mask", _trail_texture)
	material.set_shader_parameter("trail_origin", BOUNDS.position)
	material.set_shader_parameter("trail_size", BOUNDS.size)
	node.material_override = material
	node.name = "Bank_%d_%d" % [lo.x,lo.y]
	add_child(node)
	node.create_trimesh_collision()
	chunks.append(node)

func _build_trail_mask() -> void:
	trail_mask = Image.create_empty(int(BOUNDS.size.x * TRAIL_PIXELS_PER_UNIT), int(BOUNDS.size.y * TRAIL_PIXELS_PER_UNIT), false, Image.FORMAT_R8)
	trail_mask.fill(Color.BLACK)
	for route in [
		[LOW_ROUTE, 0.95], [HIGH_ROUTE, 1.2], [EAST_ROUTE, 1.15],
		[UPPER_ROUTE, 1.3], [ValleyPlaces.SOUTH_ROUTE, 1.25],
		[ValleyPlaces.SUNLEAF_ROUTE, 1.2],
	]:
		_paint_route(route[0], route[1])
	_paint_approach(Vector2(58.8,-19.6), LANDMARK, 1.3, 3.8)
	_paint_approach(Vector2(46.5,35), ValleyPlaces.LANDING, 1.25, 3.2)
	_trail_texture = ImageTexture.create_from_image(trail_mask)

func _paint_approach(start: Vector2, destination: Vector2, start_width: float, end_width: float) -> void:
	var previous := start
	for step in range(1, 25):
		var t := float(step) / 24.0
		var current := start.lerp(destination, t)
		_paint_trail_segment(previous, current, lerpf(start_width, end_width, t))
		previous = current

func _paint_route(points: Array, width: float) -> void:
	for i in range(points.size() - 1):
		var from: Vector2 = points[i]
		var to: Vector2 = points[i + 1]
		var previous := from
		var steps := maxi(1, ceili(from.distance_to(to) * 2.0))
		for step in range(1, steps + 1):
			var current := _trail_curve(points, i, float(step) / steps)
			_paint_trail_segment(previous, current, width)
			previous = current

func _trail_curve(points: Array, i: int, t: float) -> Vector2:
	var p0: Vector2 = points[maxi(0, i - 1)]
	var p1: Vector2 = points[i]
	var p2: Vector2 = points[i + 1]
	var p3: Vector2 = points[mini(points.size() - 1, i + 2)]
	return (p1 * 2.0 + (p2 - p0) * t + (p0 * 2.0 - p1 * 5.0 + p2 * 4.0 - p3) * t * t + (-p0 + p1 * 3.0 - p2 * 3.0 + p3) * t * t * t) * 0.5

func _paint_trail_segment(a: Vector2, b: Vector2, width: float) -> void:
	var radius := width + TRAIL_FEATHER
	var low := (a.min(b) - Vector2.ONE * radius - BOUNDS.position) * TRAIL_PIXELS_PER_UNIT
	var high := (a.max(b) + Vector2.ONE * radius - BOUNDS.position) * TRAIL_PIXELS_PER_UNIT
	for py in range(maxi(0, floori(low.y)), mini(trail_mask.get_height(), ceili(high.y))):
		for px in range(maxi(0, floori(low.x)), mini(trail_mask.get_width(), ceili(high.x))):
			var at := BOUNDS.position + Vector2(px + 0.5, py + 0.5) / TRAIL_PIXELS_PER_UNIT
			var distance := at.distance_to(Geometry2D.get_closest_point_to_segment(at, a, b))
			var coverage := 1.0 - smoothstep(width - TRAIL_FEATHER, radius, distance)
			if coverage > trail_mask.get_pixel(px, py).r:
				trail_mask.set_pixel(px, py, Color(coverage, 0, 0))

func trail_strength(at: Vector2) -> float:
	if not BOUNDS.has_point(at): return 0.0
	var pixel := Vector2i((at - BOUNDS.position) * TRAIL_PIXELS_PER_UNIT)
	return trail_mask.get_pixel(clampi(pixel.x, 0, trail_mask.get_width() - 1), clampi(pixel.y, 0, trail_mask.get_height() - 1)).r

func _landmark() -> void:
	var site := Node3D.new()
	site.name = "UpperWeir"
	add_child(site)
	site.position = Vector3(LANDMARK.x,height_at(LANDMARK),LANDMARK.y)
	var toward := OVERLOOK-LANDMARK
	site.rotation.y = atan2(toward.x,toward.y)
	var at := Vector3.ZERO
	var stone := Color("c5c6b2")
	var bronze := Color("8c9b87")
	RiverCraft.box(site,at+Vector3.DOWN*0.06,Vector3(14,0.12,9),stone)
	for side in [-1,1]:
		RiverCraft.box(site,at+Vector3(side*5,5,0),Vector3(2,10,2),stone)
		RiverCraft.box(site,at+Vector3(side*5,6.5,0),Vector3(2.3,0.5,2.3),bronze,0.35)
	RiverCraft.box(site,at+Vector3.UP*10,Vector3(12,1,2),stone)
	var ring := RiverCraft.ring(site,at+Vector3(0,7,0),3.0,Color("66cac4"),0.18)
	ring.rotation.x = PI/2
	RiverCraft.channel(site,at+Vector3(0,0.25,0),12)
	var sign := Label3D.new()
	sign.text = "THE UPPER FORD WEIR\nClear its intake · steady its foundations"
	sign.position = at+Vector3(0,3,2)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.font_size = 32
	sign.pixel_size = 0.01
	site.add_child(sign)

func _planting() -> void:
	# Distant silhouettes are scenery, not promised playable regions.
	for layer in 3:
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in 30:
			var x := -65.0+i*8
			var first := 8+pow(sin(float(i)*0.51+layer),2)*18+sin(float(i)*1.3)*3
			var second := 8+pow(sin(float(i+1)*0.51+layer),2)*18+sin(float(i+1)*1.3)*3
			var z := -72.0-layer*14
			var points := [Vector3(x,-2,z+8),Vector3(x,first,z),Vector3(x+8,second,z),Vector3(x+8,-2,z+8)]
			for index in [0,1,2,0,2,3]: tool.add_vertex(points[index])
		tool.generate_normals()
		RiverCraft.mesh(self,tool.commit(),Vector3.ZERO,Color("526a70").lightened(layer*0.06))

func refresh_restoration() -> void:
	# Change the affected terrain's vertex colors only on completion. Collision
	# geometry and triangle counts remain stable throughout the effect.
	for node in chunks:
		var mesh: ArrayMesh = node.mesh
		var arrays := mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var colors := PackedColorArray()
		for vertex in vertices: colors.append(_color(Vector2(vertex.x,vertex.z)))
		arrays[Mesh.ARRAY_COLOR] = colors
		var updated := ArrayMesh.new()
		updated.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		node.mesh = updated
