class_name StoryDirector
extends Node
## Conversation outcomes, chapter guidance and consumables share saved journey state.
var region: Node3D
var dialogue: DialogueScreen
var nearest: StoryNPC
var _talking := ""

func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.name = "StoryDialogue"
	layer.layer = 20
	region.add_child(layer)
	dialogue = DialogueScreen.new()
	layer.add_child(dialogue)
	dialogue.choice.connect(_act)
	dialogue.closed.connect(_resume)
	for cast in StoryChapters.CAST[region.region_id]:
		var npc := StoryNPC.new()
		npc.npc_id = cast.id
		npc.display_name = cast.name
		npc.role = cast.role
		npc.cloth = cast.color
		npc.position = ValleyPlaces.point(ValleyPlaces.LANDING) if region.builder.valley_mode and cast.id=="oren" else cast.at
		if region.builder.valley_mode: npc.surface_height = region.builder.surface_height
		npc.hero = region.hero
		region.add_child(npc)
	region.get_node("TouchControls").context_pressed.connect(func():
		if is_instance_valid(nearest): talk(nearest.npc_id)
		else: open_pack())
	region.equipment_screen.pack_requested.connect(func(): open_pack.call_deferred())

func _physics_process(_delta: float) -> void:
	nearest = null
	var best := 2.8
	for npc in get_tree().get_nodes_in_group("story_npc"):
		if npc.get_parent() != region: continue
		if region.region_id == "R2" and npc.npc_id == "neri" and region.story_flags.has("neri_reply_ready") and not region.story_flags.has("neri_reply_sent"):
			npc.work_at(Vector3(7.3,region.builder.surface_height(Vector2(7.3,5.4)),5.4))
		elif region.region_id == "R2" and npc.npc_id == "neri" and region.builder.entities.M1.runtime.ecology.states.bloomed:
			npc.work_at(Vector3(9.5,region.builder.surface_height(Vector2(9.5,8.0)),8.0))
		elif region.region_id == "R2" and npc.npc_id == "neri" and region.builder.entities.M1.runtime.ecology.states.linked:
			npc.work_at(Vector3(9.5,region.builder.surface_height(Vector2(9.5,9.5)),9.5))
		elif region.region_id == "R2" and npc.npc_id == "neri" and region.builder.entities.M1.runtime.ecology.states.cultivated:
			npc.work_at(region.builder.entities.M1.runtime.global_position+Vector3.LEFT*2)
		if region.region_id == "R2" and npc.npc_id == "daro" and region.builder.entities.M4.runtime.ecology.states.bloomed:
			npc.work_at(Vector3(9.2,region.builder.surface_height(Vector2(9.2,17.3)),17.3))
		elif region.region_id == "R2" and npc.npc_id == "daro" and region.weave_relays.spring_refuge.linked():
			npc.work_at(Vector3(8.2,region.builder.surface_height(Vector2(8.2,17.8)),17.8))
		if region.region_id == "R2" and npc.npc_id == "bryn" and region.story_flags.has("exchange_powered"):
			npc.work_at(Vector3(12.2,region.builder.surface_height(Vector2(12.2,16.2)),16.2))
		if region.region_id == "R2" and npc.npc_id == "oren" and region.builder.entities.M1.get("restored",false) and region.builder.entities.M2.get("restored",false) and region.builder.entities.M3.get("restored",false):
			var destination := Vector2(23.5,16.5) if region.story_flags.has("neri_reply_sent") else Vector2(25.0,19.0)
			npc.work_at(Vector3(destination.x,region.builder.surface_height(destination),destination.y))
		var distance: float = npc.global_position.distance_to(region.hero.global_position)
		if distance < best:
			best = distance
			nearest = npc
	region.get_node("JourneyHUD/ObjectivePanel").visible = region.recovering or nearest == null
	region.get_node("TouchControls").set_context("TALK" if nearest else "PACK",nearest.display_name if nearest else "Travelling cups")

func talk(id: String) -> void:
	var npc: StoryNPC
	for candidate in get_tree().get_nodes_in_group("story_npc"):
		if candidate.get_parent() == region and candidate.npc_id == id: npc = candidate
	if npc == null or npc.global_position.distance_to(region.hero.global_position) > 3.2: return
	_talking = id
	if region.exchange and region.exchange.handles(id):
		region.exchange.talk(id)
		return
	var content := StoryChapters.conversation(region,id)
	if id == "neri" and region.story_flags.has("marsh_message"):
		region.story_flags.neri_letter = true
	elif id == "neri" and region.builder.entities.M1.get("restored",false) and region.builder.entities.M2.get("restored",false) and region.builder.entities.M3.get("restored",false):
		region.story_flags.neri_met = true
	_open(npc.display_name,npc.role,content.pages,content.options)

