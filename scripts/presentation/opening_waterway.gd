class_name OpeningWaterway
extends Node3D
## Authored opening landmarks and consequences, derived from the existing save.
var region: Node3D
var water_channels: Array[Node3D] = []
var gathering: Node3D
var first_grove: Node3D
var spring_garden: Node3D
var _birds: Array[Node3D] = []
var _time := 0.0
const CERAMIC := Color("c5c9b8")
const BRONZE := Color("917653")
func _ready() -> void:
	name = "OpeningWaterway"
	# Caretaker's pavilion: terraces, carved hydraulic pillars and indigo awning.
	for i in 3:
		RiverCraft.box(self,Vector3(5.6,0.025+i*0.025,1.65+i*0.24),Vector3(5.0-i*0.3,0.05,0.45),CERAMIC.darkened(i*0.04))
	for x in [3.3,7.9]:
		RiverCraft.cylinder(self,Vector3(x,0.95,1.6),0.16,1.9,CERAMIC,0.13)
		for y in [0.16,1.40,1.75]: RiverCraft.ring(self,Vector3(x,y,1.6),0.19,BRONZE)
		RiverCraft.box(self,Vector3(x,1.35,1.38),Vector3(0.10,0.24,0.04),Color("68c5bd"))
	var canopy := RiverCraft.box(self,Vector3(5.6,1.98,1.9),Vector3(5.0,0.08,1.7),Color("344c68"))
	canopy.rotation.z = 0.018
	for x in range(4,8): RiverCraft.box(self,Vector3(x,1.92,2.77),Vector3(0.06,0.16,0.06),BRONZE)
	RiverCraft.box(self,Vector3(5.6,0.68,2.25),Vector3(2.8,0.12,0.65),CERAMIC)
	for x in [4.5,6.7]: RiverCraft.box(self,Vector3(x,0.32,2.25),Vector3(0.15,0.62,0.42),BRONZE)
	for x in [4.8,5.4,6.2]: RiverCraft.pot(self,Vector3(x,0.75,2.25),Color("a6bdac"),0.14)
	# An open public basin shows why the spring matters to this settlement.
	RiverCraft.cylinder(self,Vector3(10.8,0.12,7.8),1.15,0.24,CERAMIC)
	RiverCraft.ring(self,Vector3(10.8,0.27,7.8),1.13,BRONZE,0.05)
	var basin_body := StaticBody3D.new()
	var basin_collision := CollisionShape3D.new()
	var basin_shape := CylinderShape3D.new()
	basin_shape.radius = 1.05
	basin_shape.height = 0.28
	basin_collision.shape = basin_shape
	basin_body.add_child(basin_collision)
	basin_body.position = Vector3(10.8,0.14,7.8)
	add_child(basin_body)
	var basin := RiverCraft.cylinder(self,Vector3(10.8,0.255,7.8),1.02,0.035,Color("3eaaa3"))
	water_channels.append(basin)
	water_channels.append(RiverCraft.channel(self,Vector3(13.7,0.04,7.8),3.2))
	for at in [Vector3(9,0,8.7),Vector3(12.5,0,9),Vector3(13,0,2.2),Vector3(2.1,0,8.6)]:
		RiverCraft.pot(self,at,Color("b1bda4"))
		for i in 5:
			var reed := RiverCraft.cylinder(self,at+Vector3((i-2)*0.045,0.62,0.025*(i%2)),0.014,0.45+float(i%3)*0.12,Color("708a62"),0.004)
			reed.rotation.z = (i-2)*0.10
	# Grove monument: an old split crescent cradles a living water root.
	first_grove = Node3D.new()
	first_grove.name = "GroveLife"
	add_child(first_grove)
	var at: Vector3 = region.builder.entities.B1.runtime.position
	for side in [-1,1]:
		RiverCraft.cylinder(self,at+Vector3(side*1.20,0.60,-0.55),0.20,1.2,CERAMIC,0.14)
		RiverCraft.ring(self,at+Vector3(side*1.20,0.21,-0.55),0.24,BRONZE)
	var crest := RiverCraft.ring(self,at+Vector3(0,1.8,-0.75),1.35,BRONZE,0.065)
	crest.rotation.x = PI/2
	crest.scale.x = 1.2
	RiverCraft.channel(self,at+Vector3(-2,0.01,0.9),2.2).hide()
	for i in 16:
		var angle := TAU*i/16
		var p := at+Vector3(cos(angle)*1.55,0.05,sin(angle)*1.25)
		var stem := RiverCraft.cylinder(first_grove,p+Vector3.UP*0.25,0.025,0.5,Color("739871"),0.008)
		stem.rotation.z = cos(angle)*0.2
		var leaf := SphereMesh.new()
		leaf.radius = 0.17
		leaf.height = 0.22
		RiverCraft.mesh(first_grove,leaf,p+Vector3.UP*0.45,Color("91b984")).scale = Vector3(1,0.55,0.75)
	# Iona's carved gauging station overlooks the Force spring.
	for x in [29.0,31.4]:
		RiverCraft.cylinder(self,Vector3(x,0.7,2.1),0.25,1.4,CERAMIC,0.18)
		for j in 5: RiverCraft.box(self,Vector3(x,0.35+j*0.16,1.87),Vector3(0.16,0.025,0.03),BRONZE)
	RiverCraft.box(self,Vector3(30.2,1.4,2.1),Vector3(2.8,0.16,0.5),CERAMIC)
	spring_garden = Node3D.new()
	spring_garden.name = "SpringLife"
	add_child(spring_garden)
	var spring: Vector3 = region.builder.entities.C1.runtime.position
	for i in 12:
		var p := spring+Vector3(cos(i*2.4)*1.55,0.05,sin(i*2.4)*1.3)
		RiverCraft.cylinder(spring_garden,p+Vector3.UP*0.4,0.018,0.8,Color("769878"),0.005)
		var blossom := SphereMesh.new()
		blossom.radius = 0.065
		blossom.height = 0.13
		RiverCraft.mesh(spring_garden,blossom,p+Vector3.UP*0.8,Color("e4dcae"))
	gathering = Node3D.new()
	gathering.name = "RestoredGathering"
	add_child(gathering)
	for i in 4:
		RiverCraft.pot(gathering,Vector3(9.9+i*0.5,0.30,8.9),Color("bcbaa1"),0.13)
	for x in [9.3,12.3]:
		RiverCraft.box(self,Vector3(x,0.31,9.4),Vector3(0.8,0.16,0.36),CERAMIC)
	for i in 5:
		var bird := Node3D.new()
		gathering.add_child(bird)
		var wing := SphereMesh.new()
		wing.radius = 0.06
		wing.height = 0.08
		for side in [-1,1]:
			var feather := RiverCraft.mesh(bird,wing,Vector3(side*0.06,0,0),Color("e6dfbe"))
			feather.scale = Vector3(1.6,0.25,0.7)
		_birds.append(bird)
	_batch_static(self)
	_batch_static(first_grove)
	_batch_static(spring_garden)
	_batch_static(gathering)
	region.builder.restored.connect(func(_id): sync(true))
	sync(false)
