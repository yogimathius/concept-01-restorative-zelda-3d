extends SceneTree
## Headless test runner:
##   Godot --headless --path . -s tests/run_all.gd [-- <name filter>]
## A test that errors after an await never completes its coroutine, so each
## test runs under a watchdog and is failed on timeout instead of hanging.

const TEST_DIR := "res://tests/unit/"
const TEST_TIMEOUT_MS := 20000

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var filter: String = args[0] if args.size() > 0 else ""
	var files := Array(DirAccess.get_files_at(TEST_DIR)).filter(
		func(f: String) -> bool: return f.begins_with("test_") and f.ends_with(".gd"))
	files.sort()
	var passed := 0
	var failed := 0
	for file in files:
		var script: GDScript = load(TEST_DIR + file)
		if script == null:
			failed += 1
			print("FAIL ", file, " (could not load script)")
			continue
		for method in script.get_script_method_list():
			var name: String = method.name
			if not name.begins_with("test_"):
				continue
			var label := "%s::%s" % [file.get_basename(), name]
			if filter != "" and not label.contains(filter):
				continue
			var tc: TestCase = script.new()
			tc.tree = self
			await tc.before_each()
			var state := {"done": false}
			var run := func() -> void:
				await tc.call(name)
				state.done = true
			run.call()
			var deadline := Time.get_ticks_msec() + TEST_TIMEOUT_MS
			while not state.done and Time.get_ticks_msec() < deadline:
				await process_frame
			if not state.done:
				tc.failures.append("timed out (script error after an await?)")
			await tc.after_each()
			if tc.failures.is_empty():
				passed += 1
				print("PASS ", label)
			else:
				failed += 1
				print("FAIL ", label)
				for f in tc.failures:
					print("    - ", f)
	print("\n%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
