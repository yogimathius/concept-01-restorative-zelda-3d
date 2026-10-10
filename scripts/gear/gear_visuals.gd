class_name GearVisuals
extends RefCounted
## Separate bone-bound pieces. Each rebuild removes the previous three pieces.
const TOON := preload("res://shaders/hero_surface_material.tres")

static func apply(model: Node3D, equipped: Dictionary) -> void:
	var old := model.get_node_or_null("Equipment")
	if old: old.free()
	var root := Node3D.new()
	root.name = "Equipment"
	model.add_child(root)
	var skeletons := model.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty(): return
	var skeleton: Skeleton3D = skeletons[0]
	for slot in RestorationInventory.SLOTS:
		var id: String = equipped.get(slot, RestorationInventory.STARTERS[slot])
		var attachment := BoneAttachment3D.new()
		attachment.name = slot.capitalize()
		root.add_child(attachment)
		attachment.use_external_skeleton = true
		attachment.external_skeleton = attachment.get_path_to(skeleton)
		attachment.bone_name = ("hand.R" if skeleton.find_bone("hand.R") >= 0 else "forearm.R") if slot == "tool" else "chest"
		var piece := make_piece(id)
		piece.name = id
		attachment.add_child(piece)
		var bone := skeleton.find_bone(attachment.bone_name)
		var rest := skeleton.get_bone_global_rest(bone)
		var fit := Transform3D.IDENTITY
		if slot == "tool": fit.origin.x = rest.origin.x + 0.32
		piece.transform = rest.affine_inverse() * fit

static func make_piece(id: String) -> Node3D:
	var item: Dictionary = RestorationInventory.ITEMS[id]
	var root := Node3D.new()
	root.name = id
	match item.slot:
		"cloak": _mantle(root, id, item)
		"tool": _staff(root, id, item)
		"charm": _brooch(root, id, item)
	_batch(root, item.slot != "tool")
	ToonUtil.apply_toon(root, TOON)
	return root

# Match art/characters/hero_finish.py. Keep the gear fit consistent with the body.
const LOWER_BODY_SCALE := 1.17
const WAIST_HEIGHT := 0.68
const TORSO_SCALE := 1.22
const HEAD_HEIGHT := 1.05
const HEAD_SCALE := 0.82
const UPPER_WIDTH_SCALE := 0.82

static func _stature_height(y: float) -> float:
	if y < WAIST_HEIGHT: return y*LOWER_BODY_SCALE
	if y < HEAD_HEIGHT: return WAIST_HEIGHT*LOWER_BODY_SCALE+(y-WAIST_HEIGHT)*TORSO_SCALE
	return WAIST_HEIGHT*LOWER_BODY_SCALE+(HEAD_HEIGHT-WAIST_HEIGHT)*TORSO_SCALE+(y-HEAD_HEIGHT)*HEAD_SCALE

const GOLD := Color("ae8953")
const LEATHER := Color("574739")

static func _finish(node: MeshInstance3D, metallic := 0.0, fabric := false) -> void:
	var mat := node.mesh.surface_get_material(0) as StandardMaterial3D
	mat.metallic = metallic
	mat.roughness = 0.34 if metallic > 0.0 else 0.8
	mat.set_meta("fabric", float(fabric))
	mat.set_meta("outline", false)

static func _tube(root: Node3D, a: Vector3, b: Vector3, radius: float, color: Color, metallic := 0.0) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.85
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 8
	mesh.rings = 0
	var node := _mesh(root, mesh, (a+b)*0.5, color)
	node.quaternion = Quaternion(Vector3.UP, (b-a).normalized())
	_finish(node, metallic)

static func _curve(root: Node3D, points: Array, radius: float, color: Color, metallic := 0.0) -> void:
	for i in range(points.size()-1): _tube(root, points[i], points[i+1], radius, color, metallic)

