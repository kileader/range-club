extends SceneTree

var failures: int = 0
var capture: bool = false


func _initialize() -> void:
	capture = "--capture" in OS.get_cmdline_user_args()
	call_deferred("run")


func run() -> void:
	_check(ProjectSettings.get_setting("application/run/main_scene") == "res://app/startup.tscn", "project starts with the inherited splash")
	_check(not ProjectSettings.get_setting("application/boot_splash/show_image"), "engine boot image is disabled")
	_check(ProjectSettings.get_setting("application/boot_splash/bg_color") == Color.BLACK, "boot background is black")
	_check(ProjectSettings.get_setting("rendering/environment/defaults/default_clear_color") == Color.BLACK, "clear color is black")
	await _open_startup()
	var splash: Control = current_scene
	_check(splash.next_scene_path == "res://app/main.tscn", "splash opens the normal game scene")
	await create_timer(0.75).timeout
	_check(current_scene == splash, "normal startup holds the logo before entering the game")
	if capture:
		await _capture("splash-logo")
	await _wait_for_main()
	_check_game("normal startup")
	if capture:
		await _capture("splash-opening")

	var focus_key := InputEventKey.new()
	focus_key.keycode = KEY_F
	focus_key.pressed = true
	var escape_key := InputEventKey.new()
	escape_key.keycode = KEY_ESCAPE
	escape_key.pressed = true
	var left_click := InputEventMouseButton.new()
	left_click.button_index = MOUSE_BUTTON_LEFT
	left_click.position = Vector2(300, 400)
	left_click.pressed = true
	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	var gamepad := InputEventJoypadButton.new()
	gamepad.button_index = JOY_BUTTON_A
	gamepad.pressed = true
	for event: InputEvent in [focus_key, escape_key, left_click, right_click, gamepad]:
		await _open_startup()
		splash = current_scene
		InputMap.add_action(&"startup_test_press")
		InputMap.action_add_event(&"startup_test_press", event)
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		_check(splash._finished, "fresh input starts skipping")
		_check(current_scene == splash, "skip waits before loading gameplay")
		await scene_changed
		_check(not Input.is_action_just_pressed(&"startup_test_press"), "skip press is no longer just pressed when gameplay loads")
		_check_game("skip")
		var main: RunController = current_scene
		main._on_gear_requested(&"bare_rig")
		var release: InputEvent = event.duplicate()
		release.set("pressed", false)
		Input.parse_input_event(release)
		Input.flush_buffered_events()
		await physics_frame
		_check(main.shot.phase == ShotModel.Phase.IDLE and main.impacts.is_empty() and not main.focus_armed, "skip and release do not shoot or arm Focus")
		main.run_view.new_run_requested.emit()
		await create_timer(0.1).timeout
		_check(current_scene == main, "new run keeps the game scene without replaying the splash")
		_check_game("new run")
		InputMap.erase_action(&"startup_test_press")

	await _open_startup()
	splash = current_scene
	var repeat: InputEventKey = focus_key.duplicate()
	repeat.echo = true
	Input.parse_input_event(repeat)
	var drift := InputEventJoypadMotion.new()
	drift.axis_value = 0.2
	Input.parse_input_event(drift)
	Input.flush_buffered_events()
	_check(not splash._finished, "key repeats and stick drift do not skip")
	Input.parse_input_event(focus_key)
	Input.parse_input_event(left_click)
	Input.flush_buffered_events()
	await _wait_for_main()
	var main: Node = current_scene
	await create_timer(2.6).timeout
	_check(current_scene == main, "multiple skip presses cause only one transition and cancel the fade sequence")
	print("Startup checks: %d failure(s)." % failures)
	quit(0 if failures == 0 else 1)


func _open_startup() -> void:
	_check(change_scene_to_file(ProjectSettings.get_setting("application/run/main_scene")) == OK, "startup scene loads")
	await scene_changed
	await process_frame


func _wait_for_main() -> void:
	for tick: int in range(300):
		if current_scene is RunController:
			return
		await physics_frame
	_check(false, "startup reaches gameplay within five seconds")


func _check_game(context: String) -> void:
	_check(current_scene is RunController, context + " opens the game")
	if current_scene is RunController:
		var main: RunController = current_scene
		_check(main.phase == RunController.RunPhase.SELECT and not main.build_selected, context + " leaves character selection untouched")
		_check(main.total_score == 0 and main.impacts.is_empty() and main.shot.phase == ShotModel.Phase.IDLE and not main.focus_armed, context + " leaves gameplay untouched")


func _capture(label: String) -> void:
	await RenderingServer.frame_post_draw
	_check(root.get_texture().get_image().save_png("res://.tools/%s.png" % label) == OK, "save startup screenshot")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
