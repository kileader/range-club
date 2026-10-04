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
	_check(TrialRules.resolve_hit(standard_center, &"gyro_brace", true, 0.7).points == 13, "Maera's focused Standard inner hit gains three")
	_check(TrialRules.resolve_hit(standard_center, &"gyro_brace", true, 0.7).bonus == "BRACED +3", "Maera's focused bonus is shown")
	_check(TrialRules.resolve_hit(TargetLayout.score_at(centers[1] + Vector2(42, 0), centers), &"gyro_brace", true, 0.7).points == 5, "Maera's Standard outer ring earns no bonus")
	_check(TrialRules.resolve_hit(bold_center, &"gyro_brace", true, 0.7).points == 15, "Maera's bonus excludes Bold")
	_check(TrialRules.resolve_hit(bold_center, &"pulse_sight", false, 1.2).points == 18, "Vey earns quick inner bonus at deadline")
	_check(TrialRules.resolve_hit(bold_center, &"pulse_sight", false, 1.21).points == 15, "Vey loses bonus after deadline")
	_check(TrialRules.resolve_hit(TargetLayout.score_at(centers[1] + Vector2(32, 0), centers), &"pulse_sight", false, 0.7).points < 11, "Vey bonus requires inner ring")
	_check(TrialRules.resolve_hit(miss, &"pulse_sight", false, 0.7).points == 0, "miss has no bonus")
	_check(RunRules.goal_for_stage(2) == 56 and RunRules.cap_for_stage(2) == 60, "run score windows rise by stage")
	var offer_test_rng := RandomNumberGenerator.new()
	offer_test_rng.seed = 3909
	var scenario_order: Array[StringName] = RunRules.draw_scenarios(offer_test_rng)
	_check(scenario_order.size() == 3 and scenario_order[0] == &"triad" and scenario_order[1] != scenario_order[2], "run draws distinct later scenarios")
	var owned_test: Array[StringName] = [&"quickset_string", &"stabilizing_sight"]
	var offer_test: Array[StringName] = RunRules.draw_offers(owned_test, offer_test_rng)
	_check(offer_test.size() == 3 and not offer_test.has(&"quickset_string") and not offer_test.has(&"stabilizing_sight") and offer_test[0] != offer_test[1] and offer_test[1] != offer_test[2], "offers exclude owned modules and duplicates")
	_check(TrialRules.resolve_hit(safe_center, &"gyro_brace", false, 1.5, &"safe_circuit", [&"quickset_string"]).points == 9, "Quickset String does not add points")
	_check(TrialRules.resolve_hit(standard_center, &"gyro_brace", true, 1.5, &"standard_relay", [&"recirculator"]).points == 15, "Maera and Standard scenario bonuses stack")
	_check(TrialRules.resolve_hit(standard_center, &"gyro_brace", true, 1.5, &"standard_relay", [&"recirculator"]).focus_gain == 1, "recirculator refunds spent Focus")
	_check(TrialRules.resolve_hit(bold_center, &"gyro_brace", false, 1.5, &"bold_surge").points == 18, "Bold scenario changes target value")
	_check(TrialRules.resolve_hit(standard_center, &"gyro_brace", false, 1.5, &"triad", [&"stabilizing_sight"]).points == 10, "Stabilizing Sight does not add points")
	_check(TrialRules.resolve_hit(TargetLayout.score_at(centers[2] + Vector2(13, 0), centers), &"gyro_brace", false, 1.5, &"triad", [&"edge_fuse"]).points == 13, "Edge Fuse rewards Bold outer rings")
	_check(TrialRules.resolve_hit(miss, &"gyro_brace", true, 1.5, &"triad", [&"recovery_cell"]).focus_gain == 1, "Recovery Cell refunds a focused miss")
	_check(TrialRules.resolve_hit(miss, &"gyro_brace", false, 1.5, &"triad", [&"recovery_cell"]).focus_gain == 0, "Recovery Cell leaves ordinary misses alone")
	_check(TrialRules.resolve_hit(standard_center, &"gyro_brace", true, 1.5, &"triad", [&"recovery_cell"]).focus_gain == 0, "Recovery Cell does not refund a hit")
	var attached_mark := ImpactRecord.new(1, Vector2(5, -4), Vector2(-3, -4))
	_check(attached_mark.position_at(later) == later[1] + Vector2(5, -4), "hit mark follows its target")
	_check(attached_mark.direction.is_equal_approx(Vector2(-0.6, -0.8)), "embedded arrow preserves a unit travel direction as its target moves")
	var miss_mark := ImpactRecord.new(-1, Vector2(700, 600), Vector2(3, -4))
	_check(miss_mark.position_at(later) == Vector2(700, 600), "miss mark stays on the backstop")
	_check(miss_mark.direction.is_equal_approx(Vector2(0.6, -0.8)), "miss preserves its travel direction")
	var coincident_mark := ImpactRecord.new(-1, Vector2(1040, 610), Vector2.ZERO)
	_check(coincident_mark.direction == Vector2.UP, "coincident shot origin keeps a visible embedded arrow")

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
	shot.configure(1.0, 1.0, ShotModel.PRECISION_PEAK_SECONDS, ShotModel.STABILIZING_SIGHT_HOLD_SECONDS)
	shot.start_hold(centers[1])
	shot.tick(2.1, centers[1])
	_check(is_equal_approx(shot.spread_radius, shot.minimum_spread_radius()), "Stabilizing Sight holds full precision through its extra window")
	shot.tick(0.2, centers[1])
	_check(shot.spread_radius > shot.minimum_spread_radius(), "Stabilizing Sight eventually blooms")
	shot.configure(1.0, 1.0, ShotModel.PRECISION_PEAK_SECONDS - ShotModel.QUICKSET_SECONDS, ShotModel.QUICKSET_SECONDS)
	shot.start_hold(centers[1])
	shot.tick(1.2, centers[1])
	_check(is_equal_approx(shot.spread_radius, shot.minimum_spread_radius()), "Quickset String reaches minimum 0.3 seconds sooner")
	shot.tick(0.3, centers[1])
	_check(is_equal_approx(shot.spread_radius, shot.minimum_spread_radius()), "Quickset String does not start bloom early")
	shot.tick(0.2, centers[1])
	_check(shot.spread_radius > shot.minimum_spread_radius(), "Quickset String blooms after the old peak")
	shot.configure(1.0, 1.0, ShotModel.PRECISION_PEAK_SECONDS - ShotModel.QUICKSET_SECONDS, ShotModel.QUICKSET_SECONDS + ShotModel.STABILIZING_SIGHT_HOLD_SECONDS)
	shot.start_hold(centers[1])
	shot.tick(2.1, centers[1])
	_check(is_equal_approx(shot.spread_radius, shot.minimum_spread_radius()), "Quickset String and Stabilizing Sight stack")
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

	var main: RunController = load("res://app/main.tscn").instantiate() as RunController
	root.add_child(main)
	await process_frame
	var view: RangeView = main.get_node("RangeView")
	var run_ui: RunView = main.get_node("RunView")
	# Drive the presentation clock explicitly so these checks do not depend on wall time.
	view.shot_feedback.set_process(false)
	_check(main.phase == RunController.RunPhase.SELECT and main.selection_open and not main.build_selected, "new run begins at character selection")
	_check(main.scenarios.size() == 3 and main.scenarios[0] == &"triad", "new run has three scenarios")
	_check(view.get_node("UI/BuildOverlay/Rules").visible, "opening screen explains rules")
	view.get_node("UI/BuildOverlay/ArchiveButton").emit_signal("pressed")
	_check(view.get_node("UI/BuildOverlay/ArchivePage").visible and view.get_node("UI/BuildOverlay/ArchivePage/ArchiveBody").text.contains("YEAR 21XX"), "optional case file opens with the 21XX setting")
	_check(view.get_node("UI/BuildOverlay/ArchivePage/ArchiveBody").text.contains("aquatic applicants"), "case file carries the fish-darts reference")
	var archive_escape := InputEventKey.new()
	archive_escape.pressed = true
	archive_escape.keycode = KEY_ESCAPE
	view.get_viewport().push_input(archive_escape, true)
	await process_frame
	_check(not view.get_node("UI/BuildOverlay/ArchivePage").visible and main.phase == RunController.RunPhase.SELECT, "Escape closes only the case file")
	view.get_node("UI/BuildOverlay/ArchiveButton").emit_signal("pressed")
	view.get_node("UI/BuildOverlay/ArchivePage/CloseButton").emit_signal("pressed")
	_check(not view.get_node("UI/BuildOverlay/ArchivePage").visible and main.phase == RunController.RunPhase.SELECT, "closing the case file returns to selection")
	main.scenarios[1] = &"standard_relay"
	main.scenarios[2] = &"safe_circuit"
	view.get_node("UI/BuildOverlay/RulesNextButton").emit_signal("pressed")
	_check(view.natural_portrait.texture != null and view.maera_portrait.texture != null and view.vey_portrait.texture != null, "all character cards show portraits")
	view.maera_card.emit_signal("pressed")
	_check(main.phase == RunController.RunPhase.SHOOT and main.equipped.id == &"gyro_brace" and main.focus == 1, "choosing Maera starts the first trial")
	_check(view.get_node("UI/BuildButton").visible, "character can change before the first shot")
	_check(view.get_node("UI/RigDetailsButton").visible, "rig details are available before the first shot")
	view.primary_pressed.emit(view.mouse_aim())
	view.primary_released.emit()
	_check(main.impacts.is_empty(), "early release spends no shot")
	view.focus_requested.emit()
	view.primary_pressed.emit(centers[1])
	main.shot.tick(1.5, centers[1])
	var escape_event := InputEventKey.new()
	escape_event.pressed = true
	escape_event.keycode = KEY_ESCAPE
	view.get_viewport().push_input(escape_event, true)
	await process_frame
	_check(main.shot.phase == ShotModel.Phase.READY, "Escape does not cancel an active shot")
	var right_click := InputEventMouseButton.new()
	right_click.pressed = true
	right_click.button_index = MOUSE_BUTTON_RIGHT
	view.get_viewport().push_input(right_click, true)
	await process_frame
	_check(main.shot.phase == ShotModel.Phase.IDLE and main.focus == 1 and main.impacts.is_empty(), "right-click cancels a ready focused shot without cost")
	view.primary_released.emit()
	_check(main.impacts.is_empty(), "left release after right-click does not fire")
	_shoot_at(main, view, centers[1], centers, 1.5, false)
	_check(main.phase == RunController.RunPhase.SHOT_FEEDBACK and main.impacts.is_empty() and main.total_score == 0, "release reserves one shot and waits for visible impact")
	_check(main.focus == 0 and view.focus_button.disabled, "focused release spends Focus once and disables arming during flight")
	var release_time: float = main.range_time
	var release_centers: Array[Vector2] = main.release_target_centers.duplicate()
	main._physics_process(0.5)
	view.primary_pressed.emit(centers[2])
	view.primary_released.emit()
	view.cancel_requested.emit()
	view.focus_requested.emit()
	view.rig_details_requested.emit()
	_check(main.phase == RunController.RunPhase.SHOT_FEEDBACK and main.shot.phase == ShotModel.Phase.IDLE and not main.focus_armed, "flight ignores firing, cancellation, Focus, and rig-menu input")
	_check(main.range_time == release_time and view._target_centers == release_centers, "feedback freezes the target snapshot that was scored")
	view.shot_feedback.advance(view.shot_feedback.flight_seconds * 0.5)
	_check(main.impacts.is_empty(), "halfway through flight has no impact mark")
	_check(main.run_shots.is_empty(), "report excludes arrows still in flight")
	_check(not view.shot_feedback.score_popup.visible and not view.shot_feedback.effect_popup.visible, "points and proc labels stay hidden during flight")
	view.shot_feedback.advance(view.shot_feedback.flight_seconds * 0.5 + 0.001)
	_check(main.impacts.size() == 1 and main.total_score == 13, "landing reveals Maera's release-time Focus bonus")
	_check(view.shot_feedback.effect_popup.visible and view.shot_feedback.effect_popup.text == "BRACED +3", "impact announces the resolved character bonus")
	view.shot_landed.emit()
	_check(main.impacts.size() == 1 and main.total_score == 13, "duplicate landing notification cannot score twice")
	_check(main.run_shots.size() == 1 and main.run_shots[0].points == 13 and main.run_shots[0].ring == 10, "report records one resolved shot despite duplicate landing")
	view.shot_feedback.advance(view.shot_feedback.recovery_seconds)
	_check(main.phase == RunController.RunPhase.SHOOT, "ordinary shot returns control after recovery")
	_check(not view.shot_feedback.effect_popup.visible, "proc label ends at the existing recovery boundary")
	main._reset_trial()
	# Start the full-run fixture without the earlier presentation-only shot.
	main.run_shots.clear()
	_check(not view.shot_feedback.active and main.pending_resolution.is_empty(), "reset clears feedback and pending results")
	for index: int in range(5):
		_shoot_at(main, view, centers[1], centers)
	_check(main.total_score == 50 and main.impacts.size() == 5, "five Standard centers clear the opening trial")
	_check(main.phase == RunController.RunPhase.REWARD and run_ui.visible, "clear opens the reward screen")
	_check(run_ui.get_node("Panel/NextTrial").text.contains("STANDARD RELAY"), "reward previews the next scenario")
	_check(main.offers.size() == 3 and main.offers[0] != main.offers[1] and main.offers[1] != main.offers[2], "reward contains three distinct choices")
	_check(run_ui.get_node("Panel/Installed").text.contains("FOCUS RESETS TO 1"), "reward explains the next trial's Focus reset")
	run_ui.upgrade_selected.emit(&"not_an_offer")
	_check(main.phase == RunController.RunPhase.REWARD and main.upgrades.is_empty(), "unoffered module cannot be installed")
	view.primary_pressed.emit(centers[2])
	_check(main.impacts.size() == 5, "reward phase rejects range input")
	var first_upgrade: StringName = main.offers[0]
	main.focus = 0
	run_ui.get_node("Panel/OfferOne").emit_signal("pressed")
	_check(main.stage == 1 and main.phase == RunController.RunPhase.SHOOT and not run_ui.visible, "choosing a module starts trial two")
	_check(main.upgrades == [first_upgrade] and main.focus == 1 and main.total_score == 0 and main.impacts.is_empty(), "empty Focus resets to one while the module carries")
	_check(main.run_shots.size() == 5, "report retains shots when the next trial resets")
	_check(view.get_node("UI/StageLabel").text.contains("STANDARD RELAY"), "range displays the active scenario")
	_check(not view.get_node("UI/BuildButton").visible, "character is fixed after trial one")
	var time_before_menu: float = main.range_time
	view.get_node("UI/RigDetailsButton").emit_signal("pressed")
	_check(main.phase == RunController.RunPhase.LOADOUT and run_ui.visible, "rig details open without ending the trial")
	_check(run_ui.get_node("Panel/LoadoutOne").text.contains(RunRules.upgrade_title(first_upgrade)) and run_ui.get_node("Panel/LoadoutOne").text.contains(RunRules.upgrade_rule(first_upgrade).replace("\n", " ")), "rig details explain the installed module")
	view.primary_pressed.emit(centers[1])
	_check(main.shot.phase == ShotModel.Phase.IDLE and main.impacts.is_empty(), "rig details block shooting")
	main._physics_process(0.5)
	_check(is_equal_approx(main.range_time, time_before_menu), "rig details pause target motion")
	view.get_viewport().push_input(escape_event, true)
	await process_frame
	_check(main.phase == RunController.RunPhase.SHOOT and not run_ui.visible, "Escape returns from rig details")
	view.get_node("UI/RigDetailsButton").emit_signal("pressed")
	run_ui.get_node("Panel/CloseButton").emit_signal("pressed")
	_check(main.phase == RunController.RunPhase.SHOOT and not run_ui.visible and main.upgrades == [first_upgrade], "closing rig details resumes the same trial")
	_shoot_at(main, view, centers[0], centers)
	for index: int in range(4):
		_shoot_at(main, view, centers[1], centers)
	_check(main.total_score >= 52 and main.total_score <= 56 and main.phase == RunController.RunPhase.REWARD, "Safe then four Standard hits clear the relay")
	var relay_score: int = main.total_score
	_check(main.focus == 2, "Safe can raise Focus to two within a trial")
	_check(main.offers.size() == 3 and not main.offers.has(first_upgrade), "later offers exclude installed modules")
	var second_upgrade: StringName = main.offers[0]
	run_ui.get_node("Panel/OfferOne").emit_signal("pressed")
	_check(main.stage == 2 and main.upgrades == [first_upgrade, second_upgrade] and main.focus == 1, "full Focus resets to one while both modules reach the final trial")
	for index: int in range(3):
		_shoot_at(main, view, centers[2], centers)
	_shoot_at(main, view, centers[1] + Vector2(77, 0), centers)
	_shoot_at(main, view, centers[1], centers)
	_check(main.total_score == 56 and main.phase == RunController.RunPhase.RESULT, "mixed target route clears the final trial")
	_check(run_ui.get_node("Panel/Heading").text == "RUN COMPLETE" and run_ui.visible, "winning run shows result")
	var winning_report: Dictionary = main._run_report()
	_check(winning_report.total_score == 106 + relay_score and winning_report.shots == 15 and winning_report.hits == 15, "report sums all three trials rather than only the final score")
	_check(winning_report.bullseyes == 14 and winning_report.longest_streak == 15 and winning_report.best_shot == 15, "report uses resolved rings and points for notable stats")
	_check(winning_report.trials[0].score == 50 and winning_report.trials[1].score == relay_score and winning_report.trials[2].score == 56 and winning_report.trials[2].status == "CLEARED", "report preserves the per-trial ledger")
	_check(run_ui.report.visible and not run_ui.next_trial.visible and not run_ui.installed.visible, "results use the self-contained report area")
	run_ui.get_node("Panel/NewRunButton").emit_signal("pressed")
	_check(main.phase == RunController.RunPhase.SELECT and main.stage == 0 and main.upgrades.is_empty() and main.focus == 1, "new run clears all temporary progression")
	_check(not run_ui.visible and not main.build_selected and view.get_node("UI/BuildOverlay/Rules").visible, "new run returns to opening rules")
	_check(main.run_shots.is_empty() and not run_ui.report.visible, "new run clears report history and hides the report")
	view.get_node("UI/BuildOverlay/RulesNextButton").emit_signal("pressed")
	view.gear_requested.emit(&"bare_rig")
	for index: int in range(5):
		_shoot_at(main, view, Vector2(700, 620), centers)
	_check(main.phase == RunController.RunPhase.RESULT and run_ui.get_node("Panel/Heading").text == "RUN ENDED", "five misses end the run")
	var miss_report: Dictionary = main._run_report()
	_check(miss_report.hits == 0 and miss_report.shots == 5 and miss_report.best_shot == 0 and miss_report.trials[0].status == "BELOW WINDOW" and miss_report.trials[1].status == "NOT REACHED", "miss-only report has zero accuracy and distinguishes unplayed trials")
	run_ui.get_node("Panel/NewRunButton").emit_signal("pressed")
	view.get_node("UI/BuildOverlay/RulesNextButton").emit_signal("pressed")
	view.gear_requested.emit(&"pulse_sight")
	for index: int in range(3):
		_shoot_at(main, view, centers[2], centers, 0.52)
	_check(main.total_score == 54 and main.impacts.size() == 3 and main.phase == RunController.RunPhase.RESULT, "Vey quick Bold streak busts early")
	_check(run_ui.get_node("Panel/Heading").text == "RUN ENDED", "bust ends the run")
	_check(main._run_report().total_score == 54 and main._run_report().trials[0].status == "BUST", "bust report retains all points including the busting arrow")
	view.primary_pressed.emit(centers[0])
	_check(main.impacts.size() == 3, "ended run rejects another shot")
	run_ui.get_node("Panel/NewRunButton").emit_signal("pressed")
	view.get_node("UI/BuildOverlay/RulesNextButton").emit_signal("pressed")
	view.gear_requested.emit(&"bare_rig")
	main.upgrades.append(&"quickset_string")
	main.upgrades.append(&"stabilizing_sight")
	view.primary_pressed.emit(centers[1])
	_check(is_equal_approx(main.shot.precision_peak_seconds, 1.2) and is_equal_approx(main.shot.minimum_hold_seconds, 1.0), "equipped handling modules combine on a live shot")
	view.cancel_requested.emit()
	main.upgrades.clear()
	main.upgrades.append(&"recovery_cell")
	view.focus_requested.emit()
	_shoot_at(main, view, Vector2(820, 645), centers)
	_check(main.impacts.size() == 1 and main.focus == 1 and view.get_node("UI/Status").text == "MISS — FOCUS REFUNDED", "Recovery Cell restores spent Focus after a miss")
	main._start_new_run()
	view.gear_requested.emit(&"gyro_brace")
	main.total_score = 40
	_shoot_at(main, view, centers[1], centers, 1.5, false)
	view.shot_feedback.advance(view.shot_feedback.flight_seconds + 0.001)
	_check(main.total_score == 50 and main.phase == RunController.RunPhase.SHOT_FEEDBACK and not run_ui.visible, "winning impact stays visible before the reward screen")
	view.shot_feedback.advance(view.shot_feedback.recovery_seconds)
	_check(main.phase == RunController.RunPhase.SHOT_FEEDBACK, "winning shot allows a longer result beat")
	view.shot_feedback.advance(view.shot_feedback.result_recovery_seconds)
	_check(main.phase == RunController.RunPhase.REWARD and run_ui.visible, "reward opens after the winning animation")
	main._start_new_run()
	view.gear_requested.emit(&"gyro_brace")
	_shoot_at(main, view, centers[2], centers, 1.5, false)
	main._start_new_run()
	view.shot_feedback.advance(2.0)
	view.shot_landed.emit()
	view.shot_feedback_finished.emit()
	_check(main.phase == RunController.RunPhase.SELECT and main.total_score == 0 and main.impacts.is_empty(), "restart during flight cannot deliver a stale score or transition")
	_check(main.run_shots.is_empty(), "restart during flight cannot add a stale report record")
	for gear_id: StringName in [&"bare_rig", &"gyro_brace", &"pulse_sight"]:
		main._start_new_run()
		view.gear_requested.emit(gear_id)
		for target: int in range(centers.size()):
			_shoot_at(main, view, centers[target] + Vector2(2, -3), centers)
		_shoot_at(main, view, Vector2(700, 620), centers)
		main._physics_process(2.0)
		for target: int in range(centers.size()):
			_check(main.impacts[target].position_at(view._target_centers).is_equal_approx(view._target_centers[target] + Vector2(2, -3)), "%s old arrow follows moving target %d after later shots" % [gear_id, target])
		_check(main.impacts[3].position_at(view._target_centers) == Vector2(700, 620), "%s miss stays in the backstop after target motion" % gear_id)
	var feedback_cases: Array[Dictionary] = [
		{"gear": &"gyro_brace", "scenario": &"triad", "upgrades": [&"edge_fuse"], "focused": false, "point": centers[2] + Vector2(13, 0), "hold": 1.5, "text": "EDGE +3", "points": 13},
		{"gear": &"pulse_sight", "scenario": &"triad", "upgrades": [], "focused": false, "point": centers[2], "hold": 0.52, "text": "QUICK HIT +3", "points": 18},
		{"gear": &"gyro_brace", "scenario": &"safe_circuit", "upgrades": [], "focused": false, "point": centers[0], "hold": 1.5, "text": "CIRCUIT +3\nFOCUS +1", "points": 9},
		{"gear": &"gyro_brace", "scenario": &"standard_relay", "upgrades": [&"recirculator"], "focused": true, "point": centers[1], "hold": 1.5, "text": "BRACED +3\nRELAY +2\nFOCUS REFUND", "points": 15},
		{"gear": &"gyro_brace", "scenario": &"triad", "upgrades": [&"recovery_cell"], "focused": true, "point": Vector2(700, 620), "hold": 1.5, "text": "FOCUS REFUND", "points": 0},
		{"gear": &"gyro_brace", "scenario": &"triad", "upgrades": [], "focused": false, "point": centers[1], "hold": 1.5, "text": "", "points": 10},
	]
	for feedback_case: Dictionary in feedback_cases:
		main._start_new_run()
		view.gear_requested.emit(feedback_case.gear)
		main.scenarios[0] = feedback_case.scenario
		main.upgrades.assign(feedback_case.upgrades)
		if feedback_case.focused:
			view.focus_requested.emit()
		_shoot_at(main, view, feedback_case.point, centers, feedback_case.hold, false)
		_check(not view.shot_feedback.effect_popup.visible, "resolved effects are hidden until impact")
		view.shot_feedback.advance(view.shot_feedback.flight_seconds + 0.001)
		_check(view.shot_feedback.effect_popup.text == feedback_case.text and view.shot_feedback.effect_popup.visible == not feedback_case.text.is_empty(), "proc popup reflects resolved bonuses and Focus without duplicate refunds")
		_check(main.total_score == feedback_case.points, "proc presentation preserves resolved points")
		view.shot_feedback.advance(0.15)
		_check(is_equal_approx(view.shot_feedback.effect_popup.modulate.a, view.shot_feedback.score_popup.modulate.a), "proc label shares the points fade")
		main._start_new_run()
		_check(not view.shot_feedback.effect_popup.visible and view.shot_feedback.effect_popup.text.is_empty(), "reset clears proc text and visibility")
	main._start_new_run()
	view.gear_requested.emit(&"gyro_brace")
	for point: Vector2 in [centers[0], centers[0], Vector2(700, 620), centers[0], Vector2(700, 620)]:
		_shoot_at(main, view, point, centers)
	var mixed_report: Dictionary = main._run_report()
	_check(mixed_report.total_score == 18 and mixed_report.shots == 5 and mixed_report.hits == 3 and mixed_report.longest_streak == 2, "mixed report counts misses and breaks the hit streak")
	if failures == 0:
		print("All target, Focus, build, trial, and run assertions passed.")
	view.stop_sound_feedback()
	# Rapid synthetic shots can leave playback objects queued on the audio thread.
	await create_timer(0.1).timeout
	main.queue_free()
	await process_frame
	call_deferred("quit", 1 if failures > 0 else 0)


func _check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + description)


func _shoot_at(main: Node, view: RangeView, point: Vector2, centers: Array[Vector2], hold_seconds: float = 1.5, finish_feedback: bool = true) -> void:
	view.primary_pressed.emit(point)
	main.shot.tick(hold_seconds, point)
	view.visible_reticle = point
	view.visible_spread_radius = 0.0
	view.visible_reticle_valid = true
	view.visible_target_centers = centers
	view.primary_released.emit()
	var expected_direction: Vector2 = (point - view.shot_feedback._origin).normalized()
	var old_directions: Array[Vector2] = []
	for impact: ImpactRecord in main.impacts:
		old_directions.append(impact.direction)
	if finish_feedback:
		view.shot_feedback.advance(view.shot_feedback.flight_seconds + view.shot_feedback.result_recovery_seconds + 0.01)
		_check(main.impacts.back().direction.is_equal_approx(expected_direction), "embedded arrow matches the actual flight origin at release")
		for index: int in range(old_directions.size()):
			_check(main.impacts[index].direction == old_directions[index], "later shots preserve old arrow orientations")
