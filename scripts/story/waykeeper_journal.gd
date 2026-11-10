class_name WaykeeperJournal
extends RefCounted
## Read-only observations of real world state, plus one player-chosen destination.
## No independent quest rewards or duplicate restoration ledger.
const BENEFITS := {
	"R1/B1":"The grove's broad crossing reconnects the ford.",
	"R1/C1":"The spring feeds Mara's public basin; the gathering place comes alive.",
	"R1/B2":"Steady roots give the willow refuge a lasting foundation.",
	"R1/C2":"Clear water returns to the reed pocket.",
	"R1/B3":"Sunleaf growth and the surrounding ground recover together.",
	"R1/C3":"The spillway reconnects the route to Reedglass Marsh and Oren's journey.",
	"R2/M1":"Neri's kitchen garden recovers. Ground its irrigation to help her tend it.",
	"R2/M2":"The nursery's water feed opens and the reeds recover.",
	"R2/M3":"A steady bell reconnects the story of Lio and the upper sluice.",
	"R2/M4":"The willow refuge becomes stable enough to recover.",
	"R2/M5":"Daro's spring recovers; speak to him about travelling brews.",
	"R2/M6":"The lantern beds recover when their water and roots can hold.",
}
var pinned := ""

func entries(region: Node3D) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key in WaykeeperDefinitions.SITES:
		var entry := observe(region,key)
		if not entry.is_empty(): result.append(entry)
	var request := observe(region,"quest/R2/daro_water_route")
	if not request.is_empty(): result.append(request)
	var channel_request := observe(region,"quest/R2/bryn_charge_route")
	if not channel_request.is_empty(): result.append(channel_request)
	var bloom_request := observe(region,"quest/R2/neri_new_season")
	if not bloom_request.is_empty(): result.append(bloom_request)
	var reply_request := observe(region,"quest/R2/neri_reply")
	if not reply_request.is_empty(): result.append(reply_request)
	return result

func care_entries(region: Node3D) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key in WaykeeperDefinitions.SITES:
		var entry := observe(region,"care/"+key)
		if not entry.is_empty(): result.append(entry)
	return result

func observe(region: Node3D, key: String) -> Dictionary:
	if key == "quest/R2/daro_water_route": return _daro_quest(region)
	if key == "quest/R2/bryn_charge_route": return _channel_quest(region)
	if key == "quest/R2/neri_new_season": return _bloom_quest(region)
	if key == "quest/R2/neri_reply": return _reply_quest(region)
	if key.begins_with("care/"): return _care_entry(region,key)
	if not WaykeeperDefinitions.SITES.has(key) or region.waykeeper == null: return {}
	var parts := key.split("/")
	var local: bool = parts[0] == region.region_id
	var profile: Dictionary = WaykeeperDefinitions.SITES[key]
	var states := {}
	var progress := 0.0
	var restored := false
	var at := Vector3.ZERO
	if local:
		var target: RegionCreature = region.builder.entities[parts[1]].runtime
		profile = target.ecology.profile
		states = target.ecology.states
		progress = target.progress
		restored = target.restored
		at = target.global_position
	else:
		var saved = region._worlds.get(parts[0],{})
		if not saved is Dictionary: return {}
		var ecology = saved.get("ecology",{})
		states = ecology.get(parts[1],{}) if ecology is Dictionary else {}
		if not states is Dictionary: states = {}
		var completed = saved.get("restored",[])
		restored = completed is Array and completed.has(parts[1])
		var partial = saved.get("partial",{})
		var amount = partial.get(parts[1],0) if partial is Dictionary else 0
		progress = float(amount) if (amount is int or amount is float) and is_finite(amount) else 0.0
	var known_start: bool = local and key == ("R1/B1" if region.region_id == "R1" else "R2/M1")
	if not known_start and not restored and progress <= 0 and not states.get("seen",false): return {}
	var pending: Array[String] = []
	if not restored:
		for condition in profile.get("requirements",[]):
			if not states.get(condition,false): pending.append(condition)
	var optional: bool = restored and profile.get("optional_anchor",false) and not states.get("cultivated",false)
	var skill: String = "anchor" if optional else (WaykeeperDefinitions.REQUIREMENT_SKILLS[pending[0]] if not pending.is_empty() else "mend")
	var done: bool = restored and not optional
	var unlocked: bool = region.waykeeper.progress.unlocked.has(skill)
	var status: String = "Restored" if restored else ("Ready to Mend" if pending.is_empty() else "Needs " + WaykeeperDefinitions.SKILLS[skill].name)
	if optional: status = "Optional irrigation · Anchor"
	if states.get("cultivated",false): status = "Irrigation thriving"
	var steps: Array[String] = []
	for condition in profile.get("requirements",[]):
		steps.append(("Settled" if states.get(condition,false) or restored else "Needed") + " · " + ("Force clears stone" if condition == "cleared" else "Anchor steadies foundations"))
	steps.append("Restored · water and life return" if restored else "Mend · %d%% recovery saved" % roundi(clampf(progress,0,1)*100))
	if optional: steps.append("Optional · Anchor secures the irrigation")
	return {"id":key,"title":profile.title,"region":parts[0],"local":local,"at":at,"progress":1.0 if restored else clampf(progress,0,1),"restored":restored,"done":done,"skill":skill,"unlocked":unlocked,"status":status,"steps":"\n".join(steps),"benefit":ValleyPlaces.BENEFITS.get(parts[1],BENEFITS.get(key,"")) if local and region.builder.valley_mode else BENEFITS.get(key,""),"reward":RestorationInventory.DISCOVERIES.get(key,"")}