static func _arc(root: Node3D, center: Vector3, radius: float, begin: float, end: float, thickness: float, color: Color) -> void:
	var points := []
	var steps := maxi(8,ceili(radius*200.0))
	for i in steps+1:
		var angle := lerpf(begin, end, float(i)/float(steps))
		points.append(center + Vector3(cos(angle),sin(angle),0)*radius)
	_curve(root, points, thickness, color, 0.7)

static func _leaf(root: Node3D, a: Vector3, b: Vector3, width: float, color: Color, metallic := 0.0) -> void:
	var mid := a.lerp(b,0.47)
	var across := (b-a).normalized().cross(Vector3.FORWARD)*width
	var ridge := mid + Vector3(0,0,0.013)
	var vertices := [a,mid+across,b,mid-across,ridge,mid+Vector3(0,0,-0.005)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for face in [[0,1,4],[1,2,4],[2,3,4],[3,0,4],[1,0,5],[2,1,5],[3,2,5],[0,3,5]]:
		for index in face: st.add_vertex(vertices[index])
	st.generate_normals()
	st.index()
	_finish(_mesh(root,st.commit(),Vector3.ZERO,color),metallic)

static func _jewel(root: Node3D, at: Vector3, radius: float, color: Color, tall := 1.4) -> void:
	# A bevelled octagonal table, shoulder and pavilion catch different highlights.
	var vertices := []
	for ring in [[radius*0.55,radius*tall*0.63],[radius,radius*tall*0.19],[radius*0.88,-radius*tall*0.22]]:
		for i in 8:
			var angle := TAU*float(i)/8.0
			vertices.append(at+Vector3(cos(angle)*ring[0],ring[1],sin(angle)*ring[0]))
	vertices.append(at-Vector3(0,radius*tall,0))
	vertices.append(at+Vector3(0,radius*tall*0.63,0))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 8:
		var next := (i+1)%8
		for index in [25,i,next,24,16+next,16+i]: st.add_vertex(vertices[index])
		for ring in 2:
			for index in [ring*8+i,(ring+1)*8+i,ring*8+next,ring*8+next,(ring+1)*8+i,(ring+1)*8+next]: st.add_vertex(vertices[index])
	st.generate_normals()
	st.index()
	_finish(_mesh(root,st.commit(),Vector3.ZERO,color,0.12),0.45)

static func _ribbon(root: Node3D, points: Array, width: float, color: Color) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size()-1):
		var a: Vector3 = points[i]
		var b: Vector3 = points[i+1]
		var side := Vector3(width,0,0)
		for vertex in [a-side,a+side,b-side,a+side,b+side,b-side]: st.add_vertex(vertex)
	st.generate_normals()
	st.index()
	_finish(_mesh(root,st.commit(),Vector3.ZERO,color),0.0,true)

