class_name WaykeeperJourney
extends Node
## Orchestrates registered techniques; the region only saves/loads its data.
signal changed
var region: Node3D
var progress := WaykeeperProgression.new()
var screen: SkillsScreen
var feedback := ""
var _feedback_left := 0.0
var _cooldown := 0.0
var _handlers := {}
var _loading := false
var _completion_wave := false
var channel_carry := false

func _ready() -> void:
	name = "Waykeeper"
	region.builder.ability_journey = true
	register_technique("force",_pulse)
	register_technique("anchor",_ground)
	register_technique("weave",_weave_hint)
	register_technique("channel",_channel)
	register_technique("bloom",_bloom)
	for id in region.builder.manifest.ENTITIES:
		var target: RegionCreature = region.builder.entities[id].runtime
		var site := RestorationSite.new()
		target.ecology = site
		var profile: Dictionary = WaykeeperDefinitions.SITES.get(region.region_id+"/"+id,{"title":region.builder.entities[id].spec.get("title","Living place"),"requirements":[],"cap":1.0})
		site.setup(target,self,ValleyPlaces.profile(id,profile) if region.builder.valley_mode else profile)
	region.builder.restored.connect(_restored)
	screen = SkillsScreen.new()
	screen.journey = self
	var layer := CanvasLayer.new()
	layer.layer = 15
	region.add_child(layer)
	layer.add_child(screen)
	var button := Button.new()
	button.name = "SkillsButton"
	button.text = "SKILLS"
	button.position = Vector2(414,16)
	button.size = Vector2(64,34)
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.add_theme_font_size_override("font_size",10)
	button.add_theme_color_override("font_color",Color("f4dda4"))
	var style := StyleBoxFlat.new()
	style.bg_color = Color("102b35")
	style.border_color = Color("cfb477")
	style.set_border_width_all(1)
	style.set_corner_radius_all(9)
	button.add_theme_stylebox_override("normal",style)
	button.pressed.connect(func(): screen.toggle.call_deferred())
	button.gui_input.connect(func(event: InputEvent):
		if event is InputEventScreenTouch and event.pressed:
			button.pressed.emit()
			button.accept_event())
	region.get_node("JourneyHUD").add_child(button)
	region.get_viewport().size_changed.connect(func(): button.position.x = region.get_viewport().get_visible_rect().size.x-226)

func register_technique(id: String, handler: Callable) -> void:
	_handlers[id] = handler

func use_active() -> bool:
	return use_skill(progress.active)

func use_skill(id: String) -> bool:
	if not progress.unlocked.has(id):
		_message(teacher_hint(id) if id in ["force","anchor","weave","channel","bloom"] else "That tradition belongs to a future journey")
		return false
	if _cooldown > 0 or not region.hero.is_controllable() or region.hero.is_dashing(): return false
	if not _handlers.has(id): return false
	_cooldown = 0.45
	return _handlers[id].call()

func select(id: String) -> bool:
	region.hero.set_verb_held(Hero.SLOT_RESTORE,false)
	if not progress.select(id): return false
	feedback = ""
	_feedback_left = 0
	region.get_node("TouchControls").set_technique(self)
	changed.emit()
	if region._journey_ready: region._save_journey()
	return true

func cycle() -> void:
	var index := progress.unlocked.find(progress.active)
	select(progress.unlocked[(index+1)%progress.unlocked.size()])
	_message("%s ready · %s" % [WaykeeperDefinitions.SKILLS[progress.active].name,"hold to heal" if progress.active=="mend" else "hold and drag between relays" if progress.active=="weave" else "tap by the capacitor or receiver" if progress.active=="channel" else "tap beside linked living roots" if progress.active=="bloom" else "tap near a place that needs it"])

