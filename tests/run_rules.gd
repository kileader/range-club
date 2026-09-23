extends SceneTree

var failures: int = 0


func _initialize() -> void:
	call_deferred("run")


func run() -> void:
	_check(not TrialRules.is_trial_over(47, 4), "below the window leaves a shot available")
	_check(TrialRules.is_cleared(48) and TrialRules.is_trial_over(48, 4), "lower window edge clears early")
	_check(TrialRules.is_cleared(52) and TrialRules.is_trial_over(52, 4), "upper window edge clears early")
	_check(TrialRules.is_bust(53) and TrialRules.is_trial_over(53, 4), "one point over the cap busts immediately")
	_check(TrialRules.is_trial_over(47, 5) and not TrialRules.is_cleared(47), "fifth shot below the window fails")
	_check(Scoring.ring_score(Vector2.ZERO) == 10, "center scores ten")
	_check(Scoring.ring_score(Vector2(0.1, 0.0)) == 10, "inner boundary scores ten")
	_check(Scoring.ring_score(Vector2(1.0, 0.0)) == 1, "outer edge scores one")
	_check(Scoring.ring_score(Vector2(1.001, 0.0)) == 0, "outside target misses")
	var centers: Array[Vector2] = TargetLayout.centers_at(0.0)
	_check(TargetLayout.score_at(centers[0], centers).score == 6, "safe center caps at six")
	_check(TargetLayout.score_at(centers[1], centers).score == 10, "standard center scores ten")
	_check(TargetLayout.score_at(centers[2], centers).score == 15, "bold center scores fifteen")
	_check(TargetLayout.score_at(centers[2] + Vector2(25, 0), centers).score == 0, "outside the smaller Bold target misses")
	_check(TargetLayout.score_at(Vector2(820, 645), centers).score == 0, "space between targets misses")
	var later: Array[Vector2] = TargetLayout.centers_at(2.0)
	_check(later[1].distance_to(centers[1]) > 20.0, "standard target moves")
	_check(is_equal_approx(later[0].x, centers[0].x) and later[0].y != centers[0].y, "safe target bobs vertically")
	_check(is_equal_approx(later[1].y, centers[1].y), "standard target slides horizontally")
	_check(later[2].x != centers[2].x and later[2].y != centers[2].y, "bold target moves diagonally")
	_check(TargetLayout.score_at(later[2], later).score == 15, "moving target scores at displayed center")
	var safe_center: Dictionary = TargetLayout.score_at(centers[0], centers)
	var standard_center: Dictionary = TargetLayout.score_at(centers[1], centers)
	var bold_center: Dictionary = TargetLayout.score_at(centers[2], centers)
	var miss: Dictionary = TargetLayout.score_at(Vector2(820, 645), centers)
	_check(TrialRules.resolve_hit(safe_center, &"bare_rig", false, 0.6).focus_gain == 1, "safe inner hit restores Focus")
	_check(TrialRules.resolve_hit(TargetLayout.score_at(centers[0] + Vector2(75, 0), centers), &"bare_rig", false, 0.6).focus_gain == 0, "safe outer hit grants no Focus")
	_check(TrialRules.resolve_hit(standard_center, &"bare_rig", false, 0.7).points == 12, "Natural earns unfocused center bonus")
	_check(TrialRules.resolve_hit(bold_center, &"bare_rig", true, 0.7).points == 15, "Focus suppresses Natural precision bonus")
	_check(TrialRules.resolve_hit(safe_center, &"bare_rig", false, 0.7).points == 6, "Natural bonus excludes Safe")
	_check(TrialRules.resolve_hit(standard_center, &"gyro_brace", false, 0.7).points == 10, "Maera has no passive score bonus")
	_check(TrialRules.resolve_hit(bold_center, &"pulse_sight", false, 1.2).points == 18, "Vey earns quick inner bonus at deadline")
	_check(TrialRules.resolve_hit(bold_center, &"pulse_sight", false, 1.21).points == 15, "Vey loses bonus after deadline")
	_check(TrialRules.resolve_hit(TargetLayout.score_at(centers[1] + Vector2(32, 0), centers), &"pulse_sight", false, 0.7).points < 11, "Vey bonus requires inner ring")
	_check(TrialRules.resolve_hit(miss, &"pulse_sight", false, 0.7).points == 0, "miss has no bonus")
	var attached_mark := ImpactRecord.new(1, Vector2(5, -4))
	_check(attached_mark.position_at(later) == later[1] + Vector2(5, -4), "hit mark follows its target")
	var miss_mark := ImpactRecord.new(-1, Vector2(700, 600))
	_check(miss_mark.position_at(later) == Vector2(700, 600), "miss mark stays on the backstop")

	var shot: ShotModel = ShotModel.new()
	shot.start_hold(centers[1])
	shot.tick(0.2, centers[1])
	_check(shot.phase == ShotModel.Phase.DRAW, "early draw is not ready")
	_check(shot.spread_radius < ShotModel.START_SPREAD_RADIUS, "holding shrinks the landing circle")
	shot.cancel()
	_check(shot.phase == ShotModel.Phase.IDLE, "cancel clears draw")
	shot.configure(1.0, 1.0)
	shot.start_hold(centers[1])
	shot.tick(ShotModel.DRAW_READY_SECONDS, centers[1])
	_check(shot.phase == ShotModel.Phase.READY, "draw becomes ready")
	shot.tick(ShotModel.PRECISION_PEAK_SECONDS - ShotModel.DRAW_READY_SECONDS, centers[1])
	_check(is_equal_approx(shot.spread_radius, ShotModel.MIN_SPREAD_RADIUS), "circle reaches its smallest size")
	_check(is_equal_approx(shot.minimum_spread_radius(), shot.spread_radius), "preview matches the smallest landing circle")
	shot.tick(1.5, centers[1])
	_check(shot.spread_radius > ShotModel.MIN_SPREAD_RADIUS, "holding too long widens the circle")
	_check(ShotModel.spread_at(1.9) > ShotModel.spread_at(2.1), "late circle visibly pulses")
	shot.configure(0.7, 0.6)
	shot.start_hold(centers[1] + Vector2(20, 0))
	shot.tick(ShotModel.PRECISION_PEAK_SECONDS, centers[1])
	_check(is_equal_approx(shot.spread_radius, ShotModel.MIN_SPREAD_RADIUS * 0.6), "Maera Focus tightens spread")
	_check(is_equal_approx(shot.minimum_spread_radius(), shot.spread_radius), "focused preview matches the smaller circle")
	_check(shot.impact_point == centers[1], "Maera still steers rather than snapping")
	shot.configure(1.6, 1.0, 1.0)
	shot.start_hold(centers[2])
	shot.tick(1.0, centers[2])
	_check(shot.phase == ShotModel.Phase.READY and is_equal_approx(shot.spread_radius, shot.minimum_spread_radius()), "Vey reaches minimum spread before the bonus deadline")
	_check(shot.elapsed <= TrialRules.VEY_TEMPO_SECONDS, "Vey's precision peak leaves time for his bonus")
	shot.tick(0.2, centers[2])
	_check(shot.spread_radius > shot.minimum_spread_radius(), "Vey's circle widens before his bonus expires")
	shot.start_hold(Vector2(820, 645))
	shot.tick(0.5, centers[2])
	_check(shot.aim_point.distance_to(centers[2]) > 0.0, "fast steering still has travel time")
	var impact_rng := RandomNumberGenerator.new()
	impact_rng.seed = 1309
	var sampled_off_center: bool = false
	for sample_index: int in range(128):
		var sampled: Vector2 = ShotModel.sample_impact(centers[1], 20.0, impact_rng)
		_check(sampled.distance_to(centers[1]) <= 20.001, "random impact stays inside visible circle")
		if sampled.distance_to(centers[1]) > 10.0:
			sampled_off_center = true
	_check(sampled_off_center, "impact sampling covers more than the circle center")
	_check(ShotModel.sample_impact(centers[1], 0.0, impact_rng) == centers[1], "zero-radius test shot is exact")

	var main: Node = load("res://app/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var view: RangeView = main.get_node("RangeView")
	_check(main.selection_open and not main.build_selected, "build strategy opens before the trial")
	_check(view.get_node("UI/BuildOverlay/Rules").visible and not view.get_node("UI/BuildOverlay/MaeraCard").visible, "opening screen shows rules before characters")
	view.get_node("UI/BuildOverlay/RulesNextButton").emit_signal("pressed")
	_check(view.get_node("UI/BuildOverlay/MaeraCard").visible and not view.get_node("UI/BuildOverlay/Rules").visible, "next screen shows character strategies")
	view.get_node("UI/BuildOverlay/HowToPlayButton").emit_signal("pressed")
	_check(view.get_node("UI/BuildOverlay/Rules").visible, "character screen can return to rules")
	view.get_node("UI/BuildOverlay/RulesNextButton").emit_signal("pressed")
	view.gear_requested.emit(&"gyro_brace")
	_check(main.equipped.id == &"gyro_brace" and not main.selection_open and main.focus == 1, "selecting Maera starts with one Focus")
	view.primary_pressed.emit(view.mouse_aim())
	view.primary_released.emit()
	_check(main.impacts.is_empty() and main.focus == 1, "early release spends neither shot nor Focus")
	_check(view.get_node("ImpactDelay").is_stopped(), "cancelled draw has no impact sound queued")
	view.focus_requested.emit()
	_check(main.focus_armed, "Focus can be armed before a shot")
	view.primary_pressed.emit(view.mouse_aim())
	_check(main.shot_focused and is_equal_approx(main.shot.spread_scale, 0.6), "Maera's tighter circle requires Focus")
	main._physics_process(0.1)
	_check(is_equal_approx(main.range_time, 0.1), "Maera's Focus does not slow targets")
	view.primary_released.emit()
	_check(main.focus == 1 and main.focus_armed, "early focused release refunds armed Focus")
	view.primary_pressed.emit(view.mouse_aim())
	main.shot.tick(ShotModel.DRAW_READY_SECONDS, centers[0])
	view.visible_reticle = centers[0]
	view.visible_spread_radius = 0.0
	view.visible_reticle_valid = true
	view.visible_target_centers = centers
	view.primary_released.emit()
	_check(main.impacts.size() == 1 and main.focus == 1, "focused Safe center spends then restores Focus")
	_check(not view.get_node("ImpactDelay").is_stopped(), "accepted shot queues an impact sound")
	_check(main.last_focus_gain == 1 and main.total_score == 6, "Safe refill and score are shown")
	view.primary_pressed.emit(view.mouse_aim())
	_check(is_equal_approx(main.shot.spread_scale, 1.0), "Maera has no free accuracy boost without Focus")
	view.cancel_requested.emit()
	view.build_screen_requested.emit()
	_check(not main.selection_open, "build cannot change after trial starts")
	view.gear_requested.emit(&"pulse_sight")
	_check(main.equipped.id == &"gyro_brace", "build selection requires strategy screen")
	for index: int in range(4):
		view.primary_pressed.emit(view.mouse_aim())
		main.shot.tick(ShotModel.DRAW_READY_SECONDS, centers[1])
		view.visible_reticle = centers[1]
		view.visible_spread_radius = 0.0
		view.visible_reticle_valid = true
		view.visible_target_centers = centers
		view.primary_released.emit()
	_check(main.impacts.size() == 5 and main.total_score == 46, "five Maera shots total forty-six")
	_check(main.impacts[1].target_index == 1 and main.impacts[1].position_at(later) == later[1], "recorded center hit stays centered as target moves")
	_check(main.best_score == 46, "completed trial saves best")
	view.primary_pressed.emit(view.mouse_aim())
	_check(main.impacts.size() == 5, "sixth shot is rejected")
	view.retry_requested.emit()
	_check(main.impacts.is_empty() and main.focus == 1 and main.equipped.id == &"gyro_brace", "retry keeps build and resets Focus")
	var click_aim := Vector2(734, 401)
	view.primary_pressed.emit(click_aim)
	_check(main.shot.aim_point == click_aim, "shot starts at the click position")
	view.cancel_requested.emit()
	_check(main.shot.phase == ShotModel.Phase.IDLE and main.impacts.is_empty(), "cancel spends no shot")
	for index: int in range(5):
		view.primary_pressed.emit(view.mouse_aim())
		main.shot.tick(ShotModel.DRAW_READY_SECONDS, centers[0])
		view.visible_reticle = centers[0]
		view.visible_spread_radius = 0.0
		view.visible_reticle_valid = true
		view.visible_target_centers = centers
		view.primary_released.emit()
	_check(main.total_score == 30, "five safe centers cannot clear the trial")
	_check(main.focus == 2, "Safe refills Focus only to the cap")
	view.build_screen_requested.emit()
	_check(main.selection_open, "build strategy can reopen between trials")
	_check(view.get_node("UI/BuildOverlay/MaeraCard").visible, "change character opens character choices")
	view.get_node("UI/BuildOverlay/HowToPlayButton").emit_signal("pressed")
	_check(view.get_node("UI/BuildOverlay/Rules").visible, "rules remain available while changing character")
	view.get_node("UI/BuildOverlay/RulesNextButton").emit_signal("pressed")
	view.gear_requested.emit(&"pulse_sight")
	_check(main.equipped.id == &"pulse_sight" and main.impacts.is_empty() and main.focus == 1, "Vey starts a new trial")
	_check(is_equal_approx(main.equipped.focus_time_scale, 0.5), "Vey's Focus slows targets")
	view.primary_pressed.emit(view.mouse_aim())
	_check(is_equal_approx(main.shot.spread_scale, 1.0), "Vey has ordinary spread without Focus")
	_check(is_equal_approx(main.shot.precision_peak_seconds, 1.0), "Vey uses the early precision peak")
	main.shot.tick(ShotModel.DRAW_READY_SECONDS, centers[2])
	view.visible_reticle = centers[2]
	view.visible_spread_radius = 0.0
	view.visible_reticle_valid = true
	view.visible_target_centers = centers
	view.primary_released.emit()
	_check(main.total_score == 18 and main.last_bonus == "QUICK HIT +3", "Vey's quick shot earns tempo bonus")
	main.impact_rng.seed = 1309
	view.primary_pressed.emit(view.mouse_aim())
	main.shot.tick(ShotModel.DRAW_READY_SECONDS, centers[1])
	view.visible_reticle = centers[1]
	view.visible_spread_radius = 20.0
	view.visible_reticle_valid = true
	view.visible_target_centers = centers
	view.primary_released.emit()
	_check(main.impacts[1].position_at(centers).distance_to(centers[1]) <= 20.001, "accepted hit stays inside the displayed circle")
	view.cancel_requested.emit()
	view.build_screen_requested.emit()
	_check(not main.selection_open, "strategy screen cannot interrupt an active trial")
	main._reset_round()
	for index: int in range(3):
		_shoot_at(main, view, centers[2], centers)
	_check(main.total_score == 45 and not TrialRules.is_trial_over(main.total_score, main.impacts.size()), "three Bold centers leave the trial active")
	_shoot_at(main, view, centers[0], centers)
	_check(main.total_score == 51 and main.impacts.size() == 4, "Safe can finish after three Bold centers")
	view.retry_requested.emit()
	for index: int in range(3):
		_shoot_at(main, view, centers[2], centers)
	_shoot_at(main, view, centers[1] + Vector2(32, 0), centers)
	_check(main.total_score == 51 and main.impacts.size() == 4, "Standard outer ring can finish the trial")
	_check(main.best_score == 51 and view.get_node("UI/Status").text == "TRIAL CLEARED", "early clear records a valid best score")
	_check(not view.get_node("ResultDelay").is_stopped(), "clear queues a result sound")
	view.primary_pressed.emit(centers[2])
	_check(main.shot.phase == ShotModel.Phase.IDLE and main.impacts.size() == 4, "early clear rejects another shot")
	view.build_screen_requested.emit()
	_check(main.selection_open, "strategy screen reopens after an early clear")
	_check(view.get_node("UI/BuildOverlay/MaeraCard").visible, "character choices appear after a clear")
	view.build_screen_closed.emit()
	view.retry_requested.emit()
	_check(main.impacts.is_empty() and main.total_score == 0, "early clear can retry")
	_check(view.get_node("ResultDelay").is_stopped(), "retry cancels any pending result sound")
	for index: int in range(3):
		_shoot_at(main, view, centers[2], centers)
	_shoot_at(main, view, centers[1] + Vector2(30, 0), centers)
	_check(main.total_score == 52 and view.get_node("UI/Status").text == "TRIAL CLEARED", "upper edge clears before the fifth shot")
	view.retry_requested.emit()
	for point: Vector2 in [centers[2], centers[2], centers[1], centers[0], centers[2]]:
		_shoot_at(main, view, point, centers)
	_check(main.total_score == 61 and main.impacts.size() == 5, "score above the cap busts")
	_check(view.get_node("UI/Status").text == "BUST — OVER 52" and main.best_score == 52, "bust is shown and does not replace best valid score")
	view.retry_requested.emit()
	_check(main.impacts.is_empty(), "busted trial can retry")
	_shoot_at(main, view, centers[2], centers, 0.52)
	_shoot_at(main, view, centers[2], centers, 0.52)
	_shoot_at(main, view, centers[1], centers)
	_shoot_at(main, view, centers[2], centers)
	_check(main.total_score == 61 and main.impacts.size() == 4, "a bonus can bust before the fifth shot")
	view.primary_pressed.emit(centers[0])
	_check(main.shot.phase == ShotModel.Phase.IDLE and main.impacts.size() == 4, "early bust rejects another shot")

	if failures == 0:
		print("All target, dispersion, Focus, build, and trial assertions passed.")
	quit(1 if failures > 0 else 0)


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + description)


func _shoot_at(main: Node, view: RangeView, point: Vector2, centers: Array[Vector2], hold_seconds: float = 1.5) -> void:
	view.primary_pressed.emit(point)
	main.shot.tick(hold_seconds, point)
	view.visible_reticle = point
	view.visible_spread_radius = 0.0
	view.visible_reticle_valid = true
	view.visible_target_centers = centers
	view.primary_released.emit()
