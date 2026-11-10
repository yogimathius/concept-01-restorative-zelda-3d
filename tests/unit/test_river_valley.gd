extends TestCase
var region: Node3D
func load_valley() -> void:
	region = load("res://scenes/levels/river_valley.tscn").instantiate()
	region.persist_progress = false
	region.get_node("Hero").use_device_input = false
	world.add_child(region)
	await step(4)

func test_valley_is_elevated_and_routes_return_to_the_existing_opening() -> void:
	await load_valley()
	await step(60)
	check(region.hero.is_on_floor() and absf(region.hero.position.y)<0.1,"hero stands on actual terrain collision")
	check(AudioServer.is_bus_mute(0),"prototyping remains silent")
	check(region.save_path=="user://river-valley-preview.json","prototype has a separate save")
	check(region.builder.grid.get_used_cells().is_empty(),"valley replaces enclosing grid courts")
	check(RiverValley.height_at(RiverValley.OVERLOOK)>6,"overlook has real elevation")
	check(RiverValley.height_at(Vector2(23.5,5.5))==0,"grove remains approachable")
	for route in [RiverValley.LOW_ROUTE,RiverValley.HIGH_ROUTE]:
		for i in range(route.size()-1):
			var start: Vector2 = route[i]
			var end: Vector2 = route[i+1]
			for j in 20:
				var at := start.lerp(end,float(j)/20)
				check(region.builder.valley.walkable(at),"route is wide and walkable")
				var next := start.lerp(end,minf(1,float(j+1)/20))
				check(absf(RiverValley.height_at(next)-RiverValley.height_at(at))/maxf(0.001,at.distance_to(next))<0.8,"route has a forgiving slope")

func test_first_restoration_changes_actual_bridge_terrain_and_keeps_rewards() -> void:
	await load_valley()
	region.hero.respawn_at(Vector3(19,0.02,5.5))
	region._update_creature_panel()
	check(region._creature_steps.text.contains("closer"),"out-of-reach target tells player how to connect")
	region.hero.respawn_at(Vector3(21,0.02,5.5))
	region._update_creature_panel()
	check(region._creature_steps.text.contains("Hold MEND"),"in-range target tells player to Mend")
	check(not region.builder.can_walk(Vector2i(25,3)),"river crossing begins severed")
	region.builder.restore("B1")
	check(region.builder.can_walk(Vector2i(25,3)),"Mend opens the real crossing")
	check(region.builder.entities.B1.has("bridge"),"visible replacement bridge remains")
	check(region.progression.xp==40,"first restoration still grants progression")
	check(region.inventory.owned.has("grove_wand"),"opening gear reward retained")
	check(not region.builder.restore("B1"),"completion cannot farm XP")
	check(region.builder.valley.chunks.size()>20,"terrain is divided into bounded chunks")

func test_camera_relative_direction_touch_ownership_and_pause() -> void:
	await load_valley()
	var rig: ValleyCamera = region.get_node("Camera3D")
	check(rig.camera.projection==Camera3D.PROJECTION_PERSPECTIVE,"active camera is perspective")
	check(rig.camera.get_parent() is SpringArm3D,"spring arm protects the render camera")
	rig.yaw = 0
	check(rig.world_input(Vector2.UP).is_equal_approx(Vector2.UP),"up follows camera forward")
	rig.yaw = -PI/2
	check(rig.world_input(Vector2.UP).is_equal_approx(Vector2.RIGHT),"orbit rotates movement into world space")
	check(rig.screen_direction(Vector2.RIGHT).is_equal_approx(Vector2.UP),"journal arrow is camera relative")
	var size := region.get_viewport().get_visible_rect().size
	check(not rig.gesture_allowed(Vector2(80,size.y-70)),"left stick cannot rotate the camera")
	check(not rig.gesture_allowed(Vector2(size.x-60,size.y-80)),"action medallions cannot rotate the camera")
	var context: TouchScreenButton = region.get_node("TouchControls/ContextButton")
	check(not rig.gesture_allowed(context.position+context.texture_normal.get_size()*context.scale*0.5),"context button cannot rotate camera")
	var start := Vector2(230,120)
	var press := InputEventScreenTouch.new()
	press.index = 9; press.position = start; press.pressed = true
	rig._input(press)
	check(rig.drag_index==9,"clear world finger begins orbit")
	var drag := InputEventScreenDrag.new()
	drag.index = 8; drag.position = start; drag.relative = Vector2(20,0)
	var before := rig.yaw
	rig._input(drag)
	check(rig.yaw==before,"other stick/action finger cannot rotate camera")
	drag.index = 9
	rig._input(drag)
	check(rig.yaw!=before,"owned world gesture rotates camera")
	region.journey_map.toggle(region.checkpoint_position)
	check(rig.drag_index==-1 and not rig.gesture_allowed(start),"menu cancels camera gesture")
	region.journey_map.toggle(region.checkpoint_position)

