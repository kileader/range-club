extends Node

const REST_POINT: Vector2 = Vector2(820.0, 645.0)
const BARE_RIG: BuildDef = preload("res://content/equipment/bare_rig.tres")
const GYRO_BRACE: BuildDef = preload("res://content/equipment/gyro_brace.tres")
const PULSE_SIGHT: BuildDef = preload("res://content/equipment/pulse_sight.tres")

@onready var range_view: RangeView = $RangeView

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


func _ready() -> void:
	range_view.primary_pressed.connect(_on_primary_pressed)
	range_view.primary_released.connect(_on_primary_released)
	range_view.gear_requested.connect(_on_gear_requested)
	range_view.build_screen_requested.connect(_on_build_screen_requested)
	range_view.build_screen_closed.connect(_on_build_screen_closed)
	range_view.focus_requested.connect(_on_focus_requested)
	range_view.retry_requested.connect(_on_retry_requested)
	range_view.cancel_requested.connect(_on_cancel_requested)
	_refresh_view()


func _physics_process(delta: float) -> void:
	if not selection_open and impacts.size() < TrialRules.SHOTS_PER_TRIAL:
		var time_scale: float = TrialRules.FOCUS_TIME_SCALE if shot_focused else 1.0
		range_time += delta * time_scale
		shot.tick(delta, range_view.mouse_aim(), TargetLayout.centers_at(range_time))
	_refresh_view()


func _on_primary_pressed() -> void:
	if selection_open or impacts.size() >= TrialRules.SHOTS_PER_TRIAL:
		return
	if shot.phase == ShotModel.Phase.IDLE:
		shot_focused = focus_armed and focus > 0
		shot.configure(equipped.steering_scale, equipped.lock_radius if shot_focused else 0.0)
		shot.start_hold(REST_POINT)
	_refresh_view()


func _on_primary_released() -> void:
	if selection_open:
		return
	if shot.phase == ShotModel.Phase.DRAW:
		shot.cancel()
		shot_focused = false
	elif shot.phase == ShotModel.Phase.READY:
		if range_view.visible_reticle_valid:
			_accept_shot(range_view.visible_reticle)
		else:
			shot.cancel()
			shot_focused = false
	_refresh_view()


func _accept_shot(visible_impact: Vector2) -> void:
	var result: Dictionary = TargetLayout.score_at(visible_impact, range_view.visible_target_centers)
	var resolved: Dictionary = TrialRules.resolve_hit(result, equipped.id, shot_focused, shot.elapsed)
	last_score = resolved.points
	last_target = result.target
	last_bonus = resolved.bonus
	last_focus_gain = resolved.focus_gain
	total_score += last_score
	var hit_target: int = result.target_index
	var stored_point: Vector2 = visible_impact
	if hit_target >= 0:
		stored_point -= range_view.visible_target_centers[hit_target]
	impacts.append(ImpactRecord.new(hit_target, stored_point))
	if shot_focused:
		focus -= 1
	focus = mini(focus + last_focus_gain, TrialRules.MAX_FOCUS)
	focus_armed = false
	shot_focused = false
	shot.cancel()
	if impacts.size() == TrialRules.SHOTS_PER_TRIAL:
		best_score = maxi(best_score, total_score)


func _on_retry_requested() -> void:
	if build_selected and impacts.size() == TrialRules.SHOTS_PER_TRIAL:
		_reset_round()


func _on_build_screen_requested() -> void:
	if build_selected and shot.phase == ShotModel.Phase.IDLE and (impacts.is_empty() or impacts.size() == TrialRules.SHOTS_PER_TRIAL):
		selection_open = true
		_refresh_view()


func _on_build_screen_closed() -> void:
	if build_selected:
		selection_open = false
		_refresh_view()


func _on_focus_requested() -> void:
	if not selection_open and focus > 0 and shot.phase == ShotModel.Phase.IDLE and impacts.size() < TrialRules.SHOTS_PER_TRIAL:
		focus_armed = not focus_armed
		_refresh_view()


func _on_gear_requested(gear_id: StringName) -> void:
	if not selection_open or shot.phase != ShotModel.Phase.IDLE or (not impacts.is_empty() and impacts.size() < TrialRules.SHOTS_PER_TRIAL):
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
	_reset_round()


func _on_cancel_requested() -> void:
	if selection_open:
		_on_build_screen_closed()
		return
	shot.cancel()
	shot_focused = false
	_refresh_view()


func _reset_round() -> void:
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


func _refresh_view() -> void:
	range_view.present(
		shot, impacts, total_score, last_score, best_score,
		TrialRules.SHOTS_PER_TRIAL, TrialRules.GOAL_SCORE, equipped, last_target,
		last_bonus, last_focus_gain, range_time, focus, focus_armed,
		shot_focused, selection_open, build_selected
	)
