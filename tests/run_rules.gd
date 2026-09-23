extends SceneTree

var failures: int = 0


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	_check(Scoring.ring_score(Vector2.ZERO) == 10, "center scores 10")
	_check(Scoring.ring_score(Vector2(0.1, 0.0)) == 10, "inner ring boundary scores 10")
	_check(Scoring.ring_score(Vector2(0.1001, 0.0)) == 9, "outside inner ring scores 9")
	_check(Scoring.ring_score(Vector2(1.0, 0.0)) == 1, "outer edge scores 1")
	_check(Scoring.ring_score(Vector2(1.001, 0.0)) == 0, "outside target misses")
	_check(TargetLayout.score_at(TargetLayout.CENTERS[0]).score == 6, "safe center caps at six")
	_check(TargetLayout.score_at(TargetLayout.CENTERS[1]).score == 10, "standard center scores ten")
	_check(TargetLayout.score_at(TargetLayout.CENTERS[2]).score == 15, "bold center scores fifteen")
	_check(TargetLayout.score_at(Vector2(820, 645)).score == 0, "space between targets misses")

	var shot: ShotModel = ShotModel.new()
	shot.start_hold(Vector2(820, 416))
	shot.tick(0.2, Vector2(820, 416))
	_check(shot.phase == ShotModel.Phase.HOLD_DRAW, "hold draw is not ready early")
	shot.cancel()
	_check(shot.phase == ShotModel.Phase.IDLE, "early draw cancels")
	shot.start_hold(Vector2(820, 416))
	shot.tick(ShotModel.DRAW_READY_SECONDS, Vector2(820, 416))
	_check(shot.phase == ShotModel.Phase.HOLD_READY, "hold draw becomes ready")
	shot.start_timing(Vector2(820, 416))
	shot.lock_draw(ShotModel.IDEAL_DRAW)
	_check(shot.phase == ShotModel.Phase.TIMING_RELEASE, "timing draw locks")
	_check(is_equal_approx(shot.impact_point.y, 416.0), "ideal draw has no vertical offset")
	shot.tick(ShotModel.TIMING_SWEEP_SECONDS / 4.0, Vector2.ZERO)
	_check(shot.impact_point.x > 880.0, "timed sweep moves impact horizontally")
	shot.configure(0.7, 0.55)
	_check(is_equal_approx(shot.steering_scale, 0.7) and is_equal_approx(shot.sway_scale, 0.55), "equipment changes steering and sway")

	var main: Node = load("res://app/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var view: RangeView = main.get_node("RangeView")
	view.gear_requested.emit(&"gyro_brace")
	_check(main.equipped.id == &"bare_rig", "gear is locked before first trial")
	view.mode_requested.emit(RangeView.ShotMode.TIMING)
	for arrow: int in range(5):
		view.primary_pressed.emit()
		_check(main.shot.phase == ShotModel.Phase.TIMING_DRAW, "timing arrow %d starts" % arrow)
		view.visible_draw_level = ShotModel.IDEAL_DRAW
		view.visible_draw_valid = true
		view.primary_pressed.emit()
		_check(main.shot.phase == ShotModel.Phase.TIMING_RELEASE, "timing arrow %d locks" % arrow)
		view.visible_reticle = RangeView.TARGET_CENTER
		view.visible_reticle_valid = true
		view.primary_pressed.emit()
	_check(main.impacts.size() == 5, "exactly five arrows accepted")
	_check(main.total_score == 50, "five center hits total 50")
	_check(main.gear_unlocked, "first completed trial unlocks gear")
	view.primary_pressed.emit()
	_check(main.impacts.size() == 5, "complete round rejects a sixth arrow")
	view.gear_requested.emit(&"gyro_brace")
	_check(main.equipped.id == &"gyro_brace", "brace selection equips gear")
	_check(main.impacts.is_empty() and main.total_score == 0, "gear selection starts a fresh trial")
	_check(main.shot.phase == ShotModel.Phase.IDLE, "gear selection clears shot state")
	view.mode_requested.emit(RangeView.ShotMode.HOLD)
	view.primary_pressed.emit()
	view.primary_released.emit()
	_check(main.impacts.is_empty(), "early hold release spends no arrow")
	view.primary_pressed.emit()
	_check(main.shot.aim_point == main.REST_POINT, "hold starts from a fixed rest point")
	_check(is_equal_approx(main.shot.sway_scale, 0.55), "equipped brace changes active shot")
	view.cancel_requested.emit()
	_check(main.shot.phase == ShotModel.Phase.IDLE and main.impacts.is_empty(), "cancel spends no arrow")
	view.primary_pressed.emit()
	main.shot.tick(ShotModel.DRAW_READY_SECONDS, RangeView.TARGET_CENTER)
	view.visible_reticle = RangeView.TARGET_CENTER
	view.visible_reticle_valid = true
	view.primary_released.emit()
	_check(main.impacts.size() == 1 and main.total_score == 10, "ready hold release accepts one displayed hit")
	view.gear_requested.emit(&"pulse_sight")
	_check(main.equipped.id == &"gyro_brace", "gear cannot change during a trial")
	view.retry_requested.emit()
	_check(main.impacts.is_empty() and main.total_score == 0, "retry clears arrows and score")
	_check(main.equipped.id == &"gyro_brace", "retry preserves current gear")
	for arrow: int in range(5):
		view.primary_pressed.emit()
		main.shot.tick(ShotModel.DRAW_READY_SECONDS, RangeView.TARGET_CENTER)
		view.visible_reticle = TargetLayout.CENTERS[0]
		view.visible_reticle_valid = true
		view.primary_released.emit()
	_check(main.total_score == 30, "five safe centers cannot clear the trial")
	view.gear_requested.emit(&"bare_rig")
	_check(main.equipped.id == &"bare_rig" and main.impacts.is_empty(), "bare rig remains a valid build")
	view.primary_pressed.emit()
	view.gear_requested.emit(&"pulse_sight")
	_check(main.equipped.id == &"bare_rig", "gear cannot change during a fresh draw")
	view.cancel_requested.emit()

	if failures == 0:
		print("All scoring, shot, and round assertions passed.")
	quit(1 if failures > 0 else 0)


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