func test_hill_checkpoint_position_progress_and_pin_survive_json_reload() -> void:
	await load_valley()
	var at := RiverValley.OVERLOOK
	region.hero.respawn_at(Vector3(at.x,RiverValley.height_at(at)+0.02,at.y))
	region.builder.entities.B2.runtime.ecology.states.seen = true
	region.builder.entities.B2.runtime.progress = 0.43
	region.journal.pin(region,"R1/B2")
	var data: Dictionary = JSON.parse_string(JSON.stringify(region._journey_data()))
	region.hero.respawn_at(region.builder.spawn)
	region._apply_journey_data(data)
	check_near(region.hero.position.y,RiverValley.height_at(at)+0.02,0.001,"saved hill position returns above terrain")
	check(region.journal.pinned=="R1/B2","return pin survives")
	check_near(region.builder.entities.B2.runtime.progress,0.43,0.001,"partial healing survives")
	var before: String = region.save_path
	region.travel_to("R2")
	check(region.save_path==before and region.is_inside_tree(),"prototype boundary does not mix save/world layouts")

func test_hero_climbs_and_glides_on_actual_hill_collision() -> void:
	await load_valley()
	var start := Vector2(4,-12)
	region.hero.respawn_at(Vector3(start.x,RiverValley.height_at(start)+0.05,start.y))
	await step(12)
	check(region.hero.is_on_floor(),"slope collision supports the hero")
	var end := RiverValley.OVERLOOK
	region.hero.move_input = (end-start).normalized()
	var before: float = region.hero.position.y
	await step(70)
	region.hero.move_input = Vector2.ZERO
	check(region.hero.position.y>before+0.5,"movement climbs real elevation")
	check(region.hero.is_on_floor(),"floor snapping retains contact on slope")
	region.hero.request_dash()
	await step(18)
	check(region.hero.position.y>3,"Glide stays on the hill")
	check(region.hero.resources.stability>0,"forgiving slope does not cause Unmoored")

func test_spring_arm_retracts_around_actual_architecture() -> void:
	await load_valley()
	var rig: ValleyCamera = region.get_node("Camera3D")
	await step(12)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3.ONE*2
	shape.shape = box
	body.add_child(shape)
	world.add_child(body)
	body.global_position = rig.pivot.global_position+rig.arm.global_basis.z*4
	await step(10)
	check(rig.arm.get_hit_length()<4,"camera retracts before a solid wall")
	body.queue_free()
	await step(10)
	check(rig.arm.get_hit_length()>7,"camera returns after obstruction clears")

func test_valley_does_not_consume_a_pending_main_journey_save() -> void:
	var session: Node = tree.root.get_node("JourneySession")
	var previous: Dictionary = session.pending.duplicate(true)
	var previous_path: String = session.save_path
	session.pending = {"active_region":"R1","version":5,"worlds":{}}
	session.save_path = "user://restoration-journey.json"
	await load_valley()
	check(region.save_path=="user://river-valley-preview.json","pending main session cannot replace private save")
	check(not session.pending.is_empty(),"prototype leaves pending main journey intact")
	session.pending = previous
	session.save_path = previous_path