static func _staff(root: Node3D, id: String, item: Dictionary) -> void:
	var x := -0.32
	var short := id in ["wayfarer_wand","grove_wand"]
	var bottom := 0.32 if short else 0.09
	var top := 1.05 if short else 1.23
	var color: Color = item.color.darkened(0.18)
	var accent: Color = item.accent
	_tube(root,Vector3(x,bottom,0.035),Vector3(x,top,0.035),0.016,color)
	# Metal ferrules and six individual leather turns around the grip.
	for y in [bottom,0.43,0.60,top-0.03]:
		_tube(root,Vector3(x,y,0.035),Vector3(x,y+0.022,0.035),0.022,GOLD,0.7)
	for i in 6:
		_tube(root,Vector3(x,0.455+i*0.021,0.035),Vector3(x,0.473+i*0.021,0.035),0.021,LEATHER)
	var center := Vector3(x,top+0.075,0.035)
	if item.tier > 0:
		# Inlaid stem leaves and a hanging ceremonial pennant distinguish earned tools.
		for y in [0.77,0.91,top-0.035]:
			for side in [-1,1]:
				_leaf(root,Vector3(x,y,0.055),Vector3(x+side*0.022,y+0.046,0.055),0.008,GOLD,0.7)
		_ribbon(root,[center+Vector3(0.067,-0.075,-0.018),center+Vector3(0.076,-0.145,-0.01),center+Vector3(0.09,-0.24,0.01),center+Vector3(0.077,-0.31,0.028)],0.017,item.color)
		_tube(root,center+Vector3(0.063,-0.075,-0.018),center+Vector3(0.075,-0.082,-0.018),0.008,GOLD,0.7)
	match id:
		"wayfarer_wand":
			_jewel(root,center,0.035,accent)
			for side in [-1,1]:
				_leaf(root,center+Vector3(0,-0.095,0),center+Vector3(side*0.068,0.065,0),0.025,GOLD,0.7)
			_arc(root,center,0.056,0,TAU,0.006,GOLD)
		"grove_wand":
			_jewel(root,center,0.046,accent)
			for side in [-1,1]:
				_curve(root,[center+Vector3(0,-0.12,0),center+Vector3(side*0.065,-0.035,0),center+Vector3(side*0.079,0.052,0),center+Vector3(side*0.042,0.11,0)],0.009,GOLD,0.7)
				_leaf(root,center+Vector3(side*0.058,-0.02,0),center+Vector3(side*0.115,0.066,0),0.033,item.color,0.35)
		"river_staff":
			_arc(root,center,0.10,PI*0.62,PI*2.38,0.012,GOLD)
			_arc(root,center,0.078,PI*0.68,PI*2.32,0.004,item.color)
			for side in [-1,1]: _leaf(root,center+Vector3(side*0.084,-0.018,0),center+Vector3(side*0.145,0.06,0),0.025,GOLD,0.7)
			_jewel(root,center+Vector3(0,0.012,0),0.045,accent,1.7)
			for side in [-1,1]:
				_leaf(root,center+Vector3(side*0.068,-0.068,0),center+Vector3(side*0.12,0.092,0),0.025,item.color,0.5)
		"marsh_staff":
			for side in [-1,0,1]:
				var tip := center+Vector3(side*0.068,0.13-abs(side)*0.044,0)
				_curve(root,[center-Vector3(0,0.115,0),center+Vector3(side*0.067,-0.025,0),tip],0.009,GOLD,0.7)
				_leaf(root,tip-Vector3(0,0.025,0),tip+Vector3(0,0.065,0),0.026,item.color,0.45)
			_jewel(root,center,0.044,accent)
			_arc(root,center,0.06,PI,TAU,0.008,GOLD)
		"ferryman_staff":
			_arc(root,center+Vector3(0.05,0,0),0.087,0,PI*1.25,0.016,GOLD)
			var lamp := center+Vector3(0.138,-0.077,0)
			_tube(root,lamp+Vector3(0,0.08,0),lamp+Vector3(0,0.04,0),0.005,LEATHER)
			_jewel(root,lamp,0.031,accent)
			for side in [-1,1]:
				_curve(root,[lamp+Vector3(0,-0.055,0),lamp+Vector3(side*0.044,0,0),lamp+Vector3(0,0.05,0)],0.007,GOLD,0.7)
			_leaf(root,center-Vector3(0,0.09,0),center+Vector3(-0.055,0.042,0),0.028,item.color,0.5)

