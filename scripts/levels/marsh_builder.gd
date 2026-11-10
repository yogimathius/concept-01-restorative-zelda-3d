extends RegionBuilder
## Reed basin and settlement dressing over the same reliable restoration engine.
func _place_landing() -> void:
	pass

func _place_ground(cell: Vector2i, st: String) -> void:
	var path := cell.x % 16 in [6,7,8] or cell.y % 12 in [4,5,6]
	_put(cell, "ground_%s_%s" % ["b" if path else "a",st], float(absi(cell.x*3+cell.y*5)%4)*90)

func _build_library() -> void:
	super._build_library()
	for id in _library.get_item_list():
		var name := _library.get_item_name(id)
		if not name.begins_with("ground_"): continue
		var mesh := _library.get_item_mesh(id)
		for i in mesh.get_surface_count():
			var mat: ShaderMaterial = mesh.surface_get_material(i)
			var color := Color("569e8d") if name.ends_with("restored") else Color("4b4c65")
			if name.begins_with("ground_b"): color = Color("91b9a1") if name.ends_with("restored") else Color("6a6581")
			mat.set_shader_parameter("base_color",color)

func _place_scenery() -> void:
	var old := get_node_or_null("Scenery")
	if old: old.free()
	var dresser := KitDresser.new()
	dresser.name = "Scenery"
	add_child(dresser)
	for c in level.cells():
		var st := _state(c.cell,c.ch,c.area)
		var h := absi(c.cell.x*73856093 ^ c.cell.y*19349663)
		if _is_ground(c.ch) and (c.cell.x%16 in [1,14] or c.cell.y%12 in [1,10]) and h%2==0:
			dresser.place("reed","reed_"+st,_center(c.cell),float(h%360),1.3)
		if c.ch=="#" and h%5==0:
			dresser.place("tree","tree_"+st,_center(c.cell)+Vector3(0,0,-0.8),float(h%360),0.65)
	# Small inhabited platforms, garden beds and the three-pronged sluice bell.
	for at in [Vector3(5.5,0,3.5),Vector3(20.5,0,3.5),Vector3(6.5,0,16.5),Vector3(24.5,0,16.5)]:
		for side in [-1,1]: dresser.place("reed","reed_restored",at+Vector3(side*1.15,0,-0.8),25,1.0)
	var bell_restored: bool = entities.get("M3",{}).get("restored",false)
	var bell := Node3D.new()
	bell.name = "SluiceBell"
	dresser.add_child(bell)
	var rib_color := Color("ddbb72") if bell_restored else Color("5c526e")
	for i in 3:
		var base := Vector3(26.5+cos(i*TAU/3)*1.05,0,18.5+sin(i*TAU/3)*1.05)
		GearVisuals._rod(bell,base,base+Vector3.UP*2.25,0.065,rib_color)
		GearVisuals._rod(bell,base+Vector3.UP*2.25,Vector3(26.5,2.55,18.5),0.065,rib_color)
	var bell_mesh := CylinderMesh.new()
	bell_mesh.top_radius = 0.20
	bell_mesh.bottom_radius = 0.45
	bell_mesh.height = 0.5
	bell_mesh.radial_segments = 8
	GearVisuals._mesh(bell,bell_mesh,Vector3(26.5,2.08,18.5),rib_color)
	GearVisuals._gem(bell,Vector3(26.5,1.75,18.5),0.10,Color("9cffe3") if bell_restored else Color("685474"),0.3 if bell_restored else 0.0)
	ToonUtil.apply_toon(bell,TOON)
	for id in ["M1","M2","M6"]:
		if not entities.has(id): continue
		var st := "restored" if entities[id].get("restored",false) else "corrupted"
		for side in [-1,1]:
			for depth in [-1,0,1]: dresser.place("reed","reed_"+st,_center(entities[id].cell)+Vector3(side*0.6,0,depth*0.55),float(depth*50),0.9)
	dresser.build()
