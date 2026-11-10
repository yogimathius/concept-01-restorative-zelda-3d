class_name SettlementExchange
extends Node
## The Ford's first inhabited exchange: trade, craft and repeatable care work.
var region: Node3D
var _menu_title := ""
var _menu_role := ""
var _menu_page := ""
var _menu_choices: Array = []
var _menu_index := 0
var _community_reeds: KitPiece

func _ready() -> void:
	if region.region_id=="R1":
		_spawn("tavi","Tavi","Rivercraft trader",Vector2(8.5,6.5))
		_spawn("edda","Edda","Waterway steward",Vector2(10.5,6.5))
	else:
		_spawn("sela","Sela","Reedglass trader",Vector2(9.5,16.5))
		_spawn("bryn","Bryn","Marsh water steward",Vector2(11.5,16.5))

func _spawn(id: String, title: String, role: String, point: Vector2) -> void:
	if region.builder.valley_mode: point += Vector2(1,2)
	if not region.builder.can_walk(Vector2i(floori(point.x),floori(point.y))):
		point = Vector2(region.builder.spawn.x+2,region.builder.spawn.z+2)
	var npc := StoryNPC.new()
	npc.npc_id = id
	npc.display_name = title
	npc.role = role
	npc.hero = region.hero
	npc.position = Vector3(point.x,region.builder.surface_height(point),point.y)
	npc.surface_height = region.builder.surface_height
	region.add_child(npc)
	var stand := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.43
	mesh.bottom_radius = 0.50
	mesh.height = 0.5
	stand.mesh = mesh
	stand.position = npc.position + Vector3(1.25,0.25,0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("a78560") if id in ["tavi","sela"] else Color("5e8991")
	stand.material_override = mat
	var rim := MeshInstance3D.new()
	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = 0.39
	rim_mesh.outer_radius = 0.48
	rim.mesh = rim_mesh
	rim.position.y = 0.26
	var bronze := StandardMaterial3D.new()
	bronze.albedo_color = Color("bca16b")
	bronze.metallic = 0.65
	rim.material_override = bronze
	stand.add_child(rim)
	GearVisuals._gem(stand,Vector3(-0.15,0.33,0),0.075,Color("a7ede3"),0.65)
	GearVisuals._gem(stand,Vector3(0.17,0.33,0.08),0.055,Color("d8eeab"),0.45)
	var plaque := Label3D.new()
	plaque.text = "EXCHANGE" if id in ["tavi","sela"] else "CARE"
	plaque.position.y = 0.8
	plaque.font_size = 23
	plaque.pixel_size = 0.008
	plaque.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	plaque.modulate = Color("f1deb2")
	stand.add_child(plaque)
	region.add_child(stand)
	if id in ["edda","bryn"]:
		_community_reeds = KitPiece.new()
		_community_reeds.family = "reed"
		_community_reeds.shape = "reed"
		_community_reeds.restored = region.economy.commission_turnins>0
		_community_reeds.position = npc.position+Vector3(-1.35,0,0.7)
		_community_reeds.scale = Vector3.ONE*0.85
		region.add_child(_community_reeds)

func handles(id: String) -> bool:
	return id in ["tavi","edda","sela","bryn"]

func talk(id: String) -> void:
	if id in ["tavi","sela"]: _exchange()
	else: _commission()

func _merchant_name() -> String:
	return "Tavi" if region.region_id=="R1" else "Sela"

func _steward_name() -> String:
	return "Edda" if region.region_id=="R1" else "Bryn"

func handle(action: String) -> bool:
	if not action.begins_with("exchange_"): return false
	match action:
		"exchange_menu": _exchange()
		"exchange_buy": _buy()
		"exchange_sell": _sell()
		"exchange_craft": _craft_menu()
		"exchange_herb": _recipes("herbcraft")
		"exchange_river": _recipes("rivercraft")
		"exchange_gem": _recipes("gemcutting")
		"exchange_gearcraft": _gearcraft()
		"exchange_trade": _trade()
		"exchange_more": _show_menu_page()
		"exchange_commission": _care_commission()
		"exchange_accept":
			region.economy.accept_commission()
			_care_commission()
		"exchange_claim":
			var before: int = region.progression.get_level()
			var claimed: bool = region.economy.claim_commission(region.progression)
			if claimed and is_instance_valid(_community_reeds): _community_reeds.set_restored(true,true)
			region._on_economy_changed(before)
			_care_commission()
		"exchange_learn_channel":
			if region.waykeeper.learn("channel"):
				region.story_flags.bryn_channel_started = true
				region.story._open("Bryn","CHANNEL LESSON",["The restored bell can lend a safe measure of Charge. Tap Channel beside its ceramic capacitor to carry it. A bright globe follows you; there is no hurry.","Tap Channel again beside the dark lantern beds or the exchange lamp. Each receiver keeps the Charge once it is delivered. The beds must be restored first."],[{"text":"I will carry the bell's Charge","action":"close"},{"text":"Study Channel","action":"skills"}])
		"exchange_channel_reward":
			if region.region_id=="R2" and region.charge_circuit.completed("lantern_beds") and region.charge_circuit.completed("exchange_lamp") and not region.story_flags.has("bryn_channel_reward"):
				region.story_flags.bryn_channel_reward = true
				var before_level: int = region.progression.get_level()
				region.economy.scrip += 8
				region.economy.materials.riverglass += 2
				region.progression.award_activity(20)
				region._on_economy_changed(before_level)
				region.story._open("Bryn","TWO PLACES AWAKE",["The lantern reeds shine again, and Sela can work beside a steady exchange lamp. They needed Charge carried between people, not a stronger bell.","Take eight river scrip and two riverglass pieces. The work earned you 20 Waykeeper XP."],[{"text":"See the shared care commission","action":"exchange_commission"},{"text":"Return to the marsh","action":"close"}])
		_:
			if action.begins_with("exchange_buy_"):
				region.economy.buy_gear(action.trim_prefix("exchange_buy_"),region.inventory)
				region._update_gear_hud()
				_buy()
			elif action.begins_with("exchange_sell_material_"):
				region.economy.sell_material(action.trim_prefix("exchange_sell_material_"))
				_sell()
			elif action.begins_with("exchange_sell_gear_"):
				region.economy.sell_gear(action.trim_prefix("exchange_sell_gear_"),region.inventory)
				region._update_gear_hud()
				_sell()
			elif action.begins_with("exchange_make_"):
				var id := action.trim_prefix("exchange_make_")
				region.economy.craft(id,region.inventory,region.progression.get_level())
				region._update_gear_hud()
				_recipes(RestorationEconomy.RECIPES[id].discipline)
	region._save_journey()
	return true

func _open(title: String, role: String, page: String, options: Array) -> void:
	if options.size()<=2:
		region.story._open(title,role,[page],options)
		return
	_menu_title=title
	_menu_role=role
	_menu_page=page
	_menu_choices=options
	_menu_index=0
	_show_menu_page()

func _show_menu_page() -> void:
	if _menu_choices.is_empty(): return
	var entry: Dictionary = _menu_choices[_menu_index]
	_menu_index=(_menu_index+1)%_menu_choices.size()
	region.story._open(_menu_title,_menu_role,[_menu_page+"\nOption %d / %d" % [_menu_index if _menu_index>0 else _menu_choices.size(),_menu_choices.size()]],[entry,{"text":"See another option","action":"exchange_more"}])

func _exchange() -> void:
	var page := "The waterway pays scrip for tending its channels. Bring materials here, or shape them into equipment. You have %d scrip." % region.economy.scrip
	if region.region_id=="R2" and region.story_flags.has("exchange_powered"): page += " Bryn carried the bell's Charge here; this lamp lets me work the glass after sunset."
	_open(_merchant_name(),"FORD EXCHANGE" if region.region_id=="R1" else "REEDGLASS EXCHANGE",page,[{"text":"Buy or sell","action":"exchange_trade"},{"text":"Craft","action":"exchange_craft"}])

func _trade() -> void:
	_open(_merchant_name(),"EXCHANGE","Scrip: %d. Equipped pieces and starter keepsakes stay with you." % region.economy.scrip,[{"text":"Buy gear","action":"exchange_buy"},{"text":"Sell surplus","action":"exchange_sell"}])

func _buy() -> void:
	var choices := []
	var stock := ["market_reed_cloak"] if region.region_id=="R1" else ["marsh_cord_cloak"]
	for id in region.inventory.sold:
		if id not in stock: stock.append(id)
	for id in stock:
		if region.inventory.owned.has(id): continue
		var price := 14 if id=="market_reed_cloak" else 18 if id=="marsh_cord_cloak" else maxi(12,int(RestorationInventory.ITEMS[id].tier)*10)
		choices.append({"text":"%s · %d scrip" % [RestorationInventory.ITEMS[id].name,price],"action":"exchange_buy_"+id,"disabled":region.economy.scrip<price})
	_open(_merchant_name(),"BUY GEAR","You have %d scrip. Bought gear can be equipped in GEAR and visibly replaces what you wore." % region.economy.scrip,choices)

func _sell() -> void:
	var choices := []
	for id in RestorationEconomy.MATERIALS:
		if region.economy.materials[id]>0:
			choices.append({"text":"Sell 1 %s · +%d scrip (%d held)" % [id.replace("_"," "),4 if id=="polished_gem" else 2,region.economy.materials[id]],"action":"exchange_sell_material_"+id})
	for id in region.inventory.owned:
		if id in RestorationInventory.STARTERS.values() or id in region.inventory.equipped.values(): continue
		choices.append({"text":"Sell %s · +%d" % [RestorationInventory.ITEMS[id].name,maxi(6,int(RestorationInventory.ITEMS[id].tier)*5)],"action":"exchange_sell_gear_"+id})
	_open(_merchant_name(),"SELL SURPLUS","Equipped gear and starter keepsakes stay with you. Sold gear appears in buyback. Scrip: %d." % region.economy.scrip,choices)

func _craft_menu() -> void:
	_open(_merchant_name(),"MAKE SOMETHING","Practice builds separate craft ranks. Waykeeper level opens advanced work. Herbcraft %d · Rivercraft %d · Gemcutting %d." % [region.economy.rank("herbcraft"),region.economy.rank("rivercraft"),region.economy.rank("gemcutting")],[{"text":"Herbcraft · cups","action":"exchange_herb"},{"text":"Gear and gemstones","action":"exchange_gearcraft"}])

func _gearcraft() -> void:
	_open(_merchant_name(),"WORKBENCH","Reedweave clothing and polished riverglass require gathered materials and Waykeeper levels.",[{"text":"Rivercraft · clothing","action":"exchange_river"},{"text":"Gemcutting · lens","action":"exchange_gem"}])

func _recipes(discipline: String) -> void:
	var choices := []
	for id in RestorationEconomy.RECIPES:
		var recipe: Dictionary = RestorationEconomy.RECIPES[id]
		if recipe.discipline != discipline: continue
		choices.append({"text":"%s · L%d / rank %d" % [recipe.name,recipe.level,recipe.rank],"action":"exchange_make_"+id,"disabled":not region.economy.can_craft(id,region.inventory,region.progression.get_level())})
	var details := []
	for id in RestorationEconomy.RECIPES:
		var recipe: Dictionary = RestorationEconomy.RECIPES[id]
		if recipe.discipline != discipline: continue
		var costs := []
		for mat in recipe.materials: costs.append("%d %s" % [recipe.materials[mat],mat.replace("_"," ")])
		if id=="bloom_tea": costs.append("3 seeds")
		if id=="reed_cordial": costs.append("2 crystals")
		if recipe.get("scrip",0)>0: costs.append("%d scrip" % recipe.scrip)
		details.append("%s: %s" % [recipe.name,", ".join(costs)])
	_open(_merchant_name(),discipline.to_upper(),"Materials: %d reed fiber · %d silt clay · %d riverglass · %d polished gems.\n%s" % [region.economy.materials.reed_fiber,region.economy.materials.silt_clay,region.economy.materials.riverglass,region.economy.materials.polished_gem,"\n".join(details)],choices)

func _commission() -> void:
	if region.region_id=="R2" and region.builder.entities.M3.get("restored",false) and region.builder.entities.M6.get("restored",false):
		if not region.waykeeper.progress.unlocked.has("channel"):
			_open("Bryn","MARSH WATER STEWARD","The bell sings again, but its Charge has nowhere to go. Those restored lantern beds are still dark. I can teach you to carry a safe measure from its capacitor to the beds and our exchange lamp.",[ {"text":"Learn Channel · Carry","action":"exchange_learn_channel"},{"text":"Ask about care work","action":"exchange_commission"} ])
			return
		if region.charge_circuit.completed("lantern_beds") and region.charge_circuit.completed("exchange_lamp") and not region.story_flags.has("bryn_channel_reward"):
			_open("Bryn","TWO PLACES AWAKE","The beds and exchange lamp carry the bell's Charge. I saw both change after your journey. Come closer; the community has something for you.",[ {"text":"Share what changed","action":"exchange_channel_reward"},{"text":"Ask about care work","action":"exchange_commission"} ])
			return
		if not region.charge_circuit.completed("lantern_beds") or not region.charge_circuit.completed("exchange_lamp"):
			var next := "the lantern beds" if not region.charge_circuit.completed("lantern_beds") else "our exchange lamp"
			_open("Bryn","CARRYING THE CURRENT","Tap Channel beside the restored bell capacitor, then tap again beside %s. The Charge waits safely while you walk. %d of 2 receivers lit." % [next,2-region.charge_circuit.remaining()],[ {"text":"Ask about care work","action":"exchange_commission"},{"text":"Return to the marsh","action":"close"} ])
			return
	_care_commission()

func _care_commission() -> void:
	var count: int = region.economy.commission_sites.size()
	var active: bool = region.economy.commission_active
	var message := "Tend three different care patches along the restored waterway. Return to either steward for 8 scrip and 15 XP." if active else "Our two settlements share this work. Tend three different restored places; return to either market for payment."
	if region.economy.commission_turnins>0: message = "The community reeds are growing again because you tended the channels. New strain still appears in other places. " + message
	if region.region_id=="R2" and region.story_flags.has("bryn_channel_reward"): message = "The lantern beds and exchange lamp are steady now. " + message
	_open(_steward_name(),"WATERWAY COMMISSION",message+"\nProgress: %d / 3 · Scrip: %d" % [count,region.economy.scrip],[{"text":"Claim completed commission","action":"exchange_claim","disabled":not active or count<3},{"text":"Accept care commission","action":"exchange_accept","disabled":active}])
