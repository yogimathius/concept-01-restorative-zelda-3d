class_name RestorationPresentation
extends Node3D
## Reusable staged, cosmetic recovery. Gameplay/save completion is immediate.
var target: RegionCreature
var stage := "wounded"
var completing := false
var settled := false
var _elapsed := 0.0
var _arcs: Array[MeshInstance3D] = []
var _drops: Array[MeshInstance3D] = []
var _water: Array[MeshInstance3D] = []
var _start_scale := Vector3.ONE
const DURATION := 4.5
func _ready() -> void:
	name = "RestorationPresentation"
	_start_scale = target.model.scale
	for i in 3:
		var arc := RiverCraft.ring(self,Vector3.UP*0.1,0.7+i*0.2,Color("76d6c2"),0.018)
		arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arc.hide()
		_arcs.append(arc)
	for i in 12:
		var shape := SphereMesh.new()
		shape.radius = 0.025
		shape.height = 0.08
		shape.radial_segments = 6
		shape.rings = 3
		var drop := RiverCraft.mesh(self,shape,Vector3.ZERO,Color("bdebc9"),0,0.25)
		drop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		drop.hide()
		_drops.append(drop)
	# Water physically finds its way outward in ceramic channels after recovery.
	for i in 6:
		var ribbon := RiverCraft.box(self,Vector3.ZERO,Vector3(0.09,0.025,0.6),Color("64c9bd"))
		ribbon.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ribbon.hide()
		_water.append(ribbon)
	if target.restored:
		settled = true
		stage = "settled"
func complete() -> void:
	if completing or settled: return
	completing = true
	_elapsed = 0.0
	stage = "reforming"
	Juice.haptic(40)
	Juice.sfx("restore",0.02)
func _process(delta: float) -> void:
	if completing:
		_elapsed += delta
		stage = "reforming" if _elapsed<1.2 else "flowing" if _elapsed<2.6 else "awakening"
		var t := clampf(_elapsed/DURATION,0,1)
		for i in _arcs.size():
			var arc := _arcs[i]
			arc.visible = _elapsed<3.2
			arc.scale = Vector3.ONE*(0.5+t*3+i*0.3)
			arc.position.y = 0.08+i*0.05
		for i in _drops.size():
			var angle := i*TAU/12+_elapsed*0.5
			_drops[i].visible = _elapsed<3.0
			_drops[i].position = Vector3(cos(angle)*(0.8+t*1.7),0.15+sin(t*PI)*1.3,sin(angle)*(0.8+t*1.7))
		for i in _water.size():
			var amount := clampf((_elapsed-0.9-i*0.12)/1.4,0,1)
			var angle := TAU*i/6
			_water[i].visible = amount>0 and _elapsed<4.1
			_water[i].position = Vector3(sin(angle)*(0.7+amount),0.07,cos(angle)*(0.7+amount))
			_water[i].rotation.y = angle
			_water[i].scale.z = amount*2.8
		if _elapsed>=DURATION:
			completing = false
			settled = true
			stage = "settled"
			for node in _arcs+_drops+_water: node.hide()
		return
	if target.restored:
		settled = true
		stage = "settled"
		for node in _arcs+_drops+_water: node.hide()
		return
	if target.progress<=0: return
	stage = "connected" if target.progress<0.33 else "responding" if target.progress<0.70 else "viable"
	for i in _arcs.size():
		_arcs[i].visible = target._mending_left>0
		_arcs[i].position.y = 0.10+i*target.progress*0.48
		_arcs[i].scale = Vector3.ONE*(0.85+target.progress*0.25)
		_arcs[i].rotation.x = sin(Time.get_ticks_msec()*0.001+i)*0.08
