class_name RestorationInventory
extends RefCounted
## Every place has one guaranteed discovery. Equipping never destroys an item.
const SLOTS := ["tool", "cloak", "charm"]
const STARTERS := {"tool": "wayfarer_wand", "cloak": "wayfarer_cloak", "charm": "wayfarer_charm"}
const ITEMS := {
	"wayfarer_wand": {"name": "Wayfarer's wand", "slot": "tool", "color": Color("b9ad85"), "accent": Color("81d3c1"), "tier": 0, "reach": 0.0, "effect": "Your first restoration tool", "source": "Starter gear"},
	"grove_wand": {"name": "Bloomkeeper's wand", "slot": "tool", "color": Color("529574"), "accent": Color("effa9a"), "tier": 1, "reach": 0.5, "effect": "+0.5 Mend reach", "source": "Heal the first grove"},
	"river_staff": {"name": "Riverglass staff", "slot": "tool", "color": Color("438fbd"), "accent": Color("98f9ed"), "tier": 2, "reach": 0.9, "effect": "+0.9 Mend reach", "source": "Heal the southern spring"},
	"wayfarer_cloak": {"name": "Wayfarer's cloak", "slot": "cloak", "color": Color("28495a"), "accent": Color("c8b581"), "tier": 0, "speed": 0.0, "effect": "A cloak for a new journey", "source": "Starter gear"},
	"spring_cloak": {"name": "Reedglass mantle", "slot": "cloak", "color": Color("317f90"), "accent": Color("b8f2dc"), "tier": 1, "speed": 0.05, "effect": "+5% walking speed", "source": "Heal the first spring"},
	"sunleaf_cloak": {"name": "Sunleaf cloak", "slot": "cloak", "color": Color("cc813e"), "accent": Color("fff0a4"), "tier": 2, "speed": 0.10, "effect": "+10% walking speed", "source": "Heal the last grove"},
	"wayfarer_charm": {"name": "Wayfarer's brooch", "slot": "charm", "color": Color("c8b581"), "accent": Color("81d3c1"), "tier": 0, "rate": 0.0, "effect": "A keepsake over your heart", "source": "Starter gear"},
	"bloom_charm": {"name": "Heartbloom brooch", "slot": "charm", "color": Color("e4b27f"), "accent": Color("ffa6ba"), "tier": 1, "rate": 0.08, "effect": "+0.08 healing per second", "source": "Heal the reed-pocket grove"},
	"river_charm": {"name": "Dewlight brooch", "slot": "charm", "color": Color("d3e6ec"), "accent": Color("a3f5ff"), "tier": 2, "rate": 0.14, "effect": "+0.14 healing per second", "source": "Heal the reed-pocket spring"},
	"marsh_staff": {"name":"Reedcaller staff", "slot":"tool", "color":Color("8961a9"), "accent":Color("ffd39a"), "tier":3, "reach":1.2, "effect":"+1.2 Mend reach", "source":"Restore Neri's garden"},
	"marsh_cloak": {"name":"Coral-reed cloak", "slot":"cloak", "color":Color("b45e79"), "accent":Color("ffe1a5"), "tier":3, "speed":0.12, "effect":"+12% walking speed", "source":"Restore the reed nursery"},
	"bell_charm": {"name":"Sluice-song brooch", "slot":"charm", "color":Color("b997e6"), "accent":Color("ffe2a4"), "tier":3, "rate":0.20, "effect":"+0.20 healing per second", "source":"Wake the sluice bell"},
	"messenger_charm": {"name":"Messenger's brooch", "slot":"charm", "color":Color("f2bb80"), "accent":Color("b2ffd9"), "tier":3, "rate":0.24, "effect":"+0.24 healing per second", "source":"Help Neri find Lio's message"},
	"ferryman_staff":{"name":"Ferryman's staff", "slot":"tool", "color":Color("356f99"), "accent":Color("ffd492"), "tier":3, "reach":0.4, "abilities":["force_stabilizes"], "effect":"Force also steadies blocked springs", "source":"Learn Force with Iona"},
	"stonekeeper_charm":{"name":"Stonekeeper brooch", "slot":"charm", "color":Color("8467ae"), "accent":Color("ebd4a2"), "tier":3, "rate":0.04, "abilities":["anchor_clears"], "effect":"Anchor roots lift stone from water", "source":"Learn Anchor with Iona"},
	"market_reed_cloak":{"name":"Landing reed mantle", "slot":"cloak", "color":Color("457f75"), "accent":Color("d8dbad"), "tier":2, "speed":0.06, "effect":"+6% walking speed", "source":"Tavi's Ford Exchange"},
	"marsh_cord_cloak":{"name":"Reedglass cord mantle", "slot":"cloak", "color":Color("806f9c"), "accent":Color("c4efda"), "tier":3, "speed":0.04, "abilities":["anchor_clears"], "effect":"Anchor roots help lift stone from water", "source":"Sela's Reedglass Exchange"},
	"reedweave_cloak":{"name":"Reedweave mantle", "slot":"cloak", "color":Color("426d8b"), "accent":Color("b9e8c6"), "tier":2, "speed":0.07, "effect":"+7% walking speed", "source":"Rivercraft"},
	"riverglass_lens":{"name":"Riverglass lens", "slot":"charm", "color":Color("5b9eb2"), "accent":Color("d9faff"), "tier":3, "rate":0.06, "abilities":["force_stabilizes"], "effect":"Force can steady the systems it clears", "source":"Gemcutting"},
}
const DISCOVERIES := {"R1/B1": "grove_wand", "R1/C1": "spring_cloak", "R1/C3": "river_staff", "R1/B2": "bloom_charm", "R1/C2": "river_charm", "R1/B3": "sunleaf_cloak", "R2/M1":"marsh_staff", "R2/M2":"marsh_cloak", "R2/M3":"bell_charm", "R2/M4":"", "R2/M5":"", "R2/M6":""}
const CONSUMABLES := {
	"bloom_tea":{"name":"Bloom Tea", "effect":"+1.5 Mend reach for 30 seconds", "cost":3, "resource":"seeds"},
	"reed_cordial":{"name":"Reed Cordial", "effect":"+20% walking speed for 30 seconds", "cost":2, "resource":"crystals"},
}
const GIFTS := {"iona_force":{"gear":"ferryman_staff"},"iona_anchor":{"gear":"stonekeeper_charm"},"mara_intro":{"bloom_tea":2}, "daro_spring":{"bloom_tea":1,"reed_cordial":2}, "marsh_message":{"gear":"messenger_charm"}}
var gifts := PackedStringArray()
var brewed := {"bloom_tea":0,"reed_cordial":0}
var used := {"bloom_tea":0,"reed_cordial":0}
var earned_cups := {"bloom_tea":0,"reed_cordial":0}
var owned := PackedStringArray(["wayfarer_wand", "wayfarer_cloak", "wayfarer_charm"])
var equipped: Dictionary = STARTERS.duplicate()
var claimed := PackedStringArray()
var unseen := PackedStringArray()
var seeds := 0
var crystals := 0
var earned_seeds := 0
var trade_acquired := PackedStringArray()
var sold := PackedStringArray()