func learn(id: String) -> bool:
	if id == "weave":
		if region.region_id != "R2" or not region.builder.entities.M1.get("restored",false) or not region.builder.entities.M2.get("restored",false): return false
	elif id == "channel":
		if region.region_id != "R2" or not region.builder.entities.M3.get("restored",false) or not region.builder.entities.M6.get("restored",false): return false
	elif id == "bloom":
		if region.region_id != "R2" or not region.builder.entities.M1.runtime.ecology.states.linked: return false
	elif id in ["force","anchor"]:
		var prerequisite := ("B1" if id == "force" else "C1") if region.region_id == "R1" else ("M1" if id == "force" else "M2")
		if not region.builder.entities.get(prerequisite,{}).get("restored",false): return false
	else: return false
	var first := progress.unlock(id)
	if id in ["force","anchor"]: region.inventory.grant_gift("iona_"+id)
	select(id)
	region._update_gear_hud()
	if first:
		Juice.wave(region.hero.global_position+Vector3.UP*0.2,2.3,WaykeeperDefinitions.SKILLS[id].color,1.0)
		Juice.sfx("anchor")
	_message("Learned %s · swipe the medallion up to change techniques" % WaykeeperDefinitions.SKILLS[id].name)
	return true

func _weave_hint() -> bool:
	_message("Neri's ceramic links wait in Reedglass" if region.region_id == "R1" else "Hold Weave by a severed ceramic pair, drag to the partner's halo, then release")
	return false

func _channel() -> bool:
	if region.charge_circuit: return region.charge_circuit.use()
	_message("Bryn's bell capacitor and ceramic receivers wait in Reedglass")
	return false

func _bloom() -> bool:
	if region.bloom_growth: return region.bloom_growth.use()
	_message("Neri's garden and the willow refuge can grow in Reedglass")
	return false

func meaningful(id: String, event: String, amount: int) -> void:
	if _loading or not progress.award(id,event,amount): return
	changed.emit()
	if region._journey_ready:
		region._configure_restoration()
		region._save_journey()

func gear_effect(id: String) -> bool:
	for item in region.inventory.equipped.values():
		if RestorationInventory.ITEMS[item].get("abilities",[]).has(id): return true
	return false

func _eligible(id: String, radius := 5.0) -> Array[RestorationSite]:
	var result: Array[RestorationSite] = []
	for target in region.hero.find_influenceables(radius):
		if not target is RegionCreature or target.ecology == null: continue
		if not target.ecology.accepts(id): continue
		if not target.has_line_to(region.hero): continue
		result.append(target.ecology)
	result.sort_custom(func(a: RestorationSite,b: RestorationSite): return a.global_position.distance_squared_to(region.hero.global_position)<b.global_position.distance_squared_to(region.hero.global_position))
	return result

func _pulse() -> bool:
	var candidates := _eligible("force",5.0+0.15*(progress.rank("force")-1))
	var direction: Vector3 = region.hero.facing_3d()
	if not candidates.is_empty(): direction = (candidates[0].global_position-region.hero.global_position).normalized()
	if candidates.is_empty():
		_message("Force moves stone · approach a blocked waterway")
		return false
	if not _spend_flow("force"): return false
	# Reuse the Force influence grammar and its emitted pulse feedback, with forgiving aim.
	Juice.wave(region.hero.global_position+direction*0.4+Vector3.UP*0.2,3.2,Color("ffc781"),0.6)
	Juice.sfx("pulse_emit")
	region.hero.play_anim(&"attack")
	var count := candidates.size() if progress.upgrades.has("groundwave") else 1
	for i in count:
		Influence.send(candidates[i].target,Influence.force(region.hero,8,direction,PackedStringArray(["waykeeper"])))
	_message("Stone moved · the water can breathe. Switch to Mend to heal.")
	return true

func apply_force(site: RestorationSite) -> void:
	if not progress.unlocked.has("force"): return
	if site.resolve("cleared","force"):
		if effective_node("undertow"):
			site.resolve("stabilized","force")
		changed.emit()