func _care_entry(region: Node3D, key: String) -> Dictionary:
	var place_key := key.trim_prefix("care/")
	if not WaykeeperDefinitions.SITES.has(place_key) or region.waykeeper == null: return {}
	var parts := place_key.split("/")
	var id: String = parts[1]
	var local: bool = parts[0] == region.region_id
	if local:
		if not region.builder.entities[id].get("restored",false): return {}
	else:
		var saved = region._worlds.get(parts[0],{})
		var healed = saved.get("restored",[]) if saved is Dictionary else []
		if not healed is Array or not healed.has(id): return {}
	var profile: Dictionary = CareProfiles.for_site(id)
	var state: Dictionary = region.economy.patches.get(id,{"progress":0.0,"cooldown":0.0,"cycles":0})
	var ready: bool = state.cooldown <= 0
	var at := Vector3.ZERO
	if local and region.renewal_world:
		var patch: Node3D = region.renewal_world.get_node_or_null("Care_"+id)
		if patch: at = patch.global_position
	var status := "%d%% tended" % roundi(state.progress*100) if ready else "Recovering · %ds active play" % ceili(state.cooldown)
	var steps: String = profile.cue + "\n" + ("Hold Mend nearby; partial care stays." if ready else "The original place stays restored. This small strain returns after active play.")
	var benefit: String = "Care yields 2 %s, 1 river scrip and 3 XP." % profile.material.replace("_"," ")
	if id == "M1" or id == "M5" or id == "M6": benefit += " A healthy linked or charged state may also yield seed."
	return {"id":key,"kind":"care","title":profile.title,"region":parts[0],"local":local,"at":at,"progress":state.progress,"restored":true,"done":false,"skill":"mend","unlocked":region.waykeeper.progress.unlocked.has("mend"),"actionable":ready,"status":status,"steps":steps,"benefit":benefit,"reward":"","reward_text":"2 %s · 1 scrip · 3 XP" % profile.material.replace("_"," ")}

func _daro_quest(region: Node3D) -> Dictionary:
	var local: bool = region.region_id == "R2"
	var linked := false
	if local and region.weave_relays.has("spring_refuge"):
		linked = region.weave_relays.spring_refuge.linked()
	else:
		var saved = region._worlds.get("R2",{})
		var ecology = saved.get("ecology",{}) if saved is Dictionary else {}
		if ecology is Dictionary:
			var spring = ecology.get("M5",{})
			var refuge = ecology.get("M4",{})
			linked = spring is Dictionary and refuge is Dictionary and spring.get("linked",false) and refuge.get("linked",false)
	var rewarded: bool = region.story_flags.has("daro_link_reward")
	if not region.story_flags.has("daro_link_started") and not linked and not rewarded: return {}
	var status := "Completed · living mint route" if rewarded else "Return to Daro · report the new water" if linked else "Link spring and willow · Weave"
	var steps := "Daro's spring and the willow refuge are restored.\nLink their ceramic relays with Weave." if not linked else "Spring water reaches the willow roots.\nReturn to Daro for his new harvest." if not rewarded else "Daro planted mint where the waters meet.\nTending his spring now yields a seed."
	var at := Vector3(8.2,0,17.8) if linked else Vector3(9.0,0,19.0)
	return {"id":"quest/R2/daro_water_route","kind":"quest","title":"Daro's living route","region":"R2","local":local,"at":at,"progress":1.0 if rewarded else 0.66 if linked else 0.33,"restored":linked,"done":rewarded,"skill":"weave","unlocked":region.waykeeper.progress.unlocked.has("weave"),"actionable":not linked,"return_to":"Daro","status":status,"steps":steps,"benefit":"The spring can support willow roots and an herb bed without undoing either restoration.","reward":"","reward_text":"15 XP · 6 scrip · 3 seeds; spring care later yields mint seed"}