func sync(animate: bool) -> void:
	var grove: bool = region.builder.entities.B1.get("restored",false)
	var spring: bool = region.builder.entities.C1.get("restored",false)
	first_grove.visible = grove
	spring_garden.visible = spring
	gathering.visible = spring
	for water in water_channels: water.visible = spring
	if animate:
		for life in [first_grove,spring_garden]:
			if life.visible and not life.has_meta("grown"):
				life.set_meta("grown",true)
				life.scale = Vector3(1,0.03,1)
				create_tween().tween_property(life,"scale",Vector3.ONE,2.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
func _process(delta: float) -> void:
	_time += delta
	if not gathering.visible: return
	for i in _birds.size():
		_birds[i].position = Vector3(10.8+cos(_time*0.48+i*1.25)*2.8,2.1+sin(_time+i)*0.2,7.8+sin(_time*0.48+i*1.25)*1.6)
		_birds[i].rotation.y = -_time*0.48-i*1.25
		_birds[i].scale.y = 0.8+sin(_time*6+i)*0.4

func _batch_static(parent: Node3D) -> void:
	var batches := {}
	for node in parent.get_children():
		if not node is MeshInstance3D or water_channels.has(node): continue
		var key := str(hash(node.mesh.get_faces()))+str(node.material_override.get_instance_id())
		if not batches.has(key): batches[key] = {"mesh":node.mesh,"material":node.material_override,"transforms":[]}
		batches[key].transforms.append(node.transform)
		parent.remove_child(node)
		node.queue_free()
	for batch in batches.values():
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = batch.mesh
		multimesh.instance_count = batch.transforms.size()
		for i in batch.transforms.size(): multimesh.set_instance_transform(i,batch.transforms[i])
		var node := MultiMeshInstance3D.new()
		node.multimesh = multimesh
		node.material_override = batch.material
		parent.add_child(node)