func _ground() -> bool:
	var candidates := _eligible("anchor",5.0+0.15*(progress.rank("anchor")-1))
	if candidates.is_empty():
		_message("Anchor steadies roots · approach a leaning grove or fractured spring")
		return false
	if not _spend_flow("anchor"): return false
	Juice.sfx("anchor")
	Juice.wave(region.hero.global_position+Vector3.UP*0.08,2,Color("c8b5ff"),0.7)
	var nearest: RestorationSite = candidates[0]
	var targets: Array[RestorationSite] = [nearest]
	if progress.upgrades.has("shared_ground"):
		for id in region.builder.manifest.ENTITIES:
			var site: RestorationSite = region.builder.entities[id].runtime.ecology
			if site != nearest and site.accepts("anchor") and site.global_position.distance_to(nearest.global_position)<=8.0: targets.append(site)
	var cultivated := false
	for site in targets:
		if site.optional_available():
			cultivated = site.resolve("cultivated","anchor") or cultivated
			continue
		site.resolve("stabilized","anchor")
		if gear_effect("anchor_clears"): site.resolve("cleared","anchor")
		if progress.upgrades.has("root_memory") and site.ready_to_restore():
			Influence.send(site.target,Influence.restore(region.hero,0.25))
	_message("Irrigation grounded · Neri can tend her garden. Its clear water renews Flow.") if cultivated else _message("Foundations grounded · stability stays. Switch to Mend when ready.")
	return true

func _restored(id: String) -> void:
	if region.builder._replaying: return
	region.hero.resources.restoration_reward()
	feedback = ""
	_feedback_left = 0
	meaningful("mend",region.region_id+"/"+id+"/restored",3)
	var source: RestorationSite = region.builder.entities[id].runtime.ecology
	if source:
		source.states.flourishing = progress.upgrades.has("living_pulse")
		source.states.cleared = true
		source.states.stabilized = true
	if region.region_id == "R1" and id == "C3":
		_message("The upper weir is flowing · follow its channel to Oren's landing" if region.builder.valley_mode else "The spillway is flowing · the whole waterway answers. Oren waits at the east landing.")
		for area in region.builder.level.areas:
			if area.id in ["R1-S1","R1-S3","R1-S5"]: Juice.wave(Vector3(area.origin.x+4.5,0.12,area.origin.y+3.5),4.0,Color("81e5bd"),1.8)
	if _completion_wave or not progress.upgrades.has("living_pulse"): return
	_completion_wave = true
	var reach := 12.0 if progress.upgrades.has("resonant") else 8.0
	var amount := 0.30 if progress.upgrades.has("resonant") else 0.15
	Juice.wave(source.global_position+Vector3.UP*0.1,reach,Color("cee69a"),1.0)
	for other in region.builder.manifest.ENTITIES:
		var target: RegionCreature = region.builder.entities[other].runtime
		if not target.restored and target.global_position.distance_to(source.global_position)<=reach:
			Influence.send(target,Influence.restore(region.hero,amount))
	_completion_wave = false

func to_data() -> Dictionary:
	var data := progress.to_data()
	data.channel_carry = channel_carry
	return data

func site_data() -> Dictionary:
	var data := {}
	for id in region.builder.manifest.ENTITIES: data[id] = region.builder.entities[id].runtime.ecology.to_data()
	return data

func load_data(data: Dictionary, worlds: Dictionary) -> void:
	_loading = true
	progress.set_level(region.progression.get_level())
	if data.get("skills",{}) is Dictionary: progress.apply_data(data.get("skills",{}),region.progression.get_level())
	var saved_skills = data.get("skills",{})
	channel_carry = saved_skills.get("channel_carry",false)==true and progress.unlocked.has("channel") if saved_skills is Dictionary else false
	if not data.has("skills"):
		# Credit the competence represented by an older completed world; never unheal it.
		var ford = worlds.get("R1",{})
		var healed = ford.get("restored",[]) if ford is Dictionary else []
		if healed is Array:
			if healed.has("C1") or healed.has("C3"): progress.unlock("force")
			if healed.has("B2") or healed.has("B3") or healed.has("C3"): progress.unlock("anchor")
		for world_id in worlds:
			var world_data = worlds[world_id]
			if not world_data is Dictionary or not world_data.get("restored",[]) is Array: continue
			for id in world_data.get("restored",[]):
				if not id is String or not RestorationInventory.DISCOVERIES.has(world_id+"/"+id): continue
				progress.award("mend",world_id+"/"+id+"/restored",3)
				if world_id == "R1":
					if id in ["C1","C2","C3"]: progress.award("force","legacy/"+id,2)
					if id in ["B2","B3","C3"]: progress.award("anchor","legacy/"+id,2)
	var current = worlds.get(region.region_id,{})
	var ecological = current.get("ecology",{}) if current is Dictionary else {}
	for id in region.builder.manifest.ENTITIES:
		var state = ecological.get(id,{}) if ecological is Dictionary else {}
		region.builder.entities[id].runtime.ecology.apply_data(state if state is Dictionary else {})
	if region.region_id == "R2" and region.builder.entities.M6.runtime.ecology.states.charged and region.story_flags.has("exchange_powered"): channel_carry = false
	_loading = false
	region.get_node("TouchControls").set_technique(self)
	changed.emit()

