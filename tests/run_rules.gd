extends SceneTree

var failures: int = 0


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	_check(Scoring.ring_score(Vector2.ZERO) == 10, "center scores ten")
	_check(Scoring.ring_score(Vector2(0.1, 0.0)) == 10, "inner boundary scores ten")
	_check(Scoring.ring_score(Vector2(1.0, 0.0)) == 1, "outer edge scores one")
	_check(Scoring.ring_score(Vector2(1.001, 0.0)) == 0, "outside target misses")
	var centers: Array[Vector2] = TargetLayout.centers_at(0.0)
	_check(TargetLayout.score_at(centers[0], centers).score == 6, "safe center caps at six")
	_check(TargetLayout.score_at(centers[1], centers).score == 10, "standard center scores ten")
	_check(TargetLayout.score_at(centers[2], centers).score == 15, "bold center scores fifteen")
	_check(TargetLayout.score_at(Vector2(820, 645), centers).score == 0, "space between targets misses")
	var later: Array[Vector2] = TargetLayout.centers_at(2.0)
	_check(later[1].distance_to(centers[1]) > 20.0, "standard target moves")
	_check(is_equal_approx(later[0].x, centers[0].x) and later[0].y != centers[0].y, "safe target bobs vertically")
	_check(is_equal_approx(later[1].y, centers[1].y), "standard target slides horizontally")
	_check(later[2].x != centers[2].x and later[2].y != centers[2].y, "bold target moves diagonally")
	_check(TargetLayout.score_at(later[2], later).score == 15, "moving target scores at displayed center")
	var attached_mark := ImpactRecord.new(1, Vector2(5, -4))
	_check(attached_mark.position_at(later) == later[1] + Vector2(5, -4), "hit mark follows its target")
	var miss_mark := ImpactRecord.new(-1, Vector2(700, 600))
	_check(miss_mark.position_at(later) == Vector2(700, 600), "miss mark stays on the backstop")

	var shot: ShotModel = ShotModel.new()
	shot.start_hold(centers[1])
	shot.tick(0.2, centers[1], centers)
	_check(shot.phase == ShotModel.Phase.DRAW, "early draw is not ready")
	shot.cancel()
	_check(shot.phase == ShotModel.Phase.IDLE, "cancel clears draw")
	shot.configure(1.0, 0.0)
	shot.start_hold(centers[1])
	shot.tick(ShotModel.DRAW_READY_SECONDS, centers[1], centers)
	_check(shot.phase == ShotModel.Phase.READY, "draw becomes ready")
	shot.tick(3.0, centers[1], centers)
	_check(shot.impact_point == centers[1] and not shot.target_locked, "unassisted aim does not sway")
	shot.configure(0.7, 32.0)
	shot.start_hold(centers[1] + Vector2(20, 0))
	shot.tick(ShotModel.DRAW_READY_SECONDS, centers[1], centers)
	_check(shot.target_locked and shot.impact_point == centers[1], "gyro locks near a target")
	shot.tick(0.1, later[1], later)
	_check(shot.target_locked and shot.impact_point == later[1], "gyro tracks a moving target")
	shot.configure(1.6, 0.0)
	shot.start_hold(Vector2(820, 645))
	shot.tick(0.5, centers[2], centers)
	_check(shot.aim_point.distance_to(centers[2]) > 0.0, "fast steering still has travel time")
	_check(not shot.target_locked, "pulse sight has no target lock")

	var main: Node = load("res://app/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var view: RangeView = main.get_node("RangeView")
	view.gear_requested.emit(&"gyro_brace")
	_check(main.equipped.id == &"bare_rig", "build choice locked before first trial")
	view.primary_pressed.emit()
	view.primary_released.emit()
	_check(main.impacts.is_empty(), "early release spends no shot")
	for index: int in range(5):
		view.primary_pressed.emit()
		main.shot.tick(ShotModel.DRAW_READY_SECONDS, centers[1], centers)
		view.visible_reticle = centers[1]
		view.visible_reticle_valid = true
		view.visible_target_centers = centers
		view.primary_released.emit()
	_check(main.impacts.size() == 5 and main.total_score == 50, "five displayed center hits total fifty")
	_check(main.impacts[0].target_index == 1 and main.impacts[0].position_at(later) == later[1], "recorded center hit stays centered as target moves")
	_check(main.gear_unlocked and main.best_score == 50, "completed trial unlocks builds and saves best")
	view.primary_pressed.emit()
	_check(main.impacts.size() == 5, "sixth shot is rejected")
	view.gear_requested.emit(&"gyro_brace")
	_check(main.equipped.id == &"gyro_brace" and main.impacts.is_empty(), "gyro choice starts a fresh trial")
	view.primary_pressed.emit()
	_check(main.shot.aim_point == main.REST_POINT, "shot starts from fixed rest point")
	_check(is_equal_approx(main.shot.lock_radius, 32.0), "gyro build changes focus lock")
	view.gear_requested.emit(&"pulse_sight")
	_check(main.equipped.id == &"gyro_brace", "build cannot change during a draw")
	view.cancel_requested.emit()
	_check(main.shot.phase == ShotModel.Phase.IDLE and main.impacts.is_empty(), "cancel spends no shot")
	for index: int in range(5):
		view.primary_pressed.emit()
		main.shot.tick(ShotModel.DRAW_READY_SECONDS, centers[0], centers)
		view.visible_reticle = centers[0]
		view.visible_reticle_valid = true
		view.visible_target_centers = centers
		view.primary_released.emit()
	_check(main.total_score == 30, "five safe centers cannot clear the trial")
	view.gear_requested.emit(&"pulse_sight")
	_check(main.equipped.id == &"pulse_sight" and main.impacts.is_empty(), "pulse sight can be selected")
	view.retry_requested.emit()
	_check(main.equipped.id == &"pulse_sight" and main.impacts.is_empty(), "retry preserves build")
	view.gear_requested.emit(&"bare_rig")
	_check(main.equipped.id == &"bare_rig", "bare rig remains selectable")

	if failures == 0:
		print("All target, tracking, build, and trial assertions passed.")
	quit(1 if failures > 0 else 0)


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + description)
