class_name Region1Manifest
extends RefCounted
## Region 1 entities from world design §4–5. Coordinates are the designer's
## 1-based (column, row) within each area.

const ENTITIES := {
	"B1": {"kind": "bearer", "area": "R1-S2", "at": Vector2i(8, 6), "socket": Vector2i(8, 4),
		"bridge_dir": Vector2i(1, 0), "bridge_len": 3, "pool": "F1", "ripple": 4, "wakes": "A1"},
	"C1": {"kind": "charger", "area": "R1-S3", "at": Vector2i(5, 7), "conduit": "K1", "pool": "F2", "ripple": 4},
	"C2": {"kind": "charger", "area": "R1-S4", "at": Vector2i(10, 4), "pool": "F3", "ripple": 3},
	"B2": {"kind": "bearer", "area": "R1-S4", "at": Vector2i(7, 9), "socket": Vector2i(10, 10),
		"bridge_dir": Vector2i(0, -1), "bridge_len": 3, "ripple": 3},
	"B3": {"kind": "bearer", "area": "R1-S5", "at": Vector2i(5, 8), "socket": Vector2i(5, 9),
		"bridge_dir": Vector2i(0, 1), "bridge_len": 1, "pool": "F4", "ripple": 3},
	"C3": {"kind": "charger", "area": "R1-S5", "at": Vector2i(11, 4), "conduit": "K2", "pool": "F5", "ripple": 4},
}
const CONDUITS := {
	"K1": {"area": "R1-S3", "at": Vector2i(11, 7), "gate": "G1"},
	"K2": {"area": "R1-S5", "at": Vector2i(13, 6), "gate": "G2"},
}
const GATES := {
	"G1": {"area": "R1-S3", "cells": [Vector2i(8, 9), Vector2i(9, 9)]},
	"G2": {"area": "R1-S5", "cells": [Vector2i(15, 5), Vector2i(15, 6), Vector2i(15, 7)]},
}
## pool id -> [area, first corner (col,row), size]
const POOLS := {
	"F1": ["R1-S2", Vector2i(2, 9), Vector2i(2, 2)],
	"F2": ["R1-S3", Vector2i(14, 3), Vector2i(2, 2)],
	"F3": ["R1-S4", Vector2i(14, 4), Vector2i(2, 2)],
	"F4": ["R1-S5", Vector2i(2, 8), Vector2i(2, 2)],
	"F5": ["R1-S5", Vector2i(12, 10), Vector2i(2, 2)],
}
## landmark per area L cell: [kit family/shape, starts restored]
const LANDMARKS := {
	"R1-S1": ["river_marker", true],
	"R1-S3": ["river_marker", false],   # A1: wakes when B1 is restored
	"R1-S4": ["reed", true],
	"R1-S5": ["river_marker", false],
}
const ANCHOR_AREA := {"A1": "R1-S3"}
const RESTORE_ORDER := ["B1", "C1", "C3", "B2", "C2", "B3"]