func _message(text: String) -> void:
	feedback = text
	_feedback_left = 5.0

func _physics_process(delta: float) -> void:
	_feedback_left = maxf(0,_feedback_left-delta)
	_cooldown = maxf(0,_cooldown-delta)
	if _feedback_left<=0: feedback = ""

func update_guidance() -> void:
	if region.builder.valley_mode and region.valley_journey:
		region.valley_journey.update_guidance()
		if not feedback.is_empty(): region._context.text = feedback
		return
	if region.region_id == "R1":
		if region.builder.entities.B1.get("restored",false) and not progress.unlocked.has("force"):
			region._guidance.text = "The grove remembers · meet Iona"
			region._context.text = "Cross the broad bridge. Iona, the old bridgekeeper, knows how to move the stone choking the next spring. Tap TALK beside her."
		elif region.builder.entities.C1.get("restored",false) and not progress.unlocked.has("anchor"):
			region._guidance.text = "A new current · return to Iona"
			region._context.text = "The spring now feeds Mara's basin. Return west to see what changed, or ask Iona to teach Anchor. Southern gardens keep your partial work."
		elif not region.builder.entities.C1.get("restored",false) and progress.unlocked.has("force"):
			region._guidance.text = "Give the stonebound spring room to breathe"
			region._context.text = "Follow the path east from Iona. Force moves the stones; Mend brings the water back. Swipe the medallion up to switch, or tap SKILLS."
		elif not region.builder.entities.C3.get("restored",false) and progress.unlocked.has("anchor"):
			region._guidance.text = "Restore the fractured spillway"
			region._context.text = "The east spring needs room to flow and a steady foundation. Force, Anchor, then Mend; each change stays saved. Optional groves await your new techniques."
	if not feedback.is_empty(): region._context.text = feedback

func _spend_flow(id: String) -> bool:
	var cost: float = WaykeeperDefinitions.SKILLS[id].get("flow_cost",0.0)
	if region.hero.resources.spend(cost): return true
	_message("%s needs %d Flow · keep exploring; restored springs help it return" % [WaykeeperDefinitions.SKILLS[id].name, cost])
	return false

func buy_node(id: String) -> bool:
	progress.set_level(region.progression.get_level())
	if not progress.buy_upgrade(id): return false
	region._configure_restoration()
	changed.emit()
	region._save_journey()
	return true

func effective_node(id: String) -> bool:
	return progress.upgrades.has(id) or (id == "undertow" and gear_effect("force_stabilizes"))

func teacher_hint(id: String) -> String:
	if id == "weave": return "Restore garden and nursery, then ask Neri to teach Weave" if region.region_id == "R2" else "Neri teaches Weave beside the restored marsh garden"
	if id == "channel": return "Restore the sluice bell and lantern beds, then ask Bryn at the Reedglass exchange" if region.region_id == "R2" else "Bryn teaches Channel beside the Reedglass exchange"
	if id == "bloom": return "Link Neri's restored garden to the nursery, then ask Neri about living growth" if region.region_id == "R2" else "Neri teaches Bloom beside the linked Reedglass garden"
	if region.region_id == "R1": return "Learn %s from Iona beside the ford" % WaykeeperDefinitions.SKILLS[id].name
	if id == "force": return "Ask Neri by the garden to teach Force" if region.builder.entities.M1.get("restored",false) else "Mend the garden first; Neri can teach Force"
	return "Ask Oren by the bell to teach Anchor" if region.builder.entities.M2.get("restored",false) else "Restore the nursery first; Oren can teach Anchor"