func discover(place: String) -> String:
	if not DISCOVERIES.has(place) or claimed.has(place): return ""
	claimed.append(place)
	var id: String = DISCOVERIES[place]
	if not id.is_empty() and not owned.has(id):
		owned.append(id)
		unseen.append(id)
	if place.contains("/B") or place in ["R2/M1","R2/M2","R2/M4","R2/M6"]:
		seeds += 3
		earned_cups.bloom_tea += 1
	else:
		crystals += 2
		earned_cups.reed_cordial += 1
	return id

func equip(id: String) -> bool:
	if not ITEMS.has(id) or not owned.has(id): return false
	equipped[ITEMS[id].slot] = id
	unseen.erase(id)
	return true

func grant_trade(id: String) -> bool:
	if not ITEMS.has(id) or owned.has(id): return false
	owned.append(id)
	if not trade_acquired.has(id): trade_acquired.append(id)
	sold.erase(id)
	unseen.append(id)
	return true

func sell_trade(id: String) -> bool:
	if not ITEMS.has(id) or not owned.has(id) or STARTERS.values().has(id) or equipped.values().has(id): return false
	owned.erase(id)
	unseen.erase(id)
	if not sold.has(id): sold.append(id)
	return true

func bonus(stat: String) -> float:
	var value := 0.0
	for id in equipped.values(): value += float(ITEMS[id].get(stat, 0.0))
	return value

func grant_seeds(amount: int) -> void:
	if amount <= 0: return
	earned_seeds += amount
	seeds += amount

