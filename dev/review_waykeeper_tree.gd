extends SceneTree
var region: Node3D
var failures := 0
func _init(): call_deferred("run")
func frames(n := 6):
	for i in n: await physics_frame
func check(v: bool, label: String):
	print("PASS " if v else "FAIL ",label)
	if not v: failures+=1
func touch(at: Vector2, down: bool):
	var e := InputEventScreenTouch.new()
	e.index=3
	e.pressed=down
	e.position=root.get_final_transform()*at
	root.push_input(e,false)
	await frames(2)
func control(button: Control):
	var at: Vector2 = button.get_global_transform_with_canvas()*(button.size*0.5)
	await touch(at,true)
	await touch(at,false)
func snap(file: String):
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://builds/playtest/rpg-foundation/"+file+".png")
func run():
	DirAccess.make_dir_recursive_absolute("res://builds/playtest/rpg-foundation")
	region = load("res://scenes/levels/region1.tscn").instantiate()
	region.persist_progress=false
	root.add_child(region)
	current_scene=region
	region.hero.use_device_input=false
	await frames()
	region.builder.restore("B1")
	await control(region.get_node("JourneyHUD/SkillsButton"))
	var screen: Control = region.waykeeper.screen
	check(screen.visible and paused,"touch opens connected tree")
	await control(screen._tree_buttons.living_pulse)
	await control(screen._buy)
	check(region.waykeeper.progress.upgrades.has("living_pulse") and region.waykeeper.progress.skill_points()==1,"actual touch purchases Living Pulse with one point")
	await snap("tree-first-choice")
	var at: Vector2 = screen.position+screen._scroll.position+Vector2(220,95)
	await touch(at,true)
	for i in 6:
		var e := InputEventScreenDrag.new()
		e.index=3
		e.relative=Vector2(-25,0)
		e.position=root.get_final_transform()*(at+Vector2(-25*(i+1),0))
		root.push_input(e,false)
		await frames(2)
	await touch(at+Vector2(-150,0),false)
	check(screen._scroll.scroll_horizontal>190,"touch drags the watershed horizontally")
	await snap("tree-panned")
	screen._scroll.scroll_horizontal=330
	await frames()
	await control(screen._tree_buttons.shared_ground)
	check(screen.selected_node=="shared_ground" and screen._buy.disabled,"locked nodes remain inspectable with clear teaching prerequisite")
	await snap("tree-locked-warden")
	await control(screen._tech_tab)
	await control(screen._skills.force)
	await snap("tree-technique-loadout")
	check(screen._select.disabled,"tree cannot equip an unknown technique")
	await control(screen._tree_tab)
	screen._scroll.scroll_horizontal=0
	await frames()
	await control(screen._tree_buttons.deep_reserve)
	await control(screen._buy)
	check(region.hero.resources.max_flow==110 and region.waykeeper.progress.skill_points()==0,"touch stat choice affects resources and spends final point")
	await snap("tree-resource-choice")
	await frames()
	print("Native tree UI failures: ",failures)
	paused=false
	quit(1 if failures else 0)