static func _mantle(root: Node3D, id: String, item: Dictionary) -> void:
	var tier: int = item.tier
	var width := 0.28+float(tier)*0.025
	var hem := 0.29-float(tier)*0.03
	var rows := []
	for y in 13:
		var t := float(y)/12.0
		var row := []
		for x in 17:
			var u := float(x)/16.0
			var across := u*2.0-1.0
			var wave := sin(u*PI*8.0)*0.032*t
			var scallop := (0.5+0.5*cos(u*TAU*(3 if tier>0 else 1)))*0.045*pow(t,8)
			row.append(Vector3(across*lerpf(0.19,width,t),lerpf(1.025,hem,t)-scallop,-0.165-0.16*t-0.036*(1-across*across)+wave))
		rows.append(row)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in 12:
		for x in 16:
			for at in [Vector2i(x,y),Vector2i(x+1,y),Vector2i(x,y+1),Vector2i(x+1,y),Vector2i(x+1,y+1),Vector2i(x,y+1)]: st.add_vertex(rows[at.y][at.x])
	st.generate_normals()
	st.index()
	var cloth := _mesh(root,st.commit(),Vector3.ZERO,item.color.darkened(0.08))
	_finish(cloth,0,true)
	var cloth_material: StandardMaterial3D = cloth.mesh.surface_get_material(0)
	cloth_material.set_meta("cloth_pattern",float(tier+1))
	cloth_material.set_meta("cloth_width",width)
	cloth_material.set_meta("cloth_hem",_stature_height(hem))
	cloth_material.set_meta("cloth_top",_stature_height(1.025))
	cloth_material.set_meta("embroidery_color",item.accent)
	# Raised binding, a short shoulder yoke and scalloped stitched hem.
	for side in [0,16]:
		var edge := []
		for row in rows: edge.append(row[side]+Vector3(0,0,-0.008))
		_curve(root,edge,0.006,item.accent.darkened(0.15))
	var edge := []
	for v in rows[12]: edge.append(v+Vector3(0,0,-0.008))
	_curve(root,edge,0.007,item.accent.darkened(0.1))
	_curve(root,[Vector3(-0.20,1.02,-0.17),Vector3(-0.10,0.98,-0.23),Vector3(0,0.965,-0.24),Vector3(0.10,0.98,-0.23),Vector3(0.20,1.02,-0.17)],0.017,item.accent.darkened(0.25))
	var at := Vector3(0,0.68,-0.32)
	# Crest differs by garment; small ornamentation remains readable as one emblem.
	if id == "sunleaf_cloak":
		for i in 7:
			var angle := TAU*float(i)/7.0
			_leaf(root,at,at+Vector3(sin(angle),cos(angle),0)*0.105,0.022,item.accent)
	elif id == "marsh_cloak":
		for side in [-1,0,1]:
			_curve(root,[at-Vector3(0,0.10,0),at+Vector3(side*0.04,0.02,0),at+Vector3(side*0.08,0.12,0)],0.004,item.accent)
			_leaf(root,at+Vector3(side*0.04,0.02,0),at+Vector3(side*0.08,0.13,0),0.017,item.accent)
	else:
		for side in [-1,1]:
			_leaf(root,at-Vector3(0,0.07,0),at+Vector3(side*0.09,0.06,0),0.026,item.accent)
	# Three decorative hem tassels on upgraded mantles.
	if tier > 0:
		for index in [3,8,13]:
			var tip: Vector3 = rows[12][index]
			_tube(root,tip,tip-Vector3(0,0.055,0),0.007,item.accent)

