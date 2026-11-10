class_name RestorationEconomy
extends RefCounted
## Renewable care and settlement exchange. Active-play timers only; main
## restoration, mastery and unique gear claims remain independent.
const MATERIALS := ["reed_fiber","silt_clay","riverglass","polished_gem"]
const DISCIPLINES := ["herbcraft","rivercraft","gemcutting"]
const RECIPES := {
	"bloom_tea":{"name":"Bloom Tea","discipline":"herbcraft","rank":1,"level":1,"materials":{},"gear":""},
	"reed_cordial":{"name":"Reed Cordial","discipline":"herbcraft","rank":2,"level":2,"materials":{},"gear":""},
	"reedweave_cloak":{"name":"Reedweave mantle","discipline":"rivercraft","rank":1,"level":2,"materials":{"reed_fiber":4,"silt_clay":2},"scrip":4,"gear":"reedweave_cloak"},
	"polished_gem":{"name":"Polished riverglass","discipline":"gemcutting","rank":1,"level":2,"materials":{"riverglass":2},"gear":""},
	"riverglass_lens":{"name":"Riverglass lens","discipline":"gemcutting","rank":2,"level":3,"materials":{"polished_gem":2,"silt_clay":2},"scrip":8,"gear":"riverglass_lens"},
}
const COOLDOWN := 120.0
var scrip := 0
var materials := {"reed_fiber":0,"silt_clay":0,"riverglass":0,"polished_gem":0}
var craft_xp := {"herbcraft":0,"rivercraft":0,"gemcutting":0}
var patches := {}
var commission_active := false
var commission_sites := PackedStringArray()
var commission_turnins := 0

func rank(id: String) -> int:
	return mini(3,1+int(craft_xp.get(id,0))/2)

func patch(id: String) -> Dictionary:
	if not patches.has(id): patches[id] = {"progress":0.0,"cooldown":0.0,"cycles":0}
	return patches[id]

func tick_patch(id: String, delta: float) -> void:
	var state: Dictionary = patch(id)
	if delta>0 and state.cooldown>0: state.cooldown=maxf(0,state.cooldown-delta)

func tend(id: String, material: String, progression: RestorationProgression) -> bool:
	if material not in MATERIALS or material=="polished_gem": return false
	var state: Dictionary = patch(id)
	if state.cooldown>0 or state.progress<1: return false
	state.progress=0.0
	state.cooldown=COOLDOWN
	state.cycles+=1
	materials[material]+=2
	scrip+=1
	progression.award_activity(3)
	if commission_active and not commission_sites.has(id): commission_sites.append(id)
	return true

func accept_commission() -> bool:
	if commission_active: return false
	commission_active=true
	commission_sites.clear()
	return true

func claim_commission(progression: RestorationProgression) -> bool:
	if not commission_active or commission_sites.size()<3: return false
	commission_active=false
	commission_sites.clear()
	commission_turnins+=1
	scrip+=8
	progression.award_activity(15)
	return true

func can_craft(id: String, inventory: RestorationInventory, waykeeper_level: int) -> bool:
	if not RECIPES.has(id): return false
	var recipe: Dictionary = RECIPES[id]
	if waykeeper_level<int(recipe.level) or rank(recipe.discipline)<int(recipe.rank): return false
	if not recipe.gear.is_empty() and inventory.owned.has(recipe.gear): return false
	if scrip<int(recipe.get("scrip",0)): return false
	for material in recipe.materials:
		if materials.get(material,0)<recipe.materials[material]: return false
	if id in RestorationInventory.CONSUMABLES:
		return inventory.seeds>=3 if id=="bloom_tea" else inventory.crystals>=2
	return true

func craft(id: String, inventory: RestorationInventory, waykeeper_level: int) -> bool:
	if not can_craft(id,inventory,waykeeper_level): return false
	var recipe: Dictionary = RECIPES[id]
	if id in RestorationInventory.CONSUMABLES:
		if not inventory.brew(id): return false
	elif not recipe.gear.is_empty(): inventory.grant_trade(recipe.gear)
	else: materials.polished_gem+=1
	for material in recipe.materials: materials[material]-=recipe.materials[material]
	scrip-=int(recipe.get("scrip",0))
	craft_xp[recipe.discipline]+=1
	return true

func sell_material(id: String) -> bool:
	if id not in MATERIALS or materials[id]<=0: return false
	materials[id]-=1
	scrip+=4 if id=="polished_gem" else 2
	return true

func sell_gear(id: String, inventory: RestorationInventory) -> bool:
	if not inventory.sell_trade(id): return false
	scrip+=maxi(6,int(RestorationInventory.ITEMS[id].tier)*5)
	return true

func buy_gear(id: String, inventory: RestorationInventory) -> bool:
	if not RestorationInventory.ITEMS.has(id) or inventory.owned.has(id): return false
	if id not in ["market_reed_cloak","marsh_cord_cloak"] and not inventory.sold.has(id): return false
	var price := 14 if id=="market_reed_cloak" else 18 if id=="marsh_cord_cloak" else maxi(12,int(RestorationInventory.ITEMS[id].tier)*10)
	if scrip<price: return false
	scrip-=price
	inventory.grant_trade(id)
	return true

func to_data() -> Dictionary:
	return {"scrip":scrip,"materials":materials.duplicate(),"craft_xp":craft_xp.duplicate(),"patches":patches.duplicate(true),"commission_active":commission_active,"commission_sites":Array(commission_sites),"commission_turnins":commission_turnins}

func apply_data(data: Dictionary) -> void:
	scrip=clampi(int(data.get("scrip",0)),0,1000000) if data.get("scrip",0) is int or data.get("scrip",0) is float else 0
	for id in MATERIALS:
		var value = data.get("materials",{}).get(id,0) if data.get("materials",{}) is Dictionary else 0
		materials[id]=clampi(int(value),0,1000000) if value is int or value is float else 0
	for id in DISCIPLINES:
		var value = data.get("craft_xp",{}).get(id,0) if data.get("craft_xp",{}) is Dictionary else 0
		craft_xp[id]=clampi(int(value),0,100000) if value is int or value is float else 0
	patches.clear()
	var saved = data.get("patches",{})
	if saved is Dictionary:
		for id in saved:
			if not id is String or not saved[id] is Dictionary: continue
			var raw: Dictionary = saved[id]
			patches[id]={"progress":clampf(float(raw.get("progress",0)),0,1),"cooldown":clampf(float(raw.get("cooldown",0)),0,COOLDOWN),"cycles":clampi(int(raw.get("cycles",0)),0,100000)}
	commission_active=data.get("commission_active",false)==true
	commission_sites.clear()
	var sites = data.get("commission_sites",[])
	if commission_active and sites is Array:
		for id in sites:
			if id is String and not commission_sites.has(id) and commission_sites.size()<3: commission_sites.append(id)
	commission_turnins=clampi(int(data.get("commission_turnins",0)),0,100000) if data.get("commission_turnins",0) is int or data.get("commission_turnins",0) is float else 0
