class_name RunController
extends Node

enum RunPhase { SELECT, SHOOT, REWARD, RESULT, LOADOUT }

const BARE_RIG: BuildDef = preload("res://content/equipment/bare_rig.tres")
const GYRO_BRACE: BuildDef = preload("res://content/equipment/gyro_brace.tres")
const PULSE_SIGHT: BuildDef = preload("res://content/equipment/pulse_sight.tres")

@onready var range_view: RangeView = $RangeView
@onready var run_view: RunView = $RunView

var shot: ShotModel = ShotModel.new()
var impacts: Array[ImpactRecord] = []
var total_score: int = 0
var last_score: int = -1
var best_score: int = -1
var equipped: BuildDef = BARE_RIG
var last_target: String = ""
var last_bonus: String = ""
var last_focus_gain: int = 0
var range_time: float = 0.0
var focus: int = TrialRules.START_FOCUS
var focus_armed: bool = false
var shot_focused: bool = false
var selection_open: bool = true
var build_selected: bool = false
var phase: RunPhase = RunPhase.SELECT
var stage: int = 0
var scenarios: Array[StringName] = []
var upgrades: Array[StringName] = []
var offers: Array[StringName] = []
var impact_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var offer_rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	impact_rng.randomize()
	offer_rng.randomize()
	range_view.primary_pressed.connect(_on_primary_pressed)
	range_view.primary_released.connect(_on_primary_released)
	range_view.gear_requested.connect(_on_gear_requested)
	range_view.build_screen_requested.connect(_on_build_screen_requested)
	range_view.rig_details_requested.connect(_on_rig_details_requested)
	range_view.build_screen_closed.connect(_on_build_screen_closed)
	range_view.focus_requested.connect(_on_focus_requested)
	range_view.cancel_requested.connect(_on_cancel_requested)
	run_view.upgrade_selected.connect(_on_upgrade_selected)
	run_view.new_run_requested.connect(_start_new_run)
	run_view.loadout_closed.connect(_on_loadout_closed)
	_start_new_run()


func _physics_process(delta: float) -> void:
	if phase == RunPhase.SHOOT and not _trial_over():
		var time_scale: float = equipped.focus_time_scale if shot_focused else 1.0
		range_time += delta * time_scale
		shot.tick(delta, range_view.mouse_aim())
	_refresh_view()


func _on_primary_pressed(aim_position: Vector2) -> void:
	if phase != RunPhase.SHOOT or _trial_over():
		return
	if shot.phase == ShotModel.Phase.IDLE:
		shot_focused = focus_armed and focus > 0
		var quickset_seconds: float = ShotModel.QUICKSET_SECONDS if upgrades.has(&"quickset_string") else 0.0
		var sight_hold_seconds: float = ShotModel.STABILIZING_SIGHT_HOLD_SECONDS if upgrades.has(&"stabilizing_sight") else 0.0
		shot.configure(
			equipped.steering_scale,
			equipped.focus_spread_scale if shot_focused else 1.0,
			equipped.precision_peak_seconds - quickset_seconds,
			quickset_seconds + sight_hold_seconds
		)
		shot.start_hold(aim_position)
	_refresh_view()


func _on_primary_released() -> void:
	if phase != RunPhase.SHOOT:
		return
	if shot.phase == ShotModel.Phase.DRAW:
		shot.cancel()
		shot_focused = false
	elif shot.phase == ShotModel.Phase.READY:
		if range_view.visible_reticle_valid:
			var impact: Vector2 = ShotModel.sample_impact(range_view.visible_reticle, range_view.visible_spread_radius, impact_rng)
			_accept_shot(impact)
		else:
			shot.cancel()
			shot_focused = false
	_refresh_view()


func _accept_shot(impact: Vector2) -> void:
	var result: Dictionary = TargetLayout.score_at(impact, range_view.visible_target_centers)
	var resolved: Dictionary = TrialRules.resolve_hit(result, equipped.id, shot_focused, shot.elapsed, scenarios[stage], upgrades)
	last_score = resolved.points
	last_target = result.target
	last_bonus = resolved.bonus
	last_focus_gain = resolved.focus_gain
	total_score += last_score
	var hit_target: int = result.target_index
	var stored_point: Vector2 = impact
	if hit_target >= 0:
		stored_point -= range_view.visible_target_centers[hit_target]
	impacts.append(ImpactRecord.new(hit_target, stored_point))
	if shot_focused:
		focus -= 1
	focus = mini(focus + last_focus_gain, TrialRules.MAX_FOCUS)
	focus_armed = false
	shot_focused = false
	shot.cancel()
	var result_sound: RangeView.ResultSound = RangeView.ResultSound.NONE
	if TrialRules.is_bust(total_score, _cap()):
		result_sound = RangeView.ResultSound.BUST
	elif TrialRules.is_cleared(total_score, _goal(), _cap()):
		result_sound = RangeView.ResultSound.CLEAR
	elif _trial_over():
		result_sound = RangeView.ResultSound.FAIL
	range_view.play_shot_feedback(last_score > 0, result_sound)
	if _trial_over():
		if not TrialRules.is_bust(total_score, _cap()):
			best_score = maxi(best_score, total_score)
		_advance_after_trial()


