class_name Influence
extends RefCounted
## The only way one thing affects another. Receivers implement
## receive_influence(inf: Influence) and decide what it means. There is no
## damage path anywhere in this game.

enum Kind { FORCE, RESTORE, STATE, HAZARD }

var kind: Kind
var source: Node3D
var state_id: StringName = &""
var amount: float = 0.0
var direction: Vector3 = Vector3.ZERO
var tags: PackedStringArray = PackedStringArray()

static func force(src: Node3D, strength: float, dir: Vector3, p_tags := PackedStringArray()) -> Influence:
	var inf := Influence.new()
	inf.kind = Kind.FORCE
	inf.source = src
	inf.amount = strength
	inf.direction = _flatten(dir)
	inf.tags = p_tags
	return inf

static func state(src: Node3D, id: StringName, amt: float, p_tags := PackedStringArray()) -> Influence:
	var inf := Influence.new()
	inf.kind = Kind.STATE
	inf.source = src
	inf.state_id = id
	inf.amount = amt
	inf.tags = p_tags
	return inf

static func restore(src: Node3D, rate: float) -> Influence:
	var inf := Influence.new()
	inf.kind = Kind.RESTORE
	inf.source = src
	inf.amount = rate
	return inf

static func hazard(src: Node3D) -> Influence:
	var inf := Influence.new()
	inf.kind = Kind.HAZARD
	inf.source = src
	return inf

static func send(target: Object, inf: Influence) -> bool:
	if target == null or not is_instance_valid(target) or not target.has_method("receive_influence"):
		return false
	target.receive_influence(inf)
	return true

static func _flatten(v: Vector3) -> Vector3:
	v.y = 0.0
	return v.normalized() if v.length_squared() > 0.0001 else Vector3.ZERO