func to_data() -> Dictionary:
	return {"owned": Array(owned), "equipped": equipped.duplicate(), "claimed": Array(claimed), "unseen": Array(unseen), "seeds": seeds, "crystals": crystals, "earned_seeds":earned_seeds, "gifts":Array(gifts), "brewed":brewed.duplicate(), "used":used.duplicate(),"trade_acquired":Array(trade_acquired),"sold":Array(sold)}

func apply_data(data: Dictionary) -> void:
	owned = PackedStringArray(STARTERS.values())
	equipped = STARTERS.duplicate()
	claimed.clear()
	unseen.clear()
	# Reconstruct earned supplies/items from valid claims rather than trusting totals.
	seeds = 0
	crystals = 0
	earned_seeds = 0
	gifts.clear()
	trade_acquired.clear()
	sold.clear()
	brewed = {"bloom_tea":0,"reed_cordial":0}
	used = {"bloom_tea":0,"reed_cordial":0}
	earned_cups = {"bloom_tea":0,"reed_cordial":0}
	var places = data.get("claimed", [])
	if places is Array:
		for place in places:
			if place is String: discover(place)
	var saved_gifts = data.get("gifts", [])
	if saved_gifts is Array:
		for gift in saved_gifts:
			if gift is String: grant_gift(gift)
	var saved_trade = data.get("trade_acquired",[])
	if saved_trade is Array:
		for id in saved_trade:
			if id is String and ITEMS.has(id) and not STARTERS.values().has(id) and not trade_acquired.has(id):
				trade_acquired.append(id)
				if not owned.has(id): owned.append(id)
	var saved_sold = data.get("sold",[])
	if saved_sold is Array:
		for id in saved_sold:
			if id is String and ITEMS.has(id) and not STARTERS.values().has(id) and not sold.has(id):
				sold.append(id)
				owned.erase(id)
	var saved_brews = data.get("brewed", {})
	var saved_uses = data.get("used", {})
	var seed_awards = data.get("earned_seeds",0)
	if seed_awards is int or seed_awards is float:
		earned_seeds = clampi(int(seed_awards),0,100000)
		seeds += earned_seeds
	for id in CONSUMABLES:
		if saved_brews is Dictionary and (saved_brews.get(id,0) is int or saved_brews.get(id,0) is float):
			var resource: String = CONSUMABLES[id].resource
			var available := seeds if resource == "seeds" else crystals
			var amount := clampi(saved_brews[id],0,available / CONSUMABLES[id].cost) if saved_brews.has(id) else 0
			brewed[id] = amount
			if resource == "seeds": seeds -= amount * CONSUMABLES[id].cost
			else: crystals -= amount * CONSUMABLES[id].cost
		if saved_uses is Dictionary and (saved_uses.get(id,0) is int or saved_uses.get(id,0) is float):
			used[id] = clampi(saved_uses.get(id,0),0,earned_cups[id]+brewed[id])
	unseen.clear()
	var saved_unseen = data.get("unseen", [])
	if saved_unseen is Array:
		for id in saved_unseen:
			if id is String and owned.has(id) and not unseen.has(id): unseen.append(id)
	var choices = data.get("equipped", {})
	if choices is Dictionary:
		for slot in SLOTS:
			var id = choices.get(slot, "")
			if id is String and ITEMS.has(id) and ITEMS[id].slot == slot: equip(id)

func grant_gift(source: String) -> bool:
	if not GIFTS.has(source) or gifts.has(source): return false
	gifts.append(source)
	var gift: Dictionary = GIFTS[source]
	for id in CONSUMABLES: earned_cups[id] += int(gift.get(id,0))
	if gift.has("gear") and not owned.has(gift.gear):
		owned.append(gift.gear)
		unseen.append(gift.gear)
	return true

func count_consumable(id: String) -> int:
	if not CONSUMABLES.has(id): return 0
	return earned_cups[id]+brewed[id]-used[id]

func use_consumable(id: String) -> bool:
	if count_consumable(id) <= 0: return false
	used[id] += 1
	return true

func brew(id: String) -> bool:
	if not CONSUMABLES.has(id): return false
	var cup: Dictionary = CONSUMABLES[id]
	var available := seeds if cup.resource == "seeds" else crystals
	if available < cup.cost: return false
	if cup.resource == "seeds": seeds -= cup.cost
	else: crystals -= cup.cost
	brewed[id] += 1
	return true
