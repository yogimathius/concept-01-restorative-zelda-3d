class_name CareProfiles
extends RefCounted
## Renewable care is recognizable by condition and place, not a second set of
## anonymous restoration targets. Materials preserve the existing economy.
const SITES := {
	"B1":{"title":"Grove seep","kind":"reeds","material":"reed_fiber","cue":"Bent reeds rise as water returns"},
	"C1":{"title":"Spring glass seam","kind":"glass","material":"riverglass","cue":"Clouded riverglass clears from its edge"},
	"B2":{"title":"Willow thicket","kind":"habitat","material":"reed_fiber","cue":"Tangled shelter opens for small life"},
	"C2":{"title":"Silted bank","kind":"silt","material":"silt_clay","cue":"A narrow water thread cuts through settled silt"},
	"B3":{"title":"Sunleaf stand","kind":"reeds","material":"reed_fiber","cue":"Young stems lift toward healthy light"},
	"C3":{"title":"Weir glass seam","kind":"glass","material":"riverglass","cue":"Flow polishes the old riverglass channel"},
	"M1":{"title":"Garden seed bed","kind":"reeds","material":"reed_fiber","cue":"New roots take in connected water"},
	"M2":{"title":"Nursery sprigs","kind":"reeds","material":"reed_fiber","cue":"Small reeds straighten in the reopened feed"},
	"M3":{"title":"Bell riverglass","kind":"glass","material":"riverglass","cue":"The bell's clear tone steadies the glass"},
	"M4":{"title":"Willow thicket","kind":"habitat","material":"reed_fiber","cue":"A living refuge makes room for its smallest guests"},
	"M5":{"title":"Spring glass seam","kind":"glass","material":"riverglass","cue":"Clouded edges clear in spring water"},
	"M6":{"title":"Lantern silt bank","kind":"silt","material":"silt_clay","cue":"Silt parts around the lantern roots"},
}

static func for_site(id: String) -> Dictionary:
	return SITES.get(id,{"title":"Waterway care","kind":"reeds","material":"reed_fiber","cue":"Life responds to steady care"})