func _open(name: String, role: String, pages: Array, choices: Array) -> void:
	if region.equipment_screen.visible: region.equipment_screen.toggle()
	if region.journey_map.visible: region.journey_map.toggle(region.checkpoint_position)
	if region.waykeeper and region.waykeeper.screen.visible: region.waykeeper.screen.toggle()
	var controls := region.get_node("TouchControls")
	controls.cancel_touch()
	controls.hide()
	region.hero._interrupt_verbs()
	region.hero.move_input = Vector2.ZERO
	for button in ["GearButton","MapButton","SkillsButton"]: region.get_node("JourneyHUD/"+button).hide()
	region.get_node("JourneyHUD").hide()
	get_tree().paused = true
	dialogue.show_conversation(name,role,pages,choices)

func _resume() -> void:
	get_tree().paused = false
	region.get_node("JourneyHUD").show()
	region.get_node("TouchControls").show()
	for button in ["GearButton","MapButton","SkillsButton"]: region.get_node("JourneyHUD/"+button).show()
	region._update_gear_hud()
	region._save_journey()

func open_pack() -> void:
	var bag: RestorationInventory = region.inventory
	var choices := []
	for id in RestorationInventory.CONSUMABLES:
		var active: bool = region.hero.tea_left > 0 if id == "bloom_tea" else region.hero.cordial_left > 0
		choices.append({"text":"%s · %d%s" % [RestorationInventory.CONSUMABLES[id].name,bag.count_consumable(id)," (active)" if active else ""],"action":"use_"+id,"disabled":bag.count_consumable(id)==0 or active})
	# One always available close button is essential when both cups are unavailable.
	choices.append({"text":"Back to the journey","action":"close"})
	_open("Travelling cups","YOUR PACK",["Bloom Tea: +1.5 Mend reach for 30 seconds.\nReed Cordial: +20% walking speed for 30 seconds.\nDaro brews more from seeds and crystals."],choices)