func _channel_quest(region: Node3D) -> Dictionary:
	var local: bool = region.region_id == "R2"
	var beds := false
	if local: beds = region.builder.entities.M6.runtime.ecology.states.charged
	else:
		var saved = region._worlds.get("R2",{})
		var ecology = saved.get("ecology",{}) if saved is Dictionary else {}
		var site = ecology.get("M6",{}) if ecology is Dictionary else {}
		beds = site is Dictionary and site.get("charged",false)
	var exchange: bool = region.story_flags.has("exchange_powered")
	var rewarded: bool = region.story_flags.has("bryn_channel_reward")
	if not region.story_flags.has("bryn_channel_started") and not beds and not exchange and not rewarded: return {}
	var complete: bool = beds and exchange
	var carrying: bool = region.waykeeper.channel_carry
	var target := "lantern beds" if not beds else "exchange lamp"
	var status := "Completed · two places awake" if rewarded else "Return to Bryn · both receivers lit" if complete else "Charge held · carry to %s" % target if carrying else "Carry bell Charge · %s" % target
	var steps := "The restored bell is a safe Charge source. Tap Channel beside its capacitor, then beside the dark lantern beds and exchange lamp. Each receiver keeps the Charge." if not complete else "Lantern reeds and the exchange now carry the bell's Charge. Return to Bryn."
	if rewarded: steps = "Bryn saw the lantern beds and Sela's work light recover. Their new routine remains."
	var at := Vector3(12.2,0,16.2) if complete else Vector3(20.5,0,22.5) if carrying and not beds else Vector3(12.5,0,16.5) if carrying else Vector3(25.5,0,19.0)
	var progress := 1.0 if rewarded else 0.8 if complete else 0.6 if beds or exchange else 0.2
	return {"id":"quest/R2/bryn_charge_route","kind":"quest","title":"Bryn's carried current","region":"R2","local":local,"at":at,"progress":progress,"restored":complete,"done":rewarded,"skill":"channel","unlocked":region.waykeeper.progress.unlocked.has("channel"),"actionable":not complete,"return_to":"Bryn","status":status,"steps":steps,"benefit":"A steady bell can light living reeds and let Sela shape glass beside a safe evening lamp.","reward":"","reward_text":"20 XP · 8 scrip · 2 riverglass; two permanent lights"}

