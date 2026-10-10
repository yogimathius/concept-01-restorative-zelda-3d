class_name WaykeeperDefinitions
extends RefCounted
## Registry and authored site conditions. Future disciplines share the same APIs.
const SKILLS := {
	"mend":{"flow_per_second":8.0, "name":"Mend", "verb":"Restore", "color":Color("89ebc3"), "description":"Heal a viable system. Hold to restore; unfinished healing stays. Clear its obstruction or steady its foundations when needed.", "icon":"res://assets/ui/mend-medallion.png"},
	"force":{"flow_cost":12.0, "name":"Force", "verb":"Pulse", "color":Color("ffc781"), "description":"Tap to move stone out of a waterway. The nearest obstruction guides your aim. There are no timing or positioning tests.", "icon":"res://assets/ui/force-medallion.svg"},
	"anchor":{"flow_cost":14.0, "name":"Anchor", "verb":"Ground", "color":Color("c8b5ff"), "description":"Tap to steady unstable roots and structures. Stability stays while you change techniques and Mend. It never needs a timed hold.", "icon":"res://assets/ui/anchor-medallion.svg"},
	"weave":{"flow_cost":16.0, "name":"Weave", "verb":"Link", "color":Color("87cde7"), "description":"Hold the medallion near a severed relay, drag toward its partner's broad halo, then release. A completed connection stays in the world.", "icon":"res://assets/ui/weave-medallion.svg"},
	"channel":{"flow_cost":12.0, "name":"Channel", "verb":"Carry", "color":Color("a2dffc"), "description":"Tap beside the restored bell capacitor to carry safe Charge. Tap beside an unlit ceramic receiver to give it power. The charge stays with you until delivered.", "icon":"res://assets/ui/channel-medallion.svg"},
	"bloom":{"flow_cost":18.0, "name":"Bloom", "verb":"Awaken", "color":Color("cee69a"), "description":"Tap beside a restored, reconnected living place to encourage its next season. Neri's garden grows seed; the willow refuge grows a shelter that renews Stability.", "icon":"res://assets/ui/bloom-medallion.svg"},
}
const UPGRADES := {
	"mend":[{"id":"living_pulse", "name":"Living Pulse", "mastery":3, "effect":"Completion gives nearby viable places a small Mend wave."}, {"id":"resonant", "name":"Resonance", "mastery":9, "effect":"Your wave reaches farther and restores twice as much."}],
	"force":[{"id":"groundwave", "name":"Groundwave", "mastery":2, "effect":"Pulse clears every obstruction in its connected nearby court."}, {"id":"undertow", "name":"Undertow", "mastery":6, "effect":"Clearing a spring also steadies its foundation. An alternative to Anchor."}],
	"anchor":[{"id":"shared_ground", "name":"Shared Ground", "mastery":2, "effect":"Ground steadies nearby unstable systems together."}, {"id":"root_memory", "name":"Root Memory", "mastery":6, "effect":"Ground also repairs part of a viable system."}],
}
const SITES := {
	"R1/B1":{"title":"Homecoming grove", "requirements":[], "cap":1.0},
	"R1/C1":{"title":"Stonebound spring", "requirements":["cleared"], "cap":0.45},
	"R1/B2":{"title":"Leaning willow refuge", "requirements":["stabilized"], "cap":0.55},
	"R1/C2":{"title":"Silted reed spring", "requirements":["cleared"], "cap":0.45},
	"R1/B3":{"title":"Windworn sunleaf grove", "requirements":["cleared","stabilized"], "cap":0.55},
	"R1/C3":{"title":"Fractured spillway", "requirements":["cleared","stabilized"], "cap":0.40},
	"R2/M1":{"title":"Neri's kitchen garden", "requirements":[], "cap":1.0, "optional_anchor":true},
	"R2/M2":{"title":"The stonebound reed nursery", "requirements":["cleared"], "cap":0.50, "reasons":{"cleared":"Stone chokes the feed · Force opens it"}},
	"R2/M3":{"title":"The unsteady sluice bell", "requirements":["stabilized"], "cap":0.60, "reasons":{"stabilized":"Bell foundation shifts · use Anchor"}},
	"R2/M4":{"title":"Willow refuge", "requirements":["stabilized"], "cap":0.55},
	"R2/M5":{"title":"Daro's stonebound spring", "requirements":["cleared"], "cap":0.45},
	"R2/M6":{"title":"Leaning lantern beds", "requirements":["cleared","stabilized"], "cap":0.50},
}
const REQUIREMENT_SKILLS := {"cleared":"force", "stabilized":"anchor"}
const MASTERY_LEVELS := [0,3,6,10,16,24,36]