func _act(action: String) -> void:
	if region.exchange and region.exchange.handle(action): return
	if region.builder.valley_mode and region.valley_journey and region.valley_journey.handle_story(action): return
	match action:
		"learn_force","learn_anchor","learn_weave":
			var id := action.trim_prefix("learn_")
			if not region.waykeeper.learn(id): return
			if region.region_id == "R2" and id == "force": region.story_flags.neri_met = true
			var lesson := "Weave is on your medallion. Walk to the two ceramic relays east of me. Hold the medallion, drag toward the other halo and release. Their water will stay connected when you return." if id == "weave" else "%s is now on your medallion. %s\n\nA new piece is in GEAR: %s. Equip it when you want that technique to behave differently. Swipe upward on the medallion to cycle; SKILLS lets you study mastery and choose upgrades." % [WaykeeperDefinitions.SKILLS[id].name,WaykeeperDefinitions.SKILLS[id].description,"Ferryman's staff" if id=="force" else "Stonekeeper brooch"]
			_open("Iona" if region.region_id == "R1" else ("Oren" if id == "anchor" else "Neri"),"TRADITION LEARNED",[lesson],[{"text":"Try my new technique","action":"close"},{"text":"Study my skills","action":"skills"}])
		"iona_gear":
			for id in ["force","anchor"]:
				if region.waykeeper.progress.unlocked.has(id): region.inventory.grant_gift("iona_"+id)
			region._update_gear_hud()
			_open("Iona","Bridgekeeper's keepsakes",["The Ferryman's staff and Stonekeeper brooch you have learned to use are in GEAR. Try one at a time: tools and brooches replace the item you were wearing.\n\nYour old restorations remain complete. These traditions will travel with you into the marsh and future chapters."],[{"text":"Back to the waterway","action":"close"},{"text":"Study my techniques","action":"skills"}])
		"skills":
			dialogue.dismiss()
			region.waykeeper.screen.toggle.call_deferred()
		"mara_return":
			if not region.builder.entities.C1.get("restored",false): return
			region.story_flags.opening_return_seen = true
			region.story_flags.mara_met = true
			_open("Mara","A PLACE AT THE WATER",["The first water is ours again. Iona has more to teach you, and Oren still waits downstream. Your path is open; this place will remember you."],[{"text":"Continue my journey","action":"close"},{"text":"Choose my Waykeeper path","action":"skills"}])
		"mara_intro","mara_history":
			region.story_flags.mara_met = true
			var given: bool = region.inventory.grant_gift("mara_intro")
			_open("Mara","Ford caretaker",[("Two Bloom Teas for your journey. PACK holds them; each helps Mend reach farther.\n\n" if given else "Your Bloom Tea is in PACK. Daro can brew more.\n\n")+("The Stillfall struck upstream. Our channels stopped in a single night. Oren may know more; he was on the marsh when the bells went quiet." if action=="mara_history" else (("Oren is at the downstream boathouse. The upper weir has given his boat water again." if region.builder.valley_mode else "You have already restored the ford. Speak to Oren at the east landing; he can take you into Reedglass Marsh.") if region.builder.entities.get("C3",{}).get("restored",false) else "Follow the path east to the grove. Hold Mend near it. Iona waits beyond the crossing; Oren is further downstream."))],[{"text":"Set out along the waterway","action":"close"}])
		"neri_quest","neri_lio":
			region.story_flags.neri_met = true
			_open("Neri","Marsh gardener",["Lio used to send me the first seed of every orchard season. He'd wrap it in a terrible joke.\n\nMend the kitchen garden, use Force to reopen the northern nursery feed, and Anchor the southeast sluice bell before Mending it. Perhaps the water can carry his words again."],[{"text":"I'll help you hear from him","action":"close"}])
		"neri_reply_prepare":
			if region.region_id != "R2" or not region.story_flags.has("neri_letter") or region.story_flags.has("neri_reply_ready"): return
			region.story_flags.neri_reply_ready = true
			_open("Neri","A REPLY FOR LIO",["Tell Lio the garden lives, but it is not the garden he left. I want to know what he saw at the reservoir before anyone changes the sluice.","I bound a few new seeds with the reply. Oren can carry it from the bell landing. I'll tend the beds while you find him."],[{"text":"Take the reply to Oren","action":"close"}])
		"neri_reply_send":
			if region.region_id != "R2" or not region.story_flags.has("neri_reply_ready") or region.story_flags.has("neri_reply_sent"): return
			region.story_flags.neri_reply_sent = true
			var before_level: int = region.progression.get_level()
			region.economy.scrip += 4
			region.progression.award_activity(15)
			region._on_economy_changed(before_level)
			_open("Oren","A LETTER ON THE WATER",["I'll take Neri's words upstream when the orchard route is ready. She asked what Lio saw, not for a promise to undo his choice.","The marsh shares four river scrip for carrying the reply. Your work also earned 15 Waykeeper XP. Neri has gone back to her growing beds."],[{"text":"Return to the marsh","action":"close"}])
		"daro_quest":
			region.story_flags.daro_met = true
			dialogue.dismiss()
		"daro_link_quest":
			if region.region_id != "R2" or not region.builder.entities.M4.get("restored",false) or not region.builder.entities.M5.get("restored",false): return
			region.story_flags.daro_link_started = true
			_open("Daro","THE LIVING ROUTE",["The spring has clear water. The willow refuge has living roots. Their ceramic feed is still apart.","Neri can teach Weave once her garden and nursery live. Link the two relays south of my table; I'll plant mint where their waters meet."],[{"text":"I'll connect the route","action":"close"}])
		"daro_link_reward":
			if region.region_id != "R2" or not region.weave_relays.spring_refuge.linked() or region.story_flags.has("daro_link_reward"): return
			region.story_flags.daro_link_started = true
			region.story_flags.daro_link_reward = true
			var before_level: int = region.progression.get_level()
			region.inventory.grant_seeds(3)
			region.economy.scrip += 6
			region.progression.award_activity(15)
			region._on_economy_changed(before_level)
			_open("Daro","A ROUTE THAT GROWS",["The willow roots drink from my spring now. I planted mint between them; the herb bed will keep giving seed when you tend the spring.","Take three seeds and six river scrip for bringing the route back. The work also earned you 15 Waykeeper XP."],[{"text":"Brew with the new harvest","action":"brew"},{"text":"Return to the marsh","action":"close"}])
		"learn_bloom":
			if not region.waykeeper.learn("bloom"): return
			region.story_flags.neri_bloom_started = true
			_open("Neri","BLOOM LESSON",["The garden has water again. Bloom asks living roots what they can become next. Tap beside our linked garden; let it grow a new seed bed.","Daro's willow refuge can become shelter once his spring is linked to its roots. The growth stays, and you can tend the new season later."],[{"text":"I'll help them grow","action":"close"},{"text":"Study Bloom","action":"skills"}])
		"bloom_reward":
			if region.region_id != "R2" or not region.bloom_growth.completed("M1") or not region.bloom_growth.completed("M4") or region.story_flags.has("neri_bloom_reward"): return
			region.story_flags.neri_bloom_reward = true
			var before_level: int = region.progression.get_level()
			region.inventory.grant_seeds(3)
			region.economy.scrip += 5
			region.progression.award_activity(20)
			region._on_economy_changed(before_level)
			_open("Neri","A NEW SEASON",["The garden gives seed, and the willow refuge gives shelter. Daro has moved his work beneath it. They have grown into what people need now.","Take three seeds and five river scrip for the next planting. The work earned you 20 Waykeeper XP."],[{"text":"Return to the garden","action":"close"},{"text":"Study the living arts","action":"skills"}])
		"daro_reward":
			if not region.builder.entities.get("M5",{}).get("restored",false): return
			region.story_flags.daro_met = true
			region.inventory.grant_gift("daro_spring")
			_open("Daro","Reed herbalist",["One Bloom Tea and two Reed Cordials, brewed with your restored spring. You can drink them from PACK.\n\nCome back whenever you want to brew more."],[{"text":"Brew another cup","action":"brew"},{"text":"Thank you, Daro","action":"close"}])
		"brew":
			var bag: RestorationInventory = region.inventory
			_open("Daro","BREWING",["Your supplies: %d seeds and %d river crystals.\n\nBloom Tea costs 3 seeds. Reed Cordial costs 2 river crystals. Nothing is spent unless you tap a recipe." % [bag.seeds,bag.crystals]],[{"text":"Bloom Tea · 3 seeds","action":"brew_bloom_tea","disabled":bag.seeds<3},{"text":"Reed Cordial · 2 crystals","action":"brew_reed_cordial","disabled":bag.crystals<2},{"text":"Leave the brewing table","action":"close"}])
		"brew_bloom_tea","brew_reed_cordial":
			var id := action.trim_prefix("brew_")
			if region.inventory.brew(id):
				_open("Daro","Reed herbalist",["A fresh %s is in your pack. It will keep until you need it." % RestorationInventory.CONSUMABLES[id].name],[{"text":"Brew another cup","action":"brew"},{"text":"Back to the marsh","action":"close"}])
			else: _act("brew")
		"pack": open_pack()
		"use_bloom_tea","use_reed_cordial":
			var id := action.trim_prefix("use_")
			if region.inventory.count_consumable(id)>0 and region.hero.use_cup(id):
				region.inventory.use_consumable(id)
				region._configure_restoration()
				region._save_journey()
				Juice.sfx("anchor")
				dialogue.dismiss()
			else: open_pack()
		"travel_R1","travel_R2":
			dialogue.dismiss()
			region.travel_to.call_deferred(action.trim_prefix("travel_"))
		"marsh_message":
			for id in ["M1","M2","M3"]:
				if not region.builder.entities.get(id,{}).get("restored",false): return
			region.story_flags.marsh_message = true
			region.inventory.grant_gift("marsh_message")
			region._update_gear_hud()
			Juice.wave(region.hero.global_position+Vector3.UP*0.2,3.0,Color("ffe0a4"),1.2)
			_open("Oren","CHAPTER COMPLETE",["The bell carries Lio's answer. A Messenger's brooch is in your gear bag. Return to Neri to share the letter, or explore the remaining places.","Next chapter: Counterweight Orchard.\n\nLio is alive, but his letter says the upper sluice was closed deliberately. That journey is still ahead; the orchard is not playable yet."],[{"text":"Take the letter to Neri","action":"close"},{"text":"Read the letter again","action":"read_message"}])
		"read_message":
			_open("Lio's reed-letter","COUNTERWEIGHT ORCHARD",["'Neri: I'm safe in Counterweight Orchard. I closed the upper sluice to protect the reservoir. The storm didn't break it. Please send a waykeeper. — Lio'"],[{"text":"Keep the letter safe","action":"close"}])
	region._update_gear_hud()
	region._save_journey()