func _bloom_quest(region: Node3D) -> Dictionary:
	var local: bool = region.region_id == "R2"
	var garden := false
	var refuge := false
	var refuge_linked := false
	if local:
		garden = region.builder.entities.M1.runtime.ecology.states.bloomed
		refuge = region.builder.entities.M4.runtime.ecology.states.bloomed
		refuge_linked = region.builder.entities.M4.runtime.ecology.states.linked
	else:
		var saved = region._worlds.get("R2",{})
		var ecology = saved.get("ecology",{}) if saved is Dictionary else {}
		var m1 = ecology.get("M1",{}) if ecology is Dictionary else {}
		var m4 = ecology.get("M4",{}) if ecology is Dictionary else {}
		garden = m1 is Dictionary and m1.get("bloomed",false)
		refuge = m4 is Dictionary and m4.get("bloomed",false)
		refuge_linked = m4 is Dictionary and m4.get("linked",false)
	var rewarded: bool = region.story_flags.has("neri_bloom_reward")
	if not region.story_flags.has("neri_bloom_started") and not garden and not refuge and not rewarded: return {}
	var complete: bool = garden and refuge
	var status := "Completed · a new season" if rewarded else "Return to Neri · garden and refuge grown" if complete else "Link spring to refuge · Weave" if garden and not refuge_linked else "Bloom the willow refuge" if garden else "Bloom Neri's linked garden"
	var steps := "Tap Bloom beside Neri's restored, linked garden. Daro's restored willow refuge needs its spring Weaved to its roots before Bloom can grow shelter there."
	if complete: steps = "The garden grows seed and the willow refuge offers shelter. Return to Neri."
	if rewarded: steps = "Neri and Daro use the new garden and shelter. Tending the garden now yields seeds."
	var at := Vector3(9.5,0,8.0) if complete else Vector3(9.0,0,19.0) if garden and not refuge_linked else Vector3(10.5,0,17.5) if garden else Vector3(11.5,0,7.5)
	return {"id":"quest/R2/neri_new_season","kind":"quest","title":"Neri's new season","region":"R2","local":local,"at":at,"progress":1.0 if rewarded else 0.8 if complete else 0.5 if garden else 0.2,"restored":complete,"done":rewarded,"skill":"weave" if garden and not refuge_linked else "bloom","unlocked":region.waykeeper.progress.unlocked.has("bloom"),"actionable":not complete,"return_to":"Neri","status":status,"steps":steps,"benefit":"Linked water lets living places grow toward present needs: seed for the garden and shelter for the refuge.","reward":"","reward_text":"20 XP · 5 scrip · 3 seeds; permanent growth and repeatable garden seed"}

func _reply_quest(region: Node3D) -> Dictionary:
	var received: bool = region.story_flags.has("neri_letter")
	var ready: bool = region.story_flags.has("neri_reply_ready")
	var sent: bool = region.story_flags.has("neri_reply_sent")
	if not received and not ready and not sent: return {}
	var status := "Oren carries the reply" if sent else "Bring Neri's reply to Oren" if ready else "Ask Neri what she wants to say"
	var steps := "Lio's letter reached Neri. Speak with her by the garden." if not ready else "Neri bound a new seed with her questions. Carry the packet to Oren at the restored bell." if not sent else "Oren has the packet aboard his boat. Neri returned to her growing garden."
	var destination := Vector3(23.5,0,16.5) if sent else Vector3(25.0,0,19.0) if ready else Vector3(7.3,0,5.4)
	return {"id":"quest/R2/neri_reply","kind":"quest","title":"A reply on the water","region":"R2","local":region.region_id=="R2","at":destination,"progress":1.0 if sent else 0.65 if ready else 0.25,"restored":sent,"done":sent,"skill":"mend","unlocked":true,"actionable":false,"return_to":"Oren" if ready else "Neri","status":status,"steps":steps,"benefit":"Neri asks what the reservoir needs now and sends a seed from the changed garden; Oren prepares to carry her words.","reward":"","reward_text":"15 XP · 4 scrip; a persistent letter and changed routines"}

func pin(region: Node3D, key: String) -> bool:
	var entry := observe(region,key)
	if entry.is_empty() or entry.done: return false
	pinned = key
	return true

func navigation(region: Node3D) -> Dictionary:
	var entry := observe(region,pinned)
	if entry.is_empty() or entry.done: return {}
	if not entry.local: return {"title":entry.title,"caption":"In " + region_name(entry.region),"direction":Vector2.ZERO}
	var offset: Vector3 = entry.at-region.hero.global_position
	var direction := Vector2(offset.x,offset.z)
	var caption: String = "Nearby · " + entry.status if direction.length()<6 else "%s · %.0f m" % [_bearing(direction),direction.length()]
	return {"title":entry.title,"caption":caption,"direction":direction.normalized()}

func apply_data(region: Node3D, data: Variant) -> void:
	pinned = ""
	if not data is Dictionary: return
	var key = data.get("pinned","")
	if key is String: pin(region,key)

func to_data() -> Dictionary:
	return {"pinned":pinned}

static func region_name(id: String) -> String:
	return "Broken Ford" if id == "R1" else "Reedglass Marsh"

func _bearing(direction: Vector2) -> String:
	var names := ["East","Southeast","South","Southwest","West","Northwest","North","Northeast"]
	return names[posmod(roundi(direction.angle()/(PI/4)),8)]
