class_name ValleyJourney
extends Node
## Spatial guidance and inhabited consequences derive from existing site state.
## No duplicate quest reward or NPC-position save ledger.
var region: Node3D
var _wet := false
var _synced := false
func _ready() -> void:
	name = "ValleyJourney"
	region.builder.restored.connect(func(id):
		sync(not region.builder._replaying)
		if id=="C3" and not region.builder._replaying and region.hero.global_position.distance_to(region.builder.entities.C3.runtime.global_position)<8:
			region.get_node("Camera3D").frame_restoration(region.builder.entities.C3.runtime.global_position))
	sync(false)
func sync(animate: bool) -> void:
	var wet: bool = region.builder.entities.C3.get("restored",false)
	if _synced and wet==_wet and animate: return
	_synced = true
	_wet = wet
	region.builder.valley.banks.sync(wet,animate)
	for npc in get_tree().get_nodes_in_group("story_npc"):
		if npc.get_parent()!=region or npc.npc_id!="oren": continue
		var destination := ValleyPlaces.point(ValleyPlaces.BASIN+Vector2(-1,0)) if wet else ValleyPlaces.point(ValleyPlaces.LANDING)
		npc.work_at(destination,[ValleyPlaces.point(Vector2(54,37)),ValleyPlaces.point(Vector2(56,37))] if wet and animate else [])
		if not animate: npc.global_position = destination
func handle_story(action: String) -> bool:
	if action!="valley_weir": return false
	var target = region.builder.entities.C3.runtime
	target.ecology.states.seen = true
	region.journal.pin(region,"R1/C3")
	region.story.dialogue.dismiss()
	region._save_journey()
	return true
func update_guidance() -> void:
	var entities: Dictionary = region.builder.entities
	if not entities.B1.get("restored",false): return
	if not region.waykeeper.progress.unlocked.has("force"):
		region._guidance.text = "The grove remembers · meet Iona"
		region._context.text = "Cross the broad bridge. Iona teaches beside the river marker; Force can free the next spring."
	elif not entities.C1.get("restored",false):
		region._guidance.text = "Give the stonebound spring room to breathe"
		region._context.text = "The spring is beside Iona's gauging station. Force moves the stone; switch to Mend to return its water."
	elif not region.waykeeper.progress.unlocked.has("anchor"):
		region._guidance.text = "Water for home · return to Iona"
		region._context.text = "Mara's basin is filling. Return home, or ask Iona to teach Anchor before exploring the upper weir and southern willows."
	elif not entities.C3.get("restored",false):
		region._guidance.text = "Reconnect the landing · upper ford weir"
		var at: Vector3 = entities.C3.runtime.global_position
		var distance: float = region.hero.global_position.distance_to(at)
		region._context.text = "Follow the uphill trail to the split crescent · %.0f m. Force clears its intake, Anchor steadies it, then Mend. Oren waits at the downstream boathouse." % distance
	else:
		region._guidance.text = "The weir answers · return downstream"
		region._context.text = "Follow the flowing ceramic channel to Oren's landing. His boat and the planted basin now use the water you restored. Optional groves await along the trails."
	if region.hero.restore_verb and not region.hero.restore_verb.feedback.is_empty(): region._context.text = region.hero.restore_verb.feedback
