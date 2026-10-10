class_name RestorationProgression
extends RefCounted
## Experience rewards places healed, once per place across saved sessions.
const XP_PER_PLACE := 40
var xp := 0
var healed_places := PackedStringArray()
var activity_xp := 0

static func threshold(level: int) -> int:
	return 20 * level * (level - 1)

func get_level() -> int:
	var level := 1
	while xp >= threshold(level + 1): level += 1
	return level

func level_progress() -> float:
	var level := get_level()
	return float(xp - threshold(level)) / float(threshold(level + 1) - threshold(level))

func award(place_id: String) -> Dictionary:
	var before := get_level()
	if healed_places.has(place_id): return {"earned": 0, "before": before, "level": before}
	healed_places.append(place_id)
	xp += XP_PER_PLACE
	return {"earned": XP_PER_PLACE, "before": before, "level": get_level()}

func award_activity(amount: int) -> Dictionary:
	var before := get_level()
	if amount <= 0: return {"earned":0,"before":before,"level":before}
	activity_xp += mini(amount,100)
	xp = healed_places.size() * XP_PER_PLACE + activity_xp
	return {"earned":amount,"before":before,"level":get_level()}

func to_data() -> Dictionary:
	return {"xp": xp, "healed_places": Array(healed_places),"activity_xp":activity_xp}

func apply_data(data: Dictionary) -> void:
	healed_places.clear()
	var places = data.get("healed_places", [])
	if places is Array:
		for place in places:
			if place is String and not place.is_empty() and not healed_places.has(place): healed_places.append(place)
	activity_xp = clampi(int(data.get("activity_xp",0)),0,1000000) if data.get("activity_xp",0) is int or data.get("activity_xp",0) is float else 0
	xp = healed_places.size() * XP_PER_PLACE + activity_xp
