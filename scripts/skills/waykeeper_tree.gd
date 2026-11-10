class_name WaykeeperTree
extends RefCounted
## Connected river-order progression. Empty/future disciplines cannot be purchased.
const COLORS := {"Waykeeper":Color("d9bc7d"),"Mend":Color("8de3ba"),"Warden":Color("c7b5eb"),"Weaver":Color("87cde7"),"Hybrid":Color("85cddc")}
const NODES := {
 "steady_vessel":{"name":"Steady Vessel","branch":"Waykeeper","cost":1,"parents":[],"mastery":{},"effect":"+8 maximum Stability.","pos":Vector2(20,90)},
 "deep_reserve":{"name":"Deep Reserve","branch":"Waykeeper","cost":1,"parents":[],"mastery":{},"effect":"+10 maximum Flow.","pos":Vector2(150,90)},
 "spring_attunement":{"name":"Spring Attunement","branch":"Waykeeper","cost":1,"parents":["deep_reserve"],"mastery":{},"effect":"Restored springs regenerate 4 more Flow each second.","pos":Vector2(150,185)},
 "current_rider":{"name":"Current Rider","branch":"Waykeeper","cost":1,"parents":["steady_vessel"],"mastery":{},"effect":"Glide travels 25% farther when you launch beside a restored spring. Glide remains free.","pos":Vector2(20,185)},
 "restoration_return":{"name":"Restoration Return","branch":"Waykeeper","cost":1,"parents":["deep_reserve"],"mastery":{"mend":3},"effect":"Completing restoration returns 8 extra Flow.","pos":Vector2(150,280)},
 "gentle_current":{"name":"Gentle Current","branch":"Mend","cost":1,"parents":["restoration_return"],"mastery":{"mend":6},"effect":"Useful Mend costs 25% less Flow beside restored springs.","pos":Vector2(150,375)},
 "living_pulse":{"name":"Living Pulse","branch":"Mend","cost":1,"parents":[],"mastery":{"mend":3},"effect":"Completing restoration sends partial healing to nearby viable places.","pos":Vector2(280,90)},
 "resonant":{"name":"Resonance","branch":"Mend","cost":1,"parents":["living_pulse"],"mastery":{"mend":9},"effect":"Your completion wave reaches farther and carries twice as much restoration.","pos":Vector2(280,185)},
 "groundwave":{"name":"Groundwave","branch":"Warden","cost":1,"parents":[],"mastery":{"force":2},"effect":"One Force pulse clears all nearby compatible obstructions.","pos":Vector2(410,90)},
 "undertow":{"name":"Undertow","branch":"Warden","cost":1,"parents":["groundwave"],"mastery":{"force":6},"effect":"Force also grounds the foundation of a blocked spring.","pos":Vector2(410,185)},
 "shared_ground":{"name":"Shared Ground","branch":"Warden","cost":1,"parents":[],"mastery":{"anchor":2},"effect":"Anchor steadies nearby compatible systems together.","pos":Vector2(540,90)},
 "root_memory":{"name":"Root Memory","branch":"Warden","cost":1,"parents":["shared_ground"],"mastery":{"anchor":6},"effect":"Anchor also contributes partial Mend once the system is viable.","pos":Vector2(540,185)},
 "gentle_foundation":{"name":"Gentle Foundation","branch":"Hybrid","cost":2,"parents":["living_pulse","shared_ground"],"mastery":{"mend":6,"anchor":2},"effect":"Mending an Anchored system costs 25% less Flow and protects Stability during the channel. Combine Mend and Anchor.","pos":Vector2(345,300)},
 "living_conduit":{"name":"Living Conduit","branch":"Weaver","cost":1,"parents":["spring_attunement"],"mastery":{"weave":3},"effect":"Connected water renews 4 additional Flow each second while you tend either linked place.","pos":Vector2(20,475)},
 "living_echo":{"name":"Living Echo","branch":"Hybrid","cost":1,"parents":["living_pulse","living_conduit"],"mastery":{"mend":3,"weave":6},"effect":"Mend care at one linked place also restores half as much of its partner's care. The echo cannot complete care for you.","pos":Vector2(280,555)},
 "living_network":{"name":"Living Network","branch":"Hybrid","cost":1,"parents":["living_conduit"],"mastery":{"weave":6,"bloom":6},"effect":"A Bloomed willow shelter also protects the spring linked to its roots. Stability recovers faster at either end.","pos":Vector2(540,475)},
}
const LEGACY := ["living_pulse","resonant","groundwave","undertow","shared_ground","root_memory"]
