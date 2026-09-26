extends TestCase
## Bearer and Charger models (corrupted + restored forms) for step 2+.

## glb -> animations it must carry (empty = static)
const MODELS := {
	"res://assets/creatures/bearer.glb": ["idle", "walk", "slam", "stagger"],
	"res://assets/creatures/bearer_bridge.glb": [],
	"res://assets/creatures/charger.glb": ["idle", "aim", "fire", "stagger"],
	"res://assets/creatures/charger_turret.glb": ["idle", "fire"],
}
const LOOPING := ["idle", "walk"]

func test_creature_models_exist_with_animations() -> void:
	for path in MODELS:
		if not ResourceLoader.exists(path):
			check(false, "%s missing" % path)
			continue
		var root: Node = (load(path) as PackedScene).instantiate()
		check(root.find_children("*", "MeshInstance3D", true, false).size() >= 1, "%s has a mesh" % path)
		var anims: Array = MODELS[path]
		if not anims.is_empty():
			var ap := root.find_child("AnimationPlayer", true, false) as AnimationPlayer
			check(ap != null, "%s animated" % path)
			if ap:
				for a in anims:
					check(ap.has_animation(a), "%s has '%s'" % [path, a])
					if ap.has_animation(a):
						var looped: bool = ap.get_animation(a).loop_mode != Animation.LOOP_NONE
						check(looped == (a in LOOPING), "%s '%s' loop mode" % [path, a])
		root.free()

func test_bearer_growths_are_separate_bones() -> void:
	var root: Node = (load("res://assets/creatures/bearer.glb") as PackedScene).instantiate()
	var skel := root.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	for i in [1, 2, 3]:
		check(skel.find_bone("growth.%d" % i) != -1, "growth.%d bone exists (to knock off)" % i)
	root.free()