func _advance_after_trial() -> void:
	if TrialRules.is_cleared(total_score, _goal(), _cap()):
		if stage == RunRules.TRIAL_COUNT - 1:
			phase = RunPhase.RESULT
			run_view.show_result(true, stage, total_score, upgrades, equipped.operator_name)
		else:
			phase = RunPhase.REWARD
			offers = RunRules.draw_offers(upgrades, offer_rng)
			run_view.show_reward(stage, total_score, scenarios[stage + 1], offers, upgrades, equipped.operator_name)
	else:
		phase = RunPhase.RESULT
		run_view.show_result(false, stage, total_score, upgrades, equipped.operator_name)


func _on_upgrade_selected(upgrade_id: StringName) -> void:
	if phase != RunPhase.REWARD or not offers.has(upgrade_id) or upgrades.has(upgrade_id):
		return
	upgrades.append(upgrade_id)
	offers.clear()
	stage += 1
	phase = RunPhase.SHOOT
	run_view.hide_screen()
	_reset_trial()


func _on_build_screen_requested() -> void:
	if phase == RunPhase.SHOOT and stage == 0 and impacts.is_empty() and shot.phase == ShotModel.Phase.IDLE:
		selection_open = true
		phase = RunPhase.SELECT
		_refresh_view()


func _on_build_screen_closed() -> void:
	if phase == RunPhase.SELECT and build_selected:
		selection_open = false
		phase = RunPhase.SHOOT
		_refresh_view()


func _on_rig_details_requested() -> void:
	if phase != RunPhase.SHOOT or shot.phase != ShotModel.Phase.IDLE or _trial_over():
		return
	phase = RunPhase.LOADOUT
	run_view.show_loadout(equipped, stage, scenarios[stage], upgrades, focus)
	_refresh_view()


func _on_loadout_closed() -> void:
	if phase != RunPhase.LOADOUT:
		return
	phase = RunPhase.SHOOT
	run_view.hide_screen()
	_refresh_view()


func _on_focus_requested() -> void:
	if phase == RunPhase.SHOOT and focus > 0 and shot.phase == ShotModel.Phase.IDLE and not _trial_over():
		focus_armed = not focus_armed
		_refresh_view()


func _on_gear_requested(gear_id: StringName) -> void:
	if phase != RunPhase.SELECT or shot.phase != ShotModel.Phase.IDLE:
		return
	if gear_id == GYRO_BRACE.id:
		equipped = GYRO_BRACE
	elif gear_id == PULSE_SIGHT.id:
		equipped = PULSE_SIGHT
	elif gear_id == BARE_RIG.id:
		equipped = BARE_RIG
	else:
		return
	build_selected = true
	selection_open = false
	phase = RunPhase.SHOOT
	_reset_trial()


func _on_cancel_requested() -> void:
	if phase == RunPhase.LOADOUT:
		_on_loadout_closed()
		return
	if phase == RunPhase.SELECT:
		_on_build_screen_closed()
		return
	if phase != RunPhase.SHOOT:
		return
	shot.cancel()
	shot_focused = false
	_refresh_view()


func _start_new_run() -> void:
	phase = RunPhase.SELECT
	stage = 0
	scenarios = RunRules.draw_scenarios(offer_rng)
	upgrades.clear()
	offers.clear()
	equipped = BARE_RIG
	build_selected = false
	selection_open = true
	best_score = -1
	run_view.hide_screen()
	_reset_trial()


func _reset_trial() -> void:
	range_view.stop_sound_feedback()
	shot.cancel()
	impacts.clear()
	total_score = 0
	last_score = -1
	last_target = ""
	last_bonus = ""
	last_focus_gain = 0
	range_time = 0.0
	focus = TrialRules.START_FOCUS
	focus_armed = false
	shot_focused = false
	_refresh_view()


func _goal() -> int:
	return RunRules.goal_for_stage(stage)


func _cap() -> int:
	return RunRules.cap_for_stage(stage)


func _trial_over() -> bool:
	return TrialRules.is_trial_over(total_score, impacts.size(), _goal(), _cap())


func _refresh_view() -> void:
	range_view.present(
		shot, impacts, total_score, last_score, best_score,
		TrialRules.SHOTS_PER_TRIAL, _goal(), _cap(), equipped, last_target,
		last_bonus, last_focus_gain, range_time, focus, focus_armed,
		shot_focused, selection_open, build_selected, stage, scenarios[stage],
		upgrades, phase == RunPhase.SHOOT and stage == 0 and impacts.is_empty(),
		phase == RunPhase.SHOOT and build_selected and not _trial_over()
	)