static func _brooch(root: Node3D, id: String, item: Dictionary) -> void:
	var at := Vector3(-0.045,0.977,0.205)
	# Fitted prongs hold the centre stone rather than leaving it floating on a frame.
	for side in [-1,1]:
		_leaf(root,at+Vector3(side*0.008,-0.02,0.006),at+Vector3(side*0.032,0.02,0.024),0.005,GOLD,0.7)
	var accent: Color = item.accent
	for side in [-1,1]:
		_curve(root,[at+Vector3(side*0.04,0,0),Vector3(side*0.14,1.025,0.16),Vector3(side*0.20,1.03,0.08)],0.004,GOLD,0.7)
	match id:
		"wayfarer_charm":
			_arc(root,at,0.035,0,TAU,0.006,GOLD)
			_jewel(root,at+Vector3(0,0,0.008),0.021,accent)
		"bloom_charm":
			for i in 5:
				var angle := TAU*float(i)/5.0
				_leaf(root,at,at+Vector3(sin(angle),cos(angle),0)*0.059,0.022,item.color,0.6)
			_jewel(root,at+Vector3(0,0,0.02),0.019,accent)
		"river_charm":
			_arc(root,at,0.05,PI*0.35,PI*1.9,0.008,item.color)
			_jewel(root,at+Vector3(0.012,0.007,0.014),0.024,accent,1.65)
		"bell_charm":
			_arc(root,at+Vector3(0,0.012,0),0.044,0,PI,0.006,GOLD)
			for side in [-1,1]: _leaf(root,at+Vector3(side*0.039,-0.025,0),at+Vector3(side*0.025,0.026,0),0.017,item.color,0.65)
			_tube(root,at-Vector3(0.047,0.027,0),at+Vector3(0.047,-0.027,0),0.005,GOLD,0.7)
			_jewel(root,at-Vector3(0,0.029,-0.009),0.017,accent)
		"messenger_charm":
			for side in [-1,1]:
				_leaf(root,at+Vector3(0,-0.035,0),at+Vector3(side*0.074,0.042,0),0.018,item.color,0.7)
				_leaf(root,at+Vector3(side*0.027,-0.01,0),at+Vector3(side*0.059,0.055,0),0.012,accent,0.35)
			_jewel(root,at+Vector3(0,0,0.016),0.022,accent)
		"stonekeeper_charm":
			for side in [-1,1]:
				_curve(root,[at-Vector3(0,0.056,0),at+Vector3(side*0.047,0,0),at+Vector3(0,0.057,0)],0.007,GOLD,0.7)
				_leaf(root,at+Vector3(side*0.025,-0.01,0),at+Vector3(side*0.041,0.036,0),0.015,item.color,0.5)
			_jewel(root,at+Vector3(0,0,0.014),0.029,accent)
		"riverglass_lens":
			for side in [-1,1]: _arc(root,at+Vector3(side*0.018,0,0),0.046,PI*0.25,PI*1.75,0.007,GOLD)
			_jewel(root,at+Vector3(0,0,0.024),0.031,accent,1.8)

static func _batch(root: Node3D, fit_width := false) -> void:
	# One draw surface per finish, rather than a draw call for every tiny fitting.
	var groups := {}
	for child in root.get_children():
		if not child is MeshInstance3D: continue
		var mat := child.mesh.surface_get_material(0) as StandardMaterial3D
		var key := str([mat.albedo_color,mat.metallic,mat.emission_energy_multiplier,mat.emission_enabled,mat.get_meta("fabric",0.0),mat.get_meta("cloth_pattern",0.0)])
		if not groups.has(key): groups[key] = {"st":SurfaceTool.new(),"mat":mat}
		var group: Dictionary = groups[key]
		group.st.append_from(child.mesh,0,child.transform)
	var combined := ArrayMesh.new()
	for group in groups.values():
		var authored: ArrayMesh = group.st.commit()
		var arrays := authored.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		for index in vertices.size():
			var scale_y := LOWER_BODY_SCALE if vertices[index].y < WAIST_HEIGHT else (TORSO_SCALE if vertices[index].y < HEAD_HEIGHT else HEAD_SCALE)
			var scale_x := lerpf(1.0,UPPER_WIDTH_SCALE,clampf((vertices[index].y-0.60)/0.18,0.0,1.0)) if fit_width else 1.0
			normals[index] = (normals[index]*Vector3(1.0/scale_x,1.0/scale_y,1.0)).normalized()
			vertices[index].x *= scale_x
			vertices[index].y = _stature_height(vertices[index].y)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		combined.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		combined.surface_set_material(combined.get_surface_count()-1,group.mat)
	for child in root.get_children(): child.free()
	var node := MeshInstance3D.new()
	node.name = "CraftedGear"
	node.mesh = combined
	root.add_child(node)

static func _mesh(root: Node3D, mesh: Mesh, at: Vector3, color: Color, glow := 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.roughness = 0.7
	material.emission_enabled = glow > 0
	material.emission = color
	material.emission_energy_multiplier = glow
	mesh.surface_set_material(0, material)
	root.add_child(node)
	return node

static func _gem(root: Node3D, at: Vector3, radius: float, color: Color, glow: float) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.4
	mesh.radial_segments = 6
	mesh.rings = 2
	_mesh(root, mesh, at, color, glow)

static func _rod(root: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.8
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 6
	var node := _mesh(root, mesh, (a+b)*0.5, color)
	node.quaternion = Quaternion(Vector3.UP, (b-a).normalized())
