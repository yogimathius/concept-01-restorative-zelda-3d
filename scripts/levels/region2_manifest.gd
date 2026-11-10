class_name Region2Manifest
extends RefCounted
const ENTITIES := {
	"M1": {"kind":"bearer", "area":"R2-S1", "at":Vector2i(11,7), "visual":"reed", "title":"Neri's kitchen garden", "ripple":4},
	"M2": {"kind":"bearer", "area":"R2-S2", "at":Vector2i(6,7), "visual":"reed", "title":"The reed nursery", "ripple":4},
	"M3": {"kind":"charger", "area":"R2-S4", "at":Vector2i(11,7), "title":"The silent sluice bell", "ripple":4},
	"M4": {"kind":"bearer", "area":"R2-S3", "at":Vector2i(10,5), "title":"The willow refuge", "ripple":4},
	"M5": {"kind":"charger", "area":"R2-S3", "at":Vector2i(5,9), "title":"Daro's clouded spring", "pool":"F1", "ripple":4},
	"M6": {"kind":"bearer", "area":"R2-S4", "at":Vector2i(5,10), "visual":"reed", "title":"The lantern beds", "ripple":4},
}
const CONDUITS := {}
const GATES := {}
const POOLS := {"F1":["R2-S3",Vector2i(2,8),Vector2i(2,2)]}
const LANDMARKS := {"R2-S1":["river_marker",true], "R2-S2":["spillway_ring",false], "R2-S3":["tree",false], "R2-S4":["river_marker",false]}
const ANCHOR_AREA := {}
const RESTORE_ORDER := ["M1","M2","M3","M4","M5","M6"]
