class_name RenewalWorld
extends Node3D
## One care site beside every authored restoration. Original sites stay healed.
var region: Node3D

func _ready() -> void:
	for id in region.builder.manifest.ENTITIES:
		var source: Dictionary = region.builder.entities[id]
		if not source.has("runtime"): continue
		var origin: Vector3 = source.runtime.global_position
		var at := _nearby_ground(origin)
		var patch := RenewalPatch.new()
		patch.name = "Care_"+id
		patch.site_id = id
		patch.profile = CareProfiles.for_site(id)
		patch.material_id = patch.profile.material
		patch.region = region
		patch.position = at
		add_child(patch)
		var moth := RiverMoth.new()
		moth.name = "Moth_"+id
		moth.site_id = id
		moth.region = region
		moth.position = at
		add_child(moth)
		if patch.profile.kind == "habitat":
			var skipper := ReedSkipper.new()
			skipper.name = "Skipper_"+id
			skipper.site_id = id
			skipper.region = region
			skipper.position = at+Vector3(0.6,0,0.45)
			add_child(skipper)

func _nearby_ground(origin: Vector3) -> Vector3:
	for offset in [Vector2(2,1),Vector2(-2,1),Vector2(2,-1),Vector2(-2,-1),Vector2(3,0),Vector2(0,3)]:
		var point: Vector2 = Vector2(origin.x,origin.z)+offset
		if region.builder.can_walk(Vector2i(floori(point.x),floori(point.y))):
			return Vector3(point.x,region.builder.surface_height(point)+0.05,point.y)
	return origin+Vector3(1,0,1)

func echo_care(source_id: String, amount: float) -> bool:
	if amount <= 0 or not region.waykeeper.effective_node("living_echo"): return false
	for relay in region.weave_relays.values():
		if not relay.linked(): continue
		var profile: Dictionary = relay.profile
		var partner_id: String = ""
		if source_id == profile.source_site: partner_id = profile.sink_site
		elif source_id == profile.sink_site: partner_id = profile.source_site
		if partner_id.is_empty() or not region.builder.entities[partner_id].get("restored",false): continue
		var state: Dictionary = region.economy.patch(partner_id)
		if state.cooldown > 0: continue
		var before: float = state.progress
		state.progress = minf(0.9,before+amount*0.5)
		if state.progress <= before: continue
		var partner: RenewalPatch = get_node("Care_"+partner_id)
		partner.progress = state.progress
		partner._sync()
		if floori(before*4)<floori(state.progress*4):
			Juice.wave(partner.global_position+Vector3.UP*0.2,1.2,Color("87cde7"),0.5)
			region.waykeeper._message("Living Echo carries care to the linked %s" % region.builder.entities[partner_id].spec.title)
		return true
	return false
