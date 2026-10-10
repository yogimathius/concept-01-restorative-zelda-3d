class_name ValleyPlaces
extends RefCounted
## Prototype geography uses stable restoration IDs. Save rewards/conditions stay
## attached to places when their authored position changes.
const POSITIONS := {"B2":Vector2(35,35),"C2":Vector2(55,30),"B3":Vector2(78,-8),"C3":Vector2(65,-25)}
const LANDING := Vector2(53,35)
const BASIN := Vector2(57,35)
const SOUTH_ROUTE := [Vector2(30,6),Vector2(33,17),Vector2(35,35),Vector2(45,35),LANDING,Vector2(55,30)]
const SUNLEAF_ROUTE := [Vector2(48,-10),Vector2(65,-9),Vector2(78,-8)]
const WATER_ROUTE := [Vector2(65,-25),Vector2(61,-19),Vector2(58,-8),Vector2(56,7),Vector2(55,21),Vector2(57,35)]
const BENEFITS := {
	"B2":"Steady roots shelter the southern walking trail.",
	"C2":"Clear water returns to the reeds beside Oren's landing.",
	"B3":"The sunleaf grove recovers along the upper hillside trail.",
	"C3":"The weir feeds the landing's ceramic channel; Oren can prepare his boat again.",
}
static func point(at: Vector2) -> Vector3:
	return Vector3(at.x,RiverValley.height_at(at),at.y)
static func profile(id: String, source: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	if id=="C3":
		result.title = "Upper ford weir"
		result.reasons = {"cleared":"Stone blocks the weir's intake · Force opens it","stabilized":"The weir's foundation shifts · Anchor steadies it"}
	return result
static func conversation(region: Node3D, id: String, source: Dictionary) -> Dictionary:
	if id=="oren":
		if not region.builder.entities.C3.get("restored",false):
			return {"pages":["The landing is dry. I can still walk home, but my boat and the reed parcels are stranded. The upper ford weir feeds this branch; its intake is choked and its foundation is shifting.","Follow the ceramic channel uphill to the split crescent. Force opens the intake, Anchor holds the foundation, then Mend brings the water back. Iona teaches both traditions beside the first crossing. This branch is separate from the reservoir sluice; we aren't opening the whole upstream system."],"options":[{"text":"Remember the upper weir","action":"valley_weir"},{"text":"Explore the landing","action":"close"}]}
		return {"pages":["Hear that? Water in the landing again. I can float the boat off its cradle and sort the reed parcels. You repaired a connection between people, not just a monument.","Neri still waits in Reedglass for news of Lio. That next journey remains in the main two-chapter build while this valley takes shape. For now, the boat is ready and there is a place to rest beside the channel."],"options":[{"text":"Remember this place","action":"close"},{"text":"Open my travelling cups","action":"pack"}]}
	var result := source.duplicate(true)
	for i in result.pages.size():
		result.pages[i] = result.pages[i].replace("east landing","downstream boathouse").replace("far landing","downstream boathouse")
	if id=="iona" and region.waykeeper.progress.unlocked.has("anchor"):
		result.pages.append("The split crescent above the hill marks the upper ford weir. Its branch feeds Oren's landing. Follow the marked uphill trail, or meet him beside the southern channel to learn why it matters.")
	return result
