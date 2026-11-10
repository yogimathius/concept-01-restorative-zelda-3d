class_name WaykeeperProgression
extends RefCounted
## One award per meaningful event; numerical XP never unlocks a discipline.
var unlocked := PackedStringArray(["mend"])
var active := "mend"
var mastery := {}
var events := {}
var upgrades := PackedStringArray()

func unlock(id: String) -> bool:
	if id not in ["force","anchor","weave","channel","bloom"] or unlocked.has(id): return false
	unlocked.append(id)
	return true

func select(id: String) -> bool:
	if not unlocked.has(id): return false
	active = id
	return true

func award(id: String, event: String, amount: int) -> bool:
	if not unlocked.has(id) or amount <= 0 or event.is_empty(): return false
	var key := id + "/" + event
	if events.has(key): return false
	events[key] = mini(amount,3)
	mastery[id] = points(id) + mini(amount,3)
	return true

func points(id: String) -> int:
	return int(mastery.get(id,0))

func rank(id: String) -> int:
	var result := 1
	for threshold in WaykeeperDefinitions.MASTERY_LEVELS:
		if points(id) >= threshold: result += 1
	return result - 1

var level := 1
var purchased := PackedStringArray()
var inherited := PackedStringArray()

func set_level(value: int) -> void:
	level = maxi(1,value)

func skill_points() -> int:
	var spent := 0
	for id in purchased: spent += WaykeeperTree.NODES[id].cost
	return maxi(0,2*(level-1)-spent)

func requirements(id: String) -> PackedStringArray:
	var reasons := PackedStringArray()
	if not WaykeeperTree.NODES.has(id): return PackedStringArray(["Unknown node"])
	if upgrades.has(id): return PackedStringArray(["Learned"])
	var node: Dictionary = WaykeeperTree.NODES[id]
	for parent in node.parents:
		if not upgrades.has(parent): reasons.append("Learn " + WaykeeperTree.NODES[parent].name)
	for skill in node.mastery:
		if not unlocked.has(skill): reasons.append("Learn " + WaykeeperDefinitions.SKILLS[skill].name + " through the story")
		elif points(skill)<node.mastery[skill]: reasons.append("%s mastery %d / %d" % [WaykeeperDefinitions.SKILLS[skill].name,points(skill),node.mastery[skill]])
	if skill_points()<node.cost: reasons.append("Need %d Skill Points · level up through restoration" % node.cost)
	return reasons

func buy_upgrade(id: String) -> bool:
	if not requirements(id).is_empty(): return false
	purchased.append(id)
	upgrades.append(id)
	return true

func to_data() -> Dictionary:
	return {"tree_version":1,"unlocked":Array(unlocked), "active":active, "events":events.duplicate(), "upgrades":Array(upgrades),"purchased":Array(purchased),"inherited":Array(inherited)}

func _inherit(id: String) -> void:
	if upgrades.has(id): return
	for parent in WaykeeperTree.NODES[id].parents: _inherit(parent)
	upgrades.append(id)

func apply_data(data: Dictionary, current_level := 1) -> void:
	set_level(current_level)
	unlocked = PackedStringArray(["mend"])
	mastery.clear()
	events.clear()
	upgrades.clear()
	purchased.clear()
	inherited.clear()
	var learned = data.get("unlocked",[])
	if learned is Array:
		for id in learned:
			if id is String: unlock(id)
	var earned = data.get("events",{})
	if earned is Dictionary:
		for key in earned:
			if not key is String or not (earned[key] is int or earned[key] is float) or not is_finite(earned[key]): continue
			var id: String = key.get_slice("/",0)
			award(id,key.trim_prefix(id+"/"),clampi(int(earned[key]),0,3))
	var legacy = data.get("inherited",[]) if data.get("tree_version",0)==1 else data.get("upgrades",[])
	if legacy is Array:
		for id in legacy:
			if not id is String or id not in WaykeeperTree.LEGACY: continue
			var valid := true
			for skill in WaykeeperTree.NODES[id].mastery:
				if not unlocked.has(skill) or points(skill)<WaykeeperTree.NODES[id].mastery[skill]: valid=false
			if valid:
				inherited.append(id)
				_inherit(id)
	var choices = data.get("purchased",[]) if data.get("tree_version",0)==1 else []
	if choices is Array:
		for id in choices:
			if id is String: buy_upgrade(id)
	active = "mend"
	var selected = data.get("active","mend")
	if selected is String: select(selected)
