extends TestCase
const FORD := preload("res://scenes/levels/region1.tscn")
const MARSH := preload("res://scenes/levels/region2.tscn")
const VALLEY := preload("res://scenes/levels/river_valley.tscn")
const SAVE := "user://test-restorative-economy.json"

func after_each() -> void:
	tree.paused=false
	await super.after_each()
	for path in [SAVE,SAVE+".tmp"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func tap(at: Vector2) -> void:
	var event := InputEventScreenTouch.new()
	event.index=1
	event.position=at
	event.pressed=true
	tree.root.push_input(event,true)
	await step(2)
	event.pressed=false
	tree.root.push_input(event,true)
	await step(2)

func test_care_rewards_are_repeatable_only_after_active_play_and_commission_uses_distinct_sites() -> void:
	var economy := RestorationEconomy.new()
	var progress := RestorationProgression.new()
	check(economy.accept_commission(),"commission can be accepted")
	for id in ["B1","B1","C1","C3"]:
		var state := economy.patch(id)
		state.progress=1.0
		if id=="B1" and state.cycles>0: economy.tick_patch(id,RestorationEconomy.COOLDOWN)
		check(economy.tend(id,"reed_fiber",progress),"a complete, ready care patch pays once")
	check(economy.commission_sites.size()==3,"repeat tending one patch does not count as a new commission site")
	check(economy.scrip==4 and progress.activity_xp==12,"care grants small saved currency and XP")
	check(economy.claim_commission(progress),"three distinct sites allow turn-in")
	check(economy.scrip==12 and progress.activity_xp==27,"turn-in grants exactly one bonus")
	check(not economy.claim_commission(progress),"cannot claim the same commission twice")
	var saved: Dictionary = JSON.parse_string(JSON.stringify({"economy":economy.to_data(),"progress":progress.to_data()}))
	var resumed := RestorationEconomy.new()
	resumed.apply_data(saved.economy)
	var resumed_progress := RestorationProgression.new()
	resumed_progress.apply_data(saved.progress)
	check(resumed.scrip==12 and resumed.patch("B1").cooldown>0,"currency and active cooldown survive save/load")
	check(resumed_progress.xp==27,"activity XP survives save/load")

func test_crafting_levels_equipment_sale_and_buyback() -> void:
	var economy := RestorationEconomy.new()
	var bag := RestorationInventory.new()
	economy.materials.reed_fiber=4
	economy.materials.silt_clay=4
	economy.materials.riverglass=4
	economy.scrip=30
	check(not economy.can_craft("reedweave_cloak",bag,1),"Waykeeper level gates rivercraft")
	check(economy.craft("reedweave_cloak",bag,2),"level two can craft visible gear")
	check(bag.owned.has("reedweave_cloak") and economy.materials.reed_fiber==0,"craft consumes materials and owns gear")
	check(economy.craft("polished_gem",bag,2) and economy.craft("polished_gem",bag,2),"gem practice builds rank")
	check(not economy.can_craft("riverglass_lens",bag,2),"advanced lens needs Waykeeper level three")
	check(economy.craft("riverglass_lens",bag,3),"level and craft rank together unlock lens")
	check(bag.equip("riverglass_lens"),"crafted lens can replace worn charm")
	check(not economy.sell_gear("riverglass_lens",bag),"equipped gear cannot be sold")
	check(bag.equip("wayfarer_charm") and economy.sell_gear("riverglass_lens",bag),"unequipped crafted gear can be sold")
	var saved: Dictionary = JSON.parse_string(JSON.stringify({"economy":economy.to_data(),"inventory":bag.to_data()}))
	var resumed := RestorationEconomy.new()
	var resumed_bag := RestorationInventory.new()
	resumed.apply_data(saved.economy)
	resumed_bag.apply_data(saved.inventory)
	check(resumed_bag.sold.has("riverglass_lens") and not resumed_bag.owned.has("riverglass_lens"),"sale survives save/load")
	resumed.scrip=30
	check(resumed.buy_gear("riverglass_lens",resumed_bag),"sold gear can be bought back")
	check(resumed_bag.owned.has("riverglass_lens"),"bought back gear is visible in inventory")

func test_care_patch_uses_mend_and_legacy_save_receives_empty_economy() -> void:
	var region: Node3D = FORD.instantiate()
	region.save_path=SAVE
	region.get_node("Hero").use_device_input=false
	world.add_child(region)
	await step(5)
	region.builder.restore("B1")
	await step(2)
	var patch: RenewalPatch = region.renewal_world.get_node("Care_B1")
	check(not patch.restored,"restoring a grove opens nearby renewable care")
	region.hero.respawn_at(patch.global_position+Vector3.LEFT*1.0+Vector3.UP*0.02)
	region.hero.set_verb_held(Hero.SLOT_RESTORE,true)
	await step(100)
	region.hero.set_verb_held(Hero.SLOT_RESTORE,false)
	check(region.economy.patch("B1").cycles==1,"held Mend completes the care patch")
	check(region.builder.entities.B1.restored,"renewable care does not undo the original restoration")
	check(not region.waykeeper.progress.mastery.has("care"),"care does not manufacture technique mastery")
	region._save_journey()
	region.persist_progress=false
	region.free()
	var resumed: Node3D = FORD.instantiate()
	resumed.save_path=SAVE
	resumed.get_node("Hero").use_device_input=false
	world.add_child(resumed)
	await step(5)
	check(resumed.economy.patch("B1").cycles==1 and resumed.builder.entities.B1.restored,"care and unique restoration both reload")

func test_touch_dialogue_accepts_commission_and_buys_visible_gear() -> void:
	var region: Node3D = FORD.instantiate()
	region.persist_progress=false
	region.get_node("Hero").use_device_input=false
	world.add_child(region)
	await step(6)
	var edda: StoryNPC
	var tavi: StoryNPC
	for npc in tree.get_nodes_in_group("story_npc"):
		if npc.get_parent()!=region: continue
		if npc.npc_id=="edda": edda=npc
		if npc.npc_id=="tavi": tavi=npc
	check(edda!=null and tavi!=null,"the Ford exchange has two reachable inhabitants")
	if edda==null or tavi==null: return
	check(region.builder.can_walk(Vector2i(floori(edda.position.x),floori(edda.position.z))) and region.builder.can_walk(Vector2i(floori(tavi.position.x),floori(tavi.position.z))),"both traders stand on a walkable Ford path")
	region.hero.respawn_at(edda.global_position+Vector3.BACK*1.2+Vector3.UP*0.02)
	await step(4)
	var context: TouchScreenButton = region.get_node("TouchControls/ContextButton")
	await tap(context.position+context.texture_normal.get_size()*context.scale*0.5)
	check(tree.paused and region.story.dialogue.visible,"touch TALK opens Edda's commission")
	var button: Button = region.story.dialogue._buttons[1]
	await tap(region.story.dialogue.position+button.position+button.size*0.5)
	check(region.economy.commission_active,"touch acceptance starts saved care work")
	region.story.dialogue.dismiss()
	region.economy.scrip=14
	region.hero.respawn_at(tavi.global_position+Vector3.BACK*1.2+Vector3.UP*0.02)
	await step(4)
	await tap(context.position+context.texture_normal.get_size()*context.scale*0.5)
	check(region.story.dialogue.visible,"Tavi's touch exchange opens")
	button=region.story.dialogue._buttons[0]
	await tap(region.story.dialogue.position+button.position+button.size*0.5)
	button=region.story.dialogue._buttons[0]
	await tap(region.story.dialogue.position+button.position+button.size*0.5)
	button=region.story.dialogue._buttons[0]
	await tap(region.story.dialogue.position+button.position+button.size*0.5)
	check(region.inventory.owned.has("market_reed_cloak") and region.economy.scrip==0,"touch purchase trades scrip for visible equipment")

func test_every_playable_region_has_walkable_care_placements() -> void:
	for scene in [FORD,MARSH,VALLEY]:
		var region: Node3D = scene.instantiate()
		region.persist_progress=false
		region.get_node("Hero").use_device_input=false
		world.add_child(region)
		await step(3)
		var count := 0
		for id in region.builder.manifest.ENTITIES:
			var patch: RenewalPatch = region.renewal_world.get_node_or_null("Care_"+id)
			if patch==null: continue
			count+=1
			check(region.builder.can_walk(Vector2i(floori(patch.global_position.x),floori(patch.global_position.z))),"care patch "+id+" is on walkable ground")
		check(count==region.builder.manifest.ENTITIES.size(),"every authored site receives a care opportunity")
		region.free()

func test_reedglass_exchange_stock_and_commission_follow_the_journey() -> void:
	var ford: Node3D = FORD.instantiate()
	ford.persist_progress=false
	ford.get_node("Hero").use_device_input=false
	world.add_child(ford)
	await step(4)
	ford.economy.accept_commission()
	ford.economy.scrip=18
	var data: Dictionary = JSON.parse_string(JSON.stringify(ford._journey_data("R2")))
	ford.free()
	var marsh: Node3D = MARSH.instantiate()
	marsh.persist_progress=false
	marsh.get_node("Hero").use_device_input=false
	world.add_child(marsh)
	await step(4)
	marsh._apply_journey_data(data)
	check(marsh.economy.commission_active and marsh.economy.scrip==18,"commission and money travel between settlements")
	var sela: StoryNPC
	var bryn: StoryNPC
	for npc in tree.get_nodes_in_group("story_npc"):
		if npc.get_parent()!=marsh: continue
		if npc.npc_id=="sela": sela=npc
		if npc.npc_id=="bryn": bryn=npc
	check(sela!=null and bryn!=null,"Reedglass has its own trader and steward")
	if sela==null or bryn==null: return
	check(marsh.builder.can_walk(Vector2i(floori(sela.position.x),floori(sela.position.z))) and marsh.builder.can_walk(Vector2i(floori(bryn.position.x),floori(bryn.position.z))),"both Reedglass inhabitants stand on walkable ground")
	marsh.hero.respawn_at(sela.global_position+Vector3.BACK*1.2+Vector3.UP*0.02)
	await step(4)
	var context: TouchScreenButton = marsh.get_node("TouchControls/ContextButton")
	await tap(context.position+context.texture_normal.get_size()*context.scale*0.5)
	check(marsh.story.dialogue._heading.text.contains("Sela"),"touch TALK reaches Reedglass trader")
	for i in 3:
		var button: Button = marsh.story.dialogue._buttons[0]
		await tap(marsh.story.dialogue.position+button.position+button.size*0.5)
	check(marsh.inventory.owned.has("marsh_cord_cloak") and marsh.economy.scrip==0,"Reedglass sells its distinct visible gear")
	marsh.economy.commission_sites=PackedStringArray(["B1","C1","M1"])
	check(not marsh.exchange._community_reeds.restored,"steward's beds start strained")
	marsh.exchange.handle("exchange_claim")
	check(marsh.exchange._community_reeds.restored and marsh.economy.commission_turnins==1,"commission has a visible settlement consequence")
